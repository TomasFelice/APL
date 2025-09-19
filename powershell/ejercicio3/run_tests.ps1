# =================================================
# Script de pruebas para ejercicio3.ps1
# Integrantes:
# - Felice, Tomas Agustin
# - Casas, Lautaro Nahuel  
# - Coarite Coarite, Ivan Enrique
# =================================================

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "INICIANDO LOTE DE PRUEBAS - EJERCICIO 3 PS" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Contador de pruebas
$testCount = 0
$passCount = 0
$failCount = 0

# Función para ejecutar prueba
function Test-Command {
    param(
        [string]$Description,
        [string]$Command,
        [int]$ExpectedExitCode = 0,
        [string[]]$ExpectedOutput = @(),
        [bool]$ShouldFail = $false
    )
    
    $global:testCount++
    Write-Host "Prueba $global:testCount`: $Description" -ForegroundColor Yellow
    Write-Host "Comando: $Command" -ForegroundColor Gray
    
    try {
        # Ejecutar comando y capturar salida
        $output = @()
        $exitCode = 0
        
        # Usar Invoke-Expression para ejecutar el comando
        try {
            $output = Invoke-Expression $Command 2>&1
            $exitCode = $LASTEXITCODE
            if ($null -eq $exitCode) { $exitCode = 0 }
        } catch {
            $output = $_.Exception.Message
            $exitCode = 1
        }
        
        # Verificar código de salida
        $exitCodeOk = ($exitCode -eq $ExpectedExitCode)
        
        # Verificar salida esperada
        $outputOk = $true
        if ($ExpectedOutput.Count -gt 0) {
            $outputText = $output -join "`n"
            foreach ($expected in $ExpectedOutput) {
                if ($outputText -notmatch [regex]::Escape($expected)) {
                    $outputOk = $false
                    break
                }
            }
        }
        
        if ($exitCodeOk -and $outputOk) {
            Write-Host "✓ PASÓ" -ForegroundColor Green
            $global:passCount++
        } else {
            Write-Host "✗ FALLÓ" -ForegroundColor Red
            if (-not $exitCodeOk) {
                Write-Host "  Código de salida: esperado $ExpectedExitCode, obtuvo $exitCode" -ForegroundColor Red
            }
            if (-not $outputOk) {
                Write-Host "  Salida no coincide con lo esperado" -ForegroundColor Red
            }
            Write-Host "  Salida real: $($output -join ' | ')" -ForegroundColor Red
            $global:failCount++
        }
    } catch {
        Write-Host "✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        $global:failCount++
    }
    
    Write-Host ""
}

# Cambiar al directorio base
Set-Location "/home/tfelice/dev/vh/APL"

Write-Host "PRUEBAS BÁSICAS DE FUNCIONALIDAD" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Prueba del ejemplo de la consigna
Test-Command `
    "Ejemplo de la consigna (USB,Invalid)" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -Directorio './powershell/ejercicio3/in/caso_normal' -Palabras 'USB,Invalid'" `
    0 `
    @("USB: 2", "Invalid: 4")

# Prueba case-insensitive con minúsculas
Test-Command `
    "Case-insensitive - minúsculas" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_case_sensitive' -p 'usb,invalid,error'" `
    0 `
    @("usb: 3", "invalid: 3", "error: 3")

# Prueba case-insensitive con mayúsculas
Test-Command `
    "Case-insensitive - mayúsculas" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_case_sensitive' -p 'USB,INVALID,ERROR'" `
    0 `
    @("USB: 3", "INVALID: 3", "ERROR: 3")

# Prueba con una sola palabra
Test-Command `
    "Una sola palabra" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_normal' -p 'error'" `
    0 `
    @("error: 4")

Write-Host "PRUEBAS DE VALIDACIÓN DE PARÁMETROS" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta

# Sin parámetros
Test-Command `
    "Sin parámetros" `
    "pwsh -NonInteractive ./powershell/ejercicio3/ejercicio3.ps1 2>&1" `
    1 `
    @("missing mandatory parameters") `
    $false

# Solo directorio
Test-Command `
    "Solo directorio, sin palabras" `
    "pwsh -NonInteractive ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_normal' 2>&1" `
    1 `
    @("missing mandatory parameters", "Palabras") `
    $false

# Solo palabras
Test-Command `
    "Solo palabras, sin directorio" `
    "pwsh -NonInteractive ./powershell/ejercicio3/ejercicio3.ps1 -p 'test,word' 2>&1" `
    1 `
    @("missing mandatory parameters", "Directorio") `
    $false

Write-Host "PRUEBAS DE VALIDACIÓN DE DIRECTORIOS" -ForegroundColor Magenta  
Write-Host "=====================================" -ForegroundColor Magenta

# Directorio inexistente
Test-Command `
    "Directorio inexistente" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './directorio_inexistente' -p 'test' 2>&1" `
    1 `
    @("Error") `
    $true

# Directorio sin archivos .log
Test-Command `
    "Directorio sin archivos .log" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_sin_logs' -p 'test' 2>&1" `
    1 `
    @("No se encontraron archivos .log") `
    $true

Write-Host "PRUEBAS DE CASOS ESPECIALES" -ForegroundColor Magenta
Write-Host "============================" -ForegroundColor Magenta

# Archivo vacío
Test-Command `
    "Archivo log vacío" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_vacio' -p 'test,word'" `
    0 `
    @("test: 0", "word: 0")

# Archivo único
Test-Command `
    "Archivo único" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_archivo_unico' -p 'test'" `
    0 `
    @("test: 4")

Write-Host "PRUEBAS DE DIFERENTES COMBINACIONES DE PALABRAS" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta

# Palabras que no existen
Test-Command `
    "Palabras que no existen en logs" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_normal' -p 'palabra_inexistente,otra_palabra'" `
    0 `
    @("palabra_inexistente: 0", "otra_palabra: 0")

# Mezcla de palabras existentes e inexistentes
Test-Command `
    "Mezcla de palabras existentes e inexistentes" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d './powershell/ejercicio3/in/caso_normal' -p 'USB,inexistente,Invalid'" `
    0 `
    @("USB: 2", "inexistente: 0", "Invalid: 4")

Write-Host "PRUEBAS DE RUTAS RELATIVAS Y ABSOLUTAS" -ForegroundColor Magenta
Write-Host "=======================================" -ForegroundColor Magenta

# Ruta absoluta
$absolutePath = (Resolve-Path "./powershell/ejercicio3/in/caso_normal").Path
Test-Command `
    "Ruta absoluta" `
    "pwsh ./powershell/ejercicio3/ejercicio3.ps1 -d '$absolutePath' -p 'USB'" `
    0 `
    @("USB: 2")

Write-Host "RESUMEN DE PRUEBAS" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host "Total de pruebas: $testCount" -ForegroundColor White
Write-Host "Exitosas: $passCount" -ForegroundColor Green
Write-Host "Fallidas: $failCount" -ForegroundColor Red

if ($failCount -eq 0) {
    Write-Host "¡TODAS LAS PRUEBAS PASARON!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "ALGUNAS PRUEBAS FALLARON" -ForegroundColor Red
    exit 1
}
