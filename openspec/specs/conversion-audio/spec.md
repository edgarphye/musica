# Conversión de audio

## Purpose

Conversión en el dispositivo de archivos fuente (FLAC, WAV, OGG, etc.) a MP3 y AAC/M4A mediante FFmpeg, con cola secuencial, progreso real, cancelación y políticas de sobrescritura.

## Requirements

### Requirement: Perfiles de conversión MP3, M4A/AAC y MP4

El sistema SHALL ofrecer tres perfiles de salida: **MP3** (codec `libmp3lame`, 192 kbps, tags ID3v2.3), **AAC/M4A** (codec `aac`, 192 kbps, contenedor MP4) y **MP4** (codec `aac`, 192 kbps, contenedor MP4). El comando FFmpeg SHALL preservar metadatos y carátula del archivo original.

#### Scenario: Convertir FLAC a MP3
- **WHEN** el usuario convierte un `album.flac` con perfil MP3
- **THEN** se genera `album.mp3` con códec mp3, bitrate 192 k, metadatos y carátula originales

#### Scenario: Convertir OGG a M4A
- **WHEN** el usuario convierte una canción `cancion.ogg` con perfil M4A/AAC
- **THEN** se genera `cancion.m4a` con códec AAC en contenedor MP4

#### Scenario: Convertir FLAC a MP4
- **WHEN** el usuario convierte una canción `cancion.flac` con perfil MP4
- **THEN** se genera `cancion.mp4` con códec AAC en contenedor MP4

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

## Verificación E2E (Android, 2026-09-15, publicada)

El sistema SHALL quedar verificado en emulador Android (API 36, x86_64, KVM) con el bundle release `app-release.apk` y archivo real `tono.wav` (441 044 B, tono 440 Hz / 5 s), usando el flujo SAF sobre el árbol `Download` con `takePersistableUriPermission`.

#### Scenario: Carga de FFmpegKit en runtime Android
- **WHEN** la app Android inicia con el preload corregido
- **THEN** logcat NO muestra `library_unavailable`; aparece `FFmpegKitFlutterPlugin ... initialised` y la conversión usa el árbol SAF con persistencia (`PUBLISHED ANR` manejado con "Wait")

#### Scenario: Conversión real FLAC/WAV a MP3 en Android
- **WHEN** el usuario convierte `tono.wav` con perfil MP3
- **THEN** se genera `tono_copy.mp3` (57 370 B) con 205 frames MP3 con sync `0xFFE` válidos, duración ≈ 5,36 s (refleja el tono de 5 s), mediante `FFmpegKit.startAsync` completada en ~105 ms
