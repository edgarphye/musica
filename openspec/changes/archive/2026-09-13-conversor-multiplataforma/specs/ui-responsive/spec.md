## ADDED Requirements

### Requirement: Navegación adaptable a tablet y desktop

El sistema SHALL presentar una interfaz en español que se adapte al ancho: con `NavigationRail` en pantallas anchas (desktop) y barra de navegación/lista compacta en pantallas de tablet. El sistema SHALL mostrar tres secciones: **Inicio**, **Conversión** y **Biblioteca**.

#### Scenario: Uso en desktop
- **WHEN** la app corre en un PC/laptop con pantalla ≥ 900 px de ancho
- **THEN** muestra un panel de navegación lateral persistente con las tres secciones

#### Scenario: Uso en tablet
- **WHEN** la app corre en una tablet (ancho < 900 px)
- **THEN** muestra navegación compacta (barra inferior o lista colapsable) con las mismas tres secciones

### Requirement: Flujo guiado de conversión

El sistema SHALL guiar al usuario en secciones: **Inicio** para elegir origen/destino y perfil, **Conversión** para revisar la cola, iniciar/pausar y ver progreso, y **Biblioteca** para reproducir los resultados.

#### Scenario: Primer uso completo
- **WHEN** un usuario nuevo abre la app
- **THEN** la sección Inicio le pide elegir la carpeta de música y el perfil de salida antes de pasar a Conversión