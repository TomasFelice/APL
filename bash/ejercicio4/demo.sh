#!/usr/bin/env bash
# =================================================
# DEMO SIMPLE - Ejecución inmediata para mostrar 
# el funcionamiento del demonio
# =================================================

echo "=================================="
echo "  DEMO DEL DEMONIO DE MONITOREO"
echo "=================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR/repo"
CONFIG_FILE="$SCRIPT_DIR/patrones.conf"
LOG_FILE="$SCRIPT_DIR/logs/demo.txt"
DAEMON_SCRIPT="$SCRIPT_DIR/ejercicio4.sh"

# Limpiar logs previos
echo "Preparando demo..."
rm -f "$LOG_FILE"
mkdir -p "$(dirname "$LOG_FILE")"

# Detener demonio si está corriendo
"$DAEMON_SCRIPT" -r "$REPO_DIR" -k 2>/dev/null || true

echo "1. Iniciando demonio..."
"$DAEMON_SCRIPT" -r "$REPO_DIR" -c "$CONFIG_FILE" -l "$LOG_FILE" -a 3

if [ $? -ne 0 ]; then
    echo "❌ Error al iniciar demonio"
    exit 1
fi

echo "✅ Demonio iniciado correctamente"
echo "2. Esperando 5 segundos para que se establezca..."
sleep 5

echo "3. Creando commit con credenciales PELIGROSAS..."
cd "$REPO_DIR"

cat > demo_credentials.json << 'EOF'
{
    "production": {
        "database": {
            "password": "prod_password_123456",
            "host": "db.company.com"
        },
        "apis": {
            "stripe": {
                "API_KEY": "sk_live_demo_key_abcdef123456"
            },
            "sendgrid": {
                "API_KEY": "SG.demo_api_key.xyz789"
            }
        },
        "auth": {
            "jwt_secret": "super_secret_jwt_signing_key_2024",
            "session_secret": "session_secret_for_production"
        }
    }
}
EOF

git add demo_credentials.json
git commit -m "DEMO: Add production credentials (SHOULD TRIGGER MULTIPLE ALERTS)"

echo "✅ Commit realizado con múltiples credenciales"
echo "4. Esperando 10 segundos para que el demonio detecte..."

# Mostrar progreso
for i in {1..10}; do
    echo -n "."
    sleep 1
done
echo ""

echo "5. Verificando alertas generadas..."
echo ""

if [ -f "$LOG_FILE" ]; then
    echo "ALERTAS DETECTADAS:"
    echo "=================================="
    cat "$LOG_FILE"
    echo "=================================="
    echo ""
    
    # Contar alertas por patrón
    password_alerts=$(grep -c "password" "$LOG_FILE" 2>/dev/null || echo "0")
    api_key_alerts=$(grep -c "API_KEY" "$LOG_FILE" 2>/dev/null || echo "0") 
    secret_alerts=$(grep -c "secret" "$LOG_FILE" 2>/dev/null || echo "0")
    total_alerts=$(grep -c "Alerta:" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo "📈 RESUMEN:"
    echo "- Total de alertas: $total_alerts"
    echo "- Alertas 'password': $password_alerts"
    echo "- Alertas 'API_KEY': $api_key_alerts" 
    echo "- Alertas 'secret': $secret_alerts"
    
    if [ "$total_alerts" -gt 0 ]; then
        echo ""
        echo "✅ El demonio detectó las credenciales correctamente."
    else
        echo ""
        echo "❌ No se detectaron alertas. Revisa la configuración."
    fi
else
    echo "❌ No se generó archivo de log"
fi

echo ""
echo "6. Deteniendo demonio..."
"$DAEMON_SCRIPT" -r "$REPO_DIR" -k
