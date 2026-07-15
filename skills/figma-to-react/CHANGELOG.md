# Changelog

## 1.4.0

Section 7 is a checklist of ~20 small reasons a finished screen still looks slightly off from
the design — wrong font weight, a color that inverted, spacing that drifts, and so on.

This release sorts that checklist into two kinds of problem:

1. Problems caused by the **Figma file itself** being under-prepared (for example: a color wasn't
   attached to a proper design-token/variable, so the code generator has to guess it). These are best
   fixed _in Figma, once_ — otherwise they come back every time the design is exported again.
2. Problems that only exist when **writing the code or shipping it** (for example: exporting icons,
   or a stale cached image on the server). These can't be fixed in Figma and stay where they were.

What changed:

- **Added a new "Section 0: Preflight the Figma file first."** It tells you to run a new companion
  skill, `figma-preflight`, _before_ generating any code. That skill checks the Figma file for the
  kind-1 problems above and then either (a) hands you a checklist to pass to the designer (when the
  file isn't yours to edit — the safe default), or (b) fixes them directly in Figma (when you own the
  file). If you skip preflight, nothing breaks — the old checklist still catches these later.
- **Marked the 9 kind-1 items in the checklist with a "[preflight]" tag** and linked each back to
  Section 0, so it's obvious which ones should have been prevented in Figma. (Examples: a color not
  bound to a variable, the page background pointing at the wrong color token, the wrong brand font
  being substituted, text sizes that don't match the design's type scale.)
- **Left the remaining items untagged** and added a sentence explaining that those are the code/ship
  problems that have no Figma equivalent, so you still handle them while implementing — nothing about
  that workflow changed.

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
