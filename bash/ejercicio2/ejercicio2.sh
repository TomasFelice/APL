#!/usr/bin/env bash
#
# analiza_red.sh
#
# Uso:
#   ./analiza_red.sh -m /ruta/mapa_transporte.txt -h [-s "|"]
#   ./analiza_red.sh -m /ruta/mapa_transporte.txt -c [-s "|"]
#
# Produce: informe.<nombreArchivoEntrada> en el mismo directorio del archivo.
#

set -euo pipefail

show_usage() {
  cat <<EOF
Uso:
  $0 -m|--matriz <archivo> (-h|--hub | -c|--camino) [-s|--separador <caracter>]

Opciones:
  -m, --matriz     Ruta del archivo de la matriz de adyacencia (obligatorio).
  -h, --hub        Determina qué estación(es) es/son hub. No combinable con -c.
  -c, --camino     Encuentra el/los camino(s) más corto(s) en tiempo. No combinable con -h.
  -s, --separador  Separador de columnas (por defecto: | ).
EOF
  exit 1
}

# --- Parseo de argumentos ---
MATRIZ=""
MODE=""
SEP="|"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--matriz)
      MATRIZ="$2"; shift 2;;
    -h|--hub)
      MODE="hub"; shift ;;
    -c|--camino)
      MODE="camino"; shift ;;
    -s|--separador)
      if [[ ${#2} -ne 1 ]]; then
        echo "Error: El separador debe ser un único carácter." >&2
        exit 1
      fi
      SEP="$2"; shift 2;;
    -*)
      echo "Opción desconocida: $1"; show_usage;;
    *)
      echo "Parámetro inesperado: $1"; show_usage;;
  esac
done

if [[ -z "$MATRIZ" || -z "$MODE" ]]; then
  echo "Faltan argumentos obligatorios."
  show_usage
fi

if [[ ! -f "$MATRIZ" ]]; then
  echo "Archivo no encontrado: $MATRIZ"
  exit 2
fi

# Nombre del archivo de salida: informe.<basename>
basedir=$(dirname -- "$MATRIZ")
basefile=$(basename -- "$MATRIZ")
outfile="$basedir/informe.$basefile"

# Requerimos gawk (para recursión y manejo robusto de arrays). Si no existe, usamos awk y advertimos.
AWK_BIN="gawk"
if ! command -v "$AWK_BIN" >/dev/null 2>&1; then
  if command -v awk >/dev/null 2>&1; then
    AWK_BIN="awk"
    echo "Advertencia: gawk no está instalado. Se usará awk por defecto; algunas funciones (recursión) podrían no estar disponibles." >&2
  else
    echo "No se encontró awk/gawk en el sistema." >&2
    exit 3
  fi
fi

# Ejecutamos el AWK que hace toda la lógica.
"$AWK_BIN" -v sep="$SEP" -v mode="$MODE" '
# función para borrar pred arrays
# pred_count[v] da la cantidad de predecesores, pred[v,k] enumerados 1..pred_count[v]

function clear_preds() {
  for (i = 1; i <= n; i++) {
    if (pred_count[i] > 0) {
      for (k = 1; k <= pred_count[i]; k++) delete pred[i,k]
    }
    pred_count[i] = 0
  }
}

# Dijkstra desde s
function dijkstra(s,    i,j,u,v,w,newd,found,mind) {
  for (i = 1; i <= n; i++) {
    dist[i] = INF
    visited[i] = 0
    pred_count[i] = 0
  }
  dist[s] = 0
  while (1) {
    u = -1; mind = INF
    for (i = 1; i <= n; i++) if (!visited[i] && dist[i] < mind) { mind = dist[i]; u = i }
    if (u == -1) break
    visited[u] = 1
    for (v = 1; v <= n; v++) {
      w = mat[u,v]
      if (v != u && w > eps) {
        newd = dist[u] + w
        if (newd + eps < dist[v]) {
          dist[v] = newd
          # reset predecesores
          if (pred_count[v] > 0) {
            for (k = 1; k <= pred_count[v]; k++) delete pred[v,k]
          }
          pred_count[v] = 1
          pred[v,1] = u
        } else if ( (newd - dist[v]) <= eps && (dist[v] - newd) <= eps ) {
          # nuevo camino con mismo coste -> añadimos predecesor
          pred_count[v]++
          pred[v, pred_count[v]] = u
        }
      }
    }
  }
}

# reconstructor recursivo de rutas (desde target t hasta s)
# dfs(v): si v==s -> imprimir s y luego arr desde len..1
function dfs_build(v, s, arr, len,    k, out, i) {
  if (v == s) {
    out = s
    for (i = len; i >= 1; i--) out = out " -> " arr[i]
    print out
  } else {
    if (pred_count[v] == 0) {
      # no hay predecesores -> inaccesible
      # no imprimimos rutas
      return
    }
    for (k = 1; k <= pred_count[v]; k++) {
      arr[len+1] = v
      dfs_build(pred[v,k], s, arr, len+1)
    }
  }
}

BEGIN {
  FS = sep
  OFS = " "
  INF = 1e18
  eps = 1e-9
  nrows = 0
}

# lectura y validación básica línea por línea
{
  nrows++
  # split preserva campos según FS
  # guardamos campos en mat[nrows,i]
  cols = split($0, fields, FS)
  if (nrows == 1) expected = cols
  else if (cols != expected) {
    printf("ERROR: Matriz no cuadrada: fila %d tiene %d columnas (esperaba %d)\n", nrows, cols, expected) > "/dev/stderr"
    exit 2
  }
  for (i = 1; i <= cols; i++) {
    val = fields[i]
    # trim spaces
    gsub(/^[ \t\r]+|[ \t\r]+$/, "", val)
    if (val == "") val = "0"
    # validar número (entero o decimal)
    if (val !~ /^-?[0-9]+(\.[0-9]+)?$/) {
      printf("ERROR: Valor no numérico en fila %d columna %d: \"%s\"\n", nrows, i, fields[i]) > "/dev/stderr"
      exit 3
    }
    mat[nrows, i] = val + 0  # forzar numérico
  }
}

END {
  if (nrows != expected) {
    print "ERROR: Matriz no cuadrada (filas != columnas)" > "/dev/stderr"
    exit 4
  }
  n = nrows
  # comprobación de simetría y diagonal cero
  for (i = 1; i <= n; i++) {
    for (j = 1; j <= n; j++) {
      a = mat[i,j] + 0
      b = mat[j,i] + 0
      # diagonal -> se exige 0 (por definicion)
      if (i == j) {
        if ( (a > eps) || (a < -eps) ) {
          printf("ERROR: diagonal [%d,%d] debe ser 0, es %g\n", i, j, a) > "/dev/stderr"
          exit 5
        }
      }
      # simetría (permitimos pequeñas diferencias por floats)
      if ( (a - b) > eps || (b - a) > eps ) {
        printf("ERROR: Matriz no simétrica en (%d,%d): %g != %g\n", i, j, a, b) > "/dev/stderr"
        exit 6
      }
      # pesos negativos no permitidos
      if (a < -eps) {
        printf("ERROR: Peso negativo detectado en (%d,%d): %g\n", i, j, a) > "/dev/stderr"
        exit 7
      }
    }
  }

  # Si piden hub:
  if (mode == "hub") {
    # contar conexiones (no contar diagonal, y valores > 0 significan conexión)
    maxdeg = -1
    delete hubs
    for (i = 1; i <= n; i++) {
      deg = 0
      for (j = 1; j <= n; j++) {
        if (i != j && mat[i,j] > eps) deg++
      }
      degs[i] = deg
      if (deg > maxdeg) {
        maxdeg = deg
        delete hubs
        hubs[i] = 1
      } else if (deg == maxdeg) {
        hubs[i] = 1
      }
    }
    print "ANALISIS: Detectando hub(s) en la red"
    print "Estaciones totales:", n
    print ""
    print "Grado (cantidad de conexiones) por estación:"
    for (i = 1; i <= n; i++) printf("  Estación %d: %d\n", i, degs[i])
    print ""
    printf("Hub(s) (grado máximo = %d):", maxdeg)
    sepout = " "
    for (i in hubs) {
      printf("%s%d", sepout, i)
      sepout = ", "
    }
    print "\n"
    exit 0
  }

  # Si piden camino(s): implementar Dijkstra desde cada fuente (todos los pares), guardando predecesores múltiples
  if (mode == "camino") {
    printf("ANALISIS: Caminos minimos (Dijkstra) para cada par de estaciones\n")
    printf("Estaciones: %d\n\n", n)

    # Ejecutar Dijkstra para cada fuente s
    for (s = 1; s <= n; s++) {
      clear_preds()
      dijkstra(s)
      print "----"
      printf("Origen: %d\n", s)
      for (t = 1; t <= n; t++) {
        if (t == s) continue
        if (dist[t] >= INF/2) {
          printf("Destino %d: no existe camino desde %d\n", t, s)
        } else {
          # mostrar tiempo con formato: si entero mostrar sin decimales, sino con hasta 6 decimales (limpiar ceros)
          # usamos sprintf para formatear
          timestr = sprintf("%.6f", dist[t])
          # quitar ceros finales y punto si aplica
          sub(/0+$/, "", timestr)
          sub(/\.$/, "", timestr)
          printf("Destino %d: tiempo minimo = %s\n", t, timestr)
          print "Rutas (todas las rutas con tiempo minimo):"
          # reconstruir caminos: llamamos dfs_build con v=t
          delete tmparr
          dfs_build(t, s, tmparr, 0)
          print ""
        }
      }
      print ""
    }
    exit 0
  }

  print "ERROR: modo desconocido: $MODE" > "/dev/stderr"
  exit 10
}
' "$MATRIZ" > "$outfile"

echo "Informe generado: $outfile"
