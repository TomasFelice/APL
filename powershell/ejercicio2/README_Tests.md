# Documentación de Pruebas - Script de Análisis de Rutas de Transporte

Este documento contiene comandos para validar manualmente el funcionamiento del script `ejercicio2.ps1` utilizando diferentes casos de prueba.

## Estructura de Archivos de Prueba

Los archivos de prueba se encuentran en la carpeta `input/` y representan diferentes escenarios:

- **`test_minimal.txt`**: Red mínima de 2 estaciones
- **`test_simple_hub.txt`**: Red simple de 4 estaciones con hub claro
- **`test_multiple_hubs.txt`**: Red con múltiples hubs (empates en grado máximo)
- **`test_disconnected.txt`**: Red desconectada (2 componentes separados)
- **`test_multiple_paths.txt`**: Red con múltiples caminos óptimos
- **`test_large_network.txt`**: Red más grande de 6 estaciones
- **`test_complex_paths.txt`**: Red compleja de 7 estaciones
- **`mapa_transporte.txt`**: Archivo original del proyecto

## Comandos de Prueba

### 1. Prueba de Ayuda
```powershell
.\ejercicio2.ps1 -Help
```

### 2. Análisis de Hubs

#### Test Minimal (2 estaciones)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_minimal.txt" -Hub
Get-Content "input\informe.test_minimal.txt"
```

#### Test Simple Hub (4 estaciones - hub en estación 2)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_simple_hub.txt" -Hub
Get-Content "input\informe.test_simple_hub.txt"
```

#### Test Multiple Hubs (múltiples estaciones con grado máximo)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_multiple_hubs.txt" -Hub
Get-Content "input\informe.test_multiple_hubs.txt"
```

#### Test Disconnected (red desconectada)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_disconnected.txt" -Hub
Get-Content "input\informe.test_disconnected.txt"
```

#### Test Large Network (6 estaciones)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_large_network.txt" -Hub
Get-Content "input\informe.test_large_network.txt"
```

#### Test Complex Paths (7 estaciones)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_complex_paths.txt" -Hub
Get-Content "input\informe.test_complex_paths.txt"
```

#### Archivo Original
```powershell
.\ejercicio2.ps1 -Matriz "input\mapa_transporte.txt" -Hub
Get-Content "input\informe.mapa_transporte.txt"
```

### 3. Análisis de Caminos Más Cortos

#### Test Minimal (camino único)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_minimal.txt" -Camino
Get-Content "input\informe.test_minimal.txt"
```

#### Test Simple Hub (caminos desde hub)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_simple_hub.txt" -Camino
Get-Content "input\informe.test_simple_hub.txt"
```

#### Test Multiple Paths (múltiples caminos óptimos)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_multiple_paths.txt" -Camino
Get-Content "input\informe.test_multiple_paths.txt"
```

#### Test Disconnected (red desconectada - solo caminos dentro de componentes)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_disconnected.txt" -Camino
Get-Content "input\informe.test_disconnected.txt"
```

#### Test Large Network (red compleja)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_large_network.txt" -Camino
Get-Content "input\informe.test_large_network.txt"
```

#### Test Complex Paths (red con múltiples rutas)
```powershell
.\ejercicio2.ps1 -Matriz "input\test_complex_paths.txt" -Camino
Get-Content "input\informe.test_complex_paths.txt"
```

#### Archivo Original
```powershell
.\ejercicio2.ps1 -Matriz "input\mapa_transporte.txt" -Camino
Get-Content "input\informe.mapa_transporte.txt"
```

### 4. Pruebas de Validación de Errores

#### Archivo inexistente
```powershell
.\ejercicio2.ps1 -Matriz "input\noexiste.txt" -Hub
# Esperado: Error "Archivo no encontrado"
```

#### Falta especificar modo
```powershell
.\ejercicio2.ps1 -Matriz "input\test_minimal.txt"
# Esperado: Error "Debe especificar exactamente una de las opciones"
```

#### Ambos modos especificados
```powershell
.\ejercicio2.ps1 -Matriz "input\test_minimal.txt" -Hub -Camino
# Esperado: Error "Debe especificar exactamente una de las opciones"
```

### 5. Pruebas con Separador Personalizado

#### Crear archivo con separador diferente
```powershell
@"
0;2;4;3
2;0;1;5
4;1;0;2
3;5;2;0
"@ | Out-File "input\test_semicolon.txt" -Encoding UTF8
```

#### Probar con separador personalizado
```powershell
.\ejercicio2.ps1 -Matriz "input\test_semicolon.txt" -Hub -Separador ";"
Get-Content "input\informe.test_semicolon.txt"
```

### 6. Ejecución Completa de Todas las Pruebas

```powershell
# Script para ejecutar todos los tests automáticamente
$testFiles = @(
    "test_minimal.txt",
    "test_simple_hub.txt", 
    "test_multiple_hubs.txt",
    "test_disconnected.txt",
    "test_multiple_paths.txt",
    "test_large_network.txt",
    "test_complex_paths.txt",
    "mapa_transporte.txt"
)

foreach ($file in $testFiles) {
    Write-Host "=== Probando $file ==="
    Write-Host "--- Modo Hub ---"
    .\ejercicio2.ps1 -Matriz "input\$file" -Hub
    Write-Host "--- Modo Camino ---"
    .\ejercicio2.ps1 -Matriz "input\$file" -Camino
    Write-Host ""
}
```

## Resultados Esperados

### Análisis de Hubs
- **test_minimal.txt**: Ambas estaciones tienen grado 1 (empate)
- **test_simple_hub.txt**: Estación 2 debe ser el hub (mayor número de conexiones)
- **test_multiple_hubs.txt**: Múltiples estaciones con grado máximo
- **test_disconnected.txt**: Hubs locales en cada componente desconectado

### Análisis de Caminos
- **test_minimal.txt**: Un solo camino posible (1 ↔ 2)
- **test_multiple_paths.txt**: Múltiples rutas óptimas para el mismo tiempo mínimo
- **test_disconnected.txt**: Solo caminos dentro de cada componente conectado
- **test_complex_paths.txt**: Diversos caminos con diferentes longitudes y tiempos

## Verificación Manual

Para cada prueba, verificar:
1. **Sintaxis**: El script ejecuta sin errores
2. **Archivo de salida**: Se genera `informe.[nombre_archivo]` en la carpeta `input/`
3. **Contenido lógico**: Los resultados son coherentes con la matriz de entrada
4. **Formato de salida**: La información se presenta claramente

## Limpieza

Para limpiar los archivos de informe generados:
```powershell
Remove-Item "input\informe.*" -Force
```