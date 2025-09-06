#!/bin/bash
# =================================================
# Integrantes:
# - Felice, Tomas Agustin
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# =================================================

# Función para mostrar ayuda
mostrar_ayuda() {
    echo "Uso: $0 -d DIRECTORIO -p PALABRAS"
    echo ""
    echo "Procesa archivos de logs en un directorio y devuelve la cantidad de ocurrencias de las palabras indicadas."
    echo ""
    echo "Opciones:"
    echo "  -d, --directorio DIRECTORIO    Directorio que contiene los archivos a procesar (obligatorio)"
    echo "  -p, --palabras PALABRAS      Palabras a buscar separadas por comas (obligatorio)"
    echo "  -h, --help                     Mostrar esta ayuda"
    exit 0
}

# Función para validar directorio
validar_directorio() {
    local directorio="$1"
    
    # Convertir a ruta absoluta si es relativa
    if [[ ! "$directorio" = /* ]]; then
        directorio="$(realpath "$directorio" 2>/dev/null)"
        if [[ $? -ne 0 ]]; then
            echo "Error: No se pudo resolver la ruta '$1'" >&2
            return 1
        fi
    fi
    
    if [[ ! -d "$directorio" ]]; then
        echo "Error: El directorio '$directorio' no existe" >&2
        return 1
    fi
    
    if [[ ! -r "$directorio" ]]; then
        echo "Error: No se puede leer el directorio '$directorio'" >&2
        return 1
    fi
    
    echo "$directorio"
    return 0
}

# Función para procesar archivos
procesar_archivos() {
    local directorio="$1"
    
    # Verificar que hay archivos .log y que son legibles
    local archivos_encontrados=0
    for archivo in "$directorio"/*.log; do
        if [[ -f "$archivo" && -r "$archivo" ]]; then
            archivos_encontrados=1
            break
        fi
    done
    
    if [[ $archivos_encontrados -eq 0 ]]; then
        echo "Error: No se encontraron archivos .log legibles en el directorio '$directorio'" >&2
        return 1
    fi
    
    # Procesar archivos con awk
    awk -v palabras="$PALABRAS" '
    BEGIN {
        FS = "\n"
        split(palabras, arr_palabras, ",")
        
        # Procesar y limpiar palabras
        for (i in arr_palabras) {
            palabra = arr_palabras[i]
            gsub(/^ +| +$/, "", palabra)  # Eliminar espacios al inicio y final
            if (palabra != "") {
                palabra_original = palabra
                palabra_lower = tolower(palabra)
                conteos[palabra_original] = 0 # Usar palabra original para output
                palabras_buscar[palabra_lower] = palabra_original # Mapeo para búsqueda
            }
        }
        
        # Verificar que hay palabras válidas
        if (length(conteos) == 0) {
            print "Error: No se proporcionaron palabras válidas para buscar" > "/dev/stderr"
            exit 1
        }
    }
    # Esto se ejecuta por cada fila
    {
        # Limpiamos /r si viene
        gsub(/\r/, "", $0)
        linea_original = $0
        linea_lower = tolower(linea_original)
        
        # Buscar cada palabra en la línea
        for (palabra_lower in palabras_buscar) {
            palabra_original = palabras_buscar[palabra_lower]
            # Contar ocurrencias usando match con regex
            temp_linea = linea_lower
            count = 0
            while (match(temp_linea, palabra_lower)) {
                count++
                temp_linea = substr(temp_linea, RSTART + RLENGTH)
            }
            conteos[palabra_original] += count
        }
    }
    # Luego de procesar todas las filas
    END {
        # Mostrar resultados en el orden original de las palabras
        split(palabras, arr_palabras, ",")
        for (i = 1; i <= length(arr_palabras); i++) {
            palabra = arr_palabras[i]
            gsub(/^ +| +$/, "", palabra)
            if (palabra != "" && palabra in conteos) {
                print palabra ": " conteos[palabra]
            }
        }
    }
    ' "$directorio"/*.log 2>/dev/null
    
    local awk_exit_code=$?
    if [[ $awk_exit_code -ne 0 ]]; then
        echo "Error: Fallo al procesar los archivos en '$directorio'" >&2
        return 1
    fi
    
    return 0
}

# Archivo temporal para resultados
TEMP_FILE=$(mktemp /tmp/ejercicio3.XXXXXX)

# Trap para limpiar archivos temporales al salir
trap 'rm -f "$TEMP_FILE"' EXIT

# --- Manejo de parametros ---
DIRECTORIO=""
PALABRAS=""

# Si hay parametros...
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directorio)
            DIRECTORIO="$2"
            shift 2
            ;;
        -p|--palabras)
            PALABRAS="$2"
            shift 2
            ;;
        -h|--help)
            mostrar_ayuda
            ;;
        *)
            echo "Error: Parametro desconocido: $1" >&2
            echo "Use -h o --help para ver la ayuda" >&2
            exit 1
            ;;
    esac
done

# Validacion de parametros
if [[ -z "$DIRECTORIO" ]]; then
    echo "Error: Debe indicar un directorio con -d" >&2
    echo "Use -h o --help para ver la ayuda" >&2
    exit 1
fi

if [[ -z "$PALABRAS" ]]; then
    echo "Error: Debe indicar palabras a buscar con -p" >&2
    echo "Use -h o --help para ver la ayuda" >&2
    exit 1
fi

# Validar que las palabras no estén vacías después de limpiar espacios
PALABRAS_LIMPIA=$(echo "$PALABRAS" | sed 's/[[:space:]]*,[[:space:]]*/,/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [[ -z "$PALABRAS_LIMPIA" || "$PALABRAS_LIMPIA" == "," ]]; then
    echo "Error: Las palabras especificadas están vacías o son inválidas" >&2
    echo "Use -h o --help para ver la ayuda" >&2
    exit 1
fi
PALABRAS="$PALABRAS_LIMPIA"

# Validar y normalizar directorio
DIRECTORIO=$(validar_directorio "$DIRECTORIO")
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Procesar archivos y mostrar en pantalla
if ! procesar_archivos "$DIRECTORIO"; then
    echo "Error: Fallo en el procesamiento de archivos" >&2
    exit 1
fi

