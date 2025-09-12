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
$OUTPUT_DIR = Join-Path $SCRIPT_DIR "out"

# Contadores de pruebas
$script:TOTAL_TESTS = 0
$script:PASSED_TESTS = 0
$script:FAILED_TESTS = 0

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
        [switch]$ShouldFail = $false,
        [switch]$InteractiveTest = $false
    )
    
    $script:TOTAL_TESTS++
    
    Write-TestCase $TestName
    
    if (-not $Silent) {
        Write-Host "Comando: $Command" -ForegroundColor Gray
    }
    
    try {
        if ($InteractiveTest) {
            # Para pruebas interactivas donde el script pide parámetros o puede colgar
            if (-not $Silent) {
                Write-Host "⚠️  PRUEBA INTERACTIVA - Se espera que el script solicite parámetros o falle" -ForegroundColor Yellow
            }
            
            $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
            # Crear script con timeout y manejo de entrada
            @"
try {
    `$job = Start-Job -ScriptBlock { $Command }
    if (Wait-Job `$job -Timeout 10) {
        `$result = Receive-Job `$job
        `$exitCode = 0
        if (`$job.State -eq 'Failed') { `$exitCode = 1 }
    } else {
        Stop-Job `$job
        `$exitCode = 1
        `$result = "Timeout: El comando no terminó en 10 segundos"
    }
    Remove-Job `$job -Force
    Write-Output `$result
    exit `$exitCode
} catch {
    Write-Output "Error: `$(`$_.Exception.Message)"
    exit 1
}
"@ | Out-File -FilePath $tempScript -Encoding UTF8
            
            $result = & pwsh -File $tempScript 2>&1
            $exitCode = $LASTEXITCODE
            
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        } else {
            # Ejecución normal sin interactividad
            $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
            $Command + "; exit `$LASTEXITCODE" | Out-File -FilePath $tempScript -Encoding UTF8
            
            $result = & pwsh -File $tempScript 2>&1
            $exitCode = $LASTEXITCODE
            
            Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
        }
        
        # Evaluar resultado
        $testPassed = $false
        
        if ($ShouldFail) {
            if ($exitCode -ne 0) {
                Write-Host "✓ PASS - Comando falló como se esperaba (código: $exitCode)" -ForegroundColor Green
                $testPassed = $true
            } else {
                Write-Host "✗ FAIL - Comando debería haber fallado pero tuvo éxito" -ForegroundColor Red
            }
        } else {
            if ($exitCode -eq $ExpectedExitCode) {
                Write-Host "✓ PASS - Código de salida correcto ($exitCode)" -ForegroundColor Green
                $testPassed = $true
                
                if (-not $Silent -and $result) {
                    Write-Host "Salida:" -ForegroundColor Gray
                    $result | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
                }
            } else {
                Write-Host "✗ FAIL - Código de salida incorrecto. Esperado: $ExpectedExitCode, Obtenido: $exitCode" -ForegroundColor Red
                
                if ($result) {
                    Write-Host "Salida del error:" -ForegroundColor Red
                    $result | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkRed }
                }
            }
        }
        
        # Actualizar contadores
        if ($testPassed) {
            $script:PASSED_TESTS++
        } else {
            $script:FAILED_TESTS++
        }
        
    } catch {
        Write-Host "✗ FAIL - Error al ejecutar comando: $($_.Exception.Message)" -ForegroundColor Red
        $script:FAILED_TESTS++
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

function Clear-TestEnvironment {
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
    
    Test-Command "Ayuda con Get-Help" `
        "Get-Help '$EJERCICIO_SCRIPT'" `
        0
    
    Test-Command "Ayuda con Get-Help -Examples" `
        "Get-Help '$EJERCICIO_SCRIPT' -Examples" `
        0
    
    Test-Command "Ayuda con Get-Help -Detailed" `
        "Get-Help '$EJERCICIO_SCRIPT' -Detailed" `
        0
}

function Test-InvalidParameters {
    Write-TestHeader "PRUEBAS DE PARÁMETROS OBLIGATORIOS Y VALIDACIÓN"
    
    Test-Command "Sin parámetros - debe solicitar parámetros obligatorios" `
        "& '$EJERCICIO_SCRIPT'" `
        1 -ShouldFail -InteractiveTest
    
    Test-Command "Solo directorio sin especificar salida - debe fallar por ParameterSet" `
        "echo '' | timeout 5 & '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_normal'" `
        1 -ShouldFail -InteractiveTest
    
    Test-Command "Directorio vacío como parámetro - validación NotNullOrEmpty" `
        "& '$EJERCICIO_SCRIPT' -Directorio '' -Pantalla" `
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
        $script:PASSED_TESTS++
    } else {
        Write-Host "✗ FAIL - Archivo de salida no fue creado" -ForegroundColor Red
        $script:FAILED_TESTS++
    }
    $script:TOTAL_TESTS++
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

function Test-ParameterSets {
    Write-TestHeader "PRUEBAS DE CONJUNTOS DE PARÁMETROS (ParameterSets)"
    
    Test-Command "ParameterSet ArchivoSet - válido" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Archivo './powershell/ejercicio1/out/test_parameterset.json'" `
        0
    
    Test-Command "ParameterSet PantallaSet - válido" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Pantalla" `
        0
    
    # Esta prueba debe usar InteractiveTest porque PowerShell puede pedir confirmación o inputs
    Test-Command "Conflicto ParameterSets - -Archivo y -Pantalla juntos (debe fallar)" `
        "echo 'n' | & '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Archivo 'test.json' -Pantalla 2>&1" `
        1 -ShouldFail -InteractiveTest
}

function Test-ParameterOrder {
    Write-TestHeader "PRUEBAS DE ORDEN DE PARÁMETROS Y ALIASES"
    
    Test-Command "Orden: -Pantalla -Directorio" `
        "& '$EJERCICIO_SCRIPT' -Pantalla -Directorio './powershell/ejercicio1/in/caso_archivo_unico'" `
        0
    
    Test-Command "Usando aliases cortos (-d -p)" `
        "& '$EJERCICIO_SCRIPT' -p -d './powershell/ejercicio1/in/caso_archivo_unico'" `
        0
        
    Test-Command "Usando aliases cortos (-d -a)" `
        "& '$EJERCICIO_SCRIPT' -d './powershell/ejercicio1/in/caso_archivo_unico' -a './powershell/ejercicio1/out/test_alias.json'" `
        0
    
    Test-Command "Parámetro posicional (Directorio en posición 0)" `
        "& '$EJERCICIO_SCRIPT' './powershell/ejercicio1/in/caso_archivo_unico' -Pantalla" `
        0
}

function Test-OutputErrors {
    Write-TestHeader "PRUEBAS DE ARCHIVOS DE SALIDA CON ERRORES"
    
    Test-Command "Directorio de salida inexistente" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Archivo '/directorio/inexistente/archivo.json'" `
        1 -ShouldFail
}

function Test-TempFileCleanup {
    Write-TestHeader "PRUEBAS DE LIMPIEZA DE ARCHIVOS TEMPORALES"
    
    # Contar archivos temporales antes
    $tempFilesBefore = Get-ChildItem "/tmp" -Filter "*powershell_ejercicio1*" -ErrorAction SilentlyContinue
    $countBefore = if ($tempFilesBefore) { $tempFilesBefore.Count } else { 0 }
    
    Test-Command "Ejecución normal - verificar limpieza de archivos temporales" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Pantalla" `
        0
    
    # Contar archivos temporales después
    Start-Sleep -Seconds 1  # Dar tiempo para la limpieza
    $tempFilesAfter = Get-ChildItem "/tmp" -Filter "*powershell_ejercicio1*" -ErrorAction SilentlyContinue
    $countAfter = if ($tempFilesAfter) { $tempFilesAfter.Count } else { 0 }
    
    if ($countAfter -eq $countBefore) {
        Write-Host "✓ PASS - Archivos temporales limpiados correctamente" -ForegroundColor Green
        $script:PASSED_TESTS++
    } else {
        Write-Host "✗ FAIL - Archivos temporales no fueron limpiados. Antes: $countBefore, Después: $countAfter" -ForegroundColor Red
        $script:FAILED_TESTS++
    }
    $script:TOTAL_TESTS++
    
    Test-Command "Ejecución con error - verificar limpieza de archivos temporales" `
        "& '$EJERCICIO_SCRIPT' -Directorio '/directorio/inexistente' -Pantalla" `
        1 -ShouldFail
    
    # Verificar limpieza después de error
    Start-Sleep -Seconds 1
    $tempFilesAfterError = Get-ChildItem "/tmp" -Filter "*powershell_ejercicio1*" -ErrorAction SilentlyContinue
    $countAfterError = if ($tempFilesAfterError) { $tempFilesAfterError.Count } else { 0 }
    
    if ($countAfterError -eq $countBefore) {
        Write-Host "✓ PASS - Archivos temporales limpiados correctamente después de error" -ForegroundColor Green
        $script:PASSED_TESTS++
    } else {
        Write-Host "✗ FAIL - Archivos temporales no fueron limpiados después de error. Esperado: $countBefore, Actual: $countAfterError" -ForegroundColor Red
        $script:FAILED_TESTS++
    }
    $script:TOTAL_TESTS++
}

function Test-VerboseOutput {
    Write-TestHeader "PRUEBAS DE SALIDA VERBOSE"
    
    Test-Command "Ejecutar con -Verbose para verificar logging detallado" `
        "& '$EJERCICIO_SCRIPT' -Directorio './powershell/ejercicio1/in/caso_archivo_unico' -Pantalla -Verbose" `
        0
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
        Test-ParameterSets
        Test-InvalidDirectories
        Test-PathFormats
        Test-FunctionalCases
        Test-SingleFile
        Test-EmptyData
        Test-ParameterOrder
        Test-OutputErrors
        Test-TempFileCleanup
        Test-VerboseOutput
        
        # Mostrar resumen final
        Write-Host "`n$('=' * 50)" -ForegroundColor Blue
        Write-Host "  RESUMEN DE PRUEBAS" -ForegroundColor Blue
        Write-Host "$('=' * 50)" -ForegroundColor Blue
        Write-Host "Total de pruebas: $($script:TOTAL_TESTS)" -ForegroundColor White
        Write-Host "Pruebas exitosas: $($script:PASSED_TESTS)" -ForegroundColor Green
        Write-Host "Pruebas fallidas: $($script:FAILED_TESTS)" -ForegroundColor Red
        
        if ($script:FAILED_TESTS -eq 0) {
            Write-Host "`n🎉 ¡TODAS LAS PRUEBAS PASARON!" -ForegroundColor Green
            $exitCode = 0
        } else {
            Write-Host "`n❌ ALGUNAS PRUEBAS FALLARON" -ForegroundColor Red
            $exitCode = 1
        }
        
        if ($script:TOTAL_TESTS -gt 0) {
            $percentage = [math]::Round(($script:PASSED_TESTS / $script:TOTAL_TESTS) * 100, 1)
            Write-Host "Porcentaje de éxito: $percentage%" -ForegroundColor $(if ($percentage -eq 100) { "Green" } else { "Yellow" })
        } else {
            Write-Host "No se ejecutaron pruebas" -ForegroundColor Red
            $exitCode = 1
        }
        
    } finally {
        Clear-TestEnvironment
    }
    
    exit $exitCode
}

# =====================================
# EJECUTAR PRUEBAS
# =====================================

# Manejo de Ctrl+C
trap {
    Write-Host "`nPruebas interrumpidas por el usuario" -ForegroundColor Yellow
    Clear-TestEnvironment
    exit 130
}

# Ejecutar función principal
Main
