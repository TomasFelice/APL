# =================================================
# Script de Test para ejercicio4.ps1
# Simula commits con datos sensibles para probar la detección del demonio
# =================================================

[CmdletBinding()]
param(
    [string]$TestRepo = ".\test-repo",
    [string]$ConfigFile = ".\patrones.conf", 
    [string]$LogFile = ".\test-logs\audit.log",
    [int]$WaitTime = 5,
    [switch]$Cleanup,
    [switch]$Help
)

function Show-Help {
    @"
Uso:
  .\test-ejercicio4.ps1 [-TestRepo <ruta>] [-ConfigFile <ruta>] [-LogFile <ruta>] [-WaitTime <segundos>]
  .\test-ejercicio4.ps1 -Cleanup   # limpia archivos de test

Opciones:
  -TestRepo     Ruta del repositorio de prueba (default: .\test-repo)
  -ConfigFile   Ruta al archivo de patrones (default: .\patrones.conf)
  -LogFile      Ruta al archivo de logs de test (default: .\test-logs\audit.log)
  -WaitTime     Tiempo de espera entre commits en segundos (default: 5)
  -Cleanup      Limpia archivos y directorios de test
  -Help         Muestra esta ayuda

Descripción:
  Este script crea un repositorio de prueba, simula varios commits con datos
  sensibles y ejecuta el demonio ejercicio4.ps1 para verificar la detección.
"@
}

if ($Help) { Show-Help; exit 0 }

function Write-TestLog([string]$message, [string]$color = "White") {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $message" -ForegroundColor $color
}

function Remove-TestFiles {
    Write-TestLog "Iniciando limpieza de archivos de test..." "Yellow"
    
    # Detener cualquier demonio en ejecución
    if (Test-Path $TestRepo) {
        try {
            & ".\ejercicio4.ps1" -Repo $TestRepo -Kill 2>$null
            Write-TestLog "Demonio detenido (si estaba ejecutándose)" "Green"
        } catch {
            Write-TestLog "No se pudo detener el demonio o no estaba ejecutándose" "Yellow"
        }
    }
    
    # Eliminar directorios de test
    $dirsToRemove = @($TestRepo, "test-logs")
    foreach ($dir in $dirsToRemove) {
        if (Test-Path $dir) {
            try {
                Remove-Item -Path $dir -Recurse -Force
                Write-TestLog "Eliminado directorio: $dir" "Green"
            } catch {
                Write-TestLog "Error eliminando $dir`: $($_.Exception.Message)" "Red"
            }
        }
    }
    
    Write-TestLog "Limpieza completada" "Green"
}

if ($Cleanup) {
    Remove-TestFiles
    exit 0
}

function Initialize-TestRepo {
    Write-TestLog "Inicializando repositorio de prueba en: $TestRepo" "Cyan"
    
    # Crear directorio del repo
    if (Test-Path $TestRepo) {
        Remove-Item -Path $TestRepo -Recurse -Force
    }
    New-Item -ItemType Directory -Path $TestRepo -Force | Out-Null
    
    # Inicializar git
    Push-Location $TestRepo
    try {
        & git init 2>$null
        if ($LASTEXITCODE -ne 0) { throw "Error inicializando git" }
        
        & git config user.email "test@example.com" 2>$null
        & git config user.name "Test User" 2>$null
        
        # Commit inicial vacío
        "# Test Repository" | Out-File -FilePath "README.md" -Encoding utf8
        & git add README.md 2>$null
        & git commit -m "Initial commit" 2>$null
        
        Write-TestLog "Repositorio inicializado correctamente" "Green"
    } catch {
        Pop-Location
        throw "Error inicializando repositorio: $($_.Exception.Message)"
    } finally {
        Pop-Location
    }
}

function New-SensitiveFile([string]$fileName, [string]$content) {
    $filePath = Join-Path $TestRepo $fileName
    
    # Crear directorio si no existe
    $dir = Split-Path $filePath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    $content | Out-File -FilePath $filePath -Encoding utf8
    Write-TestLog "Creado archivo con datos sensibles: $fileName" "Yellow"
}

function Add-Commit([string]$message, [string[]]$files) {
    Push-Location $TestRepo
    try {
        foreach ($file in $files) {
            & git add $file 2>$null
        }
        & git commit -m $message 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TestLog "Commit realizado: $message" "Green"
        } else {
            Write-TestLog "Error en commit: $message" "Red"
        }
    } finally {
        Pop-Location
    }
}

function Start-DaemonTest {
    Write-TestLog "Iniciando demonio ejercicio4.ps1..." "Cyan"
    
    # Crear directorio para logs si no existe
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Crear el archivo de log vacío (necesario para To-AbsolutePath)
    $logPath = Join-Path $logDir "audit.log"
    if (-not (Test-Path $logPath)) {
        New-Item -ItemType File -Path $logPath -Force | Out-Null
    }
    
    # Convertir rutas a absolutas
    $repoPath = (Resolve-Path $TestRepo).Path
    $configPath = (Resolve-Path $ConfigFile).Path
    $logAbsolutePath = (Resolve-Path $logPath).Path
    
    Write-TestLog "Repo: $repoPath" "Gray"
    Write-TestLog "Config: $configPath" "Gray"  
    Write-TestLog "Log: $logAbsolutePath" "Gray"
    
    try {
        & ".\ejercicio4.ps1" -Repo $repoPath -Configuracion $configPath -Log $logAbsolutePath -Alerta 3
        Write-TestLog "Demonio iniciado correctamente" "Green"
        Start-Sleep 3  # Dar más tiempo al demonio para inicializarse
    } catch {
        throw "Error iniciando demonio: $($_.Exception.Message)"
    }
}

function Wait-AndShowProgress([int]$seconds, [string]$message) {
    Write-TestLog $message "Cyan"
    for ($i = $seconds; $i -gt 0; $i--) {
        Write-Progress -Activity $message -Status "Esperando $i segundos..." -PercentComplete ((($seconds - $i) / $seconds) * 100)
        Start-Sleep 1
    }
    Write-Progress -Activity $message -Completed
}

function Show-LogResults {
    Write-TestLog "=== RESULTADOS DEL TEST ===" "Magenta"
    
    if (Test-Path $LogFile) {
        Write-TestLog "Contenido del archivo de log:" "Cyan"
        Write-Host ""
        Get-Content $LogFile | ForEach-Object {
            if ($_ -match "Alerta:") {
                Write-Host $_ -ForegroundColor Red
            } elseif ($_ -match "Info:") {
                Write-Host $_ -ForegroundColor Green
            } else {
                Write-Host $_ -ForegroundColor White
            }
        }
        Write-Host ""
        
        # Contar alertas
        $alertas = (Get-Content $LogFile | Where-Object { $_ -match "Alerta:" }).Count
        Write-TestLog "Total de alertas detectadas: $alertas" "Magenta"
    } else {
        Write-TestLog "No se encontró el archivo de log: $LogFile" "Red"
    }
}

# ======================
# INICIO DEL TEST
# ======================

try {
    Write-TestLog "=== INICIANDO TEST DE EJERCICIO4.PS1 ===" "Magenta"
    
    # Verificar que el script principal existe
    if (-not (Test-Path ".\ejercicio4.ps1")) {
        throw "No se encontró el archivo ejercicio4.ps1 en el directorio actual"
    }
    
    if (-not (Test-Path $ConfigFile)) {
        throw "No se encontró el archivo de configuración: $ConfigFile"
    }
    
    Write-TestLog "Archivos necesarios encontrados" "Green"
    
    # Paso 1: Inicializar repositorio de prueba
    Initialize-TestRepo
    
    # Paso 2: Iniciar demonio
    Start-DaemonTest
    
    # Actualizar LogFile a la ruta absoluta para las validaciones
    $logDir = Split-Path $LogFile -Parent
    $LogFile = Join-Path $logDir "audit.log"
    $LogFile = (Resolve-Path $LogFile).Path
    
    Write-TestLog "=== INICIANDO SIMULACIÓN DE COMMITS ===" "Magenta"
    
    # Test 1: Archivo con password literal
    Write-TestLog "Test 1: Creando archivo con password literal" "Yellow"
    New-SensitiveFile "config.txt" @"
database_host=localhost
database_user=admin
database_password=secreto123
port=5432
"@
    Add-Commit "Agregar configuración de base de datos" @("config.txt")
    Wait-AndShowProgress $WaitTime "Esperando detección de password..."
    
    # Test 2: Archivo con API_KEY
    Write-TestLog "Test 2: Creando archivo con API_KEY" "Yellow"
    New-SensitiveFile "api-config.js" @"
const config = {
    API_KEY: "sk-1234567890abcdef",
    endpoint: "https://api.example.com",
    timeout: 5000
};
module.exports = config;
"@
    Add-Commit "Agregar configuración de API" @("api-config.js")
    Wait-AndShowProgress $WaitTime "Esperando detección de API_KEY..."
    
    # Test 3: Archivo que coincide con patrón regex
    Write-TestLog "Test 3: Creando archivo que coincide con patrón regex" "Yellow"
    New-SensitiveFile "environment.env" @"
DATABASE_URL=postgresql://user:pass@localhost/db
API_KEY = "production-key-xyz789"
DEBUG=false
"@
    Add-Commit "Agregar variables de entorno" @("environment.env")
    Wait-AndShowProgress $WaitTime "Esperando detección de patrón regex..."
    
    # Test 4: Archivo con secret
    Write-TestLog "Test 4: Creando archivo con secret" "Yellow"
    New-SensitiveFile "auth/tokens.json" @"
{
    "jwt_secret": "super-secret-key-123",
    "refresh_token": "refresh-abc-456",
    "encryption_key": "encrypt-789-xyz"
}
"@
    Add-Commit "Agregar tokens de autenticación" @("auth/tokens.json")
    Wait-AndShowProgress $WaitTime "Esperando detección de secret..."
    
    # Test 5: Múltiples archivos en un commit
    Write-TestLog "Test 5: Creando múltiples archivos con datos sensibles" "Yellow"
    New-SensitiveFile "credentials.py" @"
# Database credentials
DB_PASSWORD = "admin123"
API_KEY = "dev-key-456"
SECRET_TOKEN = "token-789"
"@
    
    New-SensitiveFile "settings.yaml" @"
database:
  password: mypassword
  host: localhost
api:
  secret: api_secret_key
  timeout: 30
"@
    
    Add-Commit "Agregar credenciales y configuraciones" @("credentials.py", "settings.yaml")
    Wait-AndShowProgress $WaitTime "Esperando detección en múltiples archivos..."
    
    # Test 6: Archivo sin datos sensibles (control negativo)
    Write-TestLog "Test 6: Creando archivo sin datos sensibles (control)" "Yellow"
    New-SensitiveFile "utils.js" @"
function formatDate(date) {
    return date.toISOString().split('T')[0];
}

function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

module.exports = { formatDate, capitalize };
"@
    Add-Commit "Agregar funciones utilitarias" @("utils.js")
    Wait-AndShowProgress $WaitTime "Procesando archivo sin datos sensibles..."
    
    # Espera final para asegurar que el demonio procese todo
    Wait-AndShowProgress 5 "Esperando procesamiento final del demonio..."
    
    # Detener demonio
    Write-TestLog "Deteniendo demonio..." "Yellow"
    $repoPath = (Resolve-Path $TestRepo).Path
    & ".\ejercicio4.ps1" -Repo $repoPath -Kill
    
    # Mostrar resultados
    Show-LogResults
    
    # Validación adicional
    Write-TestLog "=== VALIDACIÓN DEL TEST ===" "Magenta"
    
    if (Test-Path $LogFile) {
        $logContent = Get-Content $LogFile
        $alertCount = ($logContent | Where-Object { $_ -match "Alerta:" }).Count
        
        # Patrones esperados
        $expectedPatterns = @("password", "API_KEY", "secret")
        $detectedPatterns = @()
        
        foreach ($pattern in $expectedPatterns) {
            $found = $logContent | Where-Object { $_ -match "patrón '$pattern'" }
            if ($found) {
                $detectedPatterns += $pattern
                Write-TestLog "✓ Patrón '$pattern' detectado correctamente" "Green"
            } else {
                Write-TestLog "✗ Patrón '$pattern' NO detectado" "Red"
            }
        }
        
        # Verificar patrón regex
        $regexFound = $logContent | Where-Object { $_ -match "patrón_regex" }
        if ($regexFound) {
            Write-TestLog "✓ Patrón regex detectado correctamente" "Green"
        } else {
            Write-TestLog "✗ Patrón regex NO detectado" "Red"
        }
        
        Write-TestLog "Patrones detectados: $($detectedPatterns.Count)/$($expectedPatterns.Count)" "Cyan"
        Write-TestLog "Total de alertas: $alertCount" "Cyan"
        
        if ($alertCount -gt 0) {
            Write-TestLog "✓ TEST EXITOSO: Se detectaron datos sensibles" "Green"
        } else {
            Write-TestLog "✗ TEST FALLIDO: No se detectaron alertas" "Red"
        }
    } else {
        Write-TestLog "✗ TEST FALLIDO: No se generó archivo de log" "Red"
    }
    
} catch {
    Write-TestLog "ERROR EN TEST: $($_.Exception.Message)" "Red"
    
    # Intentar detener demonio en caso de error
    try {
        & ".\ejercicio4.ps1" -Repo $TestRepo -Kill 2>$null
    } catch {
        # Ignorar errores al detener
    }
    
    exit 1
} finally {
    Write-TestLog "=== FIN DEL TEST ===" "Magenta"
    Write-TestLog "Para limpiar archivos de test ejecute: .\test-ejercicio4.ps1 -Cleanup" "Yellow"
}