#!/usr/bin/env bash
# =================================================
# Integrantes:
# - Felice, Tomas Agustin
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# =================================================

#parametros bash
#[-n | --nombre] nombre pais a buscar 
#[-t | --ttl] tiempo en dias que se guardaran los resultados en cache
#[-h | --help] mostrar ayuda
set -euo pipefail
mostrar_ayuda(){
    # RECORDATORIO: redirecciona hacia la terminal
    cat << EOF
    Uso: $0 [-n|--nombre PAIS] [-t|--ttl TIEMPO] [-h|--help]

    Opciones:
    -n, --nombre PAIS   --> Especificar el nombre del pais (obligatorio).
    -t, --ttl TIEMPO    --> Especificar el tiempo en dias para la duracion de los archivos.
    -h, --help          --> Mostrar este mensaje de ayuda.

    Ejemplos:
        $0 -n argentina
        $0 -n "saudi arabia"
        $0 -n "saudi arabia -n argentina
        $0 -n argentina -n brasil -n colombia
        $0 -n argentina -n brasil -n colombia -t 2
EOF
    exit 0
}
handle_error(){
    echo -e "Error: $1"
    exit "$2"
}

verificar_dependencias(){
    local dependencias_faltantes=()
    
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        dependencias_faltantes+=("curl")
    fi
    
    # Verificar jq
    if ! command -v jq &> /dev/null; then
        dependencias_faltantes+=("jq")
    fi
    
    if [ ${#dependencias_faltantes[@]} -gt 0 ]; then
        echo -e "${ROJO}Las siguientes herramientas no están disponibles: ${dependencias_faltantes[*]}${RESET}"
        echo "Use el gestor de paquetes de su sistema para instalarlas:"
        
        for dep in "${dependencias_faltantes[@]}"; do
            case "$dep" in
                "jq")
                    echo -e "  • ${VERDE}Debian/Ubuntu:${RESET} sudo apt-get install jq"
                    echo -e "  • ${VERDE}Fedora/RHEL:${RESET} sudo dnf install jq"
                    echo -e "  • ${VERDE}CentOS:${RESET} sudo yum install jq"
                    echo -e "  • ${VERDE}Arch Linux:${RESET} sudo pacman -S jq"
                    echo -e "  • ${VERDE}macOS:${RESET} brew install jq"
                    ;;
                "curl")
                    echo -e "  • ${VERDE}Debian/Ubuntu:${RESET} sudo apt-get install curl"
                    echo -e "  • ${VERDE}Fedora/RHEL:${RESET} sudo dnf install curl"
                    echo -e "  • ${VERDE}CentOS:${RESET} sudo yum install curl"
                    echo -e "  • ${VERDE}Arch Linux:${RESET} sudo pacman -S curl"
                    echo -e "  • ${VERDE}macOS:${RESET} curl ya está instalado por defecto"
                    ;;
            esac
        done
        
        handle_error "${ROJO}Dependencias faltantes: ${dependencias_faltantes[*]}${RESET}" $E_COMANDO_JQ
    fi
}

verificar_sistema(){
    # Detectar el sistema operativo
    local os_type=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macOS"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        os_type="Windows"
    fi
    
    # Verificar si estamos en un entorno que requiere atención especial
    if [[ "$os_type" == "Windows" ]]; then
        echo -e "${AMARILLO}Detectado entorno Windows. Asegúrese de usar terminaciones de línea Unix.${RESET}"
    fi
}

mostrar_pais(){
    infoPais=$1
    infoMoneda=$2

    echo "${infoPais}" | jq -r '"Nombre: \(.nombre)"'
    echo "$infoPais" | jq -r '"Capital: \(.capital)"'
    echo "$infoPais" | jq -r '"Region: \(.region)"'
    echo "$infoPais" | jq -r '"Poblacion: \(.poblacion)"'
    echo "$infoMoneda" | jq -r '"Moneda: \(.tipo) (\(.abrev))"'
}

get_pais_web(){
    local nomPais="$1"
    local urlBase="https://restcountries.com/v3.1/name"
    local urlPais="${urlBase}/$(echo "${nomPais}" | sed 's/ /%20/g')"
    local encontrado=0

    http_code=$(curl --connect-timeout 10 --max-time 30 -s -o "${FILE_RESPONSE_TMP}" -w "%{http_code}" "${urlPais}")
    echo "---Buscando informacion desde la web: ${nomPais}"
    echo "---Realizando peticion: ${nomPais}"
    if [[ "${http_code}" != "200" ]]; then
        echo -e "${AMARILLO}---Error de peticion: Cod. ${http_code}${RESET}" >&2
        case "$http_code" in
            "404")
                echo -e "${AMARILLO}---Informacion no disponible en el servidor.${RESET}"
                ;;
            "000")
                echo -e "${ROJO}---Sin conexion a internet o servidor no disponible.${RESET}"
                ;;
            "403")
                echo -e "${ROJO}---Acceso denegado al servidor.${RESET}"
                ;;
            "500"|"502"|"503")
                echo -e "${ROJO}---Error interno del servidor. Intente mas tarde.${RESET}"
                ;;
            *)
                echo -e "${ROJO}---Error de conexion desconocido.${RESET}"
                ;;
        esac
        encontrado=1
        return "${encontrado}"
    fi
    echo -e "${VERDE}---Peticion exitosa.${RESET}"
    return "${encontrado}"
}

es_file_expirado(){
    fileName=$(basename "$1")

    #Ejemplo nombre de archivo: yyyy-mm-dd_nompais_ttl.json
    fechaCreacion=$(echo "$fileName" | awk -F'_' '{print $1}')
    nomPais=$(echo "$fileName" | awk -F'_' '{print $2}')
    ttlExts=$(echo "$fileName" | awk -F'_' '{print $3}')
    ttlFile=$(echo "$ttlExts" | awk -F'.' '{print $1}')

    fechaExp=$(date -d "${fechaCreacion} + ${ttlFile} days" "+%Y-%m-%d")

    tsFechaAct=$(date +%s)
    tsFechaExp=$(date -d "$fechaExp" +%s)

    expirado=0

    if [[ "$tsFechaExp" -lt "$tsFechaAct" ]]; then
        expirado=1
    fi

    echo "$expirado"
}

get_pais_file(){
    local fileName=$1
    local fileValido=0
    echo "---Buscando informacion desde un archivo local. $(basename "${fileName}")"

    if [[ $(es_file_expirado "${fileName}") == 1 ]]; then
        echo -e "${AMARILLO}---Archivo local desactualizado. ${fileName}${RESET}"
        echo -e "${AMARILLO}---Solicitar nueva informacion actualizada.${RESET}"

        mv "${fileName}" "${dirPapelera}"
        #Se encontro el archivo json pero esta vencido
        #por lo tanto se debera realizar una llamada a la api
        fileInvalido=1
        return "${fileInvalido}"
    fi
    echo -e "${VERDE}---Archivo local disponible. $(basename "${fileName}")${RESET}"
    return "${fileValido}"
}

## Lista de posibles errores
E_ARGS=65
E_ARCH_NO_ENCONTRADO=70
E_ARCH_NO_CREADO=71
E_CONEXION_INTERNET=75
E_COMANDO_JQ=80
## Lista de colores para la salida
ROJO='\e[31m'
AMARILLO='\e[33m'
VERDE='\e[32m'
RESET='\e[0m'
## ttl validos
TTL_MIN=1
TTL_MAX=5
## Lista de opciones
OPTIONS="n:t:h"
LONGOPTS="nombre:,ttl:,help"

OPTS=$(getopt --options "$OPTIONS" --longoptions "$LONGOPTS" -n "$0" -- "$@")

if [ $? -ne 0 ]; then
    handle_error "${AMARILLO}Sintaxis invalida. Se requiere un argumento para la opcion.${RESET}" $E_ARGS
fi

# esto restablece los parametros posicionales a las opcs analizadas
eval set -- "$OPTS"
nombre=""
ttl=1
paises=()
## Procesar las opciones
while [[ true ]]; do
    case "$1" in
        -n | --nombre)
            if [ "$2" = "-t" -o "$2" = "--ttl" ]; then
                handle_error "${AMARILLO}La opcion [-n, --nombre] requiere un argumento.${AMARILLO}" $E_ARGS
            fi
            nombre="$2"
            paises+=("${2,,}")
            shift 2
        ;;
        -t | --ttl)
            ttl="$2"
            if [ "$2" = "-n" -o "$2" = "--nombre" ]; then
                handle_error "${AMARILLO}La opcion [-t, --ttl] requiere un argumento.${RESET}" $E_ARGS
            fi
            if [[ ! "${ttl}" =~ ^[0-9]+$ ]]; then
                handle_error "${AMARILLO}Sintaxis invalida: [-t, --ttl] $ttl.${RESET}" $E_ARGS
            fi
            if [[ $ttl -lt $TTL_MIN || $ttl -gt $TTL_MAX ]]; then
                handle_error "La opcion [-t | --ttl] no permitida. Ingresar un valor entre $TTL_MIN y $TTL_MAX" $E_ARGS
            fi
            shift 2
        ;;
        -h | --help)
            mostrar_ayuda
            shift
        ;;
        --)
            shift
            break
        ;;
        *)
            handle_error "Se ha producido un error interno." $E_ARGS
        ;;
    esac
done

if [ "${nombre}" = "" ]; then
    handle_error "${AMARILLO}Debe especificar una opcion [-n | --nombre]${RESET}" $E_ARGS
fi

##INICIO MAIN BLOCK
# Verificar sistema y dependencias
verificar_sistema
verificar_dependencias

#Inicializar variables

scriptDir="$(dirname "$(readlink -f "$0")")"
dirCache="${scriptDir}/Pais"
dirPapelera="${scriptDir}/Papelera"
FILE_RESPONSE_TMP="${dirCache}/response.json"
FILE_PAIS_TMP="${dirCache}/pais.json"
listPaisesObt=()
listMonedasObt=()

if [[ ! -d "${dirCache}" ]]; then
    mkdir -p "${dirCache}" || handle_error "Error al crear directorio de cache: ${dirCache}" $E_ARCH_NO_CREADO
    chmod 755 "${dirCache}"
fi

if [[ ! -d "${dirPapelera}" ]]; then
    mkdir -p "${dirPapelera}" || handle_error "Error al crear directorio de papelera: ${dirPapelera}" $E_ARCH_NO_CREADO
    chmod 755 "${dirPapelera}"
fi
paisesVal=()
for item in "${paises[@]}"
do
    # Validar que el nombre del país no esté vacío y tenga al menos 2 caracteres
    if [[ -n "${item}" && "${item}" =~ ^[a-zA-Z\ ]{2,}$ ]]; then
        paisesVal+=("${item}")
    else
        echo -e "${AMARILLO}Advertencia: '${item}' no es un nombre de país válido (debe tener al menos 2 letras).${RESET}"
    fi
done

if [ ${#paisesVal[@]} -eq 0 ]; then
    handle_error "${ROJO}No se proporcionaron nombres de países válidos.${RESET}" $E_ARGS
fi


for paisItem in "${paisesVal[@]}"
do
    echo "Procesando busqueda pais: ${paisItem}"
    fileJson=$(find "$dirCache" -type f -name "*$(echo "${paisItem}" | sed 's/ /-/g')_*.json")
    hayInfoFile=1
    if [[ -f "${fileJson}" ]]; then
        #echo "---obteniendo informacion desde un archivo json."
        #hayInfoFile=$(get_pais_file "$fileJson")
        #get_pais_file "${fileJson}"
        if  get_pais_file "${fileJson}" ; then
            hayInfoFile="$?"
        fi
    fi
    
    hayInfoWeb=1
    #si no existe el archivo, realizar una llamada api
    if [[ "${hayInfoFile}" == 1 ]]; then
        #apiResults=$(get_pais_web "${paisItem}")
        #get_pais_web "${paisItem}"
        #apiResults="$?"
        if get_pais_web "${paisItem}" ; then
            exactMatch=$(jq 'length' "${FILE_RESPONSE_TMP}")
            if [[ $exactMatch -gt 10 ]]; then
                echo -e "${AMARILLO}Por favor, haga su consulta mas especifica.${paisItem}${RESET}"
            elif [[ $exactMatch -gt 1 && $exactMatch -le 10 ]]; then
                echo -e "${AMARILLO}Posibles coincidencias para la busqueda. ${paisItem}${RESET}"
                jq '.[] | "\(.name.common)"' "${FILE_RESPONSE_TMP}"
                #opcion: dar la posibilidad de elegir un pais
                #jq 'to_entries[] | (.key + 1 | tostring) + ": " + .value.name.common' ${FILE_RESPONSE_TMP}
                #read opcElegida
                #validar que sea un numero
                #indice=(($opcElegida - 1))
                # jq --argjson i "$indice" '[.[$i]]' ${FILE_RESPONSE_TMP} > ${FILE_PAIS_TMP}
            else
                #jq '.' "$FILE_RESPONSE_TMP" > ${FILE_PAIS_TMP}
                fileJson="$FILE_RESPONSE_TMP"
                hayInfoWeb=0
            fi
        else
            echo -e "${AMARILLO}---Lo sentimos. No se obtuvo informacion disponible - ${paisItem}${RESET}"
        fi
    fi

    if [[ "${hayInfoFile}" == 0 || "${hayInfoWeb}" == 0 ]]; then
        #construimos un objeto moneda
        infoMoneda=$(jq '.[0] | .currencies | keys[0] as $k | [$k, .[$k].name] | {tipo: .[1], abrev: .[0]}' $fileJson)
        
        #construimos un objeto con los campos necesarios
        paisInfoMin=$(jq '.[0] | {nombre: .name.common, capital: .capital[], region: .region, poblacion: .population}' $fileJson)
        
        echo "Seleccionando informacion basica para mostrar."
        listPaisesObt+=("${paisInfoMin}")
        listMonedasObt+=("${infoMoneda}")
    fi

    if [[ ${hayInfoWeb} == 0 ]]; then
        newFilejson="${dirCache}/$(date +%Y-%m-%d)_$(echo "${paisItem}" | sed 's/ /-/g')_${ttl}.json"
        mv ${fileJson} ${newFilejson}
        echo -e "${VERDE}Informacion guardada en el archivo. $(basename "${newFilejson}")${RESET}"
    fi
done

echo
echo "Resultados de la informacion obtenida."
echo
for p in "${!listPaisesObt[@]}"; do
    mostrar_pais "${listPaisesObt[$p]}" "${listMonedasObt[$p]}"
    echo
done

#FIN MAIN BLOCK
