## Context

El cambio arregla dos problemas que impedían distribuir la app en las tres plataformas:

1. **Linux/FFmpegKit**: el plugin `ffmpeg_kit_flutter_new_audio` ejecuta `dlopen("libffmpegkit.so")` desde su propio `.so`, cuyo RUNPATH apunta a `/home/ephye/Documentos/musica/linux/flutter/ephemeral` (directorio de build inexistente en runtime). El ejecutable del bundle tiene RUNPATH `$ORIGIN/lib` y contiene las librerías `libav*`, `libsw*` y `libffmpegkit.so`, pero un RUNPATH no es transitivo: la resolución del simbolo dinámico del plugin no llega a `$ORIGIN/lib`. Sin fix, `dlopen` falla y el plugin responde `library_unavailable` a las operaciones de conversión.

2. **Android/SAF**: el build de Android no compilaba. `MainActivity` extendía `FlutterActivity` (que extiende `android.app.Activity`, sin `registerForActivityResult`), el canal SAF usaba llamadas estáticas a `DocumentsContract` sin calificar, y la detección de directorios dependía de la constante `FLAG_DIRECTORY` que no está presente en el `android.jar` del SDK instalado.

## Goals / Non-Goals

**Goals:**
- Que el bundle Linux distribuible cargue FFmpegKit en runtime y la conversión funcione sin warnings.
- Que el APK de Android compile y la selección/exploración de árboles SAF funcione.
- Dejar `flutter analyze` y `flutter test` limpios.

**Non-Goals:**
- Rediseñar el canal SAF ni migrar a otra librería de FFmpeg (p. ej. media_kit para conversión).
- Soporte de tienda o firma de release de Android (se sigue firmando con debug keys).

## Decisions

- **Precargar las librerías desde el ejecutable antes de registrar plugins** (`preload_ffmpegkit()` en `my_application.cc`): se `dlopen(RTLD_NOW | RTLD_GLOBAL)` en orden topológico `libavutil` → `libswresample` → `libswscale` → `libavcodec` → `libavformat` → `libavfilter` → `libavdevice` → `libffmpegkit`. Alternativas descartadas: parchear el RUNPATH del `.so` del plugin (no es mantenible ni portable) y copiar las librerías junto al ejecutable sin preload (no resuelve el dlopen interno del plugin).
- **`MainActivity` extiende `FlutterFragmentActivity`**: es una `ComponentActivity`, por lo que `registerForActivityResult(ActivityResultContracts.StartActivityForResult())` está disponible. Alternativa descartada: `startActivityForResult`/`onActivityResult` (deprecated y requiere gestionar código de request). El embedding de Flutter ya incluye `androidx.fragment` transitivamente.
- **Detección de directorios por MIME** (`mime == vnd.android.document/directory`): el `android.jar` de los SDK 35/36 instalados no expone `DocumentsContract.Document.FLAG_DIRECTORY`, así que el contrato SAF se resuelve por `MIME_TYPE_DIR`, que sí está disponible y es el mecanismo canónico para identificar documentos-directorio.
- **Campos públicos en `ConversionController`** (`required this.filesystem`/`this.engine`): cumple `prefer_initializing_formals` sin tocar los call sites (`providers.dart` y los 10 de tests ya usaban nombres públicos).

## Risks / Trade-offs

- [Orden de carga de FFmpegKit incorrecto en otras plataformas] → Mitigación: se carga en orden de dependencias explícito y verificado en runtime; si una lib falta solo avisa con `g_warning` sin abortar el arranque.
- [Detectar directorios por MIME y no por flags] → Mitigación: `MIME_TYPE_DIR` es el identificador canónico de documentos-directorio según el contrato de `DocumentsContract`; la mayoría de providers lo establecen.
- [`FlutterFragmentActivity` supone un cambio de embedding] → Mitigación: es el embedding alternativo oficial de Flutter, con el que plugin y canal SAF conviven sin cambios en el manifest.
- [Build APK lento (~74 s) por primer build con NDK] → Mitigación: incremental después del primer build.