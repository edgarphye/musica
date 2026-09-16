## ADDED Requirements

### Requirement: Paquete MSIX firmado para Windows

El sistema SHALL publicar Windows como un paquete MSIX firmado (`.msix`) además del directorio `Release/` con el exe suelto. La CI SHALL generarlo con `makeappx` (MakeAppx.exe), firmarlo con `signtool` y un certificado autofirmado de desarrollo creado en el mismo job, y subirlo como artefacto `musica-windows-msix`. El manifiesto (`AppxManifest.xml`) SHALL incluir identidad (Publisher, versión 1.0.0, icono propio) y los assets MSIX (`Square150x150Logo`, `Wide310x150Logo`, `Square44x44Logo`, `StoreLogo`) derivados del icono de la app.

#### Scenario: Generar MSIX en CI Windows
- **WHEN** la CI ejecuta el job `windows-msvc`
- **THEN** el sistema empaqueta `windows/packaging/` con `makeappx pack` y produce `musica-msix_1.0.0.0_x64.msix`

#### Scenario: Firmar el MSIX con autofirma
- **WHEN** el MSIX está generado
- **THEN** el job lo firma con `signtool sign` usando el certificado autofirmado de desarrollo y lo marca como artefacto firmado

#### Scenario: Verificar instalador MSIX instalable
- **WHEN** un usuario de Windows 10/11 instala el MSIX mediante `Add-AppxPackage`
- **THEN** la instalación SHALL completarse y el ícono del launcher SHALL ser el de la app (`musica`)
