# Acceso a archivos

## Purpose

Acceso multiplataforma a la música en memorias USB/carpetas: selección de origen y destino, escaneo recursivo y resolución de rutas (SAF en Android, rutas nativas en Windows/Linux).

## Requirements

### Requirement: Seleccionar fuente de audio

El sistema SHALL permitir al usuario seleccionar una carpeta, memoria USB o unidad como origen de música. En Android SHALL usar Storage Access Framework (persistir el permiso elegido con `takePersistableUriPermission`) para poder acceder a USB-OTG y almacenamiento externo sin requerir permisos globales de almacenamiento. En Windows y Linux SHALL usar las rutas de archivo nativas. Para usar los contratos de resultados de actividad en Android, la actividad SHALL extender `FlutterFragmentActivity` (que provee `registerForActivityResult` con `ActivityResultContracts`); los usos de `DocumentsContract` SHALL estar calificados con su clase y la detección de directorios SHALL resolverse por el tipo MIME de documento (`vnd.android.document/directory`).

#### Scenario: USB-OTG en Android por primera vez
- **WHEN** el usuario conecta una memoria USB y pulsa "Elegir carpeta"
- **THEN** el sistema abre el selector SAF y guarda el permiso persistente de la USB

#### Scenario: Acceso a USB en sesiones siguientes
- **WHEN** el sistema inicia y existe un permiso SAF persistente
- **THEN** el sistema accede a la USB sin mostrar de nuevo el selector

#### Scenario: Navegar por el árbol SAF en Android
- **WHEN** el usuario explora el contenido de un árbol SAF elegido
- **THEN** el sistema lista los documentos con `DocumentsContract.buildChildDocumentsUriUsingTree`/`buildDocumentUriUsingTree` y marca como directorio los documentos con MIME `vnd.android.document/directory`

#### Scenario: Selección de carpeta en Windows/Linux
- **WHEN** el usuario pulsa "Elegir carpeta" en Windows o Linux
- **THEN** el sistema abre el selector nativo de directorio y guarda la ruta

### Requirement: Escanear archivos de audio

El sistema SHALL escanear de forma recursiva la carpeta seleccionada y descubrir archivos de audio por su extensión (FLAC, WAV, OGG, WMA, AIFF, APE, M4A, MP3 y otros soportados por FFmpeg). El escaneo SHALL reportar el total de canciones encontradas y responder a la cancelación.

#### Scenario: Carpeta con archivos en subcarpetas
- **WHEN** la carpeta origen contiene canciones en subcarpetas anidadas
- **THEN** el sistema las incluye todas en el listado, preservando su estructura relativa

#### Scenario: Directorio sin música
- **WHEN** la carpeta seleccionada no contiene archivos de audio
- **THEN** el sistema muestra un mensaje "No se encontraron canciones" y permite elegir otra carpeta

### Requirement: Elegir carpeta de destino

El sistema SHALL permitir elegir la carpeta donde se guardarán los archivos convertidos y SHALL ofrecer una carpeta por defecto en el directorio de música del dispositivo. En Android SHALL usar SAF; en Windows/Linux rutas nativas.

#### Scenario: Convertir con carpeta de destino por defecto
- **WHEN** el usuario inicia una conversión sin elegir destino
- **THEN** el sistema crea una carpeta de salida (ej. `Musica/Convertidos`) y escribe allí los resultados
## Verificación E2E (Android SAF, 2026-09-15, publicada)

El flujo SAF completo SHALL quedar verificado en emulador (API 36) con el árbol persistente `Download` (`ACTION_OPEN_DOCUMENT_TREE` + `USE THIS FOLDER`), sin usar la raíz del almacenamiento (que SAF rechaza por privacidad).

#### Scenario: Elegir el árbol Download y conservar el permiso
- **WHEN** el usuario pulsa "USAR ESTA CARPETA" sobre `Download` en el selector DocumentsUI
- **THEN** el sistema recibe el `Uri` del árbol, solicita `takePersistableUriPermission` y navega a su interior mostrando `tono.wav` (TREE) sin volver a pedir permiso

#### Scenario: SAF rechaza la raíz del almacenamiento
- **WHEN** el usuario intenta usar la raíz de `/storage/emulated/0` como árbol
- **THEN** DocumentsUI muestra "Can't use this folder / To protect your privacy, choose another folder" y no concede el permiso
