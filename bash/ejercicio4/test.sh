#!/usr/bin/env bash
# audit_test_harness.sh
# Uso: ./audit_test_harness.sh /ruta/a/audit.sh
set -euo pipefail

AUDIT_SCRIPT="$1"
WORKDIR="$(mktemp -d /tmp/audit_test.XXXXXX)"
BARE_REPO="$WORKDIR/remote.git"
CLONE_REPO="$WORKDIR/clone repo with spaces"   # prueba rutas con espacios
CONFIG_FILE="$WORKDIR/patrones.conf"
LOG_FILE="$WORKDIR/alerts log.txt"
INTERVAL=3

cleanup() {
  echo ">> Limpieza..."
  # intentar detener demonio si quedó corriendo (usa -r)
  if [ -f /tmp/git_audit_*.pid ] 2>/dev/null; then
    for f in /tmp/git_audit_*.pid; do
      [ -f "$f" ] || continue
      pid=$(cat "$f" 2>/dev/null || echo "")
      if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 0.5
      fi
      rm -f "$f" || true
    done
  fi
  rm -rf "$WORKDIR"
}
trap cleanup EXIT INT TERM

echo ">> Directorio de trabajo: $WORKDIR"

# 1) Crear repositorio bare (origin)
git init --bare "$BARE_REPO"

# 2) Clonarlo (ruta con espacios para probar)
git clone "$BARE_REPO" "$CLONE_REPO"
cd "$CLONE_REPO"

# Asegurarse de usar main como rama
git checkout -b main

# 3) Archivo inicial y push (commit inicial)
echo "init" > README.md
git add README.md
git commit -m "initial commit"
git push origin main

# 4) Crear archivo de patrones
cat > "$CONFIG_FILE" <<EOF
API_KEY
regex:^.*API_KEY\s*=\s*['\"].*['\"].*$
#comentario ignorado

EOF
echo "Config de patrones creado en: $CONFIG_FILE"

# 5) Iniciar demonio (background) con intervalo pequeño
echo ">> Iniciando demonio..."
# Pasar rutas con espacios soportadas; el script deberá manejar comillas
"$AUDIT_SCRIPT" -r "$CLONE_REPO" -c "$CONFIG_FILE" -l "$LOG_FILE" -a "$INTERVAL"
sleep 1

# Esperar pidfile aparezca (max 5s)
echo ">> Esperando pidfile..."
for i in {1..10}; do
  # buscar pidfile en /tmp que tenga hash de la ruta (no sabemos el nombre exacto), así detectamos uno que contenga el hash
  pidfile=$(ls /tmp/git_audit_*.pid 2>/dev/null | head -n1 || true)
  if [ -n "$pidfile" ]; then
    echo "pidfile encontrado: $pidfile"
    break
  fi
  sleep 0.5
done

if [ -z "${pidfile:-}" ]; then
  echo "ERROR: no se creó pidfile. Falló iniciar demonio." >&2
  exit 1
fi

pid=$(cat "$pidfile")
echo "Demonio pid: $pid"

# 6) Test 2: crear archivo que contenga API_KEY y push -> debería generar alerta
TESTFILE="config.js"
cat > "$CLONE_REPO/$TESTFILE" <<EOF
// archivo de prueba
const API_KEY = "MI_SECRETO_123";
EOF
cd "$CLONE_REPO"
git add "$TESTFILE"
git commit -m "add config with API_KEY"
git push origin main

echo ">> Commit con API_KEY pushed. Esperando que demonio lo detecte..."
sleep $((INTERVAL + 3))

# Verificar log
if grep -q "API_KEY" "$LOG_FILE"; then
  echo "OK: Se detectó 'API_KEY' en el log."
else
  echo "FALLO: No se encontró API_KEY en $LOG_FILE"
  echo "Contenido de log:"
  cat "$LOG_FILE" || true
  exit 1
fi

# 7) Test regex: añadir una línea que coincida con la regex
cat > "$CLONE_REPO/other.txt" <<EOF
some text
API_KEY = "OTRO_SECRETO"
EOF
git add other.txt
git commit -m "add other with regex match"
git push origin main

sleep $((INTERVAL + 3))
if grep -q "patrón_regex" "$LOG_FILE" || grep -q "regex" "$LOG_FILE"; then
  echo "OK: Se detectó patrón regex en el log."
else
  echo "FALLO: No se encontró alerta regex en $LOG_FILE"
  cat "$LOG_FILE"
  exit 1
fi

# 8) Test recarga de configuración: agregar 'password' y push un commit con password
echo "password" >> "$CONFIG_FILE"
# no hace falta commit del config en repo; el demonio lee archivo externo
cd "$CLONE_REPO"
cat > "$CLONE_REPO/secret.txt" <<EOF
user: admin
password: 12345
EOF
git add secret.txt
git commit -m "add password file"
git push origin main

sleep $((INTERVAL + 4))
if grep -q "password" "$LOG_FILE"; then
  echo "OK: Se detectó 'password' tras recarga de configuración."
else
  echo "FALLO: No se detectó 'password' en $LOG_FILE"
  cat "$LOG_FILE"
  exit 1
fi

# 9) Test stop con -k
echo ">> Probando parada con -k..."
"$AUDIT_SCRIPT" -r "$CLONE_REPO" -k
sleep 1
if kill -0 "$pid" 2>/dev/null; then
  echo "FALLO: el demonio sigue en ejecución (PID $pid)."
  exit 1
else
  echo "OK: demonio detenido correctamente."
fi

# 10) Test no doble demonio: arrancar demonio 1 vez e intentar arrancar segunda vez
"$AUDIT_SCRIPT" -r "$CLONE_REPO" -c "$CONFIG_FILE" -l "$LOG_FILE" -a "$INTERVAL"
sleep 1
second_pidfile=$(ls /tmp/git_audit_*.pid 2>/dev/null | head -n1 || true)
second_pid=$(cat "$second_pidfile" 2>/dev/null || echo "")
echo "Demonio arrancado (segunda ronda) pid: $second_pid"
# intentar arrancar otra vez (debe fallar) y capturar salida
set +e
out=$("$AUDIT_SCRIPT" -r "$CLONE_REPO" -c "$CONFIG_FILE" -l "$LOG_FILE" -a "$INTERVAL" 2>&1)
rc=$?
set -e
if [ $rc -eq 0 ]; then
  echo "FALLO: se permitió iniciar un segundo demonio para el mismo repo."
  exit 1
else
  echo "OK: intento de iniciar segundo demonio falló como se esperaba."
fi

# detener demonio final
"$AUDIT_SCRIPT" -r "$CLONE_REPO" -k
sleep 1

echo ">> Todos los tests básicos completados correctamente."
