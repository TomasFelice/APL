#!/bin/bash
# =================================================
# Integrantes:
# - Felice, Tomas Agustin
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# =================================================

# Función para mostrar ayuda
mostrar_ayuda() {
    echo "Uso: $0 -d DIRECTORIO [-a ARCHIVO_SALIDA | -p]"
    echo ""
    echo "Procesa archivos de datos en un directorio y genera un reporte en formato JSON."
    echo ""
    echo "Opciones:"
    echo "  -d, --directorio DIRECTORIO    Directorio que contiene los archivos a procesar (obligatorio)"
    echo "  -a, --archivo ARCHIVO          Archivo de salida donde guardar el resultado"
    echo "  -p, --pantalla                 Mostrar el resultado en pantalla"
    echo "  -h, --help                     Mostrar esta ayuda"
    echo ""
    echo "Nota: Debe especificar -a o -p, pero no ambos."
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
    
    # Verificar que hay archivos .txt y que son legibles
    local archivos_encontrados=0
    for archivo in "$directorio"/*.txt; do
        if [[ -f "$archivo" && -r "$archivo" ]]; then
            archivos_encontrados=1
            break
        fi
    done
    
    if [[ $archivos_encontrados -eq 0 ]]; then
        echo "Error: No se encontraron archivos .txt legibles en el directorio '$directorio'" >&2
        return 1
    fi
    
    awk -F"|" '
    # Esto se ejecuta por cada fila
    {
        # Limpiamos /r si viene
        gsub(/\r/, "", $0)

        # Fecha corta (yyy-mm-dd)
        fecha = substr($2, 1, 10)
        canal = $3
        clave = fecha "|" canal

        sum_tiempo[clave]   += $4
        sum_nota[clave]     += $5
        count[clave]++
        fechas[fecha] = 1
    }
    # Luego de procesar todas las filas
    END {
        # Verificar que procesamos al menos una línea
        if (length(fechas) == 0) {
            print "Error: No se procesaron datos válidos" > "/dev/stderr"
            exit 1
        }
        
        # Ordenamos las claves de fechas
        n = asorti(fechas, fechas_ordenadas)

        printf "{\n"
        for(i = 1; i <= n; i++) {
            fecha = fechas_ordenadas[i]
            printf "  \"%s\": {\n", fecha

            sep = ""
            for(clave in count) {
                split(clave, arr, "|")
                if (arr[1] == fecha) {
                    printf "%s    \"%s\": {\n", sep, arr[2]
                    printf "      \"tiempo_respuesta_promedio\": %.2f,\n", sum_tiempo[clave]/count[clave]
                    printf "      \"nota_satisfaccion_promedio\": %.2f\n", sum_nota[clave]/count[clave]
                    printf "    }"
                    sep = ",\n"
                }
            }
            printf "\n  }"
            if (i < n) printf ",\n"; else printf "\n"
        }
        printf "}\n"
    }
    ' "$directorio"/*.txt 2>/dev/null
    
    local awk_exit_code=$?
    if [[ $awk_exit_code -ne 0 ]]; then
        echo "Error: Fallo al procesar los archivos en '$directorio'" >&2
        return 1
    fi
    
    return 0
}

# Archivo temporal para resultados
TEMP_FILE=$(mktemp /tmp/ejercicio1.XXXXXX)

# Trap para limpiar archivos temporales al salir
trap 'rm -f "$TEMP_FILE"' EXIT

# --- Manejo de parametros ---
DIRECTORIO=""
ARCHIVO_SALIDA=""
PANTALLA=FALSE

# Si hay parametros...
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--directorio)
            DIRECTORIO="$2"
            shift 2
            ;;
        -a|--archivo)
            ARCHIVO_SALIDA="$2"
            shift 2
            ;;
        -p|--pantalla)
            PANTALLA=TRUE
            shift 1
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

if [[ -z "$ARCHIVO_SALIDA" && "$PANTALLA" = FALSE ]]; then
    echo "Error: Debe indicar un archivo de salida con -a o la opcion -p para mostrar en pantalla" >&2
    echo "Use -h o --help para ver la ayuda" >&2
    exit 1
fi

if [[ "$ARCHIVO_SALIDA" && "$PANTALLA" = TRUE ]]; then
    echo "Error: La opcion -p no puede ser utilizada con un archivo de salida. Debe indicar un archivo de salida sin el parametro -p, o utilizar -p sin un archivo de salida." >&2
    echo "Use -h o --help para ver la ayuda" >&2
    exit 1
fi

# Validar y normalizar directorio
DIRECTORIO=$(validar_directorio "$DIRECTORIO")
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Procesar archivos y guardar en archivo temporal
if ! procesar_archivos "$DIRECTORIO" > "$TEMP_FILE"; then
    echo "Error: Fallo en el procesamiento de archivos" >&2
    exit 1
fi

# Mostrar resultado
if [[ "$PANTALLA" = TRUE ]]; then
    cat "$TEMP_FILE"
    if [[ $? -ne 0 ]]; then
        echo "Error: No se pudo mostrar el resultado" >&2
        exit 1
    fi
else
    # Crear directorio de salida si no existe
    DIRECTORIO_SALIDA=$(dirname "$ARCHIVO_SALIDA")
    if [[ ! -d "$DIRECTORIO_SALIDA" ]]; then
        if ! mkdir -p "$DIRECTORIO_SALIDA"; then
            echo "Error: No se pudo crear el directorio '$DIRECTORIO_SALIDA'" >&2
            exit 1
        fi
    fi
    
    if ! cp "$TEMP_FILE" "$ARCHIVO_SALIDA"; then
        echo "Error: No se pudo escribir en el archivo '$ARCHIVO_SALIDA'" >&2
        exit 1
    fi
    echo "Resultado guardado en: $ARCHIVO_SALIDA"
fi