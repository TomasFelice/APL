# LOTE DE PRUEBAS - EJERCICIO 3 BASH

## Descripción del Ejercicio

El ejercicio 3 implementa un script que analiza archivos de logs (.log) en un directorio para contar la ocurrencia de eventos específicos basados en palabras clave proporcionadas.

### Características principales:
- Procesamiento de archivos .log usando AWK
- Búsqueda case-insensitive
- Soporte para múltiples palabras clave separadas por comas
- Manejo robusto de errores
- Limpieza automática de archivos temporales

## Estructura de Pruebas

```
ejercicio3/
├── ejercicio3                          # Script principal
├── test_commands.txt                   # Comandos de prueba manuales
├── run_tests.sh                       # Script automatizado de pruebas
├── README_TESTS.md                    # Este archivo
└── in/                                # Datos de entrada
    ├── caso_normal/                   # Casos de uso normales
    │   ├── system.log                 # Ejemplo exacto de la consigna
    │   ├── web.log                    # Logs de servidor web
    │   └── application.log            # Logs de aplicación Java
    ├── caso_archivo_unico/            # Casos con un solo archivo
    │   └── single.log                 # Archivo único para pruebas específicas
    ├── caso_case_sensitive/           # Casos para probar insensibilidad a mayúsculas
    │   └── mixed_case.log             # Palabras en diferentes casos
    ├── caso_vacio/                    # Archivos vacíos
    │   └── empty.log                  # Archivo .log completamente vacío
    └── caso_sin_logs/                 # Directorio sin archivos .log
        └── not_a_log.txt              # Archivo que no es .log
```

## Casos de Prueba Implementados

### 1. Ejemplo de la Consigna
```bash
bash ./ejercicio3 -d ./in/caso_normal -p "USB,Invalid"
# Salida esperada:
# USB: 2
# Invalid: 4
```

### 2. Pruebas Case-Insensitive
- Búsqueda con minúsculas: `"usb,invalid,error"`
- Búsqueda con mayúsculas: `"USB,INVALID,ERROR"`
- Búsqueda con caso mixto: `"Usb,Invalid,Error"`

### 3. Validación de Parámetros
- Sin parámetros
- Solo directorio sin palabras
- Solo palabras sin directorio
- Palabras vacías o solo comas
- Parámetros desconocidos

### 4. Validación de Directorios
- Directorio inexistente
- Directorio sin archivos .log
- Archivo en lugar de directorio

### 5. Diferentes Combinaciones de Palabras
- Una sola palabra
- Múltiples palabras existentes
- Palabras que no existen en los logs
- Mezcla de palabras existentes e inexistentes

## Contenido de los Archivos de Prueba

### caso_normal/system.log (Ejemplo de la consigna)
```
Aug 23 10:00:01 server.local kernel: [256.789] USB device plugged in.
Aug 23 10:00:05 server.local sshd[1234]: Invalid user from 192.168.1.1.
Aug 23 10:00:10 server.local sudo[5678]: Command not found.
Aug 23 10:00:15 server.local kernel: [258.123] USB device unplugged.
Aug 23 10:00:20 server.local sshd[1234]: Invalid user from 192.168.1.2.
```

### caso_case_sensitive/mixed_case.log
```
Aug 23 13:00:01 test.local process: USB USB USB device detected three times.
Aug 23 13:00:05 test.local process: Invalid invalid INVALID case test.
Aug 23 13:00:10 test.local process: Error ERROR error mixed case.
Aug 23 13:00:15 test.local process: Warning warn WARN different cases.
```

## Correcciones Realizadas al Script Original

### 1. **Problema en el conteo de palabras**
- **Antes**: Usaba `gsub()` incorrectamente para contar
- **Después**: Usa `match()` con loop para contar ocurrencias precisas

### 2. **Manejo del case-insensitive**
- **Antes**: Convertía las palabras originales a minúsculas en el output
- **Después**: Mantiene las palabras originales en el output pero busca en minúsculas

### 3. **Orden de resultados**
- **Antes**: Output en orden aleatorio (dependiente de arrays de AWK)
- **Después**: Output en el mismo orden que se proporcionaron las palabras

### 4. **Validación de palabras**
- **Antes**: No validaba palabras vacías o malformadas
- **Después**: Valida y limpia espacios, detecta palabras vacías

### 5. **Manejo de archivos temporales**
- **Agregado**: `mktemp` y `trap` para limpieza automática

## Cómo Ejecutar las Pruebas

### Opción 1: Script Automatizado (Recomendado)
```bash
cd /home/tfelice/dev/vh/APL
bash ./run_tests.sh
```

### Opción 2: Comandos Manuales
```bash
cd /home/tfelice/dev/vh/APL
# Seguir los comandos en test_commands.txt
```

### Opción 3: Pruebas Individuales
```bash
cd /home/tfelice/dev/vh/APL

# Ejemplo básico
bash ./ejercicio3 -d ./in/caso_normal -p "USB,Invalid"

# Case-insensitive
bash ./ejercicio3 -d ./in/caso_case_sensitive -p "usb,invalid,error"

# Una sola palabra
bash ./ejercicio3 -d ./in/caso_normal -p "error"
```

## Verificaciones Automáticas

El script `run_tests.sh` verifica:
- Códigos de salida correctos
- Output específico para casos conocidos
- Manejo apropiado de errores
- Limpieza de archivos temporales
- Case-insensitive funcionando correctamente
- Orden correcto de parámetros

## Ejemplos de Uso Práctico

```bash
# Buscar errores en logs de sistema
bash ./ejercicio3 -d ./in/caso_normal -p "error,failed,exception"

# Buscar intentos de conexión
bash ./ejercicio3 -d ./in/caso_normal -p "connection,connect,login"

# Buscar eventos de hardware
bash ./ejercicio3 -d ./in/caso_normal -p "USB,device,kernel"
```

## Resultados Esperados

- **22+ pruebas automatizadas**
- **100% compatibilidad con la consigna**
- **Manejo robusto de casos edge**
- **Case-insensitive completamente funcional**
- **Limpieza automática de recursos**
