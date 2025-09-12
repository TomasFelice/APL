<#
.SYNOPSIS
    Procesa archivos de datos en un directorio y genera un reporte en formato JSON.

.DESCRIPTION
    Este script procesa archivos .txt que contienen datos de canales de comunicación,
    calcula promedios de tiempo de respuesta y notas de satisfacción por fecha y canal,
    y genera un reporte en formato JSON.

.PARAMETER Directorio
    Directorio que contiene los archivos a procesar. Es obligatorio. 
    Acepta tanto rutas relativas como absolutas.

.PARAMETER Archivo
    Archivo de salida donde guardar el resultado. Es mutuamente excluyente con -Pantalla.

.PARAMETER Pantalla
    Muestra el resultado en pantalla. Es mutuamente excluyente con -Archivo.

.EXAMPLE
    .\ejercicio1.ps1 -Directorio "datos" -Archivo "resultado.json"
    Procesa archivos del directorio "datos" y guarda el resultado en "resultado.json"

.EXAMPLE
    .\ejercicio1.ps1 -Directorio "C:\datos" -Pantalla
    Procesa archivos del directorio "C:\datos" y muestra el resultado en pantalla

.INPUTS
    Archivos .txt con formato: campo1|fecha_hora|canal|tiempo|nota|campo6

.OUTPUTS
    JSON con estructura jerárquica por fecha y canal con promedios calculados

.NOTES
    Integrantes:
    - Felice, Tomas Agustin
    - Casas, Lautaro Nahuel
    - Coarite Coarite, Ivan Enrique
#>

[CmdletBinding(DefaultParameterSetName="ArchivoSet")]
param(
    [Parameter(Position=0)]
    [Alias("d")]
    [string]$Directorio,
    
    [Parameter(Mandatory=$true, ParameterSetName="ArchivoSet")]
    [ValidateNotNullOrEmpty()]
    [Alias("a")]
    [string]$Archivo,
    
    [Parameter(Mandatory=$true, ParameterSetName="PantallaSet")]
    [Alias("p")]
    [switch]$Pantalla
)

# Función para validar y normalizar directorio
function Test-InputDirectory {
    <#
    .SYNOPSIS
        Valida y normaliza la ruta del directorio de entrada.
    
    .DESCRIPTION
        Convierte rutas relativas a absolutas, verifica existencia y permisos del directorio.
    
    .PARAMETER Path
        Ruta del directorio a validar
    
    .OUTPUTS
        String con la ruta absoluta del directorio o $null en caso de error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    try {
        # Convertir a ruta absoluta si es relativa
        $ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        $AbsolutePath = $ResolvedPath.Path
        
        # Verificar que es un directorio
        if (-not (Test-Path -Path $AbsolutePath -PathType Container)) {
            Write-Error "Error: La ruta '$AbsolutePath' no es un directorio válido"
            return $null
        }
        
        # Verificar permisos de lectura
        try {
            Get-ChildItem -Path $AbsolutePath -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "Error: No se pueden leer los contenidos del directorio '$AbsolutePath'"
            return $null
        }
        
        return $AbsolutePath
    }
    catch {
        Write-Error "Error: No se pudo resolver la ruta '$Path' - $($_.Exception.Message)"
        return $null
    }
}

# Función para procesar archivos de datos
function Invoke-DataProcessing {
    <#
    .SYNOPSIS
        Procesa archivos .txt del directorio y genera datos agregados por fecha y canal.
    
    .DESCRIPTION
        Lee todos los archivos .txt del directorio especificado, extrae datos de cada línea,
        calcula promedios de tiempo de respuesta y notas de satisfacción agrupados por fecha y canal.
        Utiliza la estructura Begin/Process/End para mejor manejo de pipeline y separación de responsabilidades.
    
    .PARAMETER DirectoryPath
        Ruta absoluta del directorio que contiene los archivos a procesar.
        Acepta valores desde pipeline.
    
    .OUTPUTS
        String con el JSON resultante o $null en caso de error
    
    .EXAMPLE
        Invoke-DataProcessing -DirectoryPath "/path/to/data"
        
    .EXAMPLE
        "/path/to/data1", "/path/to/data2" | Invoke-DataProcessing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$DirectoryPath
    )
    
    Begin {
        # Validaciones adicionales explícitas
        if ([string]::IsNullOrWhiteSpace($Directorio)) {
            Write-Error "Error: El parámetro -Directorio es obligatorio y no puede estar vacío." -ErrorAction Stop
            exit 1
        }
        
        # Inicialización: se ejecuta una sola vez al inicio
        Write-Verbose "Iniciando procesamiento de datos..."
        
        # Estructuras globales para acumular datos de todos los directorios
        $script:conteos = @{}
        $script:sumaTiempo = @{}
        $script:sumaNota = @{}
        $script:fechas = @{}
        $script:directoriosProcesados = 0
        $script:archivosProcesados = 0
        $script:erroresEncontrados = @()
    }
    
    Process {
        # Se ejecuta una vez por cada DirectoryPath que llega por pipeline
        Write-Verbose "Procesando directorio: $DirectoryPath"
        
        try {
            # Buscar archivos .txt en el directorio actual
            $txtFiles = Get-ChildItem -Path $DirectoryPath -Filter "*.txt" -File -ErrorAction Stop
            
            if ($txtFiles.Count -eq 0) {
                $errorMsg = "No se encontraron archivos .txt en el directorio '$DirectoryPath'"
                Write-Warning $errorMsg
                $script:erroresEncontrados += $errorMsg
                return  # Continue con el siguiente directorio si viene por pipeline
            }
            
            Write-Verbose "Encontrados $($txtFiles.Count) archivos .txt en $DirectoryPath"
            
            # Procesar cada archivo del directorio actual
            foreach ($file in $txtFiles) {
                try {
                    Write-Verbose "Procesando archivo: $($file.FullName)"
                    $content = Get-Content -Path $file.FullName -ErrorAction Stop
                    
                    foreach ($line in $content) {
                        # Validar línea no vacía
                        if ([string]::IsNullOrWhiteSpace($line)) {
                            continue
                        }
                        
                        # Limpiar caracteres de control
                        $line = $line -replace '\r', ''
                        
                        # Dividir por pipe y validar formato
                        $fields = $line -split '\|'
                        
                        if ($fields.Count -ge 5) {
                            try {
                                # Extraer campos con validación
                                $fechaCompleta = $fields[1].Trim()
                                if ($fechaCompleta.Length -lt 10) {
                                    continue  # Saltar líneas con fecha incompleta
                                }
                                
                                $fecha = $fechaCompleta.Substring(0, 10)
                                $canal = $fields[2].Trim()
                                $tiempo = [double]::Parse($fields[3].Trim())
                                $nota = [double]::Parse($fields[4].Trim())
                                
                                $clave = "$fecha|$canal"
                                
                                # Acumular datos en las estructuras globales
                                if (-not $script:conteos.ContainsKey($clave)) {
                                    $script:conteos[$clave] = 0
                                    $script:sumaTiempo[$clave] = 0.0
                                    $script:sumaNota[$clave] = 0.0
                                }
                                
                                $script:conteos[$clave]++
                                $script:sumaTiempo[$clave] += $tiempo
                                $script:sumaNota[$clave] += $nota
                                $script:fechas[$fecha] = $true
                            }
                            catch {
                                # Silenciosamente saltar líneas con datos inválidos
                                continue
                            }
                        }
                    }
                    
                    $script:archivosProcesados++
                }
                catch {
                    $errorMsg = "Error al procesar el archivo: $($file.FullName) - $($_.Exception.Message)"
                    Write-Warning $errorMsg
                    $script:erroresEncontrados += $errorMsg
                    continue
                }
            }
            
            $script:directoriosProcesados++
        }
        catch {
            $errorMsg = "Error al acceder al directorio '$DirectoryPath' - $($_.Exception.Message)"
            Write-Warning $errorMsg
            $script:erroresEncontrados += $errorMsg
        }
    }
    
    End {
        # Finalización: se ejecuta una sola vez al final
        Write-Verbose "Finalizando procesamiento..."
        Write-Verbose "Directorios procesados: $script:directoriosProcesados"
        Write-Verbose "Archivos procesados: $script:archivosProcesados"
        
        if ($script:erroresEncontrados.Count -gt 0) {
            Write-Warning "Se encontraron $($script:erroresEncontrados.Count) errores durante el procesamiento"
        }
        
        # Verificar que se procesaron datos
        if ($script:fechas.Count -eq 0) {
            Write-Error "Error: No se procesaron datos válidos de ningún directorio"
            return $null
        }
        
        try {
            # Construir JSON con fechas ordenadas
            Write-Verbose "Construyendo JSON con $($script:fechas.Count) fechas únicas..."
            $fechasOrdenadas = $script:fechas.Keys | Sort-Object
            $jsonObject = [ordered]@{}
            
            foreach ($fecha in $fechasOrdenadas) {
                $jsonObject[$fecha] = [ordered]@{}
                
                # Encontrar claves para esta fecha y ordenar canales
                $clavesParaFecha = $script:conteos.Keys | Where-Object { $_ -like "$fecha|*" }
                $canalesOrdenados = @()
                
                foreach ($clave in $clavesParaFecha) {
                    $canal = $clave.Split('|')[1]
                    $canalesOrdenados += $canal
                }
                
                $canalesOrdenados = $canalesOrdenados | Sort-Object | Select-Object -Unique
                
                foreach ($canal in $canalesOrdenados) {
                    $clave = "$fecha|$canal"
                    $count = $script:conteos[$clave]
                    
                    $jsonObject[$fecha][$canal] = [ordered]@{
                        "tiempo_respuesta_promedio" = [math]::Round($script:sumaTiempo[$clave] / $count, 2)
                        "nota_satisfaccion_promedio" = [math]::Round($script:sumaNota[$clave] / $count, 2)
                    }
                }
            }
            
            # Convertir a JSON y retornar
            Write-Verbose "JSON construido exitosamente"
            return $jsonObject | ConvertTo-Json -Depth 4
        }
        catch {
            Write-Error "Error inesperado durante la construcción del JSON: $($_.Exception.Message)"
            return $null
        }
    }
}

# Función para escribir el resultado final
function Write-ResultOutput {
    <#
    .SYNOPSIS
        Escribe el resultado en archivo o pantalla según los parámetros especificados.
    
    .DESCRIPTION
        Toma el resultado del procesamiento y lo envía al destino apropiado
        basado en los parámetros del script.
    
    .PARAMETER ResultData
        Datos JSON a escribir
    
    .PARAMETER OutputFile
        Archivo de salida (opcional)
    
    .PARAMETER ToScreen
        Si se debe mostrar en pantalla
    
    .PARAMETER TempFilePath
        Ruta del archivo temporal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResultData,
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$false)]
        [switch]$ToScreen,
        
        [Parameter(Mandatory=$true)]
        [string]$TempFilePath
    )
    
    try {
        # Guardar en archivo temporal primero
        $ResultData | Out-File -FilePath $TempFilePath -Encoding UTF8 -ErrorAction Stop
        
        if ($ToScreen) {
            # Mostrar en pantalla
            Get-Content -Path $TempFilePath
        }
        else {
            # Copiar a archivo de destino
            try {
                Copy-Item -Path $TempFilePath -Destination $OutputFile -Force -ErrorAction Stop
                Write-Output "Resultado guardado exitosamente en: $OutputFile"
            }
            catch {
                Write-Error "Error: No se pudo escribir en el archivo '$OutputFile' - $($_.Exception.Message)"
                throw
            }
        }
    }
    catch {
        Write-Error "Error al escribir el resultado: $($_.Exception.Message)"
        throw
    }
}

# Variables para manejo de archivos temporales
$TempFile = $null

try {
    # Crear archivo temporal en /tmp
    $TempFile = [System.IO.Path]::Combine("/tmp", "powershell_ejercicio1_$(Get-Random).json")
    
    # Validar y normalizar directorio
    $ValidatedDirectory = Test-InputDirectory -Path $Directorio
    if (-not $ValidatedDirectory) {
        throw "Directorio inválido"
    }
    
    # Procesar archivos
    $resultado = Invoke-DataProcessing -DirectoryPath $ValidatedDirectory
    if (-not $resultado) {
        throw "Falló el procesamiento de archivos"
    }
    
    # Escribir resultado
    if ($Pantalla) {
        Write-ResultOutput -ResultData $resultado -ToScreen -TempFilePath $TempFile
    }
    else {
        Write-ResultOutput -ResultData $resultado -OutputFile $Archivo -TempFilePath $TempFile
    }
    
    # Éxito
    exit 0
}
catch {
    Write-Error "Error durante la ejecución: $($_.Exception.Message)"
    exit 1
}
finally {
    # Limpieza: eliminar archivo temporal
    if ($TempFile -and (Test-Path $TempFile)) {
        try {
            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Silenciosamente ignorar errores de limpieza
        }
    }
}
