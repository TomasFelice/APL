<#
.SYNOPSIS
    Devuelve informacion basica de un pais.
.DESCRIPTION
    Este script toma un nombre de un pais como parámetro y muestra
    por consola la informacion basica del pais buscado.
.PARAMETER nombre
    El nombre del pais a buscar
.PARAMETER ttl
    El tiempo (en segundos) que perdurara el archivo que almacenara la
    informacion del pais buscado.
    Si se omite la opcion, el valor por defecto es 1 (un segundo).
.EXAMPLE
    .\ejercicio5.ps1 -nombre argentina

    Muestra informacion basica para el pais argentina.
    Se establece la duracion de 1 segundo para el archivo que contendra
    la informacion para el pais Argentina
.EXAMPLE
    .\ejercicio5.ps1 -nombre argentina -ttl 2

    Muesta informacion basica para el pais argentina
    Se establece la duracion de 2 segundos para el archivo que contendra
    la informacion para el pais Argentina
.EXAMPLE
    .\ejercicio5.ps1 -nombre "saudi arabia"

    Muestra informacion basica para el pais saudi arabia
    Se establece la duracion de 1 segundos para el archivo que contendra
    la informacion para el pais buscado.
.EXAMPLE
    .\ejercicio5.ps1 -nombre "saudi arabia", argentina, colombia

    Muestra informacion basica para los paises buscados.
    Se establecera la duracion de 1 segundo para cada archivo que contendra
    la informacion de cada pais ingresado.
.EXAMPLE
    .\ejercicio5.ps1 -nombre sw

    No se procesara aquellos nombres que contengan menos de 4 caracteres.
.NOTES
    Integrantes:
        - Felice, Tomas Agustin
        - Casas, Lautaro Nahuel
        - Coarite Coarite, Ivan Enrique
#>

Param(
    [Parameter(
        Mandatory = $True,
        HelpMessage = "Ingrese el nombre del pais buscado.")]
    [string[]]$nombre,

    [Parameter(Mandatory = $False)]
    [ValidateRange(1, 60)]
    [int]$ttl = 1
)
function Get-PaisWeb {
    param (
        [Parameter()]
        [string]
        $Nombre
    )
    $uriBase = "https://restcountries.com/v3.1/name/$($Nombre)"
    Write-Host "---Buscando informacion desde la web: $Nombre."
    Write-Host "---Realizando peticion: $Nombre."
    try {
        $response = Invoke-WebRequest -Uri "$($uriBase)" -ErrorAction Stop
        $paisEncontrado = ConvertFrom-Json -InputObject $Response.Content
        Write-Host "---Peticion exitosa." -ForegroundColor Green
        return $paisEncontrado
    }
    catch {
        Write-Host "---Error de peticion: $Nombre." -ForegroundColor Yellow
        Write-Host "---Hubo un error al conectar con la api." -ForegroundColor Yellow
        Write-Host "---Mensaje de error: $_" -ForegroundColor Yellow
        return $null
    }
}
function Test-FileExpirado {
    param (
        [Parameter()]
        [string]
        $fileName
    )
    Write-Debug "Validando el estado del archivo: $fileName"
    $SEGUNDOS = 10
    $fileObj = Get-ChildItem -Path "$($dirCache)\$($fileName)"

    $campos = $fileName -split "[_.]"

    [int]$ttlFile = $campos[1]

    #$fechaExp = $fileObj.LastWriteTime.AddDays($ttlFile)
    $fechaExp = $fileObj.LastWriteTime.AddSeconds($ttlFile * $SEGUNDOS)
    $fechaAct = Get-Date
    
    Write-Debug "---Fecha modificacion: $($fileObj.LastWriteTimeString)"
    Write-Debug "---Fecha expiracion: $($fechaExp.ToString())"
    Write-Debug "---Fecha act: $($fechaAct.ToString())"

    return ($fechaExp -lt $fechaAct)
}
function Get-PaisFile() {
    param (
        [Parameter()]
        [string]
        $FileName
    )

    Write-Host "---Buscando informacion desde un archivo local: $FileName."
    $pathFileName = Join-Path -Path $dirCache -ChildPath $FileName

    $paisInfo = $null
    if ( -not (Test-FileExpirado -FileName $FileName) ) {
        Write-Host "---Archivo local disponible: $FileName." -ForegroundColor Green
        Write-Debug "$pathFileName"
        $paisInfo = Get-Content -Path $pathFileName -Raw | ConvertFrom-Json
        return $paisInfo
    }
    
    Write-Host "---Archivo local desactualizado: $FileName." -ForegroundColor Yellow
    #Los caracteres prohibidos en nombres de archivos y directorios
    #en Windows incluyen: \ / : * ? " < > | y caracteres de control.         

    #$fileJsonMv = "$(Get-Date -Format "yyyy-MM-dd")_$($fileName)"
    $fileJsonMv = "$(Get-Date -UFormat "%s")_$($fileName)"
    
    $pathJsonMv = Join-Path -Path $dirPapelera -ChildPath $fileJsonMv

    Write-Debug "---Cambio de directorio para el archivo: $FileName"
    Write-Debug "---Desde: $pathFileName"
    Write-Debug "---A: $pathFileJsonMv"

    Move-Item -Path $pathFileName -Destination $pathJsonMv

    Write-Host "---Solicitar nueva informacion actualizada." -ForegroundColor Yellow
    return $paisInfo
}

# *************** INICIO MAIN BLOCK ***************
#$DebugPreference = "Continue"

$scriptDir = Split-Path -Parent $PSCommandPath
$dirCache = Join-Path -Path $scriptDir -ChildPath "Pais"
$dirPapelera = Join-Path -Path $scriptDir -ChildPath "Papelera"
#$FILE_RESPONSE = Join-Path -Path $dirCache -ChildPath "response.json"

if (-not (Test-Path -Path "$dirCache")) {
    New-Item $dirCache -ItemType Directory
}

if (-not (Test-Path -Path $dirPapelera)) {
    New-Item -Path $dirPapelera -ItemType Directory
}

$listResultPaises = [System.Collections.Generic.List[object]]@()

$paises = $nombre.Where({ $_ -match "^.{4,}" })

foreach ($paisItem in $paises) {
    $filejson = Get-ChildItem -Path $dirCache -Filter "$($paisItem -replace '\s+', '-')_*.json"
    $paisInfo = $null #reset
    $paisInfoWeb = $False #reset

    Write-Host "Procesando busqueda pais: $($paisItem.ToLower())."
    if ( $filejson ) {
        $paisInfo = Get-PaisFile -FileName $filejson.Name
    }
    
    if ( -not $paisInfo ) {
        $apiResults = Get-PaisWeb -Nombre $paisItem.ToLower()
        if ($apiResults) {
            $cantPaises = $apiResults.Length
            if ($cantPaises -gt 10) {
                Write-Host "Por favor, haga su consulta mas especifica."
            }
            elseif ($cantPaises -gt 1 -and $cantPaises -le 10) {
                Write-Host "Adv. Posibles coincidencias para la busqueda - $paisItem." -ForegroundColor Yellow
                $apiResults | ForEach-Object {
                    Write-Host "Nombre: $($_.name.common.ToLower())"
                }
            }
            else {
                $paisInfo = $apiResults
                $paisInfoWeb = $True
            }
        }
        else {
            Write-Host "---Adv. No se encontro informacion disponible $paisItem." -ForegroundColor Yellow
        }
    }

    if ( $paisInfo -or $paisInfoWeb ) {
        Write-Host "Seleccionando informacion basica para mostrar."
        $currencies = $paisInfo.currencies
        $tipoMoneda = $currencies.PSObject.Properties.Name

        $monedaPais = $paisInfo.currencies.$tipoMoneda

        $paisInfoMin = [PSCustomObject]@{
            nombre    = $paisInfo.name.common
            capital   = $($paisInfo.capital)
            region    = $paisInfo.region
            poblacion = $paisInfo.population
            moneda    = "$($monedaPais.name) ($($tipoMoneda))"
        }

        $listResultPaises.Add($paisInfoMin)
    }
    
    if ($paisInfoWeb) {
        Write-Host "Guardando informacion de la web: $paisItem."
        $newFileJson = "$($paisItem.ToLower() -replace '\s+', '-')_$($ttl).json"
        $paisInfo | ConvertTo-Json -Compress -Depth 4 | Out-File -Path "$($dirCache)\$newFileJson"
        Write-Host "Informacion guardada en el archivo: $newFileJson." -ForegroundColor Green
    }
}

#salida formateada
Write-Host "Resultados de la informacion obtenida."
$listResultPaises | ForEach-Object {
    Write-Host "Nombre: $($_.nombre)"
    Write-Host "Capital: $($_.capital)"
    Write-Host "Región: $($_.region)"
    Write-Host "Población: $($_.poblacion)"
    Write-Host "Moneda: $($_.moneda)"
    Write-Host ""
}
# *************** FIN MAIN BLOCK ****************
