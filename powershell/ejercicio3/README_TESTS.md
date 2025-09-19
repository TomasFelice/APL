# LOTE DE PRUEBAS - EJERCICIO 3 POWERSHELL

## Descripción del Ejercicio

El ejercicio 3 implementa un script de PowerShell que analiza archivos de logs (.log) en un directorio para contar la ocurrencia de eventos específicos basados en palabras clave proporcionadas.

### Características principales:
- Procesamiento de archivos .log usando cmdlets nativos de PowerShell
- Búsqueda case-insensitive
- Soporte para múltiples palabras clave separadas por comas  
- Manejo robusto de errores con try-catch-finally
- Limpieza automática de archivos temporales
- Validación de parámetros nativa de PowerShell
- Documentación completa con Get-Help

## Estructura de Pruebas

```
ejercicio3/
├── ejercicio3.ps1                     # Script principal de PowerShell
├── run_tests.ps1                      # Script automatizado de pruebas
├── README_TESTS.md                    # Este archivo
└── in/                                # Datos de entrada (copiados desde bash)
    ├── caso_normal/                   # Casos de uso normales
    │   ├── system.log                 # Ejemplo exacto de la consigna
    │   ├── web.log                    # Logs de servidor web
    │   └── application.log            # Logs de aplicación Java
    ├── caso_archivo_unico/            # Casos con un solo archivo
    │   └── single.log                 # Archivo único para pruebas específicas
    ├── caso_case_sensitive/           # Casos para probar insensibilidad a mayúsculas
    │   └── mixed_case.log             # Palabras en diferentes casos
    ├── caso_vacio/                    # Archivos vacíos
    │   └── empty.log                  # Archivo .log completamente vacío
    └── caso_sin_logs/                 # Directorio sin archivos .log
        └── not_a_log.txt              # Archivo que no es .log
```

## Casos de Prueba Implementados

### 1. Ejemplo de la Consigna
```powershell
.\ejercicio3.ps1 -Directorio "./in/caso_normal" -Palabras "USB,Invalid"
# Salida esperada:
# USB: 2
# Invalid: 2
```

### 2. Pruebas Case-Insensitive
- Búsqueda con minúsculas: `-Palabras "usb,invalid,error"`
- Búsqueda con mayúsculas: `-Palabras "USB,INVALID,ERROR"`
- Búsqueda con caso mixto: `-Palabras "Usb,Invalid,Error"`

### 3. Validación de Parámetros (PowerShell nativo)
- Sin parámetros (PowerShell valida automáticamente)
- Solo directorio sin palabras
- Solo palabras sin directorio
- Parámetros con alias: `-d` y `-p`

### 4. Validación de Directorios
- Directorio inexistente
- Directorio sin archivos .log
- Rutas relativas y absolutas
- Verificación de permisos de lectura

### 5. Diferentes Combinaciones de Palabras
- Una sola palabra
- Múltiples palabras existentes
- Palabras que no existen en los logs
- Mezcla de palabras existentes e inexistentes

## Diferencias Clave con la Versión Bash

### 1. **Validación de Parámetros**
- **PowerShell**: Validación nativa con `[Parameter(Mandatory=$true)]`
- **Bash**: Validación manual con if/else

### 2. **Manejo de Archivos**
- **PowerShell**: `Get-ChildItem`, `Get-Content`, `Test-Path`
- **Bash**: Comandos de shell y AWK para procesamiento

### 3. **Procesamiento de Texto**
- **PowerShell**: Métodos .NET (`ToLower()`, `[regex]::Matches()`)
- **Bash**: AWK con expresiones regulares

### 4. **Manejo de Errores**
- **PowerShell**: `try-catch-finally` con `Write-Error`
- **Bash**: Códigos de retorno y redirección stderr

### 5. **Archivos Temporales**
- **PowerShell**: `New-TemporaryFile` con limpieza en `finally`
- **Bash**: `mktemp` con `trap` para limpieza

### 6. **Documentación**
- **PowerShell**: Documentación integrada con `Get-Help` (sin función personalizada)
- **Bash**: Función de ayuda manual

## Funcionalidades de PowerShell Implementadas

### 1. **Parámetros Avanzados**
```powershell
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=1)]
    [Alias("d")]
    [ValidateNotNullOrEmpty()]
    [String]$Directorio
)
```

### 2. **Documentación de Ayuda**
```powershell
<#
.SYNOPSIS
Procesa archivos de logs y cuenta ocurrencias de palabras.

.DESCRIPTION
Descripción detallada del script.

.PARAMETER Directorio
Descripción del parámetro.
#>
```

### 3. **Manejo de Errores Robusto**
```powershell
try {
    # Código principal
}
catch {
    Write-Error "Error: $($_.Exception.Message)"
    exit 1
}
finally {
    # Limpieza de recursos
}
```

### 4. **Procesamiento de Objetos**
```powershell
$logFiles | Where-Object { 
    Test-Path $_.FullName 
} | ForEach-Object {
    Get-Content $_.FullName
}
```

## Cómo Ejecutar las Pruebas

### Opción 1: Script Automatizado (Recomendado)
```powershell
cd /home/tfelice/dev/vh/APL
pwsh ./powershell/ejercicio3/run_tests.ps1
```

### Opción 2: Pruebas Individuales
```powershell
cd /home/tfelice/dev/vh/APL

# Ejemplo básico
pwsh ./powershell/ejercicio3/ejercicio3.ps1 -Directorio "./powershell/ejercicio3/in/caso_normal" -Palabras "USB,Invalid"

# Con alias
pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d "./powershell/ejercicio3/in/caso_case_sensitive" -p "usb,invalid,error"

# Obtener ayuda
Get-Help ./powershell/ejercicio3/ejercicio3.ps1
Get-Help ./powershell/ejercicio3/ejercicio3.ps1 -Full
```

## Verificaciones Automáticas

El script `run_tests.ps1` verifica:
- Códigos de salida correctos
- Output específico para casos conocidos
- Manejo apropiado de errores con PowerShell
- Limpieza de archivos temporales
- Case-insensitive funcionando correctamente
- Validación nativa de parámetros
- Compatibilidad con rutas Windows y Unix

## Ejemplos de Uso Práctico

```powershell
# Buscar errores en logs de sistema
.\ejercicio3.ps1 -Directorio "C:\logs" -Palabras "error,failed,exception"

# Buscar intentos de conexión
.\ejercicio3.ps1 -d "./logs" -p "connection,connect,login"

# Buscar eventos de hardware con alias
.\ejercicio3.ps1 -d "./logs" -p "USB,device,kernel"

# Obtener ayuda detallada
Get-Help .\ejercicio3.ps1 -Examples
```

## Ventajas de la Implementación PowerShell

1. **Validación Automática**: PowerShell valida parámetros automáticamente
2. **Documentación Integrada**: Sistema de ayuda nativo con `Get-Help`
3. **Manejo de Objetos**: Trabajo con objetos .NET en lugar de solo texto
4. **Multiplataforma**: Funciona en Windows, Linux y macOS
5. **Debugging Avanzado**: Mejor capacidad de debugging y logging
6. **Integración .NET**: Acceso a todas las capacidades del framework .NET

## Resultados Esperados

- **15+ pruebas automatizadas**
- **100% compatibilidad funcional con la versión Bash**
- **Manejo robusto de casos edge con PowerShell**
- **Case-insensitive completamente funcional**
- **Limpieza automática de recursos**
- **Documentación completa accesible con Get-Help**
