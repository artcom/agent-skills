# Changelog

## 1.3.0

- Add section 7 "Pixel-fidelity checklist" — hard-won gotchas grouped by area (tokens & color,
  type & fonts, icons, layout/spacing/constraints, verify & deliver) that make a "done"
  implementation actually match the design 1:1
- Key additions: resolve `var(--token)` values via `get_variable_defs` (never trust the fallback
  literal), check the frame fill rather than assuming the `background` token, preserve the
  surface-elevation ladder, read exact per-node type + `font-feature-settings`, treat off-brand
  font substitution as a decision, use real icon assets per node, carry min/max constraints,
  reproduce fixed pitch instead of `space-between`, and treat "looks wrong but source matches"
  as a delivery/cache problem (with cache-busting guidance)

## 1.0.0

- Initial release
- Stack-agnostic workflow for translating a Figma design into React code
- Detects the target project's existing styling approach, tokens, components, and resolution/responsiveness conventions before implementing
- Required Figma MCP flow: get_design_context, get_metadata, get_screenshot, get_variable_defs
- Anti-hallucination constraints for styles, colors, borders, positioning, and spacing
- Screenshot-based 1:1 verification step
