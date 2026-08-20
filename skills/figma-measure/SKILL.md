---
name: figma-measure
description: Measure and diagnose one specific difference between a rendered React screen and its Figma design export — which mechanism to use, how to prove the check can see the defect, and how to read the resulting number. Use when figma-to-react's §7 checklist leaves an element still reading as "off", when the user asks whether any member of a class of elements is wrong, when a diff number is implausibly large or suspiciously clean, or after changing a component several screens share.
metadata:
  version: 1.0.0
  author: ART+COM
---

# Measuring a Figma-vs-render difference

Companion to [`figma-to-react`](../figma-to-react/SKILL.md). That skill's default fidelity pass —
read the exact specs per node, proofread the export, eyeball **one** difference-blend overlay — is
what every run does, and it is deliberately cheap. This skill is the **escalation**: reach for it
only when a specific element is flagged as still-off, when the overlay shows drift you can't explain
by eye, or when the user asks about a whole class of elements at once.

Measuring locates a difference you can't explain and confirms a fix. It is **not** how you learn the
spec — `get_design_context` states the spec outright, so read it there. And measurement only ever
finds what you thought to look for: if the complaint could be copy, casing, or a mark on the wrong
side of a figure, go read the export instead (see "Read the design, don't just diff it" in
`figma-to-react` §7).

## 1. Pick the mechanism

Three mechanisms, and only the first spends image tokens:

- **Difference-blend overlay** — composite your render and the design export into one image, then
  *look* at it. This is the only step where an image goes to the model.
- **Box geometry** (`getBoundingClientRect`) — browser JS evaluated against the **running app** (e.g.
  Playwright/CDP `page.evaluate`), returning a handful of numbers as text. Needs the app running.
  Boxes match but text still ghosts → inherent Figma-vs-browser glyph-baseline difference, not a bug
  to chase; boxes offset → a real layout error.
- **Pixel statistics** (ink coverage, two-threshold diff counts, first-column-with-ink, the
  `getImageData` per-mark pass) — a **short throwaway script you write** that reads the two PNGs and
  prints numbers: Node with `sharp`/`pngjs`, Python with PIL, or ImageMagick's `magick` on the
  command line. Use whatever the project or environment already has; don't add a dependency to
  measure. The model never sees the pixels, only the printed result — which is why these are cheap
  *except* the per-mark pass, whose per-element arrays make it token-expensive. Reserve that pass for
  one hero or repeated element the user flags, never as a routine sweep.

If `@artcom/design-diff` is available in the project, prefer it over hand-rolling the pixel pass:
`design-diff verify`, then `design-diff explain <scenario>` when that fails — it reports a mean
channel delta, a best-fit pixel offset **per font size** (the gradient that identifies a
variable-font mismatch, see `figma-to-react` §4 Tokens), and the strongest differences attributed to
DOM elements. Without it, the three mechanisms above are the fallback — but diff programmatically
either way, never by inspection.

Print one number (or one coordinate) per question you're answering. A script that dumps a full array
when you needed a single offset is the expensive mistake, not the measuring itself. So: localize
once, read the spec, fix, re-measure **once** across the affected screens, and report only the
numbers that changed a decision.

## 2. Prove the check works before you trust it

- **A null result from an uncalibrated check is not evidence.** A check that reports no differences
  because it cannot see them is the quiet failure. Before writing "everything matches", point the
  same command at a difference you know exists and confirm it fires. A chromatic-difference
  threshold of 12% silently passes an accent `#8dafa0` drawn where the design has a grey `#838983`:
  they are 11% apart, so the one check written to catch wrong icon colours certified them as correct.
- **A large number is a reason to doubt the capture first.** A design overlay still composited, a
  dev-only panel left visible, or fonts not finished loading all produce enormous, confident numbers
  that have nothing to do with the code. Confirm the capture is sound before changing any CSS. If the
  diff is elevated almost everywhere — including regions that are plain background in both images —
  the baseline is misaligned, not the layout: suspect the export crop first. Two traps: a full-frame
  export carries **bleed around the frame that need not be symmetric**, so the content origin is not
  simply (bleed, bleed) — measure a known landmark instead of assuming it; and crop tools each order
  their arguments differently (height/width, top/left, x/y), so a swapped pair shifts the baseline a
  few px in both axes and manufactures a large, diffuse diff. Also confirm you fetched the
  **full-resolution** export rather than a downscaled preview — endpoints often serve one while
  reporting the original dimensions in their metadata. Sanity-check by sampling one pixel of known
  background in both images before diagnosing anything.
- **Confirm the reference itself is current.** Every number taken against a stale committed export is
  wrong in a way that looks exactly like a code defect — see "Stale baselines" in `figma-to-react`
  §7 before measuring against an overlay image or a sync baseline.
- **Inspect small elements at 1:1 or magnified — never from a downscaled composite.** Stacking your
  render beside the export and shrinking it to fit is the cheapest thing to look at and the easiest
  way to certify a defect as fine: a 2x downscale erases exactly the 1-3px insets, stroke weights and
  pill radii that make an element read as "off". If an element is under 100px, crop it at native
  resolution and scale **up** (nearest-neighbour) before judging it.
- **Sample a rounded shape at its centre line, not near its corners.** Probing a pill's height in a
  column that falls inside the corner radius reports a value several px short, and comparing two such
  probes manufactures a difference that is not there (or hides one that is). Take the vertical extent
  at the horizontal midpoint and the horizontal extent at the vertical midpoint.

## 3. Measure the element, not the screen

- **A whole-screen metric cannot see a single element being wrong — measure the element's own edge.**
  One text line shifted, or one weight too light, touches a tiny fraction of the frame, so it moves a
  whole-screen mean by less than the run-to-run noise: "the numbers are fine" is not evidence that a
  flagged element is right, and the larger the canvas the more true that gets. Measure the thing
  directly: scan the element's band in both images for the **first column (or row) containing ink**
  and compare the coordinates. That yields an exact pixel offset and, unlike a mean, points at a
  cause — a delta on one text row whose siblings align is a missing padding/inset on that row, not a
  font issue.
- **"Is any X wrong?" is answered by an inventory, not by a diff.** When the user names a *class* of
  element rather than one element — icons, badges, dots, tags — you do not yet know which member is
  wrong, so there is nothing to point a targeted measurement at, and a screen-wide diff will not tell
  you either. Extract the class from both images and compare the lists: every badge's centre and
  fill, every icon's glyph colour. Isolating one fill (in ImageMagick, `-fuzz 4% -opaque <colour>`
  plus connected components) prints a handful of coordinates and finds the odd one out immediately;
  the same question asked as a percentage returns "everything matches" while the user is looking at
  the defect. Report the two lists, not a number.
- **Weight differences need ink, not geometry.** A `font-weight` one step too light barely moves an
  aggregate diff and is nearly invisible by eye. Crop the text in render and export, count pixels
  darker than mid-grey, and compare. Equal ink across two *different* exports also proves the weight
  is not a per-instance override, so the fix belongs in the shared component.

## 4. Read what the number means

- **Split the diff by magnitude — a wrong container fill hides from a severity-only check.** If you
  reduce a comparison to one number, count differing pixels at *two* thresholds (e.g. >8/255 and
  >32/255). A wrong surface colour is a low-delta error over a huge area: neighbouring greys differ
  by ~10-20, so it barely moves the >32 count while dominating the >8 count. A screen can therefore
  look "at parity" on a single severity metric while a whole panel is visibly the wrong colour. A
  big >8 count with a flat >32 count means **large-area fill**, not text antialiasing; a small >8
  with a proportional >32 means edges and glyphs, which is normal.
- **In a repeated list/table, measure pitch vs. offset before guessing.** A *constant* offset across
  all items means a one-time height mismatch in an element **above** the list (see "A frame's height
  is not its text's line-height" in `figma-to-react` §4); a *growing* offset means a per-item pitch
  error (wrong row height or an unexpected gap). Measuring the position of repeating landmarks (e.g.
  alternating row backgrounds) in the render vs. the design export tells the two apart objectively
  and points straight at the cause.
- **After changing a shared component, re-measure every screen that renders it — at element level.**
  A single screen's diff can improve while a sibling's degrades, so averaging or checking only the
  screen you're working on hides it. A screen-wide sweep is **not** sufficient: the collateral is
  usually one small element the sweep cannot see, so a clean sweep after a shared-component change is
  worth nothing — use the inventory above instead. A fix derived from one frame routinely breaks
  another: a 16px image offset measured on one figure pushed a second screen's figure 16px down.
- **A worse number after a change you believe is correct is evidence, not noise.** The design almost
  certainly differs per instance (see "Two instances of one Figma component can differ" and "One data
  field driving two visuals" in `figma-to-react` §4) — sample both exports at that element before
  overriding the measurement with your reasoning. The screen that **doesn't** move is equally
  informative: it localizes the cause to the components the moved screens don't share with it.

## Setup note

Nothing to install: the mechanisms here use the project's existing tooling (a headless browser it
already has, or any image library on the machine). The design export comes from the Figma MCP
connector via `figma-to-react`.
