# UI responsive

## Purpose

Interfaz en español que se adapta a tablet y desktop, con un flujo guiado de conversión y reproducción.

## Requirements

### Requirement: Navegación adaptable a tablet y desktop

El sistema SHALL presentar una interfaz en español que se adapte al ancho: con `NavigationRail` en pantallas anchas (desktop) y barra de navegación/lista compacta en pantallas de tablet. El sistema SHALL mostrar cuatro secciones: **Inicio**, **Conversión**, **Biblioteca** y **Acerca de**.

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

### Requirement: Sección Acerca de con datos del autor

El sistema SHALL incluir una sección **Acerca de** (accesible desde la navegación en desktop y tablet) que muestre el nombre de la app, su versión y los datos del autor: nombre (**Edgar Phye Parga**), profesión (**Ingeniero en Desarrollo de Software**), **correo electrónico** (**ephye7214@gmail.com**) y **fecha y hora de creación** de la aplicación.

#### Scenario: Consultar datos del autor
- **WHEN** el usuario abre la sección "Acerca de"
- **THEN** se muestra MusiConvert (versión 1.0.0), el nombre del autor, su profesión, su correo electrónico y la fecha/hora de creación de la app

### Requirement: Tres diseños de ventana (temas) con selector

El sistema SHALL ofrecer cuatro temas elegantes y profesionales seleccionables desde la sección **Acerca de** mediante tarjetas con vista previa:

- **Lavanda**: claro, luminoso y fresco (semilla `#6750A4`, fondo `#F5F3FB`, tarjetas blancas).
- **Onyx**: oscuro, sobrio y sofisticado (semilla `#8B7CF6`, fondo `#0D0F1E`, tarjetas `#171A2E` con borde).
- **Esmeralda**: oscuro, natural y moderno (semilla `#2DD4A0`, fondo `#0B130F`, tarjetas `#12201A` con borde).
- **Vino**: oscuro, intenso y refinado (semilla `#E04D69`, fondo `#160810`, tarjetas `#241018` con borde `#3B1D29`).

El tema seleccionado SHALL persistirse entre sesiones y aplicarse a toda la app (navegación, tarjetas, campos y paneles).

#### Scenario: Cambiar el diseño de ventana
- **WHEN** el usuario elige el tema "Vino" en Acerca de
- **THEN** toda la interfaz pasa al diseño oscuro vino al instante y la selección se guarda

#### Scenario: El tema elegido se recuerda al reiniciar
- **WHEN** el usuario cierra la app con el tema "Lavanda" y la vuelve a abrir
- **THEN** la app inicia con "Lavanda" aplicado

### Requirement: Cerrar la aplicación desde la interfaz

El sistema SHALL ofrecer un botón para **cerrar la aplicación** accesible desde la sección **Acerca de** (todas las pantallas) y desde el panel lateral en desktop. En escritorio (Windows/Linux) SHALL finalizar el proceso; en Android SHALL cerrar la actividad.

#### Scenario: Cerrar desde el panel lateral
- **WHEN** el usuario pulsa el botón de encendido al final del panel lateral en desktop
- **THEN** la aplicación se cierra por completo

#### Scenario: Cerrar desde Acerca de
- **WHEN** el usuario pulsa "Cerrar la aplicación" en Acerca de
- **THEN** la aplicación finaliza de inmediato en todas las plataformas