#!/usr/bin/env bash
# Generador de tráfico de estado estable (Lab 5).
# Envía RATE ventas por segundo en lazo abierto (cada petición sale en segundo plano,
# la tasa NO baja aunque el sistema se ponga lento) y, cada 5 s, una petición a la salud
# de Logística, al ítem de Inventario y al catálogo de productos externos (radio de impacto).
#
# Uso:  ./generador_trafico.sh salida.csv
# Variables (las define el bloque de variables del ambiente):
#   VENTA_URL  LOGISTICA_URL  INVENTARIO_URL  CATALOGO_URL
# Opcionales: RATE=2  DURACION=0 (segundos; 0 = hasta Ctrl+C)  VENTA_BODY=venta.json  MAX_TIME=10
#
# CSV: hora_utc,endpoint,codigo,latencia_ms,pending
#   endpoint ∈ venta | logistica | inventario | catalogo ; codigo 000 = sin respuesta/timeout
#   pending = 1 si el cuerpo trae pending_stock_confirmation

set -u
OUT="${1:?Uso: $0 salida.csv}"
RATE="${RATE:-2}"
DURACION="${DURACION:-0}"
VENTA_BODY="${VENTA_BODY:-venta.json}"
MAX_TIME="${MAX_TIME:-10}"
: "${VENTA_URL:?Defina VENTA_URL (pegue el bloque de variables del ambiente)}"
: "${LOGISTICA_URL:?Defina LOGISTICA_URL}"
: "${INVENTARIO_URL:?Defina INVENTARIO_URL}"
: "${CATALOGO_URL:?Defina CATALOGO_URL}"
[ -f "$VENTA_BODY" ] || { echo "No encuentro $VENTA_BODY (corra el script desde la carpeta de trabajo)"; exit 1; }

echo "hora_utc,endpoint,codigo,latencia_ms,pending" > "$OUT"

# Una petición: registra una línea en el CSV (líneas cortas: el append es atómico).
peticion() {
  local nombre="$1" metodo="$2" url="$3" tmp res code t pending ts
  tmp=$(mktemp)
  ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  if [ "$metodo" = "POST" ]; then
    res=$(curl -s -o "$tmp" -w '%{http_code} %{time_total}' --max-time "$MAX_TIME" \
          -X POST -H 'Content-Type: application/json' -d @"$VENTA_BODY" "$url")
  else
    res=$(curl -s -o "$tmp" -w '%{http_code} %{time_total}' --max-time "$MAX_TIME" "$url")
  fi
  code="${res%% *}"; t="${res##* }"
  [ -z "$code" ] && code=000
  pending=0
  grep -q 'pending_stock_confirmation' "$tmp" 2>/dev/null && pending=1
  rm -f "$tmp"
  # time_total en segundos (a veces con coma según el locale) -> ms
  echo "$ts,$nombre,$code,$(awk -v t="${t/,/.}" 'BEGIN{printf "%d", t*1000}'),$pending" >> "$OUT"
}

trap 'echo; echo "Detenido. Esperando respuestas pendientes..."; wait; echo "Listo: $OUT ($(($(wc -l < "$OUT")-1)) peticiones)"; exit 0' INT TERM

INTERVALO_MS=$(awk -v r="$RATE" 'BEGIN{printf "%d", 1000/r}')
INICIO=$(date +%s%3N)
PROX=$INICIO
SONDA_PROX=$INICIO
echo "Generador: $RATE ventas/s hacia $VENTA_URL -> $OUT (Ctrl+C para detener)"

while :; do
  AHORA=$(date +%s%3N)
  if [ "$DURACION" -gt 0 ] && [ $((AHORA - INICIO)) -ge $((DURACION * 1000)) ]; then break; fi
  if [ "$AHORA" -ge "$PROX" ]; then
    peticion venta POST "$VENTA_URL" &
    PROX=$((PROX + INTERVALO_MS))        # agenda por reloj: no acumula deriva
  fi
  if [ "$AHORA" -ge "$SONDA_PROX" ]; then
    peticion logistica GET "$LOGISTICA_URL" &
    peticion inventario GET "$INVENTARIO_URL" &
    peticion catalogo GET "$CATALOGO_URL" &
    SONDA_PROX=$((SONDA_PROX + 5000))
  fi
  sleep 0.02
done
wait
echo "Listo: $OUT ($(($(wc -l < "$OUT")-1)) peticiones)"
