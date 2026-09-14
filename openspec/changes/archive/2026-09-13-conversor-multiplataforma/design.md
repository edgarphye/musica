## Context

Proyecto nuevo (greenfield) en `/home/ephye/Documentos/musica`. Objetivo: app Flutter que convierte música local (memoria USB / carpetas) a MP3 y M4A/AAC de forma 100 % offline y la reproduce, corriendo en **Android (tablets)**, **Windows** y **Linux** con una sola base de código. Entorno de desarrollo: Debian 13 x86_64 (Flutter 3.47.4, Android SDK 36, Linux desktop disponible). El binario Windows requiere MSVC, se genera en CI.

## Goals / Non-Goals

**Goals:**
- Arquitectura por capas (presentación / aplicación / dominio / datos) con Clean Architecture liviana.
- Abstracción de acceso a archivos que oculte la diferencia Android (SAF) vs Windows/Linux (`dart:io`).
- Motor de conversión con FFmpeg embebido, cola, progreso real y cancelación.
- Reproductor simple compartiendo API de `just_audio` en las tres plataformas.
- UI responsive (NavigationRail en desktop, compacta en tablet), en español, con Riverpod.
- Pipeline CI que compila Windows con MSVC + APK Android + Linux.

**Non-Goals:**
- No hay descargas desde servicios de streaming.
- No hay backend ni nube.
- No se convierte video.
- Fuera de alcance: ecualizador, playlists complejas, transcodificación streaming.

## Decisions

### D1. Flutter como única base multiplataforma
Un solo código Dart compila a nativo para Android, Windows y Linux. Alternativas descartadas: React Native (desktop débil) y PWA/Electron (conversión limitada en navegador, no nativa en tablet).

### D2. FFmpeg embebido vía `ffmpeg_kit_flutter_new_audio`
Fork mantenido de FFmpegKit (FFmpeg 8.1.2) con variante **audio** (más pequeña que `full`). Incluye `libmp3lame` (MP3) y encoder AAC nativo; soporta Android, Windows y Linux x86_64 (binarios prebuilt descargados en build time). Alternativa considerada: `ffmpeg_kit_flutter_new_full` (más pesada, innecesaria). Si el fork dejara de publicar, la API es idéntica a la original y el cambio sería de dependencia.

### D3. Abstracción FilesystemGateway
Interfaz `FilesystemGateway` con dos implementaciones:
- `AndroidFilesystem` → SAF: `ACTION_OPEN_DOCUMENT_TREE` + `takePersistableUriPermission`, resolución de URIs a rutas temporales/`content://` para FFmpeg (el fork soporta SAF directamente).
- `DesktopFilesystem` (`dart:io`) → rutas nativas en Windows/Linux.
Se resuelve por plataforma (inversión de dependencias en tiempo de compilación, no parches por `.dart.library.io` en caliente).

### D4. Reproducción: `just_audio` + `just_audio_media_kit`
`just_audio` usa su implementación nativa en Android; en Windows/Linux la implementación la aporta `just_audio_media_kit` (basado en `media_kit`/mpv) con `media_kit_libs_windows_audio` y `media_kit_libs_linux`. La UI depende solo de la API de `just_audio`.

### D5. Cola de conversión con progreso real
Se usa FFprobe para obtener duración; por sesión FFmpeg se registran callbacks de estadísticas (`FFmpegKitConfig.enableStatisticsCallback`) y el progreso de cada archivo = `time / duration`. Modelo de estados por archivo: pendiente, convirtiendo, completo, error, cancelado, omitido. Cancelación vía `session.cancel()`; el archivo parcial se elimina.

### D6. Manejo de estado con Riverpod (v3)
Providers tipados por capa: `filesystemProvider`, `conversionQueueProvider` (cola + progreso), `libraryProvider`, `playerProvider`. UI como observadora pura.

### D7. Estructura de proyecto
```
lib/
  main.dart
  src/
    domain/          # entidades y puertos (AudioFile, ConversionJob, ConversionProfile, FilesystemGateway)
    application/     # casos de uso (scanSource, convertQueue, cancelQueue, loadLibrary)
    infra/           # AndroidFilesystem, DesktopFilesystem, FfmpegEngine, MediaKitPlayer
    ui/              # pages (home/convert/library) + widgets (queue list, player bar) + providers
```

### D8. CI para MSVC (Windows)
Workflow GitHub Actions con `windows-latest` (VS2022 + MSVC ya preinstalado): `flutter pub get` → `flutter test` → `flutter build windows --release` → artefacto `.zip` del bundle. Además jobs para APK (Linux runner) y Linux bundle en CI. Localmente, Linux se compila en este equipo.

## Risks / Trade-offs

- [FFmpeg embebido = APK grande] → Mitigación: usar variante `_audio` (no `_full`/video).
- [Windows no compilable desde Linux (MSVC)] → Mitigación: CI con runner `windows-latest`; artefacto descargable.
- [USB-OTG y SAF en Android] → Mitigación: `takePersistableUriPermission` + clara UI de error si se revoca el permiso.
- [Fork de FFmpegKit con soporte comunitario] → Mitigación: API estable y conocida; fácil migración de dependencia.
- [media_kit/mpv como librería dinámica] → Mitigación: distribuir bundles con las libs (política estándar de Flutter desktop).