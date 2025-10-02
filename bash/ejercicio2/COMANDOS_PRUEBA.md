# Guía de Comandos de Prueba para el Script de Análisis de Red de Transporte

Este documento contiene una serie de comandos listos para copiar y ejecutar que validan el funcionamiento del script `ejercicio2.sh` con diferentes casos de prueba.

## Requisitos

- Tener los archivos `ejercicio2.sh` y `main.awk` en el directorio actual
- Ejecutar desde el directorio donde se encuentran estos scripts
- Asegurarse de que el script tenga permisos de ejecución

## Estructura de Archivos de Prueba

Los archivos de prueba están organizados en el directorio `tests/` y cubren los siguientes escenarios:

### Casos de Prueba Válidos

1. **matriz_simple_3x3.txt** - Matriz básica 3x3 para pruebas simples
2. **matriz_hub_central.txt** - Matriz 4x4 donde la estación 4 es claramente el hub
3. **matriz_hub_claro.txt** - Matriz 5x5 donde la estación 1 es el hub único
4. **matriz_caminos_multiples.txt** - Matriz 5x5 con múltiples caminos posibles
5. **matriz_triangulo_equilatero.txt** - Matriz 3x3 simétrica con distancias iguales
6. **matriz_decimales_separador_punto_coma.txt** - Matriz con números decimales y separador `;`
7. **matriz_multiple_caminos_minimos.txt** - Matriz que produce múltiples caminos mínimos
8. **matriz_grande_7x7.txt** - Matriz más grande para probar escalabilidad
9. **matriz_sin_conexiones.txt** - Matriz sin conexiones entre estaciones

### Casos de Error/Validación

10. **matriz_diagonal_no_cero.txt** - Error: diagonal no es cero
11. **matriz_peso_negativo.txt** - Error: contiene pesos negativos
12. **matriz_no_cuadrada.txt** - Error: matriz no cuadrada

---

## Comandos de Prueba

### 1. Ayuda del Script

```bash
# Mostrar ayuda del script
bash ejercicio2.sh --help
```

### 2. Análisis de Hubs

```bash
# Caso 1: Matriz simple 3x3 - análisis de hubs
bash ejercicio2.sh -m tests/matriz_simple_3x3.txt -h

# Caso 2: Hub claro en estación 1
bash ejercicio2.sh -m tests/matriz_hub_claro.txt -h

# Caso 3: Hub central en matriz 4x4
bash ejercicio2.sh -m tests/matriz_hub_central.txt -h

# Caso 4: Matriz grande 7x7 - análisis de hubs
bash ejercicio2.sh -m tests/matriz_grande_7x7.txt -h

# Caso 5: Matriz sin conexiones (todos los nodos tendrán grado 0)
bash ejercicio2.sh -m tests/matriz_sin_conexiones.txt -h

# Caso 6: Triángulo equilátero (todos los nodos tienen el mismo grado)
bash ejercicio2.sh -m tests/matriz_triangulo_equilatero.txt -h
```

### 3. Análisis de Caminos Mínimos

```bash
# Caso 1: Caminos mínimos en matriz simple 3x3
bash ejercicio2.sh -m tests/matriz_simple_3x3.txt -c

# Caso 2: Caminos mínimos con múltiples rutas posibles
bash ejercicio2.sh -m tests/matriz_caminos_multiples.txt -c

# Caso 3: Caminos mínimos en matriz con hub central
bash ejercicio2.sh -m tests/matriz_hub_central.txt -c

# Caso 4: Múltiples caminos mínimos con mismo tiempo
bash ejercicio2.sh -m tests/matriz_multiple_caminos_minimos.txt -c

# Caso 5: Matriz grande 7x7 - caminos mínimos
bash ejercicio2.sh -m tests/matriz_grande_7x7.txt -c

# Caso 6: Matriz sin conexiones (no debería encontrar caminos)
bash ejercicio2.sh -m tests/matriz_sin_conexiones.txt -c
```

### 4. Pruebas con Separador Personalizado

```bash
# Usar separador punto y coma con números decimales
bash ejercicio2.sh -m tests/matriz_decimales_separador_punto_coma.txt -h -s ";"

# Caminos mínimos con separador punto y coma
bash ejercicio2.sh -m tests/matriz_decimales_separador_punto_coma.txt -c -s ";"
```

### 5. Casos de Error Esperados

```bash
# Error: Diagonal no es cero
bash ejercicio2.sh -m tests/matriz_diagonal_no_cero.txt -h

# Error: Peso negativo
bash ejercicio2.sh -m tests/matriz_peso_negativo.txt -h

# Error: Matriz no cuadrada
bash ejercicio2.sh -m tests/matriz_no_cuadrada.txt -h

# Error: Archivo no existe
bash ejercicio2.sh -m tests/archivo_inexistente.txt -h

# Error: Falta argumento obligatorio
bash ejercicio2.sh -h

# Error: Separador inválido (más de un carácter)
bash ejercicio2.sh -m tests/matriz_simple_3x3.txt -h -s "||"
```

### 6. Verificación de Archivos de Salida

```bash
# Después de ejecutar cualquier comando, verificar que se generó el archivo de informe
ls -la tests/informe.*

# Visualizar el contenido de los informes generados
cat tests/informe.matriz_simple_3x3.txt
cat tests/informe.matriz_hub_claro.txt
cat tests/informe.matriz_multiple_caminos_minimos.txt
```

### 7. Limpieza de Archivos de Prueba

```bash
# Limpiar todos los archivos de informe generados
rm -f tests/informe.*

# Verificar que se limpiaron
ls -la tests/
```

## Validaciones Esperadas

### Resultados de Hubs Esperados:

- **matriz_hub_claro.txt**: La estación 1 debería ser el hub único (4 conexiones)
- **matriz_triangulo_equilatero.txt**: Todas las estaciones deberían ser hubs (empate con 2 conexiones cada una)
- **matriz_sin_conexiones.txt**: Todas las estaciones tienen 0 conexiones

### Resultados de Caminos Esperados:

- **matriz_simple_3x3.txt**: Camino mínimo debería ser 2 (entre estaciones 1-2)
- **matriz_multiple_caminos_minimos.txt**: Debería mostrar múltiples rutas con el mismo tiempo mínimo

### Errores Esperados:

- **matriz_diagonal_no_cero.txt**: "ERROR: diagonal [1,1] debe ser 0"
- **matriz_peso_negativo.txt**: "ERROR: Peso negativo detectado"
- **matriz_no_cuadrada.txt**: "ERROR: Matriz no cuadrada"

## Scripts Automáticos de Prueba

### Ejecutar todas las pruebas válidas de hubs:

```bash
# Script para probar todos los casos de hubs válidos
for archivo in tests/matriz_simple_3x3.txt tests/matriz_hub_claro.txt tests/matriz_hub_central.txt tests/matriz_grande_7x7.txt tests/matriz_sin_conexiones.txt tests/matriz_triangulo_equilatero.txt; do
    echo "=== Probando hubs en $archivo ==="
    bash ejercicio2.sh -m "$archivo" -h
    echo ""
done
```

### Ejecutar todas las pruebas válidas de caminos:

```bash
# Script para probar todos los casos de caminos válidos
for archivo in tests/matriz_simple_3x3.txt tests/matriz_caminos_multiples.txt tests/matriz_hub_central.txt tests/matriz_multiple_caminos_minimos.txt tests/matriz_grande_7x7.txt; do
    echo "=== Probando caminos en $archivo ==="
    bash ejercicio2.sh -m "$archivo" -c
    echo ""
done
```

### Ejecutar casos de error:

```bash
# Script para probar casos de error esperados
echo "=== Probando casos de error ==="
echo "1. Diagonal no cero:"
bash ejercicio2.sh -m tests/matriz_diagonal_no_cero.txt -h 2>&1 || echo "Error esperado: OK"
echo ""

echo "2. Peso negativo:"
bash ejercicio2.sh -m tests/matriz_peso_negativo.txt -h 2>&1 || echo "Error esperado: OK"
echo ""

echo "3. Matriz no cuadrada:"
bash ejercicio2.sh -m tests/matriz_no_cuadrada.txt -h 2>&1 || echo "Error esperado: OK"
echo ""
```

## Notas Adicionales

1. **Permisos**: Si obtienes errores de permisos, ejecuta: `chmod +x ejercicio2.sh`
2. **Separadores**: El script soporta separadores personalizados con la opción `-s`
3. **Archivos de salida**: Todos los informes se guardan como `informe.<nombre_archivo_original>`
4. **Validaciones**: El script valida matrices simétricas, diagonal cero, y pesos no negativos
5. **Algoritmo**: Usa Dijkstra para encontrar caminos mínimos y soporta múltiples rutas con el mismo costo

## Verificación Manual

Para verificar manualmente que el script funciona correctamente:

1. Ejecuta algunos comandos de la lista anterior
2. Verifica que se generen los archivos `informe.*` correspondientes
3. Revisa el contenido de los informes para asegurar que la información es correcta
4. Confirma que los casos de error devuelven los códigos de salida apropiados
5. Prueba tanto el modo hub (`-h`) como el modo camino (`-c`)