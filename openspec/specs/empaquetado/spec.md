# Empaquetado y distribución

## Purpose

Distribución multiplataforma de la aplicación con identidad visual propia: icono aplicado en Android, Windows y Linux, lanzador de escritorio en GNOME y binarios listos para instalar generados por CI.

## Requirements

### Requirement: Icono de aplicación propio en las tres plataformas

El sistema SHALL contar con un icono de aplicación único y coherente: un cuadrado redondeado con degradado violeta (`#a78bfa` → `#3b1d7a`), brillo superior, una corchea doble blanca y barras de onda de audio. El icono SHALL aplicarse en cada plataforma:

- **Android**: mipmaps `ic_launcher.png` en densidades mdpi (48), hdpi (72), xhdpi (96), xxhdpi (144) y xxxhdpi (192), con el label de launcher `musica`.
- **Windows**: `windows/runner/resources/app_icon.ico` con tamaños múltiples de 16 a 256 px (PNG dentro de ICO).
- **Linux**: el PNG del icono se empaqueta como asset de Flutter (`assets/icon.png`) y el runner GTK lo carga para mostrarlo en la barra de tareas y la cabecera de la ventana.

#### Scenario: Linux muestra el icono en la barra de tareas
- **WHEN** la app se ejecuta en GNU/Linux (X11 o Wayland)
- **THEN** la ventana y la barra de tareas muestran el icono cargado desde `data/flutter_assets/assets/icon.png` del bundle

#### Scenario: Windows muestra el icono en el ejecutable
- **WHEN** se genera el binario de Windows
- **THEN** el icono incrustado en `app_icon.ico` se muestra en el explorador y en el proceso en ejecución

#### Scenario: Android muestra el icono del launcher
- **WHEN** la app se instala desde APK
- **THEN** el launcher muestra el icono en `mipmap-*` con el label `musica`

### Requirement: Lanzador de escritorio GNOME

El sistema SHALL incluir un archivo `packaging/musica.desktop` que registre la app en el escritorio GNOME con nombre **MusiConvert**, icono `musica` (instalado en `hicolor/512x512/apps`) y `StartupWMClass` que coincide con el título de la ventana del runner. El lanzador SHALL poder instalarse copiándolo a `~/.local/share/applications`.

#### Scenario: La app aparece en el grid de aplicaciones
- **WHEN** el usuario instala `musica.desktop` e `hicolor/512x512/apps/musica.png`
- **THEN** la app aparece en el grid de GNOME con el nombre MusiConvert y su icono, y se lanza el binario del bundle

### Requirement: Binarios distribuibles y CI

El sistema SHALL generar binarios distribuibles por plataforma: bundle Linux autónomo en `build/linux/x64/release/bundle/` con las librerías de FFmpeg y media_kit incluidas, APK de Android, y build de Windows con MSVC. La integración continua SHALL verificar el build de Windows en cada push.

#### Scenario: Build de Windows en CI
- **WHEN** se hace push al repositorio
- **THEN** el flujo `.github/workflows/build.yml` compila la app con MSVC y reporta el resultado (o sube los artefactos)

#### Scenario: Bundle Linux autónomo
- **WHEN** el usuario descarga la carpeta `bundle` del release de Linux
- **THEN** ejecuta `./musica` directamente sin instalar dependencias adicionales (las librías de FFmpeg y reproducción van dentro del bundle)