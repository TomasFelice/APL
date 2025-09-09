#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Script automatizado de pruebas para ejercicio1.ps1

.DESCRIPTION
    Ejecuta un conjunto completo de pruebas automatizadas del script ejercicio1.ps1
    de forma similar a la versión bash, pero adaptado a PowerShell.

.PARAMETER Silent
    Ejecuta las pruebas en modo silencioso (solo muestra resultados finales)

.EXAMPLE
    ./run_tests.ps1
    Ejecuta todas las pruebas con salida completa

.EXAMPLE
    ./run_tests.ps1 -Silent
    Ejecuta todas las pruebas en modo silencioso
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Silent
)

# =====================================
# CONFIGURACIÓN INICIAL
# =====================================

$SCRIPT_DIR = $PSScriptRoot
$BASE_DIR = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)
$EJERCICIO_SCRIPT = Join-Path $SCRIPT_DIR "ejercicio1.ps1"
$TEST_DIR = Join-Path $SCRIPT_DIR "in"
$OUTPUT_DIR = Join-Path $SCRIPT_DIR "out"

# Contadores de pruebas
$TOTAL_TESTS = 0
$PASSED_TESTS = 0
$FAILED_TESTS = 0

# Archivo de log temporal
$TEMP_LOG = [System.IO.Path]::GetTempFileName()

# =====================================
# FUNCIONES AUXILIARES
# =====================================

function Write-TestHeader {
    param([string]$Title)
    if (-not $Silent) {
        Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "$('=' * 50)" -ForegroundColor Cyan
    }
}

function Write-TestCase {
    param([string]$TestName)
    if (-not $Silent) {
        Write-Host "`n--- $TestName ---" -ForegroundColor Yellow
    }
}

function Test-Command {
    param(
        [string]$TestName,
        [string]$Command,
        [int]$ExpectedExitCode = 0,
        [string]$ExpectedOutput = "",
        [switch]$ShouldFail = $false
    )
    
    $global:TOTAL_TESTS++
    
    Write-TestCase $TestName
    
    if (-not $Silent) {
        Write-Host "Comando: $Command" -ForegroundColor Gray
    }
    
    try {
        # Crear un script temporal para ejecutar el comando y capturar el código de salida
        $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
        $Command + "; exit `$LASTEXITCODE" | Out-File -FilePath $tempScript -Encoding UTF8
        
        # Ejecutar el script temporal
        $result = & pwsh -File $tempScript 2>&1
        $exitCode = $LASTEXITCODE
        
        # Limpiar archivo temporal
        Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        
        if ($ShouldFail) {
            if ($exitCode -ne 0) {
                Write-Host "✓ PASS - Comando falló como se esperaba (código: $exitCode)" -ForegroundColor Green
                $global:PASSED_TESTS++
            } else {
                Write-Host "✗ FAIL - Comando debería haber fallado pero tuvo éxito" -ForegroundColor Red
                $global:FAILED_TESTS++
            }
        } else {
            if ($exitCode -eq $ExpectedExitCode) {
                Write-Host "✓ PASS - Código de salida correcto ($exitCode)" -ForegroundColor Green
                $global:PASSED_TESTS++
                
                if (-not $Silent -and $result) {
                    Write-Host "Salida:" -ForegroundColor Gray
                    $result | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
                }
            } else {
                Write-Host "✗ FAIL - Código de salida incorrecto. Esperado: $ExpectedExitCode, Obtenido: $exitCode" -ForegroundColor Red
                $global:FAILED_TESTS++
                
                if ($result) {
                    Write-Host "Salida del error:" -ForegroundColor Red
                    $result | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
                }
            }
        }
        
    } catch {
        Write-Host "✗ FAIL - Error al ejecutar comando: $($_.Exception.Message)" -ForegroundColor Red
        $global:FAILED_TESTS++
    }
}

function Initialize-TestEnvironment {
    Write-Host "Inicializando entorno de pruebas..." -ForegroundColor Blue
    
    # Crear directorios de salida
    $outputDirs = @(
        (Join-Path $OUTPUT_DIR "caso_normal"),
        (Join-Path $OUTPUT_DIR "caso_archivo_unico"),
        (Join-Path $OUTPUT_DIR "casos_especiales")
    )
    
    foreach ($dir in $outputDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    
    # Cambiar al directorio base para pruebas relativas
    Set-Location $BASE_DIR
    
    Write-Host "Entorno inicializado correctamente" -ForegroundColor Green
}

function Cleanup-TestEnvironment {
    Write-Host "`nLimpiando entorno de pruebas..." -ForegroundColor Blue
    
    # Limpiar archivos temporales
    if (Test-Path $TEMP_LOG) {
        Remove-Item $TEMP_LOG -Force
    }
    
    Write-Host "Limpieza completada" -ForegroundColor Green
}

# =====================================
# PRUEBAS ESPECÍFICAS
# =====================================

function Test-HelpOptions {
    Write-TestHeader "PRUEBAS DE AYUDA"
    
    Test-Command "Ayuda con -Help" `
        "& '$EJERCICIO_SCRIPT' -Help" `
        0
    
    Test-Command "Ayuda con -h" `
        "& '$EJERCICIO_SCRIPT' -h" `
        0
}

function Test-InvalidParameters {
    Write-TestHeader "PRUEBAS DE PARÁMETROS INCORRECTOS"
    
    Test-Command "Sin parámetros" `
        "& '$EJERCICIO_SCRIPT'" `
        1 -ShouldFail
    
    Test-Command "Solo directorio sin salida" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_normal'" `
        1 -ShouldFail
    
    Test-Command "Conflicto -Archivo y -Pantalla" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_normal' -Archivo 'salida.json' -Pantalla" `
        1 -ShouldFail
}

function Test-InvalidDirectories {
    Write-TestHeader "PRUEBAS DE DIRECTORIO INEXISTENTE/INVÁLIDO"
    
    Test-Command "Directorio inexistente" `
        "& '$EJERCICIO_SCRIPT' -Directorio '/directorio/inexistente' -Pantalla" `
        1 -ShouldFail
    
    Test-Command "Directorio sin archivos .txt" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_vacio' -Pantalla" `
        1 -ShouldFail
    
    Test-Command "Archivo en lugar de directorio" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/ejercicio1.ps1' -Pantalla" `
        1 -ShouldFail
}

function Test-PathFormats {
    Write-TestHeader "PRUEBAS DE RUTAS RELATIVAS Y ABSOLUTAS"
    
    Test-Command "Ruta relativa con ./" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_normal' -Pantalla" `
        0
    
    Test-Command "Ruta relativa sin ./" `
        "& '$EJERCICIO_SCRIPT' -Directorio 'powershell/ejercicio1/in/caso_normal' -Pantalla" `
        0
}

function Test-FunctionalCases {
    Write-TestHeader "PRUEBAS FUNCIONALES - CASOS NORMALES"
    
    Test-Command "Caso normal - salida a pantalla" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_normal' -Pantalla" `
        0
    
    Test-Command "Caso normal - salida a archivo" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_normal' -Archivo './powershell/ejercicio1/out/caso_normal/resultado_completo.json'" `
        0
    
    # Verificar que el archivo se creó
    $outputFile = "./powershell/ejercicio1/out/caso_normal/resultado_completo.json"
    if (Test-Path $outputFile) {
        Write-Host "✓ PASS - Archivo de salida creado correctamente" -ForegroundColor Green
        $global:PASSED_TESTS++
    } else {
        Write-Host "✗ FAIL - Archivo de salida no fue creado" -ForegroundColor Red
        $global:FAILED_TESTS++
    }
    $global:TOTAL_TESTS++
}

function Test-SingleFile {
    Write-TestHeader "PRUEBAS CON ARCHIVO ÚNICO"
    
    Test-Command "Archivo único - datos mínimos" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Pantalla" `
        0
    
    Test-Command "Archivo único - con aliases cortos" `
        "& '$EJERCICIO_SCRIPT' -d './powershell/ejercicio1/in/caso_archivo_unico' -a './powershell/ejercicio1/out/caso_archivo_unico/cambio_año.json'" `
        0
}

function Test-EmptyData {
    Write-TestHeader "PRUEBAS CON DATOS INVÁLIDOS"
    
    Test-Command "Archivos completamente vacíos" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_solo_vacios' -Pantalla" `
        1 -ShouldFail
}

function Test-ParameterOrder {
    Write-TestHeader "PRUEBAS DE ORDEN DE PARÁMETROS"
    
    Test-Command "Orden: -Pantalla -Directorio" `
        "& '$EJERCICIO_SCRIPT' -Pantalla -Directorio './powershell/ejercicio1/in/caso_archivo_unico'" `
        0
    
    Test-Command "Usando aliases cortos" `
        "& '$EJERCICIO_SCRIPT' -p -d './powershell/ejercicio1/in/caso_archivo_unico'" `
        0
}

function Test-OutputErrors {
    Write-TestHeader "PRUEBAS DE ARCHIVOS DE SALIDA CON ERRORES"
    
    Test-Command "Directorio de salida inexistente" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Archivo '/directorio/inexistente/archivo.json'" `
        1 -ShouldFail
}

# =====================================
# FUNCIÓN PRINCIPAL
# =====================================

function Main {
    Write-Host "=======================================" -ForegroundColor Blue
    Write-Host "  INICIANDO PRUEBAS EJERCICIO 1 (PS)" -ForegroundColor Blue
    Write-Host "=======================================" -ForegroundColor Blue
    
    # Verificar que el script existe
    if (-not (Test-Path $EJERCICIO_SCRIPT)) {
        Write-Host "ERROR: No se encuentra el script ejercicio1.ps1 en $EJERCICIO_SCRIPT" -ForegroundColor Red
        exit 1
    }
    
    # Inicializar entorno
    Initialize-TestEnvironment
    
    try {
        # Ejecutar todas las pruebas
        Test-HelpOptions
        Test-InvalidParameters
        Test-InvalidDirectories
        Test-PathFormats
        Test-FunctionalCases
        Test-SingleFile
        Test-EmptyData
        Test-ParameterOrder
        Test-OutputErrors
        
        # Mostrar resumen final
        Write-Host "`n$('=' * 50)" -ForegroundColor Blue
        Write-Host "  RESUMEN DE PRUEBAS" -ForegroundColor Blue
        Write-Host "$('=' * 50)" -ForegroundColor Blue
        Write-Host "Total de pruebas: $TOTAL_TESTS" -ForegroundColor White
        Write-Host "Pruebas exitosas: $PASSED_TESTS" -ForegroundColor Green
        Write-Host "Pruebas fallidas: $FAILED_TESTS" -ForegroundColor Red
        
        if ($FAILED_TESTS -eq 0) {
            Write-Host "`n🎉 ¡TODAS LAS PRUEBAS PASARON!" -ForegroundColor Green
            $exitCode = 0
        } else {
            Write-Host "`n❌ ALGUNAS PRUEBAS FALLARON" -ForegroundColor Red
            $exitCode = 1
        }
        
        $percentage = [math]::Round(($PASSED_TESTS / $TOTAL_TESTS) * 100, 1)
        Write-Host "Porcentaje de éxito: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } else { "Yellow" })
        
    } finally {
        Cleanup-TestEnvironment
    }
    
    exit $exitCode
}

# =====================================
# EJECUTAR PRUEBAS
# =====================================

# Manejo de Ctrl+C
trap {
    Write-Host "`nPruebas interrumpidas por el usuario" -ForegroundColor Yellow
    Cleanup-TestEnvironment
    exit 130
}

# Ejecutar función principal
Main
