# LOTE DE PRUEBAS - EJERCICIO 1 BASH

## Estructura de Pruebas

Este directorio contiene un lote completo de pruebas para el ejercicio1 de bash.

### Estructura de Directorios

```
ejercicio1/
├── ejercicio1                          # Script principal
├── test_commands.txt                   # Comandos de prueba manuales
├── run_tests.sh                       # Script automatizado de pruebas
├── README_TESTS.md                    # Este archivo
├── in/                                # Datos de entrada
│   ├── caso_normal/                   # Casos de uso normales
│   │   ├── 2025-08-30.txt            # Datos múltiples del mismo día
│   │   ├── 2025-08-29.txt            # Datos de otro día
│   │   ├── datos_multiples_fechas.txt # Datos de múltiples fechas
│   │   └── canales_especiales.txt     # Canales con nombres especiales
│   ├── caso_archivo_unico/            # Casos con un solo archivo
│   │   ├── datos_minimos.txt          # Datos mínimos (3 registros)
│   │   ├── datos_cambio_año.txt       # Datos con cambio de año
│   │   └── cambio_año_futuro.txt      # Cambio de año hacia futuro
│   ├── caso_vacio/                    # Directorio sin archivos .txt
│   └── caso_datos_invalidos/          # Casos con datos incorrectos
│       ├── archivo_vacio.txt          # Archivo sin datos válidos
│       └── formato_incorrecto.txt     # Datos con formato incorrecto
└── out/                               # Archivos de salida
    ├── caso_normal/                   # Salidas para casos normales
    ├── caso_archivo_unico/            # Salidas para archivo único
    └── casos_especiales/              # Salidas para casos especiales
```

## Tipos de Pruebas

### 1. Pruebas de Ayuda
- **-h**: Verificar ayuda corta
- **--help**: Verificar ayuda larga

### 2. Pruebas de Validación de Parámetros
- Sin parámetros
- Parámetros incompletos
- Parámetros conflictivos (-a y -p juntos)
- Parámetros desconocidos

### 3. Pruebas de Validación de Directorios
- Directorio inexistente
- Directorio sin archivos .txt
- Archivo en lugar de directorio
- Directorio sin permisos de lectura

### 4. Pruebas de Rutas
- Rutas relativas con ./
- Rutas relativas sin ./
- Rutas absolutas
- Normalización de rutas

### 5. Pruebas Funcionales
- Procesamiento normal con múltiples archivos
- Procesamiento con un solo archivo
- Diferentes órdenes de parámetros
- Salida a pantalla vs archivo

### 6. Pruebas de Manejo de Errores
- Datos con formato incorrecto
- Archivos vacíos
- Directorio de salida inexistente
- Archivos sin permisos de escritura

### 7. Pruebas de Limpieza
- Verificación de archivos temporales
- Uso correcto del trap

## Cómo Ejecutar las Pruebas

### Opción 1: Script Automatizado (Recomendado)
```bash
cd /tu-ruta-a-la-carpeta-base/APL/bash/ejercicio1/
bash ./run_tests.sh
```

### Opción 2: Comandos Manuales
```bash
cd /tu-ruta-a-la-carpeta-base/APL/bash/ejercicio1/
# Seguir los comandos en test_commands.txt
```

### Opción 3: Pruebas Individuales
```bash
cd /tu-ruta-a-la-carpeta-base/APL/bash/ejercicio1/

# Ejemplo: Caso normal
bash ./ejercicio1.sh -d ./in/caso_normal -p

# Ejemplo: Archivo único
bash ./ejercicio1.sh -d ./in/caso_archivo_unico -a ./out/caso_archivo_unico/resultado.json
```

## Casos de Prueba Específicos

### Datos de Entrada

1. **caso_normal/**: Múltiples archivos con datos válidos
   - Diferentes fechas y canales
   - Volumen representativo de datos
   
2. **caso_archivo_unico/**: Un solo archivo
   - Datos mínimos (3 registros)
   - Cambios de año (2024->2025, 2025->2026)
   
3. **caso_datos_invalidos/**: Datos problemáticos
   - Archivos vacíos
   - Formato incorrecto
   - Datos sin estructura

### Resultados Esperados

- **Casos exitosos**: Código de salida 0, JSON válido
- **Casos de error**: Código de salida != 0, mensaje descriptivo

## Verificaciones Automáticas

El script `run_tests.sh` verifica:
- Códigos de salida correctos
- Manejo apropiado de errores
- Limpieza de archivos temporales
- Generación correcta de archivos de salida

## Limpieza

Para limpiar archivos de salida generados:
```bash
rm -f ./out/caso_normal/*.json
rm -f ./out/caso_archivo_unico/*.json
rm -f ./out/casos_especiales/*.json
```
