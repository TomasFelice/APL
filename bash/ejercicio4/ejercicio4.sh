#!/usr/bin/env bash
# =================================================
# Integrantes:
# - Casas, Lautaro Nahuel
# - Coarite Coarite, Ivan Enrique
# - Felice, Tomas Agustin
# =================================================

set -o pipefail

PROG_NAME="$(basename "$0")"
DEFAULT_INTERVAL=60

print_help() {
  cat <<EOF
  Uso: $PROG_NAME -r <repo> -c <config> -l <log> [-a <segundos>] 
        $PROG_NAME -r <repo> -k
  Opciones:
    -r, --repo           Ruta del repositorio Git a monitorear. (obligatorio)
    -c, --configuracion  Ruta del archivo de patrones (una por línea). (obligatorio al iniciar)
    -l, --log            Ruta del archivo de logs donde se registran las alertas. (obligatorio al iniciar)
    -a, --alerta         Intervalo de comprobación en segundos (default: ${DEFAULT_INTERVAL}).
    -k, --kill           Detiene el demonio asociado al repo (usar junto con -r).
    -h, --help           Muestra esta ayuda.
  Notas:
    - El archivo de config admite líneas 'regex:TU_REGEX' o palabras literales.
    - Rutas pueden ser relativas, absolutas o contener espacios.
EOF
}

friendly_exit() {
  local msg="$1"
  echo "Error: $msg" >&2
  exit 1
}

# Leer patrones desde config
read_patterns() {
  patterns_literal=()
  patterns_regex=()
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(printf '%s' "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    case "$line" in
      \#*) continue ;; # comentario
      regex:*) r="${line#regex:}"; [ -n "$r" ] && patterns_regex+=("$r") ;;
      *) patterns_literal+=("$line") ;;
    esac
  done < "$CONFIG"
}

# Simple logging helper
log_alert() {
  local msg="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] %s\n' "$ts" "$msg" >> "$LOG" 2>/dev/null || {
    echo "No se puede escribir en el archivo de log '$LOG'. Compruebe permisos." >&2
  }
}

cleanup() {
  rm -f "$PIDFILE" "$LASTFILE" 2>/dev/null
}

# --- Función que escanea archivos modificados entre commits ---
scan_diff() {
  local oldc="$1" newc="$2"
  # obtener lista de archivos modificados entre commits
  mapfile -t files < <(git diff --name-only "$oldc" "$newc" -- 2>/dev/null)
  if [ "${#files[@]}" -eq 0 ]; then
    return 0
  fi

  for f in "${files[@]}"; do
    # Ruta completa
    full="$REPO/$f"
    # si el archivo fue borrado en el commit nuevo, saltar
    if [ ! -f "$full" ]; then
      continue
    fi

    # escanear patrones literales
    for patt in "${patterns_literal[@]}"; do
      # Capturar coincidencias en un array para evitar problemas con pipes
      mapfile -t matches < <(grep -nH -F -- "$patt" -- "$full" 2>/dev/null)
      grep_rc=$?
      if [ $grep_rc -eq 0 ]; then
        for matchline in "${matches[@]}"; do
          log_alert "Alerta: patrón '$patt' encontrado en el archivo '$f' -> ${matchline#*:}"
        done
      elif [ $grep_rc -gt 1 ]; then
        # 2 = error en grep
        log_alert "Error al escanear '$f' con patrón literal '$patt'."
      fi
    done

    # escanear patrones regex
    for rp in "${patterns_regex[@]}"; do
      mapfile -t matches < <(grep -nH -E -- "$rp" -- "$full" 2>/dev/null)
      grep_rc=$?
      if [ $grep_rc -eq 0 ]; then
        for matchline in "${matches[@]}"; do
          log_alert "Alerta: patrón_regex '$rp' encontrado en el archivo '$f' -> ${matchline#*:}"
        done
      elif [ $grep_rc -gt 1 ]; then
        log_alert "Error al escanear '$f' con patrón regex '$rp'."
      fi
    done
  done
}

# --- Argument parsing (GNU getopt) ---
OPTS=$(getopt -o r:c:l:a:kh --long repo:,configuracion:,log:,alerta:,kill,help,run-daemon -- "$@")
if [ $? -ne 0 ]; then
  print_help
  exit 2
fi
eval set -- "$OPTS"

# Variables
REPO=""
CONFIG=""
LOG=""
KILL_FLAG=0
INTERVAL="$DEFAULT_INTERVAL"
RUN_DAEMON=0

while true; do
  case "$1" in
    -r|--repo) REPO="$2"; shift 2;;
    -c|--configuracion) CONFIG="$2"; shift 2;;
    -l|--log) LOG="$2"; shift 2;;
    -a|--alerta) INTERVAL="$2"; shift 2;;
    -k|--kill) KILL_FLAG=1; shift;;
    --run-daemon) RUN_DAEMON=1; shift;;
    -h|--help) print_help; exit 0;;
    --) shift; break;;
    *) break;;
  esac
done

# Validate some basics for user-friendly messages
if [ -z "$REPO" ]; then
  friendly_exit "Falta parámetro obligatorio -r / --repo. Usa -h para ayuda."
fi

# Normalize repo path (preserve spaces)
REPO="$(readlink -f -- "$REPO" 2>/dev/null || printf '%s\n' "$REPO")"

# Note: CONFIG and LOG are normalized below when launching daemon (non-run-daemon)

# pidfile & tmp file naming (unique por repo)
repo_hash=$(printf '%s' "$REPO" | sha1sum 2>/dev/null | awk '{print substr($1,1,12)}')
PIDFILE="/tmp/git_audit_${repo_hash}.pid"
LASTFILE="/tmp/git_audit_${repo_hash}.last"

# If kill mode: only require -r and attempt to stop daemon
if [ "$KILL_FLAG" -eq 1 ]; then
  if [ ! -f "$PIDFILE" ]; then
    echo "No se encontró un demonio en ejecución para el repositorio '$REPO' (pidfile $PIDFILE)." >&2
    exit 1
  fi
  pid=$(cat "$PIDFILE" 2>/dev/null)
  if [ -z "$pid" ]; then
    rm -f "$PIDFILE" "$LASTFILE" 2>/dev/null
    echo "Pid inválido. Archivos temporales eliminados." >&2
    exit 1
  fi
  if kill -0 "$pid" 2>/dev/null; then
    echo "Deteniendo demonio (PID $pid) para repo: $REPO ..."
    kill "$pid" || { echo "No se pudo enviar señal al proceso $pid." >&2; exit 1; }
    # espere a que muera
    for i in {1..10}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 0.5
    done
    if kill -0 "$pid" 2>/dev/null; then
      echo "No pudo detenerse en el tiempo esperado. Enviando SIGKILL..."
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PIDFILE" "$LASTFILE" 2>/dev/null
    echo "Demonio detenido."
    exit 0
  else
    echo "No existe proceso con PID $pid. Eliminando archivos temporales." >&2
    rm -f "$PIDFILE" "$LASTFILE" 2>/dev/null
    exit 1
  fi
fi

# If not run-daemon mode (inicio): require CONFIG and LOG
if [ "$RUN_DAEMON" -eq 0 ]; then
  if [ -z "$CONFIG" ] || [ -z "$LOG" ]; then
    friendly_exit "Al iniciar el demonio se requieren -c/--configuracion y -l/--log además de -r/--repo."
  fi
  # Normalize config and log paths
  CONFIG="$(readlink -f -- "$CONFIG" 2>/dev/null || printf '%s\n' "$CONFIG")"
  LOG="$(readlink -f -- "$LOG" 2>/dev/null || printf '%s\n' "$LOG")"

  # Check pidfile to avoid multiple demons for same repo
  if [ -f "$PIDFILE" ]; then
    existing_pid=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
      friendly_exit "Ya hay un demonio en ejecución para ese repositorio (PID $existing_pid)."
    else
      echo "El pidfile existía pero el proceso no está activo. Limpiando pidfile."
      rm -f "$PIDFILE" "$LASTFILE" 2>/dev/null || true
    fi
  fi

  # Re-exec this script detached (background) para correr la lógica real con --run-daemon
  # build argument list preserving spaces
  ARGS=()
  ARGS+=(--run-daemon)
  ARGS+=(--repo) && ARGS+=("$REPO")
  ARGS+=(--configuracion) && ARGS+=("$CONFIG")
  ARGS+=(--log) && ARGS+=("$LOG")
  ARGS+=(--alerta) && ARGS+=("$INTERVAL")
  # Lanzar con setsid para desapegarse de la terminal
  setsid "$0" "${ARGS[@]}" >/dev/null 2>&1 &
  child_pid=$!
  # Guardar pid
  echo "$child_pid" > "$PIDFILE" || { echo "No se pudo escribir pidfile $PIDFILE" >&2; exit 1; }
  echo "Demonio iniciado (PID $child_pid). Log: $LOG"
  exit 0
fi

# ---------------------------
# Aquí comienza el demonio real (RUN_DAEMON==1)
# ---------------------------
# Esperamos recibir REPO, CONFIG, LOG, INTERVAL al re-parsing previo.
# A partir de aquí trabajamos en segundo plano.

trap 'cleanup; exit 0' EXIT INT TERM

# Validaciones del repo y archivos
if [ ! -d "$REPO" ]; then
  friendly_exit "El directorio del repositorio no existe: '$REPO'."
fi

if [ ! -f "$CONFIG" ]; then
  friendly_exit "El archivo de configuración no existe: '$CONFIG'."
fi

# Asegurar que directorio del log exista
log_dir=$(dirname -- "$LOG")
if [ ! -d "$log_dir" ]; then
  mkdir -p -- "$log_dir" 2>/dev/null || friendly_exit "No se pudo crear el directorio del log: $log_dir"
fi

# Comprobar que es repo git
cd "$REPO" || friendly_exit "No se puede acceder al repositorio: $REPO"
git rev-parse --git-dir >/dev/null 2>&1 || friendly_exit "'$REPO' no parece ser un repositorio Git."

# -----------------------------
# Determinar referencia a monitorear: SOLO RAMA LOCAL (HEAD)
# -----------------------------
current_local_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
UPSTREAM="$current_local_branch"
log_alert "Info: usando rama local para monitoreo: '$UPSTREAM'"
 
read_patterns || friendly_exit "No se pudieron leer los patrones de '$CONFIG'."

# Nota: eliminamos TODAS las llamadas a 'git fetch origin' porque el demonio trabaja solo con ramas locales

if ! current_commit=$(git rev-parse --verify "$UPSTREAM" 2>/dev/null); then
  friendly_exit "No se pudo obtener commit de '$UPSTREAM'."
fi

# Si no existe lastfile, lo creamos con el commit actual y no escaneamos nada (primer arranque)
if [ ! -f "$LASTFILE" ]; then
  echo "$current_commit" > "$LASTFILE" || friendly_exit "No se pudo escribir '$LASTFILE'."
fi

last_commit=$(cat "$LASTFILE" 2>/dev/null || echo "")

# Guardar el pidfile (en caso de que no lo esté)
if [ ! -f "$PIDFILE" ]; then
  echo $$ > "$PIDFILE" 2>/dev/null || echo "Advertencia: no se pudo escribir $PIDFILE" >&2
fi

# Bucle principal
while true; do
  sleep "$INTERVAL"
  # refrescar patrones en cada iteración para permitir cambios en el archivo de configuración
  if [ -f "$CONFIG" ]; then
    read_patterns
  fi

  new_commit=$(git rev-parse --verify "$UPSTREAM" 2>/dev/null) || {
    log_alert "Error: no se pudo obtener commit actual de $UPSTREAM."
    continue
  }

  if [ "$new_commit" != "$last_commit" ]; then
    # Si last_commit está vacío, lo iniciamos sin escaneo
    if [ -z "$last_commit" ]; then
      last_commit="$new_commit"
      echo "$last_commit" > "$LASTFILE"
      continue
    fi

    # Escanear diffs entre commits
    scan_diff "$last_commit" "$new_commit"
    # actualizar last commit
    echo "$new_commit" > "$LASTFILE" 2>/dev/null || log_alert "Advertencia: no se pudo actualizar $LASTFILE."
    last_commit="$new_commit"
  fi
done

# fin del script demonio
