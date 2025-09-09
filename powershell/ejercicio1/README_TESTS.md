# 🧪 **GUÍA COMPLETA DE PRUEBAS - EJERCICIO 1 POWERSHELL**

## 📋 **Índice**
- [Introducción](#introducción)
- [Estructura de Archivos](#estructura-de-archivos)
- [Ejecución de Pruebas](#ejecución-de-pruebas)
- [Diferencias con Bash](#diferencias-con-bash)
- [Casos de Prueba](#casos-de-prueba)
- [Interpretación de Resultados](#interpretación-de-resultados)
- [Solución de Problemas](#solución-de-problemas)

---

## 🎯 **Introducción**

Este directorio contiene un sistema completo de pruebas para el **ejercicio1.ps1**, la versión PowerShell del procesador de archivos de datos. Las pruebas están diseñadas para validar todas las funcionalidades, manejo de errores y casos edge del script.

### **Objetivos de las Pruebas**
- ✅ Validar parámetros y sintaxis PowerShell
- ✅ Verificar manejo correcto de rutas Windows/Linux
- ✅ Comprobar generación de JSON válido
- ✅ Testear casos de error y recuperación
- ✅ Asegurar compatibilidad multiplataforma

---

## 📁 **Estructura de Archivos**

```
powershell/ejercicio1/
├── ejercicio1.ps1          # Script principal
├── README_TESTS.md         # Esta guía
├── run_tests.ps1          # Script automatizado de pruebas
├── test_commands.txt      # Lista completa de comandos de prueba
├── in/                    # Datos de entrada organizados por casos
│   ├── caso_normal/       # Múltiples archivos con datos variados
│   ├── caso_archivo_unico/ # Un solo archivo con datos mínimos
│   ├── caso_datos_invalidos/ # Archivos con formatos incorrectos
│   ├── caso_solo_vacios/  # Archivos completamente vacíos
│   └── caso_vacio/        # Directorio sin archivos .txt
└── out/                   # Directorio para archivos de salida generados
    ├── caso_normal/
    ├── caso_archivo_unico/
    └── casos_especiales/
```

---

## 🚀 **Ejecución de Pruebas**

### **Método 1: Script Automatizado (RECOMENDADO)**

```powershell
# Desde el directorio base del proyecto (/home/tfelice/dev/vh/APL)
./powershell/ejercicio1/run_tests.ps1

# Modo silencioso (solo resultados)
./powershell/ejercicio1/run_tests.ps1 -Silent
```

### **Método 2: Comandos Manuales**

```powershell
# Ejecutar comandos individuales desde test_commands.txt
Get-Content ./powershell/ejercicio1/test_commands.txt | Where-Object { $_ -match "^\./" } | ForEach-Object { Invoke-Expression $_ }
```

### **Método 3: Pruebas Específicas**

```powershell
# Prueba individual de ayuda
./powershell/ejercicio1/ejercicio1.ps1 -Help

# Prueba de caso normal
./powershell/ejercicio1/ejercicio1.ps1 -Directorio ./powershell/ejercicio1/in/caso_normal -Pantalla

# Prueba con archivo de salida
./powershell/ejercicio1/ejercicio1.ps1 -d ./powershell/ejercicio1/in/caso_archivo_unico -a ./powershell/ejercicio1/out/resultado.json
```

---

## 🔄 **Diferencias con Bash**

| Aspecto | Bash | PowerShell |
|---------|------|------------|
| **Parámetros** | `-d`, `-p`, `-a` | `-Directorio`, `-Pantalla`, `-Archivo` |
| **Aliases** | Argumentos cortos | `-d`, `-p`, `-a` disponibles |
| **Switch Parameters** | `-p` requiere argumento | `-Pantalla` es un switch (sin valor) |
| **Rutas** | Separador `/` | Funciona con `/` y `\` |
| **Ayuda** | `-h` | `-Help` y `-h` |
| **Códigos de Salida** | `exit 0/1` | `exit 0/1` (compatible) |
| **JSON** | AWK manual | `ConvertTo-Json` nativo |
| **Objetos** | Texto plano | Objetos PowerShell estructurados |

### **Sintaxis Equivalente**

```bash
# BASH
./ejercicio1 -d ./in/datos -p
./ejercicio1 -d ./in/datos -a salida.json

# POWERSHELL
./ejercicio1.ps1 -Directorio ./in/datos -Pantalla
./ejercicio1.ps1 -Directorio ./in/datos -Archivo salida.json

# POWERSHELL (aliases)
./ejercicio1.ps1 -d ./in/datos -p
./ejercicio1.ps1 -d ./in/datos -a salida.json
```

---

## 🧪 **Casos de Prueba**

### **1. Pruebas de Ayuda** ✅
- `-Help` muestra ayuda completa
- `-h` muestra ayuda abreviada

### **2. Pruebas de Parámetros** ❌➡️✅
- Sin parámetros → Error
- Solo directorio sin salida → Error
- Conflicto `-Archivo` y `-Pantalla` → Error

### **3. Pruebas de Directorio** ❌➡️✅
- Directorio inexistente → Error
- Directorio sin archivos .txt → Error
- Archivo en lugar de directorio → Error

### **4. Pruebas de Rutas** ✅
- Rutas relativas (`./directorio`)
- Rutas sin prefijo (`directorio`)
- Rutas absolutas (`/home/user/...`)

### **5. Casos Funcionales** ✅
- **caso_normal**: Múltiples archivos, datos variados
- **caso_archivo_unico**: Un archivo con datos mínimos
- **caso_solo_vacios**: Archivos vacíos (debería procesar sin error)

### **6. Pruebas de Salida** ✅
- Salida a pantalla con formato JSON
- Salida a archivo con creación de directorios
- Verificación de archivos generados

### **7. Casos Edge** ✅
- Orden de parámetros variable
- Uso de aliases cortos
- Manejo de caracteres especiales (ñ, acentos)

---

## 📊 **Interpretación de Resultados**

### **Salida del Script Automatizado**

```
=======================================
  INICIANDO PRUEBAS EJERCICIO 1 (PS)
=======================================

==================================================
  PRUEBAS DE AYUDA
==================================================

--- Ayuda con -Help ---
Comando: & './powershell/ejercicio1/ejercicio1.ps1' -Help
✓ PASS - Código de salida correcto (0)

...

==================================================
  RESUMEN DE PRUEBAS
==================================================
Total de pruebas: 24
Pruebas exitosas: 24
Pruebas fallidas: 0

🎉 ¡TODAS LAS PRUEBAS PASARON!
Porcentaje de éxito: 100%
```

### **Códigos de Salida**
- `0`: Todas las pruebas pasaron
- `1`: Una o más pruebas fallaron
- `130`: Pruebas interrumpidas por usuario (Ctrl+C)

### **Indicadores de Estado**
- ✅ `✓ PASS`: Prueba exitosa
- ❌ `✗ FAIL`: Prueba falló
- ⚠️ `WARN`: Advertencia (no crítico)

---

## 🔧 **Solución de Problemas**

### **Error: "No se puede ejecutar scripts"**
```powershell
# Cambiar política de ejecución (temporal)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verificar política actual
Get-ExecutionPolicy
```

### **Error: "Archivo no encontrado"**
- Verificar que estás en el directorio base del proyecto
- Usar rutas absolutas si es necesario
- Verificar permisos de archivo

### **Error: "JSON inválido"**
```powershell
# Verificar archivo de salida
Get-Content ./powershell/ejercicio1/out/resultado.json | ConvertFrom-Json

# Validar manualmente
Test-Json (Get-Content ./powershell/ejercicio1/out/resultado.json -Raw)
```

### **Pruebas Fallan Inconsistentemente**
- Limpiar directorio `out/` antes de ejecutar
- Verificar que no hay archivos temporales bloqueados
- Ejecutar en modo administrador si hay problemas de permisos

### **Diferencias con Versión Bash**
```powershell
# Comparar resultados
./bash/ejercicio1/ejercicio1 -d ./bash/ejercicio1/in/caso_normal -p > bash_output.json
./powershell/ejercicio1/ejercicio1.ps1 -d ./powershell/ejercicio1/in/caso_normal -p > ps_output.json

# Comparar archivos
Compare-Object (Get-Content bash_output.json) (Get-Content ps_output.json)
```

---

## 📝 **Comandos Útiles**

### **Limpieza de Archivos de Prueba**
```powershell
# Limpiar todas las salidas generadas
Remove-Item ./powershell/ejercicio1/out/caso_normal/*.json -Force -ErrorAction SilentlyContinue
Remove-Item ./powershell/ejercicio1/out/caso_archivo_unico/*.json -Force -ErrorAction SilentlyContinue
Remove-Item ./powershell/ejercicio1/out/casos_especiales/*.json -Force -ErrorAction SilentlyContinue

# Limpiar archivos temporales
Get-ChildItem $env:TEMP -Filter "*ejercicio1*" | Remove-Item -Force
```

### **Verificación Rápida**
```powershell
# Verificar que el script es funcional
./powershell/ejercicio1/ejercicio1.ps1 -Help

# Prueba rápida de funcionalidad
./powershell/ejercicio1/ejercicio1.ps1 -d ./powershell/ejercicio1/in/caso_archivo_unico -p
```

### **Monitoreo de Archivos**
```powershell
# Ver archivos generados en tiempo real
Get-ChildItem ./powershell/ejercicio1/out -Recurse -Filter "*.json" | Sort-Object LastWriteTime

# Contar archivos de entrada por caso
Get-ChildItem ./powershell/ejercicio1/in -Recurse -Filter "*.txt" | Group-Object Directory | Select-Object Name, Count
```

---

## 🎯 **Próximos Pasos**

1. **Ejecutar las pruebas completas**: `./run_tests.ps1`
2. **Revisar casos fallidos** (si los hay)
3. **Comparar con versión Bash** para validar equivalencia
4. **Adaptar a entorno específico** si es necesario

---

## 📞 **Soporte**

Si las pruebas fallan consistentemente:
1. Verificar versión de PowerShell: `$PSVersionTable`
2. Comprobar permisos de archivos
3. Revisar logs de error en detalle
4. Comparar con comportamiento esperado de la versión Bash

---

**¡Las pruebas están listas para ejecutar! 🚀**
