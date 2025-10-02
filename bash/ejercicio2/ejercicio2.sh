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
      MATRIZ="$2";
      shift 2;;
    -h|--hub)
      MODE="hub";
      shift ;;
    -c|--camino)
      MODE="camino";
      shift ;;
    -s|--separador)
      if [[ ${#2} -ne 1 ]]; then
        echo "Error: El separador debe ser un único carácter." >&2
        exit 1
      fi
      SEP="$2";
      shift 2;;
    --help)
      show_usage;
      shift;;
    -* | *)
      echo "Error: Parametro desconocido: $1" >&2
      echo "Use --help para ver la ayuda" >&2
      exit 1
      ;;
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
outfile="output/informe.$basefile"

# Ejecutamos el AWK que hace toda la lógica.
awk -v sep="$SEP" -v mode="$MODE" -f main.awk "$MATRIZ" > "$outfile"

echo "Informe generado: $outfile"
