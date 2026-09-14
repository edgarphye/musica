# MusiConvert

Conversor y reproductor de audio **multiplataforma** que convierte música de una memoria USB (FLAC, WAV, OGG, OPUS, APE, etc.) a formatos compatibles con cualquier tablet, portátil o PC: **MP3** (libmp3lame 192 kbps) y **AAC / M4A** (aac, faststart).

- Conversión 100 % local con FFmpeg: **nada se sube a la nube**.
- Conserva metadatos e información de la carátula (`-map_metadata 0`).
- Reproduce y busca la música directamente desde el USB (barra de reproductor persistente).
- Interfaz adaptativa en español: `NavigationRail` en pantallas anchas, barra compacta en tablets.
- Plataformas: **Android** (tablets), **Windows** (MSVC) y **Linux**.

## Requisitos

- Flutter SDK **3.44+** (estable).
- Android: JDK 21 + Android SDK (platform 36, build-tools 36).
- Windows: Visual Studio 2022 con la carga de trabajo *Desktop development with C++* (provee MSVC).
- Linux: deps del sistema (Debian/Ubuntu):

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
  libstdc++-12-dev libjson-glib-dev
```

## Compilar y ejecutar

### Android (tablet)

```bash
flutter build apk --release
# instalación directa en el dispositivo por USB
flutter install --release
```

> En Android el origen/destino se elige vía **Storage Access Framework** (`ACTION_OPEN_DOCUMENT_TREE`), pensado para memorias USB-OTG; no se usa permiso de almacenamiento amplio.

### Windows (MSVC)

```bash
flutter config --enable-windows-desktop
flutter build windows --release
```

El ejecutable queda en `build/windows/x64/runner/Release/`.

### Linux

```bash
flutter build linux --release
```

El bundle relocable queda en `build/linux/x64/release/bundle/` (ejecuta `./musica`).

## Integración continua

El workflow `.github/workflows/build.yml` compila y sube artefactos para:

1. **Windows (MSVC)** en `windows-latest` (VS2022).
2. **Android APK** en `ubuntu-latest` (JDK 21).
3. **Bundle de Linux** en `ubuntu-latest`.

## Arquitectura

- `lib/src/domain/` — modelos (`AudioFile`, `ConversionJob`, `ConversionProfile`).
- `lib/src/infra/` — `FilesystemGateway` (desktop con `dart:io`, Android con SAF) y `FfmpegEngine`.
- `lib/src/application/` — `ConversionController` (cola) y `PlayerController` (just_audio / just_audio_media_kit).
- `lib/src/ui/` — UI Riverpod (`browse_page`, `convert_page`, `recent_page`, `player_bar`).

## Pruebas

```bash
flutter analyze
flutter test
```