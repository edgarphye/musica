# Empaca Windows como MSIX firmado

## Why

Hoy el CI de Windows produce solo un `.exe` suelto (release de MSVC) sin instalador ni firma: SmartScreen lo bloquea, no hay identidad de sistema (icono/Publisher/versión) y no es instalable limpiamente en Windows 10/11. El usuario pidió revisar el tema Windows/MSIX y eligió "Añadir spec MSIX + CI": el sistema SHALL generar un paquete MSIX firmado y publicarlo como artefacto del CI.

## What Changes

- **Spec de empaquetado**: se añade el Requirement `Paquete MSIX firmado para Windows` al capability `empaquetado`, con escenarios para generación (MakeAppx), firma (signtool), contenido del manifiesto (AppxManifest.xml con identidad, iconos) y verificación de instalación.
- **CI**: el job `windows-msvc` del workflow `build.yml` se amplía para producir el MSIX: empaquetar `windows/packaging/AppxManifest.xml` + assets con `makeappx pack`, firmar con `signtool` y subir el `musica-*.msix` como artefacto.
- **Windows** (repositorio): se añade `windows/packaging/AppxManifest.xml` y los assets MSIX (logos `Square150x150Logo`, `StoreLogo`, `Square44x44Logo`) reutilizando el icono existente.

## Capabilities

### Modified Capabilities
- `empaquetado`: el sistema SHALL poder generar un MSIX firmado para Windows y la CI SHALL subirlo como artefacto.

## Impact

- `openspec/specs/empaquetado/spec.md`: nuevo Requirement + 3 escenarios MSIX.
- `.github/workflows/build.yml`: paso de empaquetado/firma/subida MSIX en el job `windows-msvc`.
- `windows/packaging/AppxManifest.xml` y assets de logo (nuevos).
- Sin cambios en código Dart ni en dependencias.
