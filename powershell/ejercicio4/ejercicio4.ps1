# =================================================
# Integrantes:
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# - Felice, Tomas Agustin
# =================================================

<#
.SYNOPSIS
  Demonio de auditoría Git que escanea cambios y busca patrones en los archivos.

.DESCRIPTION
  Este script monitorea un repositorio Git y detecta patrones (literales o
  expresiones regulares) en los archivos modificados entre commits. Puede
  ejecutarse en modo demonio (detached), iniciarse en foreground para lanzar
  el demonio, o detener un demonio existente.

.PARAMETER Repo
  Ruta al repositorio Git a monitorear (obligatorio).

.PARAMETER Configuracion
  Ruta al archivo de patrones. Cada línea puede ser una palabra literal o
  empezar con "regex:" seguido de la expresión regular.

.PARAMETER Log
  Ruta al archivo donde se registrarán las alertas y mensajes.

.PARAMETER Alerta
  Intervalo en segundos entre comprobaciones (default: 60).

.PARAMETER Kill
  Detiene el demonio asociado al repositorio (solo requiere -Repo).

.PARAMETER Help
  Muestra esta ayuda y termina.

.PARAMETER RunDaemon
  Parámetro interno usado para ejecutar el proceso en modo demonio (no usar
  manualmente salvo que se sepa lo que se hace).

.EXAMPLE
  Get-Help .\ejercicio4.ps1
  Muestra la ayuda breve del script.

.EXAMPLE
  .\ejercicio4.ps1 -Repo 'C:\mi_repo' -Configuracion patrones.conf -Log alerts.log
  Inicia el demonio en segundo plano.

.EXAMPLE
  .\ejercicio4.ps1 -Repo 'C:\mi_repo' -Kill
  Detiene el demonio asociado al repositorio.

.NOTES
  Autor(es): Casas, Lautaro Nahuel; Coarite Coarite, Ivan Enrique; Felice, Tomas Agustin
  Fecha: 2025-10-17
#>


[CmdletBinding()]
param(
  [Alias('r')][string]$Repo,
  [Alias('c')][string]$Configuracion,
  [Alias('l')][string]$Log,
  [Alias('a')][int]$Alerta = 60,
  [Alias('k')][switch]$Kill,
  [Alias('h')][switch]$Help,
  [switch]$RunDaemon
)

function Show-Help {
  @"
Uso:
  .\audit.ps1 -Repo <ruta> -Configuracion <patrones.conf> -Log <alerts.log> [-Alerta <segundos>]
  .\audit.ps1 -Repo <ruta> -Kill   # detiene el demonio asociado al repo

Opciones:
  -Repo / -r           Ruta al repositorio Git a monitorear (obligatorio).
  -Configuracion / -c  Ruta al archivo de patrones (obligatorio al iniciar).
  -Log / -l            Ruta al archivo de logs (obligatorio al iniciar).
  -Alerta / -a         Intervalo de comprobación en segundos (default: 60).
  -Kill / -k           Detiene el demonio (solamente requiere -Repo).
  -Help / -h           Muestra esta ayuda.
Notas:
  - El archivo de patrones admite líneas 'regex:TU_REGEX' o palabras literales.
  - Acepta rutas con espacios.
"@
}

if ($Help) { Show-Help; exit 0 }

function Friendly-Exit([string]$msg, [int]$code = 1) {
  Write-Error "Error: $msg"
  exit $code
}

# Normalizar rutas
function To-AbsolutePath([string]$p) {
  if ([string]::IsNullOrWhiteSpace($p)) { return $p }
  return (Resolve-Path -Path $p -ErrorAction SilentlyContinue).ProviderPath
}

# Logger (append)
function Log-Alert([string]$msg) {
  $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  try {
    "$([string]::Format('[{0}] {1}', $ts, $msg))" | Out-File -FilePath $Global:LOG -Encoding utf8 -Append -ErrorAction Stop
  } catch {
    Write-Error "No se puede escribir en el archivo de log '$Global:LOG'. Compruebe permisos."
  }
}

# Cleanup: borrar pidfile y lastfile
function Cleanup {
  try {
    if (Test-Path $Global:PIDFILE) { Remove-Item -Path $Global:PIDFILE -Force -ErrorAction SilentlyContinue }
    if (Test-Path $Global:LASTFILE) { Remove-Item -Path $Global:LASTFILE -Force -ErrorAction SilentlyContinue }
  } catch {
    # ignoro errores aqui
  }
}

# Leer patrones
function Read-Patterns {
  param([string]$configPath)
  $Global:patterns_literal = @()
  $Global:patterns_regex = @()
  try {
    Get-Content -Raw -LiteralPath $configPath -ErrorAction Stop |
      ForEach-Object {
        $_ -split "`n" | ForEach-Object {
          $line = $_.Trim()
          if ([string]::IsNullOrWhiteSpace($line)) { return }
          if ($line.StartsWith('#')) { return }
          if ($line.StartsWith('regex:')) {
            $r = $line.Substring(6)
            if (-not [string]::IsNullOrWhiteSpace($r)) { $Global:patterns_regex += $r }
          } else {
            $Global:patterns_literal += $line
          }
        }
      }
  } catch {
    throw "No se pudieron leer los patrones de '$configPath'."
  }
}

# Escanear diffs entre commits (oldCommit -> newCommit)
function Scan-Diff {
  param([string]$oldc, [string]$newc)

  # Obtener archivos modificados
  try {
    $files = & git diff --name-only $oldc $newc -- 2>$null
    if (-not $files) { return }
    $files = $files -split "`n" | Where-Object { $_ -ne '' }
  } catch {
    Log-Alert "Error: git diff falló entre $oldc y $newc."
    return
  }

  foreach ($f in $files) {
    $full = Join-Path -Path $Global:REPO -ChildPath $f
    if (-not (Test-Path -Path $full -PathType Leaf)) { continue }
    # Literales
    foreach ($patt in $Global:patterns_literal) {
      try {
        $foundMatches = Select-String -Path $full -Pattern $patt -SimpleMatch -ErrorAction Stop
        foreach ($m in $foundMatches) {
          Log-Alert "Alerta: patrón '$patt' encontrado en el archivo '$f' -> $($m.LineNumber):$($m.Line.Trim())"
        }
      } catch [System.Management.Automation.ItemNotFoundException] {
        # archivo no encontrado, ignorar
      } catch [System.Management.Automation.ParameterBindingException] {
        # error en Select-String por patrón inválido en modo SimpleMatch (raro). Reportar
        Log-Alert "Error al escanear '$f' con patrón literal '$patt'."
      } catch {
        # si Select-String devuelve no matches, lanza código 1: lo manejamos así
        if ($_.Exception -and $_.Exception.InnerException -and $_.Exception.InnerException.HResult -ne 1) {
          Log-Alert "Error al escanear '$f' con patrón literal '$patt'."
        }
      }
    }

    # Regex
    foreach ($rp in $Global:patterns_regex) {
      try {
        $regexMatches = Select-String -Path $full -Pattern $rp -AllMatches -ErrorAction Stop
        foreach ($m in $regexMatches) {
          Log-Alert "Alerta: patrón_regex '$rp' encontrado en el archivo '$f' -> $($m.LineNumber):$($m.Line.Trim())"
        }
      } catch {
        # si Select-String no encuentra coincidencias no lanza excepción; si lanza, lo registramos
        Log-Alert "Error al escanear '$f' con patrón regex '$rp'."
      }
    }
  }
}

# -----------------------
# Inicio del script
# -----------------------
# Validaciones básicas
if (-not $Repo) { Friendly-Exit "Falta parámetro obligatorio -Repo. Usa -Help para ayuda." }
$REPO = To-AbsolutePath $Repo
if (-not $REPO) { Friendly-Exit "Ruta del repositorio inválida: '$Repo'." }

# Nombre único para pid/last (hash de ruta)
$repoHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($REPO))) -Algorithm SHA1).Hash.Substring(0,12)
$tempDir = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
$procIdFILE = Join-Path -Path $tempDir -ChildPath ("git_audit_{0}.pid" -f $repoHash)
$LASTFILE = Join-Path -Path $tempDir -ChildPath ("git_audit_{0}.last" -f $repoHash)
${Global:PIDFILE} = $procIdFILE
${Global:LASTFILE} = $LASTFILE

# Kill mode (solo requiere Repo)
if ($Kill) {
  if (-not (Test-Path $procIdFILE)) { Write-Error "No se encontró un demonio en ejecución para el repositorio '$REPO' (pidfile $procIdFILE)."; exit 1 }
  try {
    $procId = Get-Content -LiteralPath $procIdFILE -ErrorAction Stop
    if ($procId -and (Get-Process -Id $procId -ErrorAction SilentlyContinue)) {
      Write-Output "Deteniendo demonio (PID $procId) para repo: $REPO ..."
      Stop-Process -Id $procId -ErrorAction Stop
      Start-Sleep -Milliseconds 500
    } else {
      Write-Warning "Proceso con PID $procId no existe."
    }
  } catch {
    Write-Warning "No se pudo detener el proceso: $($_.Exception.Message)"
  } finally {
    Cleanup
  }
  Write-Output "Demonio detenido."
  exit 0
}

# Si no estamos lanzando el daemon (inicio): requerir Config y Log
if (-not $RunDaemon) {
  if (-not $Configuracion -or -not $Log) {
    Friendly-Exit "Al iniciar el demonio se requieren -Configuracion y -Log además de -Repo."
  }
  $CONFIG = To-AbsolutePath $Configuracion
  if (-not $CONFIG) { Friendly-Exit "Archivo de configuración inválido: $Configuracion" }

  # Resolver/crear ruta de log: permitir nombres simples como 'salida' y crear si no existe
  if ([string]::IsNullOrWhiteSpace($Log)) { Friendly-Exit "Ruta de log inválida: $Log" }
  try {
    $LOG = [System.IO.Path]::GetFullPath($Log)
  } catch {
    Friendly-Exit "Ruta de log inválida: $Log"
  }
  $logDir = Split-Path -Path $LOG -Parent
  if (-not (Test-Path -Path $logDir)) {
    try { New-Item -ItemType Directory -Path $logDir -Force | Out-Null } catch { Friendly-Exit "No se pudo crear el directorio del log: $logDir" }
  }
  try {
    if (-not (Test-Path -LiteralPath $LOG -PathType Leaf)) { New-Item -ItemType File -Path $LOG -Force | Out-Null }
  } catch {
    Friendly-Exit "No se pudo crear el archivo de log en '$LOG': $($_.Exception.Message)"
  }

  # Evitar doble demonio
  if (Test-Path $procIdFILE) {
    try {
      $existing = Get-Content -LiteralPath $procIdFILE -ErrorAction Stop
      if ($existing -and (Get-Process -Id $existing -ErrorAction SilentlyContinue)) {
        Friendly-Exit "Ya hay un demonio en ejecución para ese repositorio (PID $existing)."
      } else {
        Remove-Item -Path $procIdFILE -ErrorAction SilentlyContinue
        Remove-Item -Path $LASTFILE -ErrorAction SilentlyContinue
      }
    } catch {
      # ignorar
    }
  }

  # Lanzar proceso hijo (detached)
  $scriptPath = $MyInvocation.MyCommand.Path
  $childArgs = @("-NoProfile","-ExecutionPolicy","Bypass","-File",$scriptPath,"-RunDaemon","-Repo",$REPO,"-Configuracion",$CONFIG,"-Log",$LOG,"-Alerta",$Alerta)
  try {
    $proc = Start-Process -FilePath (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source -ArgumentList $childArgs -WindowStyle Hidden -PassThru -ErrorAction Stop
    if (-not $proc) {
      # Fallback a powershell.exe
      $proc = Start-Process -FilePath (Get-Command powershell -ErrorAction SilentlyContinue).Source -ArgumentList $childArgs -WindowStyle Hidden -PassThru -ErrorAction Stop
    }
    # Guardar pid del hijo
    $proc.Id | Out-File -FilePath $procIdFILE -Encoding ascii -Force
    Write-Output "Demonio iniciado (PID $($proc.Id)). Log: $LOG"
    exit 0
  } catch {
    Friendly-Exit "No se pudo iniciar el proceso demonio: $($_.Exception.Message)"
  }
}

# -------------------------
# Aquí corre el proceso demonio (RunDaemon)
# -------------------------
# REPO, CONFIG, LOG deben haber sido pasados por el padre
$CONFIG = To-AbsolutePath $Configuracion
$LOG = To-AbsolutePath $Log
$Global:REPO = $REPO
$Global:LOG = $LOG

# Registrar cleanup en caso de salida normal (no garantiza si kill -9)
$script:OnExit = {
  Cleanup
}
# No hay garantía de captura completa de señales en PowerShell; el finally/catch ayuda.

# Validar paths y permisos
if (-not (Test-Path -Path $REPO -PathType Container)) { Friendly-Exit "El directorio del repositorio no existe: '$REPO'." }
if (-not (Test-Path -Path $CONFIG -PathType Leaf)) { Friendly-Exit "El archivo de configuracion no existe: '$CONFIG'." }

# Asegurar directorio del log
$logDir = Split-Path -Path $LOG -Parent
if (-not (Test-Path -Path $logDir)) {
  try { New-Item -ItemType Directory -Path $logDir -Force | Out-Null } catch { Friendly-Exit "No se pudo crear el directorio del log: $logDir" }
}

# Comprobar repo git
Push-Location $REPO
try {
  & git rev-parse --git-dir 2>$null
  if ($LASTEXITCODE -ne 0) { Pop-Location; Friendly-Exit "'$REPO' no parece ser un repositorio Git." }
} catch {
  Pop-Location
  Friendly-Exit "'$REPO' no parece ser un repositorio Git."
}

# Usar rama local HEAD
try {
  $current_local_branch = (& git rev-parse --abbrev-ref HEAD).Trim()
  if (-not $current_local_branch) { $current_local_branch = "HEAD" }
  $UPSTREAM = $current_local_branch
  Log-Alert "Info: usando rama local para monitoreo: '$UPSTREAM'"
} catch {
  Pop-Location
  Friendly-Exit "No se pudo determinar la rama local (HEAD)."
}

# Leer patrones
try {
  Read-Patterns -configPath $CONFIG
} catch {
  Pop-Location
  Friendly-Exit $_
}

# Inicializar last commit
try {
  $current_commit = (& git rev-parse --verify $UPSTREAM).Trim()
  if (-not $current_commit) { Pop-Location; Friendly-Exit "No se pudo obtener commit de '$UPSTREAM'." }
} catch {
  Pop-Location
  Friendly-Exit "No se pudo obtener commit de '$UPSTREAM'."
}

if (-not (Test-Path -Path $LASTFILE)) {
  $current_commit | Out-File -FilePath $LASTFILE -Encoding ascii -Force
}
$last_commit = (Get-Content -Raw -LiteralPath $LASTFILE).Trim()

# Guardar pidfile del proceso actual
try { $PID | Out-File -FilePath $procIdFILE -Encoding ascii -Force } catch { Write-Warning "No se pudo escribir pidfile $procIdFILE" }

# Bucle principal
try {
  while ($true) {
    Start-Sleep -Seconds $Alerta

    # recargar patrones si cambió el archivo
    if (Test-Path -Path $CONFIG) {
      try { Read-Patterns -configPath $CONFIG } catch { Log-Alert "Advertencia: no se pudieron recargar patrones: $_"; }
    }

    # obtener commit actual de la rama local
    try {
      $new_commit = (& git rev-parse --verify $UPSTREAM).Trim()
      if (-not $new_commit) { Log-Alert "Error: no se pudo obtener commit actual de $UPSTREAM."; continue }
    } catch {
      Log-Alert "Error: no se pudo obtener commit actual de $UPSTREAM."
      continue
    }

    if ($new_commit -ne $last_commit) {
      if ([string]::IsNullOrWhiteSpace($last_commit)) {
        $last_commit = $new_commit
        $last_commit | Out-File -FilePath $LASTFILE -Encoding ascii -Force
        continue
      }

      # escanear diffs
      Scan-Diff -oldc $last_commit -newc $new_commit

      # actualizar last
      $new_commit | Out-File -FilePath $LASTFILE -Encoding ascii -Force
      $last_commit = $new_commit
    }
  }
}
finally {
  # cleanup siempre que el script termine limpiamente
  Pop-Location
  Cleanup
}
