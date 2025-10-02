# Script de Test para ejercicio4.ps1

Este script (`test-ejercicio4.ps1`) simula commits con datos sensibles en un repositorio Git para probar la funcionalidad del demonio `ejercicio4.ps1`.

## Descripción

El script de test realiza lo siguiente:

1. **Crea un repositorio Git de prueba** con commits que contienen datos sensibles
2. **Inicia el demonio `ejercicio4.ps1`** para monitorear el repositorio
3. **Simula varios escenarios** de commits con diferentes tipos de datos sensibles
4. **Verifica las alertas generadas** en el archivo de log
5. **Proporciona un resumen** de los resultados del test

## Tipos de Test Incluidos

### Test 1: Password literal
- Archivo: `config.txt`
- Contiene: `database_password=secreto123`
- Detecta el patrón: `password`

### Test 2: API Key
- Archivo: `api-config.js`
- Contiene: `API_KEY: "sk-1234567890abcdef"`
- Detecta el patrón: `API_KEY`

### Test 3: Patrón Regex
- Archivo: `environment.env`
- Contiene: `API_KEY = "production-key-xyz789"`
- Detecta el patrón regex: `^.*API_KEY\s*=\s*['"].*['"].*$`

### Test 4: Secret
- Archivo: `auth/tokens.json`
- Contiene: `"jwt_secret": "super-secret-key-123"`
- Detecta el patrón: `secret`

### Test 5: Múltiples archivos
- Archivos: `credentials.py`, `settings.yaml`
- Contiene múltiples patrones en un solo commit
- Detecta: `password`, `API_KEY`, `secret`

### Test 6: Control negativo
- Archivo: `utils.js`
- Contiene solo funciones JavaScript sin datos sensibles
- No debe generar alertas

## Uso

### Ejecutar el test completo
```powershell
.\test-ejercicio4.ps1
```

### Opciones disponibles
```powershell
# Usar rutas personalizadas
.\test-ejercicio4.ps1 -TestRepo ".\mi-repo-test" -LogFile ".\mis-logs\test.log"

# Cambiar tiempo de espera entre commits
.\test-ejercicio4.ps1 -WaitTime 10

# Mostrar ayuda
.\test-ejercicio4.ps1 -Help

# Limpiar archivos de test
.\test-ejercicio4.ps1 -Cleanup
```

## Parámetros

- **TestRepo**: Ruta del repositorio de prueba (default: `.\test-repo`)
- **ConfigFile**: Archivo de patrones a usar (default: `.\patrones.conf`)
- **LogFile**: Archivo donde se escriben los logs del test (default: `.\test-logs\audit.log`)
- **WaitTime**: Segundos de espera entre commits (default: 5)
- **Cleanup**: Limpia archivos y directorios de test
- **Help**: Muestra la ayuda

## Resultados Esperados

Al ejecutar el test exitosamente, deberías ver:

1. **Mensajes de log coloridos** indicando el progreso del test
2. **Alertas detectadas** mostradas en rojo en el archivo de log
3. **Resumen de validación** con:
   - ✓ Patrones detectados correctamente
   - ✓ Total de alertas generadas
   - ✓ Confirmación de test exitoso

## Ejemplo de Salida

```
[2025-10-01 15:30:15] === INICIANDO TEST DE EJERCICIO4.PS1 ===
[2025-10-01 15:30:15] Archivos necesarios encontrados
[2025-10-01 15:30:15] Inicializando repositorio de prueba en: .\test-repo
[2025-10-01 15:30:16] Repositorio inicializado correctamente
[2025-10-01 15:30:16] Iniciando demonio ejercicio4.ps1...
[2025-10-01 15:30:18] Demonio iniciado correctamente
[2025-10-01 15:30:18] === INICIANDO SIMULACIÓN DE COMMITS ===
[2025-10-01 15:30:18] Test 1: Creando archivo con password literal
[2025-10-01 15:30:18] Creado archivo con datos sensibles: config.txt
[2025-10-01 15:30:18] Commit realizado: Agregar configuración de base de datos
...
[2025-10-01 15:30:45] === RESULTADOS DEL TEST ===
[2025-10-01 15:30:45] Total de alertas detectadas: 8
[2025-10-01 15:30:45] === VALIDACIÓN DEL TEST ===
[2025-10-01 15:30:45] ✓ Patrón 'password' detectado correctamente
[2025-10-01 15:30:45] ✓ Patrón 'API_KEY' detectado correctamente
[2025-10-01 15:30:45] ✓ Patrón 'secret' detectado correctamente
[2025-10-01 15:30:45] ✓ Patrón regex detectado correctamente
[2025-10-01 15:30:45] ✓ TEST EXITOSO: Se detectaron datos sensibles
```

## Limpieza

Después de ejecutar el test, puedes limpiar los archivos generados:

```powershell
.\test-ejercicio4.ps1 -Cleanup
```

Esto eliminará:
- El directorio `test-repo` y todo su contenido
- El directorio `test-logs` y los archivos de log
- Detendrá cualquier demonio en ejecución

## Requisitos

- PowerShell 5.1 o superior
- Git instalado y disponible en PATH
- El archivo `ejercicio4.ps1` en el mismo directorio
- El archivo `patrones.conf` con los patrones de búsqueda
- Permisos de escritura en el directorio actual

## Notas

- El test crea un repositorio Git temporal que se puede eliminar después
- El demonio se ejecuta con un intervalo de 3 segundos para acelerar el test
- Los logs del test se guardan por separado de los logs del script original
- El script maneja automáticamente la limpieza del demonio al finalizar