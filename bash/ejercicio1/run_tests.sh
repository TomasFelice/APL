#!/bin/bash
# =================================================
# SCRIPT EJECUTABLE DE PRUEBAS - EJERCICIO 1
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
    
    echo -e "${BLUE}Ejecutando:${NC} $descripcion"
    echo -e "${YELLOW}Comando:${NC} $comando"
    
    PRUEBAS_TOTAL=$((PRUEBAS_TOTAL + 1))
    
    # Ejecutar comando y capturar código de salida
    eval $comando
    local codigo_salida=$?
    
    # Verificar resultado
    if [[ "$esperado_exitoso" == "true" && $codigo_salida -eq 0 ]] || [[ "$esperado_exitoso" == "false" && $codigo_salida -ne 0 ]]; then
        echo -e "${GREEN}✓ PRUEBA EXITOSA${NC}"
        PRUEBAS_EXITOSAS=$((PRUEBAS_EXITOSAS + 1))
    else
        echo -e "${RED}✗ PRUEBA FALLIDA${NC} (código: $codigo_salida)"
        PRUEBAS_FALLIDAS=$((PRUEBAS_FALLIDAS + 1))
    fi
    echo -e "${BLUE}----------------------------------------${NC}"
}

echo -e "${GREEN}=== INICIANDO LOTE DE PRUEBAS AUTOMATIZADO - EJERCICIO 1 ===${NC}"

# Ir al directorio correcto
cd /home/tfelice/dev/vh/APL

echo -e "${YELLOW}=== 1. PRUEBAS DE AYUDA ===${NC}"
ejecutar_prueba "Ayuda con -h" "./bash/ejercicio1/ejercicio1 -h > /dev/null" "true"
ejecutar_prueba "Ayuda con --help" "./bash/ejercicio1/ejercicio1 --help > /dev/null" "true"

echo -e "${YELLOW}=== 2. PRUEBAS DE PARÁMETROS INCORRECTOS ===${NC}"
ejecutar_prueba "Sin parámetros" "./bash/ejercicio1/ejercicio1 2>/dev/null" "false"
ejecutar_prueba "Solo directorio sin salida" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_normal 2>/dev/null" "false"
ejecutar_prueba "Parámetro desconocido" "./bash/ejercicio1/ejercicio1 -x parametro_malo 2>/dev/null" "false"
ejecutar_prueba "Conflicto -a y -p juntos" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_normal -a salida.json -p 2>/dev/null" "false"

echo -e "${YELLOW}=== 3. PRUEBAS DE DIRECTORIO INEXISTENTE/INVÁLIDO ===${NC}"
ejecutar_prueba "Directorio inexistente" "./bash/ejercicio1/ejercicio1 -d /directorio/inexistente -p 2>/dev/null" "false"
ejecutar_prueba "Directorio sin archivos .txt" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_vacio -p 2>/dev/null" "false"

echo -e "${YELLOW}=== 4. PRUEBAS FUNCIONALES - CASOS EXITOSOS ===${NC}"
ejecutar_prueba "Caso normal - ruta relativa" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_normal -p > /dev/null" "true"
ejecutar_prueba "Caso normal - salida a archivo" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_normal -a ./bash/ejercicio1/out/caso_normal/test_resultado.json" "true"
ejecutar_prueba "Archivo único" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_archivo_unico -p > /dev/null" "true"
ejecutar_prueba "Orden parámetros diferente" "./bash/ejercicio1/ejercicio1 -p -d ./bash/ejercicio1/in/caso_archivo_unico > /dev/null" "true"

echo -e "${YELLOW}=== 5. PRUEBAS CON DATOS INVÁLIDOS ===${NC}"
ejecutar_prueba "Archivos completamente vacíos" "./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_solo_vacios -p 2>/dev/null" "false"

echo -e "${YELLOW}=== 6. VERIFICACIÓN DE ARCHIVOS TEMPORALES ===${NC}"
# Ejecutar comando que debería limpiar archivos temporales
./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_archivo_unico -p > /dev/null

# Verificar que no quedan archivos temporales
if ls /tmp/ejercicio1.* >/dev/null 2>&1; then
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
