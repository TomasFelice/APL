#!/usr/bin/env bash
# =================================================
# Integrantes:
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# - Felice, Tomas Agustin
# =================================================

set -euo pipefail

# Función para mostrar ayuda
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
      MATRIZ="$2"
      shift 2;;
    -h|--hub)
      MODE="hub"
      shift;;
    -c|--camino)
      MODE="camino"
      shift;;
    -s|--separador)
      [[ ${#2} -ne 1 ]] && { echo "Error: El separador debe ser un único carácter." >&2; exit 1; }
      SEP="$2"
      shift 2;;
    --help)
      show_usage;;
    *)
      echo "Error: Parametro desconocido: $1" >&2
      echo "Use --help para ver la ayuda" >&2
      exit 1;;
  esac
done

# Validaciones consolidadas
[[ -z "$MATRIZ" || -z "$MODE" ]] && { echo "Faltan argumentos obligatorios."; show_usage; }
[[ ! -f "$MATRIZ" ]] && { echo "Archivo no encontrado: $MATRIZ"; exit 2; }

# Archivo de salida simplificado
outfile="output/informe.$(basename -- "$MATRIZ")"

# Ejecutamos el AWK que hace toda la lógica.
awk -v sep="$SEP" -v mode="$MODE" -f main.awk "$MATRIZ" > "$outfile"

echo "Informe generado: $outfile"
