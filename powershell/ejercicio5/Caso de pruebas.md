# Casos de prueba

## B-01 Búsqueda simple de un país (sin caché).

- Powershell
    - `.\ejercicio5.ps1 -nombre argentina`
- Bash
    - `./ejercicio5.sh -n argentina`

Muestra la información de Argentina.

Crea el archivo de caché: argentina_1.json.

Muestra mensajes de "Buscando información desde la web" e "Información guardada".

* * *

## B-02 Búsqueda simple de un país ya en caché (no expirado, TTL por defecto).

- Powershell
    - `.\ejercicio5.ps1 -nombre argentina`
- Bash
    - `./ejercicio5.sh -n argentina`

Muestra la información de Argentina.

Muestra mensajes de "Buscando información desde un archivo local" y "Archivo local disponible".

No llama a la API web.

* * *

## B-03 Búsqueda de un país con un TTL de 2 días.

- Powershell
    - `.\ejercicio5.ps1 -nombre brasil -ttl 2`
- Bash
    - `` `./ejercicio5.sh -n brasil -ttl 2` ``

Muestra la información de brasil.

Crea el archivo de caché: brasil_2.json.

* * *

## B-04 Búsqueda de un país con nombre compuesto (con comillas).

- Powershell
    - `.\ejercicio5.ps1 -nombre "saudi arabia"`
- Bash
    - `./ejercicio5.sh -n "saudi arabia`

Muestra la información de Saudi Arabia.

Crea el archivo de caché: saudi-arabia_1.json.

Muestra mensajes de "Buscando información desde la web" e "Información guardada".

* * *

## B-05 Búsqueda de múltiples países.

- Powershell
    - `.\ejercicio5.ps1 -nombre peru, colombia -ttl 3`
- Bash
    - `./ejercicio5.sh --nombre peru, -n colombia -ttl 3`

Muestra la información de Perú y Colombia (buscándolos o desde caché).

Crea o actualiza archivos de caché (e.g., peru_3.json, colombia_3.json).

* * *

## C-06 Archivo de caché expirado (simulado).

Agregar manualmente un archivo en la carpeta **Pais.**

Realizar una copia de un archivo expirado desde la carpeta **LoteDePrueba** hacia la carpeta **Pais**.

Nombre del archivo a copiar (entorno Windows): **mexico_1.json**

Nombre del archivo a copiar (entorno Linux): **2025-09-28_ecuador.json**

Luego ejecutar:

- Powershell
    - `.\ejercicio5.ps1 -nombre mexico`
- Bash
    - `./ejercicio5.sh -n ecuador`

Muestra el mensaje "Archivo local desactualizado". Mueve el archivo expirado a la carpeta Papelera.

Busca la información desde la web.

Crea un nuevo archivo mexico_1.json.

Crea un nuevo archivo yyyy-mm-dd_ecuador_1.json

* * *

## E-07 Búsqueda de un país que no existe.

- <span style="color: rgb(255, 255, 255);">**Powershell**</span>
    - `.\ejercicio5.ps1 -nombre "paisinexistente"`
- <span style="color: rgb(255, 255, 255);">Bash</span>
    - `./ejercicio5.sh -n "paisinexistente"`

Muestra mensajes de error de petición (Error de petición, Hubo un error al conectar con la api) y el mensaje "Adv. No se encontró información disponible".

No añade nada a los resultados.

* * *

## E-08 Búsqueda de un país cuyo nombre es muy corto ( < 4 caracteres).

- Powershell
    - `.\ejercicio5.ps1 -nombre usa`
- Bash
    - `./ejercicio5.sh -n usa`

El país es ignorado debido al filtro `$paises = $nombre.Where({ $_ -match "^.{4,}" })`. El script bash también aplica un filtro.

No se realiza ninguna búsqueda.

* * *

## E-09 Búsqueda con múltiples coincidencias (entre 2 y 10).

- Powershell
    - `.\ejercicio5.ps1 -nombre korea`
- Bash
    - `./ejercicio5.sh -n korea`

Muestra el mensaje de advertencia: "Adv. Posibles coincidencias para la busqueda - korea".

Lista los nombres comunes de los países encontrados (e.g., North Korea, South Korea, etc.).

No añade nada a los resultados ni guarda en caché.

* * *

## P-10 Uso de un valor de ttl no permitido.

- Powershell
    - `.\ejercicio5.ps1 -nombre brasil -ttl 7`
- Bash
    - `./ejercicio5.sh -n brasil -ttl 7`

Falla la ejecución del script (error de validación de parámetros de PowerShell) antes de que comience la ejecución del Main block, debido a \[ValidateSet(1, 2, 3, 4, 5)\].

Falla la ejecución del script (error de validación de parámetros de Bash) antes de que comience la ejecución del Main block, debido a un control de rango permitido en bash.

* * *

## P-11 Omisión del parámetro obligatorio nombre.

- Powershell
    - `.\ejercicio5.ps1 -ttl 2`
- Bash
    - `./ejercicio5.sh -t 2`

PowerShell sugerirá ingresar el nombre del país a buscar, pero si decide presionar 'enter' omitiendo el nombre entonces fallara la ejecución del script (error de validación de parámetros de PowerShell) ya que nombre es Mandatory = $True.

Bash muestra un mensaje de 'Error: Debe especificar una opcion \[-n | --nombre\]", evitando la ejecución del script completo.