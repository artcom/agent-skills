# Changelog

## 1.0.0

- Initial release
- Stack-agnostic workflow for translating a Figma design into React code
- Detects the target project's existing styling approach, tokens, components, and resolution/responsiveness conventions before implementing
- Required Figma MCP flow: get_design_context, get_metadata, get_screenshot, get_variable_defs
- Anti-hallucination constraints for styles, colors, borders, positioning, and spacing
- Screenshot-based 1:1 verification step

## Unreleased

- §Verification now leads with measuring the render against the reference programmatically
  (`@artcom/design-diff`) instead of comparing screenshots by eye, and warns that a large
  diff is a reason to doubt the capture before changing CSS.
- Cross-referenced the static-vs-variable font bullet to the per-font-size offset gradient
  that identifies it.
- Added a "Prototype interactions" section covering how to detect and carry over Figma's
  click-through wiring: the `<a>`-vs-`<div>` tell in `get_design_context` output for a quick
  check, the Figma REST API's per-node `interactions` field (trigger + NAVIGATE actions,
  resolved via `destinationId`) as the authoritative source for multi-screen flows, how to spot
  an orphaned frame that never appears as a destination, and translating the live/dead-end
  distinction into real vs. inert handlers instead of wiring every similar-looking button.
  Required flow (§3) now calls for pulling this map before implementing when a target spans
  multiple linked frames.
