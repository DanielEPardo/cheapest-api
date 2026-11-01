#!/usr/bin/env python3
"""Resumen por ventanas de 10 s de un CSV del generador de tráfico o de la tormenta.

Uso:  python3 ventanas.py archivo.csv [--inj HH:MM:SS] [--margen 30] [--ventana 10]

Por ventana y endpoint: peticiones, disponibilidad percibida (2xx en < 3000 ms),
% de pending, p99 de latencia. Guarda <archivo>_ventanas.csv.
Con --inj (hora UTC de T_inj) calcula además el mínimo de disponibilidad y el
máximo de p99 pasados `margen` segundos desde la inyección (medida de los ASR).
"""
import argparse, csv, math, sys
from collections import defaultdict
from datetime import datetime, timezone

UMBRAL_MS = 3000

def epoch(s):
    return datetime.strptime(s, "%Y-%m-%dT%H:%M:%S.%fZ").replace(tzinfo=timezone.utc).timestamp()

def p99(vals):
    v = sorted(vals)
    return v[max(0, math.ceil(0.99 * len(v)) - 1)] if v else 0

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--inj", help="hora UTC de T_inj, HH:MM:SS")
    ap.add_argument("--margen", type=int, default=30)
    ap.add_argument("--ventana", type=int, default=10)
    a = ap.parse_args()

    filas = []
    with open(a.csv, newline="") as f:
        for r in csv.DictReader(f):
            try:
                filas.append((epoch(r["hora_utc"]), r["endpoint"], int(r["codigo"]),
                              float(r["latencia_ms"]), int(r.get("pending") or 0)))
            except (ValueError, KeyError):
                continue
    if not filas:
        sys.exit("El CSV no tiene filas válidas.")

    t0 = min(f[0] for f in filas)
    W = a.ventana
    grupos = defaultdict(list)
    for t, ep, code, lat, pend in filas:
        grupos[(int((t - t0) // W) * W, ep)].append((code, lat, pend))

    t_inj = None
    if a.inj:
        dia = datetime.fromtimestamp(t0, timezone.utc).date()
        h = datetime.strptime(a.inj, "%H:%M:%S").time()
        t_inj = datetime.combine(dia, h, tzinfo=timezone.utc).timestamp() - t0

    base = a.csv[:-4] if a.csv.endswith(".csv") else a.csv
    salida = base + "_ventanas.csv"
    resumen = defaultdict(lambda: {"disp": [], "p99": [], "pend": []})
    print(f"{'t(s)':>6} {'hora_utc':>9} {'endpoint':<11} {'n':>4} {'disp%':>7} {'pend%':>6} {'p99ms':>7}")
    with open(salida, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["ventana_s", "hora_utc", "endpoint", "peticiones", "disponibilidad_pct", "pending_pct", "p99_ms"])
        for (ini, ep) in sorted(grupos):
            g = grupos[(ini, ep)]
            n = len(g)
            utiles = sum(1 for c, l, _ in g if 200 <= c < 300 and l < UMBRAL_MS)
            disp = 100.0 * utiles / n
            pend = 100.0 * sum(p for *_, p in g) / n
            q = p99([l for _, l, _ in g])
            hora = datetime.fromtimestamp(t0 + ini, timezone.utc).strftime("%H:%M:%S")
            w.writerow([ini, hora, ep, n, f"{disp:.1f}", f"{pend:.1f}", f"{q:.0f}"])
            print(f"{ini:>6} {hora:>9} {ep:<11} {n:>4} {disp:>7.1f} {pend:>6.1f} {q:>7.0f}")
            if t_inj is None or ini >= t_inj + a.margen:
                resumen[ep]["disp"].append(disp); resumen[ep]["p99"].append(q); resumen[ep]["pend"].append(pend)

    cab = "todas las ventanas" if t_inj is None else f"ventanas desde T_inj+{a.margen}s"
    print(f"\nResumen ({cab}):")
    for ep, d in sorted(resumen.items()):
        if d["disp"]:
            print(f"  {ep:<11} disp. mínima {min(d['disp']):.1f}% | p99 máx {max(d['p99']):.0f} ms | "
                  f"pending medio {sum(d['pend'])/len(d['pend']):.1f}% | ventanas {len(d['disp'])}")
    print(f"\nTabla guardada en {salida}")

if __name__ == "__main__":
    main()
