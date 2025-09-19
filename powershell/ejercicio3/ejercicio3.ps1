<#
=================================================
Integrantes:
- Felice, Tomas Agustin
- Casas, Lautaro Nahuel  
- Coarite Coarite, Ivan Enrique
=================================================

.SYNOPSIS
Procesa archivos de logs en un directorio y devuelve la cantidad de ocurrencias de las palabras indicadas.

.DESCRIPTION
Este script analiza archivos .log en un directorio especificado y cuenta las ocurrencias de palabras clave proporcionadas. 
La búsqueda es case-insensitive y muestra los resultados en el orden en que se proporcionaron las palabras.

.PARAMETER Directorio
Directorio que contiene los archivos .log a procesar (obligatorio)

.PARAMETER Palabras  
Palabras a buscar separadas por comas (obligatorio)

.EXAMPLE
.\ejercicio3.ps1 -Directorio "C:\logs" -Palabras "error,warning,info"

.EXAMPLE
.\ejercicio3.ps1 -d "./logs" -p "USB,Invalid"

.INPUTS
System.String

.OUTPUTS
System.String
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=1)]
    [Alias("d")]
    [ValidateNotNullOrEmpty()]
    [String]$Directorio,
    
    [Parameter(Mandatory=$true, Position=2)]
    [Alias("p")]
    [ValidateNotNullOrEmpty()]
    [String]$Palabras
)

# Función para mostrar ayuda personalizada
function Show-Help {
    Write-Host "Uso: .\ejercicio3.ps1 -Directorio DIRECTORIO -Palabras PALABRAS"
    Write-Host ""
    Write-Host "Procesa archivos de logs en un directorio y devuelve la cantidad de ocurrencias de las palabras indicadas."
    Write-Host ""
    Write-Host "Parámetros:"
    Write-Host "  -Directorio, -d    Directorio que contiene los archivos a procesar (obligatorio)"
    Write-Host "  -Palabras, -p      Palabras a buscar separadas por comas (obligatorio)"
    Write-Host "  -Help              Mostrar esta ayuda"
    exit 0
}

# Función para validar directorio
function Test-DirectoryPath {
    param(
        [Parameter(Mandatory=$true)]
        [String]$Path
    )
    
    try {
        # Convertir a ruta absoluta si es relativa
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            $Path = (Resolve-Path $Path -ErrorAction Stop).Path
        }
        
        if (-not (Test-Path $Path -PathType Container)) {
            Write-Error "Error: El directorio '$Path' no existe"
            return $null
        }
        
        # Verificar permisos de lectura
        try {
            Get-ChildItem $Path -ErrorAction Stop | Out-Null
        } catch {
            Write-Error "Error: No se puede leer el directorio '$Path'"
            return $null
        }
        
        return $Path
    } catch {
        Write-Error "Error: No se pudo resolver la ruta '$Path'"
        return $null
    }
}

# Función para procesar archivos
function Process-LogFiles {
    param(
        [Parameter(Mandatory=$true)]
        [String]$DirectoryPath,
        
        [Parameter(Mandatory=$true)]
        [String]$WordList
    )
    
    try {
        # Obtener archivos .log
        $logFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.log" -File
        
        if ($logFiles.Count -eq 0) {
            Write-Error "Error: No se encontraron archivos .log legibles en el directorio '$DirectoryPath'"
            return $false
        }
        
        # Verificar que al menos uno es legible
        $readableFiles = $logFiles | Where-Object { 
            try { 
                Get-Content $_.FullName -TotalCount 1 -ErrorAction Stop | Out-Null
                return $true 
            } catch { 
                return $false 
            }
        }
        
        if ($readableFiles.Count -eq 0) {
            Write-Error "Error: No se encontraron archivos .log legibles en el directorio '$DirectoryPath'"
            return $false
        }
        
        # Procesar palabras
        $wordsArray = $WordList -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        
        if ($wordsArray.Count -eq 0) {
            Write-Error "Error: No se proporcionaron palabras válidas para buscar"
            return $false
        }
        
        # Inicializar contadores
        $wordCounts = @{}
        foreach ($word in $wordsArray) {
            $wordCounts[$word] = 0
        }
        
        # Procesar cada archivo
        foreach ($file in $readableFiles) {
            try {
                $content = Get-Content $file.FullName -ErrorAction Stop
                
                foreach ($line in $content) {
                    # Limpiar caracteres de retorno de carro
                    $cleanLine = $line -replace "`r", ""
                    $lowerLine = $cleanLine.ToLower()
                    
                    # Buscar cada palabra en la línea
                    foreach ($word in $wordsArray) {
                        $lowerWord = $word.ToLower()
                        $matches = [regex]::Matches($lowerLine, [regex]::Escape($lowerWord))
                        $wordCounts[$word] += $matches.Count
                    }
                }
            } catch {
                Write-Warning "No se pudo procesar el archivo '$($file.FullName)'"
                continue
            }
        }
        
        # Mostrar resultados en el orden original de las palabras
        foreach ($word in $wordsArray) {
            Write-Host "${word}: $($wordCounts[$word])"
        }
        
        return $true
        
    } catch {
        Write-Error "Error: Fallo al procesar los archivos en '$DirectoryPath'"
        return $false
    }
}

# Verificar si se solicita ayuda
if ($PSBoundParameters.ContainsKey('Help') -or $args -contains '-h' -or $args -contains '--help') {
    Show-Help
}

# Función principal
try {
    # Crear archivo temporal
    $tempFile = $null
    
    try {
        $tempFile = New-TemporaryFile
        
        # Validar y limpiar palabras
        $cleanWords = $Palabras -replace '\s*,\s*', ',' -replace '^\s*|\s*$', ''
        if ([string]::IsNullOrEmpty($cleanWords) -or $cleanWords -eq ',') {
            Write-Error "Error: Las palabras especificadas están vacías o son inválidas"
            Write-Error "Use Get-Help .\ejercicio3.ps1 para ver la ayuda"
            exit 1
        }
        
        # Validar y normalizar directorio
        $validatedDirectory = Test-DirectoryPath -Path $Directorio
        if ($null -eq $validatedDirectory) {
            exit 1
        }
        
        # Procesar archivos y mostrar en pantalla
        $success = Process-LogFiles -DirectoryPath $validatedDirectory -WordList $cleanWords
        if (-not $success) {
            Write-Error "Error: Fallo en el procesamiento de archivos"
            exit 1
        }
        
    } catch {
        Write-Error "Error inesperado: $($_.Exception.Message)"
        exit 1
    } finally {
        # Limpiar archivos temporales
        if ($null -ne $tempFile -and (Test-Path $tempFile)) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    Write-Error "Error crítico: $($_.Exception.Message)"
    exit 1
}
