## MODIFIED Requirements

### Requirement: Binarios distribuibles y CI

El sistema SHALL generar binarios distribuibles por plataforma: bundle Linux autónomo en `build/linux/x64/release/bundle/` con las librerías de FFmpeg y media_kit incluidas, APK de Android, y build de Windows con MSVC. La integración continua SHALL verificar el build de Windows en cada push. En Linux el ejecutable SHALL precargar las librerías de FFmpegKit con `dlopen(RTLD_NOW | RTLD_GLOBAL)` antes de registrar los plugins, ya que el plugin las abre desde su propio `.so` cuyo RUNPATH apunta a un directorio de build inexistente en runtime; el preload se hace desde el ejecutable, cuyo RUNPATH es `$ORIGIN/lib`, en orden de dependencias (ffmpegkit → avdevice → avfilter → avformat → avcodec → swscale → swresample → avutil).

#### Scenario: Bundle Linux autónomo

- **WHEN** el usuario descarga la carpeta `bundle` del release de Linux
- **THEN** ejecuta `./musica` directamente sin instalar dependencias adicionales (las librías de FFmpeg y reproducción van dentro del bundle)

#### Scenario: Bundle Linux carga FFmpegKit sin errores en runtime

- **WHEN** la app se lanza desde el bundle Linux distribuible
- **THEN** el ejecutable precarga `libffmpegkit.so` y sus dependencias desde `$ORIGIN/lib` y el plugin las resuelve, sin el warning `dlopen(libffmpegkit.so) failed` y sin errores `library_unavailable` en las operaciones de conversión

#### Scenario: Build de Windows en CI

- **WHEN** se hace push al repositorio
- **THEN** el flujo `.github/workflows/build.yml` compila la app con MSVC y reporta el resultado (o sube los artefactos)