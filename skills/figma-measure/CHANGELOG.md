# Changelog

## 1.0.0

- Initial release, extracted from `figma-to-react` §7 "Verify & deliver" (1.10.0). That section had
  grown into a 150-line forensic manual that every run loaded, while it only applies once a specific
  element is already flagged as off — the same reason motion guidance moved out in 1.7.0.
- Holds the escalation half: which of the three mechanisms to use (difference overlay, box geometry,
  pixel statistics) plus `@artcom/design-diff` where available; proving a check can see the defect
  before trusting a null result; doubting a large number's capture; element-level measurement and
  class inventories; and reading magnitude splits, pitch-vs-offset, and shared-component collateral.
- `figma-to-react` keeps the cheap default pass — read the specs, proofread the export, one
  difference-blend overlay — and the delivery/staleness rules, and points here to escalate.
