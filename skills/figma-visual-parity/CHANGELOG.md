# Changelog

## 1.0.0

- Initial release
- Documents the published [`@artcom/figma-visual-parity`](https://www.npmjs.com/package/@artcom/figma-visual-parity)
  npm package (CLI + library): config shape, scenarios, declarative `prepare` steps
  (including `mqtt` for broker-driven apps), and the `doctor`/`capture`/`verify`/`explain`
  commands
- `explain`'s ranked-diagnosis order (environment → font-metrics → uniform-offset →
  hotspots → baseline-rounding) and what each finding actually means, cross-referenced to
  `figma-to-react`'s font-file and stroke guidance
- `--save-captures` for writing a raw capture and a `difference`-blend diff PNG per
  scenario when a mismatch needs to be looked at, not just read as numbers
- Gotchas: integer-only offset scans, hiding dev-only UI without hiding real errors,
  suppressing a design overlay during capture, and why the verdict also gates on a single
  bad block instead of only the frame-wide mean
