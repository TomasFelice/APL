<#
.SYNOPSIS
  Analiza una matriz de adyacencia (tiempos) para detectar hub o caminos mínimos (Dijkstra).
.PARAMETER Matriz
  Ruta al archivo de la matriz (obligatorio).
.PARAMETER Hub
  Indica modo hub (mutuamente excluyente con Camino).
.PARAMETER Camino
  Indica modo camino (mutuamente excluyente con Hub).
.PARAMETER Separador
  Separador de columnas (por defecto '|').
#>

param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Matriz,

  [switch]$Hub,

  [switch]$Camino,

  [string]$Separador = "|"
)

# --- Validaciones de parámetros ---
if (($Hub -and $Camino) -or (-not $Hub -and -not $Camino)) {
  Write-Error "Debe especificar exactamente una de las opciones: -Hub o -Camino."
  exit 1
}

if (-not (Test-Path -Path $Matriz -PathType Leaf)) {
  Write-Error "Archivo no encontrado: $Matriz"
  exit 2
}

$basedir = Split-Path -Parent $Matriz
$leaf = Split-Path -Leaf $Matriz
$outfile = Join-Path $basedir ("informe.$leaf")

# Constantes
$eps = 1e-9
$INF = [double]::PositiveInfinity

# Leer y normalizar líneas útiles
$pattern = [regex]::Escape($Separador)
$lines = Get-Content -LiteralPath $Matriz
$lines = $lines | Where-Object { $_.Trim().Length -gt 0 }   # eliminar líneas vacías

$n = $lines.Count
if ($n -eq 0) {
  Write-Error "Archivo vacío."
  exit 3
}

# Construir matriz (jagged) y validar número de columnas por fila
$mat = @()   # array de filas; cada fila será un double[]
for ($i = 0; $i -lt $n; $i++) {
  $rawRow = $lines[$i]
  $parts = $rawRow -split $pattern
  # trim de cada campo
  for ($j = 0; $j -lt $parts.Count; $j++) { $parts[$j] = $parts[$j].Trim() }

  if ($parts.Count -ne $n) {
    Write-Error ("Matriz no cuadrada: fila {0} tiene {1} columnas (esperaba {2})." -f ($i+1), $parts.Count, $n)
    exit 4
  }

  # convertir a double[] con tratamiento de cadenas vacías como 0
  $drow = New-Object 'double[]' $n
  for ($j = 0; $j -lt $n; $j++) {
    $s = $parts[$j]
    if ($s -eq "") { $s = "0" }
    $num = $s -as [double]
    if ($null -eq $num) {
      Write-Error ("Valor no numérico en fila {0} columna {1}: '{2}'" -f ($i+1), ($j+1), $s)
      exit 5
    }
    $drow[$j] = [double]$num
  }
  $mat += ,$drow
}

# Validar que la matriz fue poblada correctamente
if ($null -eq $mat -or $mat.Count -eq 0) {
  Write-Error "Error: la matriz no fue cargada correctamente."
  exit 6
}
# Validación de simetría, diagonal y no-negatividad
for ($i = 0; $i -lt $n; $i++) {
  if ($null -eq $mat[$i]) { Write-Error ("Fila {0} nula." -f ($i+1)); exit 7 }
  if ($mat[$i].Length -ne $n) { Write-Error ("Fila {0} con longitud inconsistente." -f ($i+1)); exit 8 }
  for ($j = 0; $j -lt $n; $j++) {
    $a = $mat[$i][$j]
    $b = $mat[$j][$i]
    if ($i -eq $j) {
      if ([math]::Abs($a) -gt $eps) {
        Write-Error ("Diagonal ({0},{1}) debe ser 0, es {2}" -f ($i+1), ($j+1), $a)
        exit 9
      }
    }
    if ([math]::Abs($a - $b) -gt $eps) {
      Write-Error ("Matriz no simétrica en ({0},{1}): {2} != {3}" -f ($i+1), ($j+1), $a, $b)
      exit 10
    }
    if ($a -lt -$eps) {
      Write-Error ("Peso negativo detectado en ({0},{1}): {2}" -f ($i+1), ($j+1), $a)
      exit 11
    }
  }
}

# Helper: formatear tiempo como en la versión anterior
function Format-Time {
  param([double]$x)
  if ($x -eq [double]::PositiveInfinity) { return "INF" }
  $s = "{0:F6}" -f $x
  $s = $s.TrimEnd('0')
  if ($s.EndsWith('.')) { $s = $s.TrimEnd('.') }
  if ($s -eq "") { $s = "0" }
  return $s
}

# --- MODO HUB ---
if ($Hub) {
  $rows = $mat.Count
  $degrees = New-Object 'int[]' $rows
  $maxdeg = -1

  for ($i = 0; $i -lt $rows; $i++) {
    $deg = 0
    $row = $mat[$i]
    for ($j = 0; $j -lt $rows; $j++) {
      if ($i -ne $j -and $row[$j] -gt $eps) { $deg++ }
    }
    $degrees[$i] = $deg
    if ($deg -gt $maxdeg) { $maxdeg = $deg }
  }

  $hubs = New-Object System.Collections.ArrayList
  for ($i = 0; $i -lt $rows; $i++) {
    if ($degrees[$i] -eq $maxdeg) { $hubs.Add($i+1) | Out-Null }
  }

  $outLines = New-Object System.Collections.ArrayList
  $outLines.Add("ANALISIS: Detectando hub(s) en la red") | Out-Null
  $outLines.Add(("Estaciones totales: {0}" -f $rows)) | Out-Null
  $outLines.Add("") | Out-Null
  $outLines.Add("Grado (cantidad de conexiones) por estación:") | Out-Null
  for ($i = 0; $i -lt $rows; $i++) {
    $outLines.Add(("  Estación {0}: {1}" -f ($i+1), $degrees[$i])) | Out-Null
  }
  $outLines.Add("") | Out-Null
  $outLines.Add(("Hub(s) (grado máximo = {0}): {1}" -f $maxdeg, ($hubs -join ", "))) | Out-Null

  $outLines | Out-File -FilePath $outfile -Encoding UTF8
  Write-Output ("Informe generado: {0}" -f $outfile)
  exit 0
}

# --- MODO CAMINO: Dijkstra all-pairs con predecesores múltiples ---
# Distancias y predecesores guardados por origen (1-based keys como strings)
$distSaved = @{}
$predSaved = @{}

for ($s = 0; $s -lt $n; $s++) {
  # inicializar dist y visited
  $dist = New-Object 'double[]' $n
  for ($i = 0; $i -lt $n; $i++) { $dist[$i] = [double]::PositiveInfinity }
  $visited = New-Object 'bool[]' $n
  $pred = @{}  # hashtable: key=int (0-based), value = ArrayList de predecesores (0-based)

  $dist[$s] = 0.0

  while ($true) {
    $u = -1
    $mind = [double]::PositiveInfinity
    for ($i = 0; $i -lt $n; $i++) {
      if (-not $visited[$i] -and $dist[$i] -lt $mind) {
        $mind = $dist[$i]; $u = $i
      }
    }
    if ($u -eq -1) { break }

    $visited[$u] = $true

    for ($v = 0; $v -lt $n; $v++) {
      $w = $mat[$u][$v]
      if ($v -ne $u -and $w -gt $eps) {
        $newd = $dist[$u] + $w
        if ($newd + $eps -lt $dist[$v]) {
          $dist[$v] = $newd
          $alist = New-Object System.Collections.ArrayList
          $alist.Add($u) | Out-Null
          $pred[$v] = $alist
        } elseif ([math]::Abs($newd - $dist[$v]) -le $eps) {
          if (-not $pred.ContainsKey($v)) { $pred[$v] = New-Object System.Collections.ArrayList }
          if (-not ($pred[$v] -contains $u)) { $pred[$v].Add($u) | Out-Null }
        }
      }
    }
  } # fin Dijkstra para s

  # Guardar dist y pred para este s (usar claves 1-based como strings)
  $sKey = ($s + 1).ToString()
  $distSaved[$sKey] = @{}
  $predSaved[$sKey] = @{}
  for ($t = 0; $t -lt $n; $t++) {
    $tKey = ($t + 1).ToString()
    $distSaved[$sKey][$tKey] = $dist[$t]
    if ($pred.ContainsKey($t)) {
      $arr = New-Object System.Collections.ArrayList
      foreach ($p in $pred[$t]) { $arr.Add($p + 1) | Out-Null }  # guardar 1-based
      $predSaved[$sKey][$tKey] = $arr
    } else {
      $predSaved[$sKey][$tKey] = $null
    }
  }
}

# Calcular minimo global entre todos los pares s != t (si es finito)
$globalMin = [double]::PositiveInfinity
foreach ($sKey in $distSaved.Keys) {
  foreach ($tKey in $distSaved[$sKey].Keys) {
    if ($sKey -ne $tKey) {
      $d = [double]$distSaved[$sKey][$tKey]
      if ($d -lt $globalMin) { $globalMin = $d }
    }
  }
}

if ($globalMin -eq [double]::PositiveInfinity) {
  "No hay caminos entre estaciones (o todas son inalcanzables)." | Out-File -FilePath $outfile -Encoding UTF8
  Write-Output ("Informe generado: {0}" -f $outfile)
  exit 0
}

# Función para reconstruir todas las rutas (usa predSaved[sKey][tKey] = ArrayList 1-based)
function Get-AllPaths {
  param(
    [int]$s,
    [int]$t,
    [hashtable]$predForSource
  )
  $results = New-Object System.Collections.ArrayList

  function _dfs {
    param([int]$current, [System.Collections.ArrayList]$stack)
    if ($current -eq $s) {
      $path = New-Object System.Collections.ArrayList
      $path.Add($s) | Out-Null
      for ($ii = $stack.Count - 1; $ii -ge 0; $ii--) { $path.Add($stack[$ii]) | Out-Null }
      $results.Add($path) | Out-Null
      return
    }
    if (-not $predForSource.ContainsKey($current.ToString())) { return }
    $preds = $predForSource[$current.ToString()]
    if ($null -eq $preds) { return }
    foreach ($p in $preds) {
      $stack.Add($current) | Out-Null
      _dfs -current $p -stack $stack
      $stack.RemoveAt($stack.Count - 1) | Out-Null
    }
  }

  $stack0 = New-Object System.Collections.ArrayList
  _dfs -current $t -stack $stack0
  return ,$results
}

# Imprimir únicamente pares cuyo tiempo mínimo == globalMin
$outLines = New-Object System.Collections.ArrayList

for ($s = 1; $s -le $n; $s++) {
  $sKey = $s.ToString()
  $printedAny = $false
  for ($t = 1; $t -le $n; $t++) {
    if ($s -eq $t) { continue }
    $d = [double]$distSaved[$sKey][$t.ToString()]
    if ([math]::Abs($d - $globalMin) -le $eps) {
      if (-not $printedAny) {
        $outLines.Add("----") | Out-Null
        $outLines.Add(("Origen: {0}" -f $s)) | Out-Null
        $printedAny = $true
      }
      $outLines.Add(("Destino {0}: tiempo minimo = {1}" -f $t, (Format-Time $d))) | Out-Null
      $outLines.Add("Rutas (todas las rutas con tiempo minimo):") | Out-Null

      $predForSource = $predSaved[$sKey]
      $pathsWrapper = Get-AllPaths -s $s -t $t -predForSource $predForSource
      $paths = $pathsWrapper[0]
      if ($paths.Count -eq 0) {
        # fallback: imprimir directo si existe arista directa
        if ($mat[$s-1][$t-1] -gt $eps) {
          $outLines.Add(("  {0} -> {1}" -f $s, $t)) | Out-Null
        } else {
          $outLines.Add("  (ruta mínima calculada pero no se encontraron predecesores)") | Out-Null
        }
      } else {
        foreach ($p in $paths) {
          $outLines.Add(("  " + ($p -join " -> "))) | Out-Null
        }
      }
      $outLines.Add("") | Out-Null
    }
  }
}

if ($outLines.Count -eq 0) {
  $outLines.Add("No se encontraron pares con el mínimo global (verificar).") | Out-Null
}

$outLines | Out-File -FilePath $outfile -Encoding UTF8
Write-Output ("Informe generado: {0}" -f $outfile)
exit 0
