# Casos de prueba

## B-01 Búsqueda simple de un país (sin especificar un ttl caché).

- Powershell
    - `.\ejercicio5.ps1 -nombre argentina`
- Bash
    - `./ejercicio5.sh -n argentina`

Muestra la información de Argentina.

Crea el archivo de caché: argentina_1.json - Powershell
Crea el archivo de caché: timestamps_argentina_1.json - Bash

Muestra mensajes de "Buscando información desde la web" e "Información guardada".

* * *

## B-02 Búsqueda de un país con un TTL de 60 segundos.

- Powershell
    - `.\ejercicio5.ps1 -nombre brasil -ttl 60`
- Bash
    - `` `./ejercicio5.sh -n brasil -ttl 60` ``

Muestra la información de brasil.

Crea el archivo de caché: brasil_60.json - Powershell
Crea el archivo de caché: timestamps_brasil_60.json - Bash

* * *

## B-03 Búsqueda simple de un país ya en caché.

- Powershell
    - `.\ejercicio5.ps1 -nombre brasil`
- Bash
    - `./ejercicio5.sh -n brasil`

Muestra la información de Brasil.

Muestra mensajes de "Buscando información desde un archivo local" y "Archivo local disponible".

No llama a la API web.

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
    - `.\ejercicio5.ps1 -nombre peru, colombia -ttl 30`
- Bash
    - `./ejercicio5.sh --nombre peru, -n colombia -ttl 30`

Muestra la información de Perú y Colombia (buscándolos o desde caché).

Crea o actualiza archivos de caché (e.g., peru_30.json, colombia_30.json).

* * *

## C-06 Archivo de caché expirado (ttl en segundos).

Realizar una busqueda nuevamente del pais "argentina".

Luego ejecutar:

- Powershell
    - `.\ejercicio5.ps1 -nombre argentina -ttl 30`
- Bash
    - `./ejercicio5.sh -n argentina -t 30`

Muestra el mensaje "Archivo local desactualizado".
Mueve el archivo expirado a la carpeta Papelera.

Busca la información desde la web.

Crea un nuevo archivo: argentina_30.json - Powershell
Crea un nuevo archivo: timestamps_argentina_30.json - Bash

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

## E-09 Búsqueda con múltiples coincidencias.

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
    - `.\ejercicio5.ps1 -nombre brasil -ttl 70`
- Bash
    - `./ejercicio5.sh -n brasil -ttl 70`

Falla la ejecución del script (error de validación de parámetros de PowerShell) antes de que comience la ejecución del Main block, debido a \[ValidateRange(1, 60)\].

Falla la ejecución del script (error de validación de parámetros de Bash) antes de que comience la ejecución del Main block, debido a un control de rango permitido en bash.

* * *

## P-11 Omisión del parámetro obligatorio nombre.

- Powershell
    - `.\ejercicio5.ps1 -ttl 2`
- Bash
    - `./ejercicio5.sh -t 2`

PowerShell sugerirá ingresar el nombre del país a buscar, pero si decide presionar 'enter' omitiendo el nombre entonces fallara la ejecución del script (error de validación de parámetros de PowerShell) ya que nombre es Mandatory = $True.

Bash muestra un mensaje de 'Error: Debe especificar una opcion \[-n | --nombre\]", evitando la ejecución del script completo.
