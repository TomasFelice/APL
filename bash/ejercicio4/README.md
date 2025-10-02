# Demo del Demonio de Monitoreo Git

## Descripción
Script de demostración que prueba el funcionamiento del demonio `ejercicio4.sh` para detectar credenciales y datos sensibles en commits de Git.

## Uso

### En Git Bash o WSL:
```bash
./demo.sh
```

### En PowerShell:
```bash
bash demo.sh
```

## ¿Qué hace el demo?

1. **Inicia el demonio** de monitoreo en segundo plano
2. **Crea un commit** con un archivo JSON que contiene credenciales peligrosas:
   - Passwords de base de datos
   - API Keys de servicios (Stripe, SendGrid)
   - Secrets JWT y de sesión
3. **Espera 10 segundos** para que el demonio detecte los cambios
4. **Muestra las alertas** generadas en tiempo real
5. **Cuenta por tipo** de patrón detectado
6. **Detiene el demonio** automáticamente

## Resultados Esperados

El demo debería detectar múltiples alertas:
- ✅ `password` (contraseñas)
- ✅ `API_KEY` (claves de API)  
- ✅ `secret` (tokens y secretos)

## Archivos Generados

- `logs/demo.txt` - Log con las alertas detectadas
- `repo/demo_credentials.json` - Archivo con credenciales de prueba

## Limpieza

El script se encarga automáticamente de:
- Iniciar y detener el demonio
- Crear los directorios necesarios
- Manejar errores básicos

## Troubleshooting

**Si no aparecen alertas:**
- Verificar que `repo/` sea un repositorio Git válido
- Comprobar que `patrones.conf` existe y contiene los patrones
- Asegurar permisos de escritura en el directorio `logs/`

**En Windows:**
- Usar Git Bash, WSL, o PowerShell con `bash demo.sh`
- Verificar que Git esté en el PATH del sistema