## 1. Linux: carga de FFmpegKit en el bundle

- [x] 1.1 Añadir `#include <dlfcn.h>` y la función `preload_ffmpegkit()` en `linux/runner/my_application.cc`
- [x] 1.2 Preload con `dlopen(RTLD_NOW | RTLD_GLOBAL)` en orden de dependencias (avutil → swresample → swscale → avcodec → avformat → avfilter → avdevice → ffmpegkit)
- [x] 1.3 Llamar `preload_ffmpegkit()` antes de `fl_register_plugins` en `my_application_activate`
- [x] 1.4 Verificar en runtime: sin warning `dlopen(libffmpegkit.so) failed` y log "Loaded ffmpeg-kit" en el bundle de release

## 2. Android: actividad y SAF compilables

- [x] 2.1 Cambiar `MainActivity` de `FlutterActivity` a `FlutterFragmentActivity` para disponer de `registerForActivityResult`
- [x] 2.2 Calificar llamadas estáticas de `DocumentsContract` (`buildChildDocumentsUriUsingTree`, `buildDocumentUriUsingTree`) en `SafHelper.kt`
- [x] 2.3 Detectar directorios por `MIME_TYPE_DIR` en lugar de la constante `FLAG_DIRECTORY` ausente en el SDK
- [x] 2.4 Verificar que `flutter build apk --release` compila (APK ~134 MB)

## 3. Dart: lint y sanidad general

- [x] 3.1 Exponer campos públicos `filesystem`/`engine` en el constructor de `ConversionController` (cumple `prefer_initializing_formals`)
- [x] 3.2 Verificar `flutter analyze` sin issues
- [x] 3.3 Verificar `flutter test` en verde (19 tests)
- [x] 3.4 Verificar `flutter build linux --release` tras los cambios
- [x] 3.5 Commit de los cambios (795706b)