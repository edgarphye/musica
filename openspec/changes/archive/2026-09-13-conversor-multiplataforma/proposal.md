# Cambio: conversor-multiplataforma

## Why

Los usuarios tienen colecciones de música en formatos pesados (FLAC, WAV, OGG, etc.) almacenadas en memorias USB que no se reproducen bien en tablets, laptops y PCs. No existe una solución simple, offline y multiplataforma que convierta esos archivos a MP3/AAC/M4A directamente en el dispositivo y permita escucharlos.

## What Changes

- Nueva aplicación Flutter multiplataforma que compila en **Android (tablets)**, **Windows** y **Linux (laptops/PCs)** con una sola base de código.
- **Conversión 100 % en el dispositivo**: FFmpeg embebido vía `ffmpeg_kit_flutter_new_audio`. Sin internet ni servidores.
- Entrada: cualquier carpeta/USB con audio (FLAC, WAV, OGG, WMA, AIFF, APE, M4A, MP3...). Acceso vía SAF en Android y `dart:io` en Windows/Linux.
- Salida: **MP3** (libmp3lame, 192 kbps por defecto) y **AAC/M4A** (aac, 192 kbps), preservando metadatos y carátula.
- Cola de conversión en lote con **progreso real por archivo** (FFprobe + callbacks de FFmpegKit), cancelación individual/global y registro de errores.
- **Reproducción simple** de la biblioteca convertida (`just_audio` + `just_audio_media_kit`).
- Interfaz responsive en español (inicio, conversión, biblioteca + reproductor), adaptable a tablet y desktop.
- Pipeline CI (GitHub Actions) que produce el binario **Windows con MSVC** (Visual Studio), además de Android APK y Linux.

## Capabilities

### New Capabilities
- `acceso-archivos`: Abstracción de sistema de archivos (FilesystemGateway) con implementación SAF (Android, incluye USB-OTG con permiso persistente) y `dart:io` (Windows/Linux); escaneo recursivo por extensiones de audio.
- `conversion-audio`: Motor de conversión: comandos FFmpeg (perfiles MP3 y M4A/AAC), detección de duración vía FFprobe, cola de trabajos con progreso, cancelación, salto/sobrescritura y registro de errores.
- `reproduccion`: Biblioteca de archivos convertidos + reproductor simple (play/pause, siguiente/anterior, seek, carátula).
- `ui-responsive`: Navegación adaptable (NavigationRail en pantallas anchas, barra inferior/lista en tablets), flujo inicio → conversión → biblioteca.

### Modified Capabilities
(Vacío: no hay specs previas.)

## Impact

- **Código**: nuevo proyecto Flutter bajo `/home/ephye/Documentos/musica` (`lib/`, `android/`, `windows/`, `linux/`). Arquitectura por capas: presentación (Riverpod), aplicación (casos de uso), dominio (entidades) y datos (gateways).
- **Dependencias nuevas**: `ffmpeg_kit_flutter_new_audio`, `just_audio`, `just_audio_media_kit`, `media_kit_libs_linux`, `media_kit_libs_windows_audio`, `flutter_riverpod`, `file_picker`, `path`, `path_provider`.
- **Build**: Linux local (compilable aquí); Android APK firmado; Windows requiere MSVC (Visual Studio) → CI GitHub Actions con runner `windows-latest`. FFmpeg prebuilt se descarga en build time en Windows/Linux.
- **Reproducción**: `just_audio` nativo en Android; `just_audio_media_kit` (media_kit) en Windows/Linux.
- **Sin cambios en** specs OpenSpec existentes (proyecto nuevo).