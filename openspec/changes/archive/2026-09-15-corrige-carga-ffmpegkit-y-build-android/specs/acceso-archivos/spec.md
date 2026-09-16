## MODIFIED Requirements

### Requirement: Seleccionar fuente de audio

El sistema SHALL permitir al usuario seleccionar una carpeta, memoria USB o unidad como origen de música. En Android SHALL usar Storage Access Framework (persistir el permiso elegido con `takePersistableUriPermission`) para poder acceder a USB-OTG y almacenamiento externo sin requerir permisos globales de almacenamiento. En Windows y Linux SHALL usar las rutas de archivo nativas. Para usar los contratos de resultados de actividad en Android, la actividad SHALL extender `FlutterFragmentActivity` (que provee `registerForActivityResult` con `ActivityResultContracts`); los usos de `DocumentsContract` SHALL estar calificados con su clase y la detección de directorios SHALL resolverse por el tipo MIME de documento (`vnd.android.document/directory`).

#### Scenario: USB-OTG en Android por primera vez

- **WHEN** el usuario conecta una memoria USB y pulsa "Elegir carpeta"
- **THEN** el sistema abre el selector SAF guardando el permiso persistente de la USB

#### Scenario: Acceso a USB en sesiones siguientes

- **WHEN** el sistema inicia y existe un permiso SAF persistente
- **THEN** el sistema accede a la USB sin mostrar de nuevo el selector

#### Scenario: Navegar por el árbol SAF en Android

- **WHEN** el usuario explora el contenido de un árbol SAF elegido
- **THEN** el sistema lista los documentos con `DocumentsContract.buildChildDocumentsUriUsingTree`/`buildDocumentUriUsingTree` y marca como directorio los documentos con MIME `vnd.android.document/directory`

#### Scenario: Selección de carpeta en Windows/Linux

- **WHEN** el usuario pulsa "Elegir carpeta" en Windows o Linux
- **THEN** el sistema abre el selector nativo de directorio y guarda la ruta