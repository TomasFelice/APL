# =================================================
# Integrantes:
# - Felice, Tomas Agustin
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# =================================================

param(
    [Parameter(Mandatory=$false)]
    [Alias("d")]
    [string]$Directorio,
    
    [Parameter(Mandatory=$false)]
    [Alias("a")]
    [string]$Archivo,
    
    [Parameter(Mandatory=$false)]
    [Alias("p")]
    [switch]$Pantalla,
    
    [Parameter(Mandatory=$false)]
    [Alias("h")]
    [switch]$Help
)

# Función para mostrar ayuda
function Show-Help {
    Write-Host "Uso: .\ejercicio1.ps1 -Directorio DIRECTORIO [-Archivo ARCHIVO_SALIDA | -Pantalla]"
    Write-Host ""
    Write-Host "Procesa archivos de datos en un directorio y genera un reporte en formato JSON."
    Write-Host ""
    Write-Host "Parámetros:"
    Write-Host "  -Directorio, -d DIRECTORIO     Directorio que contiene los archivos a procesar (obligatorio)"
    Write-Host "  -Archivo, -a ARCHIVO           Archivo de salida donde guardar el resultado"
    Write-Host "  -Pantalla, -p                  Mostrar el resultado en pantalla"
    Write-Host "  -Help, -h                      Mostrar esta ayuda"
    Write-Host ""
    Write-Host "Nota: Debe especificar -Archivo o -Pantalla, pero no ambos."
    exit 0
}

# Función para validar directorio
function Test-InputDirectory {
    param([string]$Path)
    
    # Convertir a ruta absoluta si es relativa
    try {
        $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        $AbsolutePath = $ResolvedPath.Path
    }
    catch {
        Write-Error "Error: No se pudo resolver la ruta '$Path'"
        return $null
    }
    
    if (-not (Test-Path -Path $AbsolutePath -PathType Container)) {
        Write-Error "Error: El directorio '$AbsolutePath' no existe"
        return $null
    }
    
    # Verificar permisos de lectura
    try {
        Get-ChildItem -Path $AbsolutePath -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Error: No se puede leer el directorio '$AbsolutePath'"
        return $null
    }
    
    return $AbsolutePath
}

# Función para procesar archivos
function Process-Files {
    param([string]$DirectoryPath)
    
    # Verificar que hay archivos .txt y que son legibles
    $txtFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.txt" -File -ErrorAction SilentlyContinue
    
    if ($txtFiles.Count -eq 0) {
        Write-Error "Error: No se encontraron archivos .txt legibles en el directorio '$DirectoryPath'"
        return $null
    }
    
    # Estructuras para almacenar datos
    $conteos = @{}
    $sumaTiempo = @{}
    $sumaNota = @{}
    $fechas = @{}
    
    # Procesar cada archivo
    foreach ($file in $txtFiles) {
        try {
            $content = Get-Content -Path $file.FullName -ErrorAction Stop
            
            foreach ($line in $content) {
                # Limpiar caracteres de retorno de carro
                $line = $line -replace '\r', ''
                
                # Dividir por pipe
                $fields = $line -split '\|'
                
                if ($fields.Count -ge 5) {
                    # Extraer fecha (yyy-mm-dd)
                    $fecha = $fields[1].Substring(0, 10)
                    $canal = $fields[2]
                    $tiempo = [double]$fields[3]
                    $nota = [double]$fields[4]
                    
                    $clave = "$fecha|$canal"
                    
                    # Acumular datos
                    if (-not $conteos.ContainsKey($clave)) {
                        $conteos[$clave] = 0
                        $sumaTiempo[$clave] = 0
                        $sumaNota[$clave] = 0
                    }
                    
                    $conteos[$clave]++
                    $sumaTiempo[$clave] += $tiempo
                    $sumaNota[$clave] += $nota
                    $fechas[$fecha] = $true
                }
            }
        }
        catch {
            Write-Error "Error al procesar el archivo: $($file.FullName)"
            return $null
        }
    }
    
    # Verificar que se procesaron datos
    if ($fechas.Count -eq 0) {
        Write-Error "Error: No se procesaron datos válidos"
        return $null
    }
    
    # Ordenar fechas y construir JSON
    $fechasOrdenadas = $fechas.Keys | Sort-Object
    
    $jsonObject = [ordered]@{}
    
    foreach ($fecha in $fechasOrdenadas) {
        $jsonObject[$fecha] = [ordered]@{}
        
        # Buscar todas las claves que corresponden a esta fecha
        $clavesParaFecha = $conteos.Keys | Where-Object { $_ -like "$fecha|*" }
        
        foreach ($clave in $clavesParaFecha) {
            $canal = $clave.Split('|')[1]
            $count = $conteos[$clave]
            
            $jsonObject[$fecha][$canal] = [ordered]@{
                "tiempo_respuesta_promedio" = [math]::Round($sumaTiempo[$clave] / $count, 2)
                "nota_satisfaccion_promedio" = [math]::Round($sumaNota[$clave] / $count, 2)
            }
        }
    }
    
    # Convertir a JSON
    return $jsonObject | ConvertTo-Json -Depth 4
}

# Archivo temporal para resultados
$TempFile = [System.IO.Path]::GetTempFileName()

# Registro para limpieza (equivalente a trap)
$cleanup = {
    if (Test-Path $TempFile) {
        Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
    }
}

# Registrar evento de salida
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $cleanup | Out-Null

try {
    # Manejo de parámetros y validación
    if ($Help) {
        Show-Help
    }
    
    if (-not $Directorio) {
        Write-Error "Error: Debe indicar un directorio con -Directorio"
        Write-Host "Use -Help para ver la ayuda"
        exit 1
    }
    
    if (-not $Archivo -and -not $Pantalla) {
        Write-Error "Error: Debe indicar un archivo de salida con -Archivo o la opcion -Pantalla para mostrar en pantalla"
        Write-Host "Use -Help para ver la ayuda"
        exit 1
    }
    
    if ($Archivo -and $Pantalla) {
        Write-Error "Error: La opcion -Pantalla no puede ser utilizada con un archivo de salida. Debe indicar un archivo de salida sin el parametro -Pantalla, o utilizar -Pantalla sin un archivo de salida."
        Write-Host "Use -Help para ver la ayuda"
        exit 1
    }
    
    # Validar y normalizar directorio
    $ValidatedDirectory = Test-InputDirectory -Path $Directorio
    if (-not $ValidatedDirectory) {
        exit 1
    }
    
    # Procesar archivos y guardar en archivo temporal
    $resultado = Process-Files -DirectoryPath $ValidatedDirectory
    if (-not $resultado) {
        Write-Error "Error: Fallo en el procesamiento de archivos"
        exit 1
    }
    
    # Guardar resultado en archivo temporal
    $resultado | Out-File -FilePath $TempFile -Encoding UTF8 -ErrorAction Stop
    
    # Mostrar resultado
    if ($Pantalla) {
        Get-Content -Path $TempFile
    }
    else {
        try {
            Copy-Item -Path $TempFile -Destination $Archivo -Force -ErrorAction Stop
            Write-Host "Resultado guardado en: $Archivo"
        }
        catch {
            Write-Error "Error: No se pudo escribir en el archivo '$Archivo'"
            exit 1
        }
    }
    
    # Si llegamos aquí, todo fue exitoso
    exit 0
}
finally {
    # Ejecutar limpieza manual también
    & $cleanup
}
