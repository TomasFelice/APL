# función para borrar pred arrays
# pred_count[v] da la cantidad de predecesores, pred[v,k] enumerados 1..pred_count[v]

function clear_preds() {
  for (i = 1; i <= n; i++) {
    if (pred_count[i] > 0) {
      for (k = 1; k <= pred_count[i]; k++) delete pred[i,k]
    }
    pred_count[i] = 0
  }
}

# Dijkstra desde s
function dijkstra(source, node, current, neighbor, weight, tentative_dist, found_flag, min_dist) {
  for (node = 1; node <= n; node++) {
    dist[node] = INF
    visited[node] = 0
    pred_count[node] = 0
  }
  dist[source] = 0
  while (1) {
    current = -1; min_dist = INF
    for (node = 1; node <= n; node++){
      if (!visited[node] && dist[node] < min_dist) {
        min_dist = dist[node]; current = node
      }
    }

    if (current == -1) break
    visited[current] = 1
    for (neighbor = 1; neighbor <= n; neighbor++) {
      weight = mat[current,neighbor]
      if (neighbor != current && weight > eps) {
        tentative_dist = dist[current] + weight
        if (tentative_dist + eps < dist[neighbor]) {
          dist[neighbor] = tentative_dist
          # reset predecesores
          if (pred_count[neighbor] > 0) {
            for (k = 1; k <= pred_count[neighbor]; k++) delete pred[neighbor,k]
          }
          pred_count[neighbor] = 1
          pred[neighbor,1] = current
        } else if ( (tentative_dist - dist[neighbor]) <= eps && (dist[neighbor] - tentative_dist) <= eps ) {
          # nuevo camino con mismo coste -> añadimos predecesor
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
  # comprobación de simetría y diagonal cero
  for (i = 1; i <= n; i++) {
    for (j = 1; j <= n; j++) {
      a = mat[i,j] + 0
      b = mat[j,i] + 0
      # diagonal -> se exige 0 (por definicion)
      if (i == j) {
        if ( (a > eps) || (a < -eps) ) {
          printf("ERROR: diagonal [%d,%d] debe ser 0, es %g\n", i, j, a) > "/dev/stderr"
          exit 5
        }
      }
      # simetría (permitimos pequeñas diferencias por floats)
      if ( (a - b) > eps || (b - a) > eps ) {
        printf("ERROR: Matriz no simétrica en (%d,%d): %g != %g\n", i, j, a, b) > "/dev/stderr"
        exit 6
      }
      # pesos negativos no permitidos
      if (a < -eps) {
        printf("ERROR: Peso negativo detectado en (%d,%d): %g\n", i, j, a) > "/dev/stderr"
        exit 7
      }
    }
  }

  print "## Informe de análisis de red de transporte"

  # Si piden hub:
  if (mode == "hub") {
    # contar conexiones (no contar diagonal, y valores > 0 significan conexión)
    maxdeg = -1
    delete hubs
    for (i = 1; i <= n; i++) {
      deg = 0
      for (j = 1; j <= n; j++) {
        if (i != j && mat[i,j] > eps) deg++
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
    printf("**Hub(s) de la red:**\n")
    sepout = " "
    for (i in hubs) {
      printf("Estacion %d: %d conexiones\n", i,maxdeg)
      sepout = ", "
    }
    print "\n"
    exit 0
  }

  # Si piden camino(s): implementar Dijkstra desde cada fuente (todos los pares), guardando predecesores múltiples
  if (mode == "camino") {
    printf("ANALISIS: Caminos minimos (Dijkstra) para cada par de estaciones\n")
    printf("Estaciones: %d\n\n", n)

    global_min = INF
    # Ejecutar Dijkstra desde cada s y guardar resultados
    for (s = 1; s <= n; s++) {
      clear_preds()
      dijkstra(s)
      for (t = 1; t <= n; t++) {
        dist_saved[s, t] = dist[t]
        pred_count_saved[s, t] = pred_count[t]
        if (pred_count[t] > 0) {
          for (k = 1; k <= pred_count[t]; k++) pred_saved[s, t, k] = pred[t, k]
        } else {
          # aseguramos que no queden restos antiguos
          pred_count_saved[s, t] = 0
        }
        # actualizar mínimo global (excluimos s==t y caminos inalcanzables)
        if (t != s && dist[t] < INF/2) {
          if (dist[t] + eps < global_min) global_min = dist[t]
        }
      }
    }

    if (global_min >= INF/2) {
      print "No hay caminos entre estaciones (o todas son inalcanzables)."
      exit 0
    }

    # Imprimir únicamente pares cuyo tiempo mínimo == global_min
    for (s = 1; s <= n; s++) {
      printed_any = 0
      # primero revisamos si existe al menos un destino t para este s con dist == global_min
      for (t = 1; t <= n; t++) {
        if (t == s) continue
        # comparar con tolerancia eps
        d = dist_saved[s, t]
        if (d < INF/2 && ( (d - global_min) <= eps && (global_min - d) <= eps )) {
          printed_any = 1
          break
        }
      }
      if (printed_any) {
        print "----"
        printf("Origen: %d\n", s)
        for (t = 1; t <= n; t++) {
          if (t == s) continue
          d = dist_saved[s, t]
          if (d < INF/2 && ( (d - global_min) <= eps && (global_min - d) <= eps )) {
            printf("Destino %d: tiempo minimo = %s\n", t, format_time(d))
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
