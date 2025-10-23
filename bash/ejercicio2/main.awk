# Funciones helper para comparaciones flotantes
function equals(a, b) { return ((a - b) <= eps && (b - a) <= eps) }
function is_zero(x) { return (x <= eps && x >= -eps) }
function is_positive(x) { return x > eps }

# Dijkstra optimizado
function dijkstra(source,    node, current, neighbor, weight, tentative_dist, min_dist) {
  # Inicialización
  for (node = 1; node <= n; node++) {
    dist[node] = INF; visited[node] = 0; pred_count[node] = 0
  }
  dist[source] = 0
  
  while (1) {
    # Encontrar nodo no visitado con distancia mínima
    current = -1; min_dist = INF
    for (node = 1; node <= n; node++) {
      if (!visited[node] && dist[node] < min_dist) {
        min_dist = dist[node]; current = node
      }
    }
    if (current == -1) break
    
    visited[current] = 1
    # Relajar vecinos
    for (neighbor = 1; neighbor <= n; neighbor++) {
      weight = mat[current,neighbor]
      if (neighbor != current && is_positive(weight)) {
        tentative_dist = dist[current] + weight
        if (tentative_dist < dist[neighbor] - eps) {
          # Nuevo camino más corto
          dist[neighbor] = tentative_dist
          pred_count[neighbor] = 1
          pred[neighbor,1] = current
        } else if (equals(tentative_dist, dist[neighbor])) {
          # Camino alternativo con mismo costo
          pred_count[neighbor]++
          pred[neighbor, pred_count[neighbor]] = current
        }
      }
    }
  }
}

# reconstructor recursivo de rutas (desde target t hasta s)
# dfs(v): si v==s -> imprimir s y luego arr desde len..1
function dfs_build(s, v, arr, len, k,i,out) {
  if (v == s) {
    out = s
    for (i = len; i >= 1; i--) out = out " -> " arr[i]
    print out
  } else {
    if (pred_count[v] == 0) {
      # no hay predecesores -> inaccesible
      # no imprimimos rutas
      return
    }
    for (k = 1; k <= pred_count[v]; k++) {
      arr[len+1] = v
      dfs_build(pred[v,k], s, arr, len+1)
    }
  }
}

# formato tiempo: corta ceros finales y punto si corresponde
function format_time(x,    s) {
  s = sprintf("%.6f", x)
  sub(/0+$/, "", s)
  sub(/\.$/, "", s)
  return s
}

BEGIN {
  FS = sep
  OFS = " "
  INF = 1e18
  eps = 1e-9
  nrows = 0
}

# lectura y validación básica línea por línea
{
  nrows++
  # split preserva campos según FS
  # guardamos campos en mat[nrows,i]
  cols = split($0, fields, FS)
  if (nrows == 1) expected = cols
  else if (cols != expected) {
    printf("ERROR: Matriz no cuadrada: fila %d tiene %d columnas (esperaba %d)\n", nrows, cols, expected) > "/dev/stderr"
    exit 2
  }
  for (i = 1; i <= cols; i++) {
    val = fields[i]
    # trim spaces
    gsub(/^[ \t\r]+|[ \t\r]+$/, "", val)
    if (val == "") val = "0"
    # validar número (entero o decimal)
    if (val !~ /^-?[0-9]+(\.[0-9]+)?$/) {
      printf("ERROR: Valor no numérico en fila %d columna %d: \"%s\"\n", nrows, i, fields[i]) > "/dev/stderr"
      exit 3
    }
    mat[nrows, i] = val + 0  # forzar numérico
  }
}

END {
  if (nrows != expected) {
    print "ERROR: Matriz no cuadrada (filas != columnas)" > "/dev/stderr"
    exit 4
  }
  n = nrows
  
  # Validación consolidada de matriz
  for (i = 1; i <= n; i++) {
    for (j = 1; j <= n; j++) {
      a = mat[i,j] + 0
      b = mat[j,i] + 0
      
      # Diagonal debe ser cero
      if (i == j && !is_zero(a)) {
        printf("ERROR: diagonal [%d,%d] debe ser 0, es %g\n", i, j, a) > "/dev/stderr"
        exit 5
      }
      # Verificar simetría
      if (!equals(a, b)) {
        printf("ERROR: Matriz no simétrica en (%d,%d): %g != %g\n", i, j, a, b) > "/dev/stderr"
        exit 6
      }
      # No permitir pesos negativos
      if (a < -eps) {
        printf("ERROR: Peso negativo detectado en (%d,%d): %g\n", i, j, a) > "/dev/stderr"
        exit 7
      }
    }
  }

  print "## Informe de análisis de red de transporte"

  # Modo hub: encontrar estaciones con más conexiones
  if (mode == "hub") {
    maxdeg = -1
    for (i = 1; i <= n; i++) {
      deg = 0
      for (j = 1; j <= n; j++) {
        if (i != j && is_positive(mat[i,j])) deg++
      }
      degs[i] = deg
      if (deg > maxdeg) {
        maxdeg = deg
        delete hubs
        hubs[i] = 1
      } else if (deg == maxdeg) {
        hubs[i] = 1
      }
    }

    print "Estaciones totales:", n
    print ""
    print "Grado (cantidad de conexiones) por estación:"
    for (i = 1; i <= n; i++) printf("  Estación %d: %d\n", i, degs[i])
    print ""
    print "**Hub(s) de la red:**"
    for (i in hubs) printf("Estacion %d: %d conexiones\n", i, maxdeg)
    print ""
    exit 0
  }

  # Modo camino: encontrar caminos más cortos
  if (mode == "camino") {
    print "ANALISIS: Caminos minimos (Dijkstra) para cada par de estaciones"
    printf("Estaciones: %d\n\n", n)

    global_min = INF
    # Ejecutar Dijkstra desde cada origen
    for (s = 1; s <= n; s++) {
      dijkstra(s)
      for (t = 1; t <= n; t++) {
        if (t != s && dist[t] < INF/2 && dist[t] < global_min) {
          global_min = dist[t]
        }
        # Guardar resultados
        dist_saved[s, t] = dist[t]
        pred_count_saved[s, t] = pred_count[t]
        for (k = 1; k <= pred_count[t]; k++) {
          pred_saved[s, t, k] = pred[t, k]
        }
      }
    }

    if (global_min >= INF/2) {
      print "No hay caminos entre estaciones (o todas son inalcanzables)."
      exit 0
    }

    # Mostrar solo pares con tiempo mínimo global
    for (s = 1; s <= n; s++) {
      has_min_path = 0
      for (t = 1; t <= n; t++) {
        if (t != s && equals(dist_saved[s, t], global_min)) {
          has_min_path = 1
          break
        }
      }
      if (has_min_path) {
        print "----"
        printf("Origen: %d\n", s)
        for (t = 1; t <= n; t++) {
          if (t != s && equals(dist_saved[s, t], global_min)) {
            printf("Destino %d: tiempo minimo = %s\n", t, format_time(dist_saved[s, t]))
            print "Rutas (todas las rutas con tiempo minimo):"
            delete tmparr
            dfs_build(s, t, tmparr, 0)
            print ""
          }
        }
        exit 0
      }
    }
  }
}
