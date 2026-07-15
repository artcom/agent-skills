# Changelog

## 1.0.0

- Initial release
- Preflight a Figma source file for design-to-code fidelity BEFORE `figma-to-react` codegen
- Two modes chosen per run: **report** (read-only checklist to verify/request from the designer)
  and **fix** (repair the source in Figma via `figma-use`, when the user owns the file)
- Detects the source-fixable subset of `figma-to-react` §7: unbound colors → `var(--token, black)`
  fallback, page-bg not bound to a background token, collapsed surface-elevation ladder,
  substituted brand font, off-ramp/overridden type, unpinned instance theme modes, packing-vs-fixed-pitch
  and missing min/max constraints, auto-layout alignment
- Each check cross-references its §7 bullet; leaves inherent codegen/delivery items to `figma-to-react`
