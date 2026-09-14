# Conversión de audio

## Purpose

Conversión en el dispositivo de archivos fuente (FLAC, WAV, OGG, etc.) a MP3 y AAC/M4A mediante FFmpeg, con cola secuencial, progreso real, cancelación y políticas de sobrescritura.

## Requirements

### Requirement: Perfiles de conversión MP3 y M4A/AAC

El sistema SHALL ofrecer dos perfiles de salida: **MP3** (codec `libmp3lame`, 192 kbps, tags ID3v2.3) y **AAC/M4A** (codec `aac`, 192 kbps, contenedor MP4). El comando FFmpeg SHALL preservar metadatos y carátula del archivo original.

#### Scenario: Convertir FLAC a MP3
- **WHEN** el usuario convierte un `album.flac` con perfil MP3
- **THEN** se genera `album.mp3` con códec mp3, bitrate 192 k, metadatos y carátula originales

#### Scenario: Convertir OGG a M4A
- **WHEN** el usuario convierte una canción `cancion.ogg` con perfil M4A/AAC
- **THEN** se genera `cancion.m4a` con códec AAC en contenedor MP4

### Requirement: Cola de conversión en lote

El sistema SHALL procesar los archivos seleccionados en una cola, uno tras otro, mostrando estado por archivo (pendiente, convirtiendo, completado, error, cancelado). El sistema SHALL detectar la duración de cada archivo con FFprobe para calcular el **porcentaje de progreso real** vía callbacks de estadísticas de FFmpegKit.

#### Scenario: Conversión de muchos archivos
- **WHEN** el usuario convierte 200 canciones
- **THEN** el sistema las procesa secuencialmente mostrando progreso agregado y por archivo, y al final reporta totales de completados/con errores

#### Scenario: Progreso real por archivo
- **WHEN** un archivo está convirtiéndose
- **THEN** la barra de progreso avanza según el tiempo procesado sobre la duración total del archivo

### Requirement: Cancelación y manejo de errores

El sistema SHALL permitir cancelar un solo archivo o toda la cola, sin corromper el archivo de salida parcial (descartándolo). El sistema SHALL registrar los errores individuales y continuar con el siguiente archivo.

#### Scenario: Cancelar la cola
- **WHEN** el usuario pulsa "Cancelar todo" durante una cola activa
- **THEN** el trabajo en curso se aborta, el archivo parcial se elimina y los pendientes pasan a "cancelado"

#### Scenario: Archivo con error
- **WHEN** un archivo de origen está dañado y FFmpeg falla
- **THEN** el sistema marca ese archivo como "error", muestra el motivo y continúa con el siguiente

### Requirement: Política de sobrescritura

El sistema SHALL ofrecer política de sobrescritura: reemplazar el destino si ya existe, saltarlo (marcándolo como "omitido") o renombrar con sufijo numérico.

#### Scenario: Destino ya existe con política saltar
- **WHEN** un archivo convertido ya existe en el destino y la política es "saltar"
- **THEN** el sistema no lo re-convierte y lo marca como "omitido"