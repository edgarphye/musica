## Why

El bundle Linux distribuible no podía cargar las librerías de FFmpegKit en runtime (`dlopen(libffmpegkit.so)` fallaba) porque el plugin las abre desde su propio `.so` cuyo RUNPATH apunta a un directorio de build inexistente, rompiendo la conversión. Además, el build de Android no compilaba: el código SAF usaba APIs no disponibles en la actividad base y llamadas estáticas a `DocumentsContract` sin calificar.

## What Changes

- **Linux**: el runner GTK precarga las librerías de FFmpegKit con `dlopen(RTLD_NOW | RTLD_GLOBAL)` desde el ejecutable (cuyo RUNPATH es `$ORIGIN/lib`) en orden de dependencias: `libavutil`, `libswresample`, `libswscale`, `libavcodec`, `libavformat`, `libavfilter`, `libavdevice` y `libffmpegkit`. Con esto la conversión funciona en el bundle distribuible y desaparece el warning `dlopen(libffmpegkit.so) failed`.
- **Android**: `MainActivity` pasa a extender `FlutterFragmentActivity` (que sí expone `registerForActivityResult` mediante `ActivityResultContracts`, por ser `ComponentActivity`). El código SAF usa `DocumentsContract.buildChildDocumentsUriUsingTree` / `buildDocumentUriUsingTree` calificadas correctamente y la detección de directorios se resuelve por tipo MIME (`MIME_TYPE_DIR`), sin depender de la constante `FLAG_DIRECTORY` ausente en el `android.jar` del SDK.
- **Código Dart**: `ConversionController` expone campos públicos `filesystem`/`engine` en su constructor para cumplir el lint `prefer_initializing_formals`.

## Capabilities

### New Capabilities
<!-- Capabilities being introduced. Replace <name> with kebab-case identifier (e.g., user-auth, data-export, api-rate-limiting). Each creates specs/<name>/spec.md -->

### Modified Capabilities
- `empaquetado`: el bundle Linux autónomo debe cargar las librerías FFmpeg a runtime con el preload del ejecutable.
- `acceso-archivos`: el acceso SAF en Android usa la actividad base adecuada y resuelve los árboles de documentos de forma compatible con el SDK.

## Impact

- `linux/runner/my_application.cc`: nueva función `preload_ffmpegkit()` llamada antes de `fl_register_plugins`.
- `android/app/src/main/kotlin/com/musica/musica/MainActivity.kt` y `SafHelper.kt`: base de actividad y correcciones de referencias.
- `lib/src/application/conversion_controller.dart`: campos públicos en constructor.
- Sin cambios de dependencias ni de APIs públicas de Dart.