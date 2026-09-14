## ADDED Requirements

### Requirement: Seleccionar fuente de audio

El sistema SHALL permitir al usuario seleccionar una carpeta, memoria USB o unidad como origen de música. En Android SHALL usar Storage Access Framework (persistir el permiso elegido con `takePersistableUriPermission`) para poder acceder a USB-OTG y almacenamiento externo sin requerir permisos globales de almacenamiento. En Windows y Linux SHALL usar las rutas de archivo nativas.

#### Scenario: USB-OTG en Android por primera vez
- **WHEN** el usuario conecta una memoria USB y pulsa "Elegir carpeta"
- **THEN** el sistema abre el selector SAF y guarda el permiso persistente de la USB

#### Scenario: Acceso a USB en sesiones siguientes
- **WHEN** el sistema inicia y existe un permiso SAF persistente
- **THEN** el sistema accede a la USB sin mostrar de nuevo el selector

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