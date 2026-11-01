#!/usr/bin/env bash
# Simula CLIENTES instancias de una app de tenderos con la política de reintentos DEFECTUOSA:
# cada app envía un pedido y, si no recibe un 2xx dentro de TIMEOUT_CLIENTE segundos,
# ABANDONA la petición y la REENVÍA de inmediato (sin esperar). Tras un pedido exitoso
# espera 5 s antes del siguiente. Una petición abandonada no se cancela en el servidor.
#
# Uso:  CLIENTES=50 DURACION=120 ./tormenta_reintentos.sh salida.csv
# Variables: VENTA_URL (obligatoria)  CLIENTES=50  DURACION=120  TIMEOUT_CLIENTE=3
#            BACKOFF=0 (1 = el cliente espera entre intentos: backoff exponencial + jitter)
#            VENTA_BODY=venta.json
#
# CSV: hora_utc,endpoint,codigo,latencia_ms,pending,cliente,pedido,intento   (endpoint=tormenta)
#   codigo 000 = petición abandonada por el cliente (timeout)

set -u
OUT="${1:?Uso: $0 salida.csv}"
CLIENTES="${CLIENTES:-50}"
DURACION="${DURACION:-120}"
TIMEOUT_CLIENTE="${TIMEOUT_CLIENTE:-3}"
BACKOFF="${BACKOFF:-0}"
VENTA_BODY="${VENTA_BODY:-venta.json}"
: "${VENTA_URL:?Defina VENTA_URL (pegue el bloque de variables del ambiente)}"
[ -f "$VENTA_BODY" ] || { echo "No encuentro $VENTA_BODY (corra el script desde la carpeta de trabajo)"; exit 1; }

echo "hora_utc,endpoint,codigo,latencia_ms,pending,cliente,pedido,intento" > "$OUT"
FIN=$(( $(date +%s%3N) + DURACION * 1000 ))

cliente() {
  local id="$1" pedido=0 intento ok tmp res code t pending ts
  while [ "$(date +%s%3N)" -lt "$FIN" ]; do
    pedido=$((pedido + 1)); intento=0; ok=0
    while [ "$(date +%s%3N)" -lt "$FIN" ]; do
      intento=$((intento + 1))
      tmp=$(mktemp)
      ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
      res=$(curl -s -o "$tmp" -w '%{http_code} %{time_total}' --max-time "$TIMEOUT_CLIENTE" \
            -X POST -H 'Content-Type: application/json' -d @"$VENTA_BODY" "$VENTA_URL")
      code="${res%% *}"; t="${res##* }"; [ -z "$code" ] && code=000
      pending=0; grep -q 'pending_stock_confirmation' "$tmp" 2>/dev/null && pending=1
      rm -f "$tmp"
      echo "$ts,tormenta,$code,$(awk -v t="${t/,/.}" 'BEGIN{printf "%d", t*1000}'),$pending,$id,$pedido,$intento" >> "$OUT"
      if [ "$code" -ge 200 ] 2>/dev/null && [ "$code" -lt 300 ]; then ok=1; break; fi
      if [ "$BACKOFF" = "1" ]; then
        sleep "$(awk -v n="$intento" -v s="$RANDOM" 'BEGIN{srand(s); e=0.2*2^(n-1); if(e>5)e=5; printf "%.2f", e*(0.5+rand())}')"
      fi
    done
    [ "$ok" = "1" ] && sleep 5
  done
}

echo "Tormenta: $CLIENTES apps, ${DURACION}s, timeout ${TIMEOUT_CLIENTE}s, BACKOFF=$BACKOFF -> $OUT"
trap 'kill $(jobs -p) 2>/dev/null' INT TERM
for i in $(seq 1 "$CLIENTES"); do cliente "$i" & done
wait

# Resumen
awk -F, 'NR>1 {
  intentos++; k=$6 "-" $7
  if(!(k in vis)){vis[k]=1; pedidos++}
  if($3>=200 && $3<300 && !(k in comp)){comp[k]=1; completados++}
  if($3=="000") aband++
  if($3=="429") r429++
  if($3>=500) r5xx++
  if($5==1) pend++
} END {
  printf "\n=== Resumen de la tormenta ===\n"
  printf "Pedidos que querían hacer las apps : %d\n", pedidos
  printf "Pedidos completados (2xx a tiempo) : %d (%.1f%%)\n", completados, (pedidos? 100*completados/pedidos:0)
  printf "Peticiones enviadas (intentos)     : %d\n", intentos
  printf "Intentos por pedido                : %.2f\n", (pedidos? intentos/pedidos:0)
  printf "Peticiones abandonadas (timeout)   : %d\n", aband
  printf "Respuestas 429                     : %d\n", r429
  printf "Respuestas 5xx                     : %d\n", r5xx
  printf "Respuestas pending_stock_confirm.  : %d\n", pend
}' "$OUT"
