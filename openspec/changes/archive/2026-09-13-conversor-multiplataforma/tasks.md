## 1. Setup del proyecto

- [x] 1.1 Proyecto Flutter creado con plataformas android/windows/linux
- [x] 1.2 Dependencias añadidas (ffmpeg_kit_flutter_new_audio, just_audio, just_audio_media_kit, media_kit libs, flutter_riverpod, file_picker, path, path_provider)
- [x] 1.3 Descripción y metadatos de la app actualizados (pubspec/AndroidManifest: nombre, permisos)

## 2. Núcleo (dominio + datos)

- [x] 2.1 Entidades de dominio: AudioFile, ConversionJob, ConversionProfile, JobStatus (pending/converting/done/error/cancelled/skipped)
- [x] 2.2 Interfaz FilesystemGateway con setup de selección origen/destino, escaneo recursivo y resolución de archivos
- [x] 2.3 Implementación AndroidFilesystem con SAF (ACTION_OPEN_DOCUMENT_TREE + takePersistableUriPermission) y soporte de URIs para FFmpeg
- [x] 2.4 Implementación DesktopFilesystem con dart:io (rutas nativas Windows/Linux)
- [x] 2.5 Builder de comandos FFmpeg: perfiles MP3 (libmp3lame 192k, ID3v2.3) y M4A/AAC; conserva metadatos/carátula; salto/sobrescritura/renombre
- [x] 2.6 Pruebas unitarias: escáner por extensiones, builder de comandos (args exactos), lógica de sobrescritura

## 3. Motor de conversión

- [x] 3.1 FfmpegEngine: FFprobe para duración + ejecución con callbacks de estadísticas y cancelación
- [x] 3.2 Cola de conversión (caso de uso): procesa secuencialmente, actualiza estados por archivo, reporta totales
- [x] 3.3 Cancelación individual/global con descarte del archivo parcial
- [x] 3.4 Registro de errores por archivo y continuidad de la cola
- [x] 3.5 Pruebas unitarias de la maquinaria de cola (estados y políticas) con engine fake

## 4. Reproductor y biblioteca

- [x] 4.1 Servicio de reproducción (just_audio + just_audio_media_kit) con play/pause/next/prev/seek
- [x] 4.2 Biblioteca: listar canciones convertidas con metadatos (título/duración/carátula cuando exista)

## 5. UI responsive

- [x] 5.1 Navegación adaptable: NavigationRail (>=900px) / barra o lista compacta (tablet), idioma español
- [x] 5.2 Pantalla Inicio: elegir origen, destino y perfil MP3/M4A
- [x] 5.3 Pantalla Conversión: revisar cola, iniciar, ver progreso por archivo y agregado, cancelar
- [x] 5.4 Pantalla Biblioteca: lista de canciones + barra de reproductor; inicializar media_kit en main()
- [x] 5.5 Provider Riverpod que conecta UI con casos de uso

## 6. Pruebas y build

- [x] 6.1 `flutter analyze` sin errores
- [x] 6.2 `flutter test` verde
- [x] 6.3 `flutter build linux` exitoso en este equipo
- [x] 6.4 Workflow CI: job Windows (MSVC via windows-latest), job Android APK, job Linux bundle, artifact upload

## 7. Despliegue y documentación

- [x] 7.1 Instrucciones de build/instalación por plataforma (README)
- [x] 7.2 Archivar el cambio OpenSpec (opsx-archive) y sincronizar specs principales