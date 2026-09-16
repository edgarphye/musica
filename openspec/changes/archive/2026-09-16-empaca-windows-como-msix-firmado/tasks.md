# Tareas — Empaca Windows como MSIX firmado

## 1. Spec de empaquetado — Requirement MSIX

- [x] Añadir a `openspec/specs/empaquetado/spec.md` el requirement `Paquete MSIX firmado para Windows` con 4 escenarios (generar con MakeAppx, manifest con identidad+iconos, firmar con signtool autofirmado, verificación de instalación/artefacto).
- [x] Escenario extra `MSIX con cert comercial` documentado como nota (SmartScreen sin aviso requiere cert de confianza; el autofirmado es para CI/dev).

## 2. Assets MSIX

- [x] Crear `windows/packaging/AppxManifest.xml` con identidad `musica` v1.0.0, Publisher autofirmado y los 4 logos.
- [x] Añadir `windows/packaging/assets/` (los 4 PNG generados en CI, no commiteados — se regeneran).

## 3. CI (build.yml)

- [x] Ampliar el job `windows-msvc`: pasos `Generate MSIX resources`, `Find SDK tools`, `MakeAppx pack`, `Sign MSIX`, `Upload MSIX artifact`.
- [x] Mantener el artefacto `Release/` existente y añadir el nuevo `musica-windows-msix`.

## 4. Verificación

- [x] Ejecutar build local (o CI) y confirmar que el `musica-1.0.0.msix` existe y está firmado (PowerShell: `Get-AuthenticodeSignature` retorna `Valid`).
- [x] (Futuro, documentado) firmar con cert comercial y publicar en Microsoft Store.
