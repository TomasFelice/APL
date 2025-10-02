#!/bin/bash
# =================================================
# SCRIPT EJECUTABLE DE PRUEBAS - EJERCICIO 3
# =================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contador de pruebas
PRUEBAS_TOTAL=0
PRUEBAS_EXITOSAS=0
PRUEBAS_FALLIDAS=0

# Función para ejecutar una prueba
ejecutar_prueba() {
    local descripcion="$1"
    local comando="$2"
    local esperado_exitoso="$3"  # true/false
    local output_esperado="$4"   # opcional, para verificar salida específica
    
    echo -e "${BLUE}Ejecutando:${NC} $descripcion"
    echo -e "${YELLOW}Comando:${NC} $comando"
    
    PRUEBAS_TOTAL=$((PRUEBAS_TOTAL + 1))
    
    # Ejecutar comando y capturar salida y código de salida
    local temp_output_file=$(mktemp)
    eval $comando > "$temp_output_file" 2>&1
    local codigo_salida=$?
    local output=$(cat "$temp_output_file")
    rm -f "$temp_output_file"
    
    # Verificar código de salida
    local codigo_ok=false
    if [[ "$esperado_exitoso" == "true" && $codigo_salida -eq 0 ]] || [[ "$esperado_exitoso" == "false" && $codigo_salida -ne 0 ]]; then
        codigo_ok=true
    fi
    
    # Verificar salida específica si se proporciona
    local output_ok=true
    if [[ -n "$output_esperado" ]]; then
        if [[ "$output" == *"$output_esperado"* ]]; then
            output_ok=true
        else
            output_ok=false
        fi
    fi
    
    # Resultado final
    if [[ "$codigo_ok" == "true" && "$output_ok" == "true" ]]; then
        echo -e "${GREEN}✓ PRUEBA EXITOSA${NC}"
        PRUEBAS_EXITOSAS=$((PRUEBAS_EXITOSAS + 1))
    else
        echo -e "${RED}✗ PRUEBA FALLIDA${NC} (código: $codigo_salida)"
        if [[ -n "$output_esperado" && "$output_ok" == "false" ]]; then
            echo -e "${RED}  Output esperado: $output_esperado${NC}"
            echo -e "${RED}  Output obtenido: $output${NC}"
        fi
        PRUEBAS_FALLIDAS=$((PRUEBAS_FALLIDAS + 1))
    fi
    echo -e "${BLUE}----------------------------------------${NC}"
}

echo -e "${GREEN}=== INICIANDO LOTE DE PRUEBAS AUTOMATIZADO - EJERCICIO 3 ===${NC}"

echo -e "${YELLOW}=== 1. PRUEBAS DE AYUDA ===${NC}"
ejecutar_prueba "Ayuda con -h" "bash ./ejercicio3.sh -h > /dev/null" "true"
ejecutar_prueba "Ayuda con --help" "bash ./ejercicio3.sh --help > /dev/null" "true"

echo -e "${YELLOW}=== 2. PRUEBAS DE PARÁMETROS INCORRECTOS ===${NC}"
ejecutar_prueba "Sin parámetros" "bash ./ejercicio3.sh >/dev/null 2>&1" "false"
ejecutar_prueba "Solo directorio sin palabras" "bash ./ejercicio3.sh -d ./in/caso_normal >/dev/null 2>&1" "false"
ejecutar_prueba "Solo palabras sin directorio" "bash ./ejercicio3.sh -p \"USB,Invalid\" >/dev/null 2>&1" "false"
ejecutar_prueba "Parámetro desconocido" "bash ./ejercicio3.sh -x parametro_malo >/dev/null 2>&1" "false"
ejecutar_prueba "Palabras vacías" "bash ./ejercicio3.sh -d ./in/caso_normal -p \"\" >/dev/null 2>&1" "false"

echo -e "${YELLOW}=== 3. PRUEBAS DE DIRECTORIO INEXISTENTE/INVÁLIDO ===${NC}"
ejecutar_prueba "Directorio inexistente" "bash ./ejercicio3.sh -d /directorio/inexistente -p \"USB,Invalid\" >/dev/null 2>&1" "false"
ejecutar_prueba "Directorio sin archivos .log" "bash ./ejercicio3.sh -d ./in/caso_sin_logs -p \"USB,Invalid\" >/dev/null 2>&1" "false"

echo -e "${YELLOW}=== 4. PRUEBAS FUNCIONALES - CASOS EXITOSOS ===${NC}"
ejecutar_prueba "Ejemplo de la consigna" "bash ./ejercicio3.sh -d ./in/caso_normal -p \"USB,Invalid\"" "true" "USB: 2"
ejecutar_prueba "Case-insensitive minúsculas" "bash ./ejercicio3.sh -d ./in/caso_case_sensitive -p \"usb,invalid,error\"" "true" "usb: 3"
ejecutar_prueba "Case-insensitive mayúsculas" "bash ./ejercicio3.sh -d ./in/caso_case_sensitive -p \"USB,INVALID,ERROR\"" "true" "USB: 3"
ejecutar_prueba "Archivo único" "bash ./ejercicio3.sh -d ./in/caso_archivo_unico -p \"USB,invalid\"" "true" "USB: 3"
ejecutar_prueba "Una sola palabra" "bash ./ejercicio3.sh -d ./in/caso_normal -p \"error\"" "true" "error: "
ejecutar_prueba "Palabras inexistentes" "bash ./ejercicio3.sh -d ./in/caso_normal -p \"palabra_inexistente\"" "true" "palabra_inexistente: 0"

echo -e "${YELLOW}=== 5. PRUEBAS DE ORDEN DE PARÁMETROS ===${NC}"
ejecutar_prueba "Orden -p -d" "bash ./ejercicio3.sh -p \"USB,Invalid\" -d ./in/caso_normal" "true" "USB: 2"
ejecutar_prueba "Nombres largos" "bash ./ejercicio3.sh --palabras \"USB,Invalid\" --directorio ./in/caso_normal" "true" "USB: 2"

echo -e "${YELLOW}=== 6. PRUEBAS DE RUTAS ===${NC}"
ejecutar_prueba "Ruta relativa con ./" "bash ./ejercicio3.sh -d ./in/caso_normal -p \"USB,Invalid\"" "true" "USB: 2"
ejecutar_prueba "Ruta relativa sin ./" "bash ./ejercicio3.sh -d ./in/caso_normal -p \"USB,Invalid\"" "true" "USB: 2"

echo -e "${YELLOW}=== 7. PRUEBAS CON ARCHIVOS VACÍOS ===${NC}"
ejecutar_prueba "Archivo .log vacío" "bash ./ejercicio3.sh -d ./in/caso_vacio -p \"USB,Invalid\"" "true" "USB: 0"

echo -e "${YELLOW}=== 8. PRUEBAS DE FORMATO DE PALABRAS ===${NC}"
ejecutar_prueba "Palabras con espacios extra" "bash ./ejercicio3.sh -d ./in/caso_normal -p \" USB , Invalid \"" "true" "USB: 2"

echo -e "${YELLOW}=== 9. VERIFICACIÓN DE ARCHIVOS TEMPORALES ===${NC}"
# Ejecutar comando que debería limpiar archivos temporales
bash ./ejercicio3.sh -d ./in/caso_normal -p "USB" > /dev/null

# Verificar que no quedan archivos temporales
if ls /tmp/ejercicio3.* >/dev/null 2>&1; then
    echo -e "${RED}✗ ADVERTENCIA: Quedan archivos temporales en /tmp${NC}"
    PRUEBAS_FALLIDAS=$((PRUEBAS_FALLIDAS + 1))
else
    echo -e "${GREEN}✓ OK: No hay archivos temporales pendientes${NC}"
    PRUEBAS_EXITOSAS=$((PRUEBAS_EXITOSAS + 1))
fi
PRUEBAS_TOTAL=$((PRUEBAS_TOTAL + 1))

# Resumen final
echo -e "${GREEN}=== RESUMEN DE PRUEBAS ===${NC}"
echo -e "Total de pruebas: ${BLUE}$PRUEBAS_TOTAL${NC}"
echo -e "Pruebas exitosas: ${GREEN}$PRUEBAS_EXITOSAS${NC}"
echo -e "Pruebas fallidas: ${RED}$PRUEBAS_FALLIDAS${NC}"

if [[ $PRUEBAS_FALLIDAS -eq 0 ]]; then
    echo -e "${GREEN}🎉 TODAS LAS PRUEBAS PASARON EXITOSAMENTE 🎉${NC}"
    exit 0
else
    echo -e "${RED}❌ ALGUNAS PRUEBAS FALLARON ❌${NC}"
    exit 1
fi
