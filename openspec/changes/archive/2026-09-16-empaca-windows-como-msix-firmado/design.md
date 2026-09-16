# Empaca Windows como MSIX firmado — Design

## Goals

- Producir un paquete MSIX instalable y firmado para Windows 10/11 desde el CI, publicado como artefacto descargable.
- Mantener el exe suelto (compat) Y añadir el MSIX (instalador limpio): el workflow `windows-msvc` genera ambos.

## Context / Assumptions

- El job actual `windows-msvc` ya compila con MSVC (Visual Studio 2022 preinstalado en `windows-latest`) y sube `Release/` como artefacto. Ahí mismo están disponibles `makeappx.exe`, `signTool.exe` y `makepri.exe` (Windows SDK, `C:\Program Files (x86)\Windows Kits\10\bin\<ver>\x64\`).
- La app Flutter Windows ya tiene icono (ICO) y nombre `musica`. El MSIX necesita identidad (Publisher) coherente con la app.
- **Firma real**: no hay certificado de confianza pública (comercial) en el repo. La CI SHALL firmar con **certificado autofirmado** (creado en el job con `makecert`/`New-SelfSignedCertificate`) — válido para instalación local de desarrollo y para tests, pero SmartScreen de producción seguirá requiriendo un cert comercial. La spec lo refleja con un escenario separado.

## Approach

### 1. Estructura de assets MSIX en el repo

```
windows/packaging/
  AppxManifest.xml          # identidad (Publisher, Version), propiedades, iconos
  assets/
    Square150x150Logo.png   # icono cuadrado 150 (se deriva del icono existente)
    Square44x44Logo.png
    StoreLogo.png
    Wide310x150Logo.png
```

El manifiesto referencia `/assets/` del empaquetado (rutas relativas a la raíz del MSIX) y los logos se generan desde `assets/icon.png` con los tamaños requeridos por MSIX (150/44/Store 50/Wide 310x150) usando ImageMagick en el CI (o assets PNG commiteados).

### 2. CI: job windows-msvc ampliado

Paso a paso dentro del job `windows-msvc` de `.github/workflows/build.yml`:

```yaml
- name: Generate MSIX resources (logos)
  shell: pwsh
  run: |
    # escalar assets/icon.png a los 4 tamaños MSIX con ImageMagick
    magick assets/icon.png -resize 150x150 windows/packaging/assets/Square150x150Logo.png
    magick assets/icon.png -resize 44x44  windows/packaging/assets/Square44x44Logo.png
    magick assets/icon.png -resize 50x50  windows/packaging/assets/StoreLogo.png
    magick assets/icon.png -resize 310x150 windows/packaging/assets/Wide310x150Logo.png

- name: Find Windows SDK tools
  shell: pwsh
  id: sdk
  run: |
    $k = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Directory | Sort-Object Name -Descending | Select-Object -First 1
    echo "KIT=$($k.FullName)" | Out-File $env:GITHUB_OUTPUT

- name: MakeAppx pack
  shell: pwsh
  run: |
    $kit = "${{ steps.sdk.outputs.KIT }}\x64"
    & "$kit\makeappx.exe" pack /d windows/packaging /p musica-1.0.0.msix /o

- name: Sign MSIX (self-signed for CI)
  shell: pwsh
  run: |
    $powershell = Start-Process -PassThru powershell -ArgumentList '-Command', 'New-SelfSignedCertificate ...'
    & "$kit\signtool.exe" sign /f cert.pfx /p "" /fd SHA256 /a musica-1.0.0.msix

- name: Upload MSIX artifact
  uses: actions/upload-artifact@v4
  with:
    name: musica-windows-msix
    path: musica-1.0.0.msix
```

### 3. Manifiesto (AppxManifest.xml)

Identidad coherente con la app `musica` v1.0.0, Publisher con DN del certificado autofirmado, `TargetDeviceFamily` para Windows 10/11, `uap10:MainPackageDependencies` vacío (sin dependencia de Desktop Bridge en este MVP), iconos de los 4 assets, y capacidades mínimas. La app no usa APIs restringidas → sin `uap` capabilities adicionales.

## Alternatives Considered

- **MSIX firmado solo con cert comercial**: más correcto, pero depende de un secreto de certificado que no existe en el repo. Se deja documentado como "cómo firmar en producción".
- **Inno Setup / NSIS (exe instalador)**: genera `.exe` instalador tradicional; el usuario pidió concretamente MSIX → se descarta.
- **winget publish**: requiere repo asociado y cert comercial; fuera del MVP del CI, se documenta como futuro.

## Open Questions / Risks

- El carácter "firmado" en la spec es con autofirma (dev). El escenario "distribución pública SHALL pasar SmartScreen sin aviso" requiere cert comercial — la spec lo separa como future/nota, no como fallback silencioso.
- El MSIX debe incluir el runtime de la app Flutter: `flutter build windows --release` produce `windows/runner/Release/` con la app + DLLs. El MSIX empaqueta esa carpeta (layout) — se reutiliza el resultado del paso de build previo del mismo job, mapeándolo a `windows/packaging/<archivo>.exe` etc. En el diseño del MSIX el layout se arma en un dir `msixlayout/` copiando `Release/*` bajo la raíz del paquete.
