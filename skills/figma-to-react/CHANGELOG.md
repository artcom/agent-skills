# Changelog

## 1.9.0

- **Correcting the font files invalidates every nudge that was compensating for them** (§4, Tokens).
  The variable-font rule from 1.6.0 usually arrives after someone papered over the symptom with a
  `translateY`, a pinned `top:`, or a hand-measured `line-height`; those were tuned against the old
  metrics, so swapping to the right faces makes them add instead of cancel. Swapping the files now
  ends with grepping out the old compensations and re-measuring.
- **The node's own geometry beats the codegen's token values** (§7, Layout). Stronger than the
  existing "don't trust the `var(--token, fallback)` fallback" rule: the token value itself can be
  wrong for the instance — `px-[11.429px]` on a pill whose measured inset is 10px. Implement the
  measured value and report the mismatch, since it is usually an override or a detached instance.
  Tagged **[preflight]**.
- **Two new measurement rules** (§7, Verify & deliver): inspect sub-100px elements at native
  resolution scaled *up*, never from a downscaled side-by-side composite, which erases the 1-3px
  insets and stroke weights that make an element read as "off"; and sample a rounded shape at its
  centre line, since probing a pill inside its corner radius manufactures differences.
- **Reworked the overlay-sync bullet into "Stale baselines"** (§7, Verify & deliver): committed
  exports go stale silently and the drift is not always cosmetic, so diff a fresh export against the
  committed one before trusting any number taken against it. `DESIGN_CHANGED` is the trigger to
  re-export; a clean `SYNC` never means "code matches design". §6 step 1 carries the pointer.
- **Added a "Prototype interactions" section** (§4), merged from `main`: Figma's click-through
  wiring is invisible to `get_metadata`, so this covers the `<a>`-vs-`<div>` tell in
  `get_design_context` output as the quick check, the Figma REST API's per-node `interactions` field
  (trigger + `NAVIGATE` actions resolved via `destinationId`) as the authoritative source for
  multi-screen flows, spotting an orphaned frame that never appears as a destination, and carrying
  the live/dead-end distinction into real vs. inert handlers. §3's required flow now pulls this map
  before implementing when a target spans multiple linked frames.
- **`@artcom/design-diff` is the preferred measurement tool where it exists** (§7, "How to actually
  measure"), also from `main`: `design-diff verify` / `design-diff explain <scenario>` report a mean
  channel delta, a best-fit offset per font size, and DOM-attributed differences — the hand-rolled
  mechanisms are the fallback. The variable-font bullet cross-references the per-size gradient.
- **A large diff is a reason to doubt the capture first** — an overlay still composited, a dev-only
  panel left visible, fonts not finished loading. Folded into §7's existing "Validate the comparison
  before trusting its verdict" bullet rather than repeated as a separate rule.

## 1.8.0

Sections 6 and 7 had both become verification sections that cross-referenced each other, with the
split between them arbitrary: per-instance differences in §6, magnitude diffs in §7, the overlay in
both. A reader could not tell which one to follow. §6 is now the flow and §7 the substance — no
guidance was dropped, three bullets moved to where they belong.

- **§6 is now a numbered sequence** of seven steps (re-fetch screenshot → fix → work through §7 →
  run the app → overlay → figma-sync → lint), with §7 as an explicit step rather than an implied one.
  Adds the warning that a by-eye screenshot comparison catches boxes and colours and reliably misses
  the per-element errors §7 exists for — previously the numbered flow's biggest silent assumption.
- **Moved "Two instances of one Figma component can differ" to §4 Components**, next to "reuse the
  code, re-derive the data". It is an implementation rule about where a difference belongs (in the
  data layer, not the shared component), not a measurement technique — it was only in §6 because
  that is where you notice it.
- **Moved the pitch-vs-offset diagnostic and "changing a shared component is a multi-screen change"
  to §7 "Verify & deliver"**, joining the other measurement guidance. Both are about how to read a
  number, so they now sit with the section that explains how to produce one.
- Repointed the cross-references the moves invalidated: §7 no longer sends the reader to §6 for the
  constant-vs-growing diagnostic it now contains itself, and the two moved bullets name their §4
  counterparts explicitly instead of saying "previous bullet".

## 1.7.0

- Move the "Motion the design does not specify" section out into the new
  [`react-transition-performance`](../react-transition-performance/SKILL.md) skill. Its 25 lines were
  browser performance debugging — paint flashing, Performance recordings, `decode()`, compositor
  demotion, per-layer memoisation — which is neither Figma-to-code translation nor something most runs
  touch, yet every run loaded it. Section 4 keeps a short pointer, so transitions are still handled;
  they are just no longer paid for by runs that involve no animation.

## 1.6.0

- **Load the design's actual font files — static faces, not a variable font** (section 4, Tokens).
  Figma composes text from concrete named faces per weight; declaring one variable file across a
  weight range can land every text run on a slightly different baseline. The decisive test is that
  the error **scales with font size** — headings visibly off while body text looks fine means the
  font files, not the CSS, so don't chase it with per-element `margin-top`/`line-height` nudges.
  Declare one `@font-face` per weight and style, keep `font-synthesis: none` so a missing weight
  fails visibly instead of being faked, and accept a ~1px residual on large text from browser
  baseline rounding.
- Scope the neighbouring font bullet to **horizontal** metrics (wrapping, clipping, ellipsis — those
  usually are a CSS property, not the typeface) and point vertical offsets at the rule above, so the
  two bullets no longer read as opposite instructions.

## 1.5.1

- Clarify **how** §7's verification steps are actually executed — the section described what to
  measure but never named a mechanism. Adds a short "How to actually measure" note to
  "Verify & deliver" separating the three: the difference-blend overlay (the only step that sends an
  image to the model), box geometry via browser JS against the running app, and pixel statistics via
  a throwaway script over the two PNGs (`sharp`/`pngjs`, PIL, or `magick` — whatever is already
  available, no new dependency). Also makes explicit that the model sees printed numbers rather than
  pixels, which is what makes these cheap apart from the per-mark array pass.

## 1.5.0

Additive guidance only — nothing about the required workflow changed. All of it comes from cases
where a screen was reported as "done" but still didn't match, and the reason was a habit rather than
a missing rule.

- **Re-implementing against an updated design node** (section 0): when the designer fixes a source
  problem you previously worked around in code, that workaround becomes a new defect. Re-check and
  delete the compensations the file no longer needs.
- **A child fetch does not describe its container** (section 3): drilling into sub-frames to save
  context leaves every wrapper above them a guess — and the wrapper usually carries the surface
  colour. `get_metadata` gives geometry, never fill, so a container is never "white by inference".
- **Reusing a component for a second screen: reuse the code, re-derive the data** (section 4):
  copying a sibling screen's content entry and editing the visible strings silently carries over
  state-bearing values (which timeline step is current, which rows are warnings, which tag tone).
- **New "Motion the design does not specify" subsection** (section 4): Figma carries end states
  only, so transitions are an addition you author. Profile before theorising, don't build the
  incoming view inside the interaction, and don't disturb other layers while animating.
- **Per-instance differences belong in data, not in the shared component** (section 6): and changing
  a shared component is a multi-screen change — re-measure every screen that renders it, and treat a
  metric that moved the wrong way as evidence rather than noise.
- **Don't inherit type from your own earlier implementation** (section 7): re-read the font style
  per node; ink coverage settles weight objectively where the eye and aggregate diffs can't.
- **Measurement discipline** (section 7): split a pixel diff across two thresholds so a wrong
  large-area fill can't hide behind a severity-only metric; validate the comparison harness (export
  bleed, crop-argument order, downscaled previews) before trusting a bad number; measure an
  element's own edge, since a whole-screen metric cannot see one element being wrong.
- **Re-derive placement when swapping a baked image asset** (section 7): a container export has the
  crop baked in, a source export doesn't — feeding one into the other's CSS re-scales it.

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

