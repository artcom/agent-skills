# Changelog

## 1.0.0

- Initial release
- Stack-agnostic workflow for externalizing hard-coded texts and media into the ART+COM configuration
  repository and storage/asset server, referenced via `${storageServerUri}`
- Three-folder (Application / Configuration / Assets) workspace prerequisite and setup guidance
- Conventions for the `content` (text) and `assets` (URL) config blocks, and for threading config into
  module-level constant tables
- Guidance to keep animated inline SVGs in code and externalize only static media
- Guardrail: never delete files from the Assets Server — deletion is always a human action
- Figma → React variant: route exported assets to the asset server + config instead of `public/`
- `scripts/check-prerequisites.sh` verifies the workspace folders and asset-volume mount
