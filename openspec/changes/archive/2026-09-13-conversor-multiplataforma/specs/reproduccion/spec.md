## ADDED Requirements

### Requirement: Biblioteca de canciones convertidas

El sistema SHALL listar los archivos de audio de la carpeta de destino (biblioteca), agrupados opcionalmente por álbum/carpeta, con metadatos accesibles (título, artista, duración, carátula) cuando estén disponibles.

#### Scenario: Abrir biblioteca tras una conversión
- **WHEN** el usuario termina una conversión y abre "Biblioteca"
- **THEN** el sistema muestra las canciones convertidas con su carátula, título y duración

### Requirement: Reproductor con controles básicos

El sistema SHALL reproducir una canción de la biblioteca con controles de play/pause, anterior/siguiente, barra de búsqueda (seek) y nombre/carátula de la canción actual. SHALL reproducirse MP3 y M4A en Android (just_audio nativo) y en Windows/Linux (just_audio_media_kit sobre media_kit).

#### Scenario: Reproducir una canción
- **WHEN** el usuario pulsa una canción de la biblioteca
- **THEN** el reproductor carga el archivo y la reproduce, mostrando posición y duración

#### Scenario: Siguiente canción
- **WHEN** el usuario pulsa "siguiente"
- **THEN** el reproductor pasa a la siguiente canción de la biblioteca manteniendo la lista