---
name: figma-to-react
description: Translate a Figma design into React code that matches the target project's own styling approach, design tokens, and components. Use whenever the user shares a Figma link/node, asks to implement or build UI from a Figma design, or wants existing UI matched 1:1 to Figma. Requires the Figma MCP connector.
metadata:
  version: 1.3.0
  author: ART+COM
---

# Figma → React

Rules for turning a Figma design into React code. This skill is deliberately stack-agnostic: detect
the target project's real conventions first, then follow them — never impose a styling system,
resolution, or constraint the project doesn't already have. The one exception is **component
structure**: when the project has no real components to conform to, follow the Figma component
hierarchy instead of collapsing the design into one file — see "Component structure & granularity"
in section 1.

## 1. Learn the project before touching Figma

- Read `AGENTS.md` / `CLAUDE.md` at the project root if present. Anything they say **overrides this
  skill** on conflict (e.g. "no hover states", a fixed canvas size, accessibility requirements,
  dependency-placement rules).
- Identify the styling approach already used by existing components (CSS Modules, Tailwind,
  styled-components or other CSS-in-JS, Sass, plain CSS, vanilla-extract, etc.) and use that same
  approach for new code. Do not introduce a second styling system alongside an established one.
- Check whether existing screens are fixed-size or responsive. If components hardcode pixel values
  with no media queries or breakpoints, treat the target as fixed-size and use the exact Figma px
  values without inventing responsiveness. If the project already uses fluid units, breakpoints, or
  `%`/`vw`/`clamp()`, build the new UI responsively too, matching the existing breakpoints. Never
  assume a specific resolution — if it's ambiguous and matters, ask.
- Locate where design tokens live (CSS custom properties, a theme object, a Tailwind config, a
  design-system package) and where shared/reusable components live (commonly `src/components/`,
  `components/`, or a UI package). Both should be reused, not duplicated.
- Check `package.json` for the project's actual dev/build/lint scripts and package manager instead
  of assuming `npm run dev` — a project-specific `/run` skill, if installed, can also launch it.
- Match how the project already treats hover/focus/active states (some touchscreen-only or kiosk
  apps intentionally omit them) and accessibility attributes — don't add or remove either category
  based on assumption; follow what's already there or what `AGENTS.md` says.
- Keep new dependencies in whatever section (`dependencies` vs `devDependencies`) the project's
  existing packages use for comparable tools — some deployment setups (e.g. buildpack-based hosts)
  require everything in `dependencies`.

### Component structure & granularity (decide before implementing)

Figma designs are built from components and instances (e.g. a `MetricCard`, a `Tag`, a `Panel`, a
table row). The **default target is one code component per meaningful Figma component/node**, composed
to mirror the design's hierarchy — not a single monolithic component for the whole screen. Which
structure you actually use depends on what already exists in the repo:

- **Empty or near-empty project** — no real UI components yet, or only starter/demo scaffolding (e.g.
  a Vite counter `App.jsx`, a single stylesheet, no component directory or shared components): **use
  the Figma structure.** Create a component for each meaningful Figma component/node and compose them,
  establishing the hierarchy and naming from the design. Do **not** collapse the whole screen into one
  monolithic component just because the starter happened to be a single file — a bare starter is not a
  convention to preserve.

- **Project already contains several real components** — an established component architecture,
  styling system, and/or token layer: do **not** silently impose the Figma structure, and do **not**
  silently flatten the design to fit. **Ask the user explicitly** (e.g. via `AskUserQuestion`,
  ideally together with the section 2 question) which they want:
  1. **Keep the existing structure** — generate the new screen within the current architecture and
     conventions, reusing existing components and tokens (the behaviour described in section 4).
  2. **Refactor to the Figma structure** — reorganize/rewrite so the code matches the Figma component
     hierarchy and naming (one component per Figma node), migrating existing code as needed.

  Proceed only according to the user's choice; if the run is non-interactive and the user can't be
  asked, keep the existing structure and note the assumption in the final summary.

When you do create per-node components, mirror the Figma component **names** and nesting, and — if
`figma-sync` is opted in (section 2) — add a `// figma-sync:` annotation per component so the
node→component mapping is explicit.

## 2. Optional companion skills — ask the user first

Three companion skills can extend this workflow. All three are **optional**: none of them is
required to translate a design, and none may be used without the user's consent. After learning
the project (section 1) and **before implementing**, check which of them are relevant to this
project, then ask the user **once, in a single question** (multi-select, e.g. via
`AskUserQuestion`) which ones to use for this task. Skip any the user declines and don't ask
again in the same session. In a non-interactive run where the user cannot be asked, skip all
three and note that in the final summary.

- **`figma-sync`** — keeps generated components verifiably in sync with their Figma nodes.
  Relevant when the project has a `.figma-sync/` directory, an `@artcom/figma-sync` dependency,
  or `figma:*` scripts in `package.json`. If the user opts in: keep existing
  `// figma-sync: file=<fileKey> node=<nodeId> name=<ComponentName>` annotations intact, add one
  to each newly implemented component, and after implementation re-baseline with the project's
  update-manifest script (e.g. `npm run figma:update-manifest`), confirming the status script
  (e.g. `npm run figma:status`) reports `[SYNC]` for the touched components.

- **`react-pixel-overlay`** — a PerfectPixel-style overlay for pixel-perfect QA. Relevant when
  the project depends on `react-pixel-overlay` / `@artcom/react-pixel-overlay` (or mounts a
  `PixelOverlay` component). If the user opts in: export the implemented Figma frame as a PNG at
  the exact target resolution into the project's overlay sources folder (commonly
  `public/design-overlays/`), then verify the running app under the overlay — difference blend
  mode makes any deviation light up — as part of the Verification step.

- **`config-content-assets`** — the project's convention for separating configuration, content,
  and assets from component code. If the user opts in and the skill is installed, invoke it and
  follow its instructions for where downloaded Figma assets, copy/text content, and configurable
  values belong instead of hardcoding them into components.

If a skill the user chose turns out not to be available in this project, say so, continue
without it, and mention the gap in the final summary.

## 3. Required flow (do not skip)

1. **Get the design context** for the exact node(s): call the Figma MCP tool that returns the
   structured node representation (`get_design_context`; some connectors name it `get_code`).
2. If the response is truncated or too large, call **`get_metadata`** for the node map, then
   re-fetch only the needed child node(s) with `get_design_context`.
3. Call **`get_screenshot`** (aka `get_image`) for a visual reference of the exact variant.
4. Pull Figma variables with **`get_variable_defs`** if available, and map them to the project's
   existing design tokens (see Tokens below).
5. **Search the project's component directory for an existing component to reuse** before writing
   anything new. Reuse is mandatory — only create a new component if nothing fits.
6. Only after you have context + screenshot + reuse decision: download any needed assets, then
   implement — applying whichever companion skills the user opted into (section 2).
7. **Verify 1:1** against the screenshot (see Verification) before marking the task complete.

## 4. Implementation rules

- Treat MCP output as a _representation_ of design and behavior, not as final code. Rewrite it into
  the project's own idioms (its component style, file layout, and styling approach).
- Map Figma **Auto Layout** directly to `display: flex` / `display: grid` (or the equivalent utility
  classes) with the exact gaps, padding, and sizes from the node data — do not approximate spacing.
- **A frame's height is not its text's line-height.** Text/label frames often reserve extra vertical
  space (fixed frame height, or padding around the line box) beyond the glyphs. Porting only
  `font-size` + `line-height` makes the element shorter than the design; when it sits above other
  content, everything below shifts up. Carry the layer's **explicit frame height** (or its padding),
  not just the type ramp — e.g. a 64px heading frame around a 60px line, or a 48px label whose text
  line box is only ~36px.
- **Give fixed-size children `flex-shrink: 0` inside an overflowing flex container.** Figma frames that
  overflow are *clipped* (overflow-clip), not shrunk. A CSS flex container whose content overflows will
  instead shrink its children by default, silently undoing an explicit `height`/`width` you just set.
  Mark fixed-dimension children `flex-shrink: 0` so they keep their design size and the container clips,
  matching Figma.
- Reuse tokens, existing components, and typography wherever possible. Match the surrounding code's
  naming and structure.
- Respect existing routing, state, and data-fetch patterns already in the repo.
- When Figma and an existing token conflict, prefer the token and adjust spacing/size minimally to
  match, rather than hardcoding the Figma value.

### Components

- **First settle structure via the section 1 decision** ("Component structure & granularity"): in an
  empty/near-empty project, or when the user chose to refactor, create one component per meaningful
  Figma node mirroring the design hierarchy; otherwise generate within the existing structure as below.
- New UI components go wherever the project already keeps them, following its existing naming and
  file-organization convention (co-located styles, index files, folder-per-component, etc.) — mirror
  an existing component's layout exactly.
- If a component needs a new variant, **extend the existing component**, don't clone it.
- Import and apply styles the way the rest of the project does (e.g. `styles.foo` for CSS Modules,
  `className="..."` for Tailwind, a styled-component call, etc.).

### Tokens

- Use the project's existing token/variable references — never hardcode a raw hex/rgb/px value that
  a token already covers.
- If the Figma design uses a variable **not yet** defined in the project: add it wherever tokens
  already live, using the **Figma variable's own name** (adapted to the project's existing naming
  convention), then reference it. Do **not** invent extra component-level alias layers that the
  design doesn't define.
- Match the project's existing font-loading approach (`@font-face`, a font package, a web-font link,
  etc.) for any typeface Figma specifies. **Don't assume the design font is missing/substituted** —
  it may already be installed at the OS level (so the browser renders it directly from a family-name
  reference with no `@font-face`) or bundled. Verify before attributing any layout difference to the
  font; text metrics (wrapping, clipping, ellipsis) usually diverge because of a CSS property, not the
  typeface. If the font is only OS-installed and the app must render identically elsewhere, note that
  bundling it via `@font-face` is a separate portability task.

### Strokes / borders (do not translate a Figma Stroke to a CSS `border`)

A Figma **Stroke is layout-neutral**: padding is measured from the frame's bounds and the stroke is
painted on that edge, so adding/removing a stroke never moves the frame's children. A CSS **`border`
is part of the box model**: with `box-sizing: border-box` it pushes all content inward by the stroke
width (and shrinks the content area); with `content-box` it grows the frame. Either way a plain
`border` on a fixed-size, padded auto-layout frame **shifts content or resizes the box** versus the
design — most visibly when only one variant (hover, selected, alert) carries the stroke, so its text
drops off the baseline shared by the others.

- Translate a decorative stroke to a **layout-neutral ring**: `box-shadow: inset 0 0 0 <w> <color>`
  or `outline: <w> solid <color>; outline-offset: -<w>` — never a plain `border` — so the content
  position is identical to the un-stroked variant.
- **Respect stroke alignment.** *Inside* → inset ring (stays within the frame footprint; keeps gaps
  between siblings intact). *Outside* → outset ring (`box-shadow: 0 0 0 <w>` / `outline`), but note
  it is painted beyond the frame and **eats into the gap** to adjacent elements — only use it when
  the design's stroke is genuinely outside. *Center* → split the width across an inset+outset pair.
  When alignment is ambiguous, an inside-aligned inset ring is the safe default and matches most
  component states.
- **When a variant differs from its base only by a stroke,** make sure the base reserves the same
  space (e.g. a transparent inset ring / border) so switching states causes zero reflow.

### Text wrapping & line breaks

- **Keep a text layer as one string; let CSS soft-wrap it.** Do not split a label into multiple
  spans joined by synthesized `<br>`s to force the design's line breaks — each span then soft-wraps on
  its own and the result diverges from the source text (and often clips). Port the layer's actual
  string and its white-space mode.
- **Reproduce where the design wraps, which means reproducing the wrap *width*.** A Figma text box
  often hugs its content and is allowed to run into the frame's padding before wrapping, so a line can
  be wider than the padded content box. If you constrain wrapping to `frame − 2×padding`, a long line
  breaks too early (one word too soon). Check where the design actually wraps and give the text that
  width (e.g. `width: calc(100% + <padding>)` to let it use the padding up to the frame edge), rather
  than adding a manual break.
- **Don't clip text horizontally.** An `overflow: hidden` added only to bound height will also cut off
  text that legitimately overflows the padding. Bound height without clipping width.
- **Verify against the widest realistic content, not just the sampled string** — a header/label that
  fits the sampled data can still wrap or clip on a longer value.

## 5. Anti-hallucination constraints

- **No guessing styles.** If a property (`border`, `box-shadow`, `border-radius`…) is not in the
  Figma node data, do not add it to the CSS.
- **Color integrity.** Only use colors defined in Figma variables or existing project tokens. If a
  hex is within ~5% brightness of an existing token, use the token. If there's no close match,
  **ask before proceeding** — never invent a value.
- **Ghost outlines.** Only add `outline`/`border` if it exists as an explicit **Stroke** in Figma.
  Never add borders for visual separation the design doesn't have. And when a Stroke *does* exist,
  render it as a layout-neutral ring, not a `border` — see "Strokes / borders" in section 4.
- **No absolute positioning** unless the Figma layer is explicitly "Absolute position".
- **Zero-margin policy.** All spacing comes from Figma Auto Layout → tokens/px. Don't rely on
  default browser margins/paddings.
- **Truncated data:** never fill gaps with assumptions — use `get_metadata` then re-fetch the real
  node(s).

## 6. Verification

- After the first implementation, re-fetch `get_screenshot` and compare against the rendered code.
- Fix any layout drift, spacing mismatch, wrong color, or extra border **before** finishing. If the
  screenshot has a clean background but your CSS added a border, remove it.
- **When alignment drifts in a repeated list/table, measure pitch vs. offset before guessing.** A
  *constant* offset across all items means a one-time height mismatch in an element **above** the list
  (see "A frame's height is not its text's line-height"); a *growing* offset means a per-item pitch
  error (wrong row height or an unexpected gap). Measuring the position of repeating landmarks (e.g.
  alternating row backgrounds) in the render vs. the design export tells the two apart objectively and
  points straight at the cause.
- Run the app with its own dev command from `package.json` (a `/run` skill, if installed, can launch
  it for you) to visually confirm.
- If the user opted into `react-pixel-overlay` (section 2), also verify under the overlay with the
  exported design image.
- If the user opted into `figma-sync` (section 2), re-baseline and confirm the sync status is clean.
- Lint using the project's own lint command before finishing.

## 7. Pixel-fidelity checklist (why a "done" screen still reads as "slightly off")

Small per-element errors — a body size off by 4px, weight 400 vs 500, an inverted token, a
missing constraint — compound and read to the user as "everything is slightly off" even when
the layout boxes are correct. Work through these by area.

### Tokens & color

- **Never trust the fallback literal in `var(--token, fallback)`.** Figma codegen writes
  `var(--text/primary, black)`, but that trailing `black`/`white` is a generic placeholder, NOT
  the variable's value. Resolve every token via `get_variable_defs` and reference the project's
  token — using the fallback silently inverts colors (dark-bg/white-text labels become
  white-bg/black-text; white dots become black).
- **Don't assume the page background is the `background` token — check the frame's fill.** A
  token named `fills/background` (e.g. #000) does not mean the screen uses it; a design often
  fills the whole screen with a `surface` color and reserves the near-black token for
  insets/pills. Sample the actual frame fill (cheap: crop a ~20px corner, read one pixel).
- **Preserve the surface-elevation ladder — don't collapse near-identical neutrals.** Keep the
  RELATIVE order (e.g. card lighter than page, tiles/rows lighter than card, inset panels darker
  than card). Shift the whole ladder one step and nested insets that share a token with their
  parent lose all contrast and **vanish** — when a panel looks missing, suspect the parent
  surface token before adding borders/shadows.
- **Color data-driven marks by their value, not one accent** (e.g. gauge/waveform bars that are
  an accent color only past a threshold, dimmed otherwise). Read the per-mark color from assets.
- **An isolated component render can be in a different theme mode than the screen.** If the
  `get_design_context` preview looks inverted vs. the overview export, trust the full-frame
  export and screen-level token values (ground truth), not the isolated preview.

### Type & fonts

- **Read exact type per text node — never eyeball it.** Pull `font-size`, `font-weight`,
  `line-height`, letter-spacing, and container padding/gap from `get_design_context`. A value
  outside the design's type ramp (e.g. `24px` when the ramp is 20/26/40/72) is a tell you guessed.
- **An off-brand `font-['Inter:…']` in the codegen usually means the Figma file is missing that
  weight of the brand font** and substituted a system font for just those layers. This is a
  decision, not an auto-fix: surface it — keep the brand font (correct for production) or bundle
  the fallback to match the mockup 1:1. Don't silently ship a non-brand font or silently "correct" it.
- **Fix the font before the size.** Different families size differently per px, so matching a
  size by eye with the wrong family gives a compensating value that's wrong once the right font
  loads. Set `font-family` first, then apply the design's real `font-size`.
- **Carry `font-feature-settings`, not just size/weight.** The node may specify figure style
  (`"lnum" 1, "pnum" 1` = proportional lining) vs the `tabular-nums` you'd default to; numbers
  look "off in style" if you ignore it.

### Icons

- **Use the design's real icon assets — never hand-draw `<path>` data from memory.**
  `get_design_context` returns each icon as an asset URL (usually SVG). Tint them by replacing
  `fill="var(--fill-0, …)"` with `fill="currentColor"` and setting the parent's `color`. Inline
  them (e.g. a small `icons.json` + one `Icon` component). Flag any stub as a placeholder.
- **Fetch every icon node individually — same label ≠ same icon.** Sibling tags with identical
  text can use entirely different glyphs; a message's alert icon can differ from a status row's.
  Use the icon the specific node references, not one reused from a sibling.
- **A layer's name can lie about geometry — verify the actual glyph.** A node named "Navigation
  Left" may hold a right-pointing arrow (the design flips it per instance); read the path/render
  and mirror with `scaleX(-1)` as the design does, or arrows come out reversed.

### Layout, spacing & constraints

- **Carry size constraints, not just padding/color — `min-width`/`min-height`/`max-width`.** A
  button's `min-w-[160px]` keeps a short label a full-width pill; a text block's `max-w-[Npx]`
  sets the wrap point (a body wrapping "too late" is usually a missing `max-width`, not a font bug).
- **Match the design's flex alignment** (`items-end` vs `center`) and let heights be
  content-driven where the design is; a header forced to `align-items: center` + fixed height
  when the design uses `items-end` shifts every title a few px.
- **`space-between` is not "evenly spaced with fixed pitch."** It stretches repeated marks
  edge-to-edge with a container-dependent pitch that drifts from the design's fixed pitch (a
  difference-overlay shows ghost "doubling"). Reproduce real pitch = mark-width + gap
  (`justify-center` + a set `gap`). Account for `stroke-linecap: round` rendering a line ~2px
  longer than nominal.
- **Don't double-render baked content.** If you bake a region into one image (a map that already
  contains rings/legend/labels), don't also re-render those elements as HTML/CSS on top — they
  mismatch and read as doubled. One source of truth per element; if you can't get a clean asset,
  choose the baked version deliberately and note baked text is no longer config-driven.

### Verify & deliver

- **Scale verification effort to the element — don't measure everything.** Default fidelity is
  cheap and applies to every element: read exact specs (the sections above) and eyeball **one**
  `difference`-blend overlay of your render on the design export (matching pixels go black).
  Escalate to precise measurement only when a specific element is flagged as still-off or the
  overlay shows drift you can't explain by eye: compare `getBoundingClientRect` to the Figma
  coords (boxes match but text still ghosts → inherent Figma-vs-browser glyph-baseline diff, not a
  bug to chase; boxes offset → real layout error). The canvas `getImageData` per-mark pass
  (center/height/color arrays) is **token-expensive — reserve it for one hero/repeated element the
  user flags**, never as a routine sweep. (See §6 for the constant-vs-growing offset diagnostic.)
- **Beyond §3's per-node fetch, don't reconstruct a rich sub-component from the overview
  screenshot.** A media card / carousel / chart has assets and styles you'll fake otherwise — a
  6-thumbnail strip is six *different* images, and image crops are explicit (Figma gives
  size/offset like `h-[152.58%] top-[-6.21%]` → replicate via `object-position`, not center `cover`).
- **Cache-bust when overwriting a hosted asset at the same URL.** In-place replacement keeps
  serving stale bytes to cached clients — server updated, app shows old. Version the filename or
  add `?v=N` and update the reference. Confirm the server serves new bytes AND the app fetches
  the new URL (separate failures).
- **"Looks wrong but your source matches" → suspect stale delivery before re-editing.** Diff the
  deployed asset against the design (byte size / pixel compare); if they match, the bug is
  delivery (cache, unmounted volume, stale dev bundle, wrong env), not the code.
- **Keep the `react-pixel-overlay` reference synced to the current design node.** When the design
  updates, re-export the overlay image from the *new* node at target resolution — a "doesn't
  match the overlay" report can just be a stale overlay image.

## Setup note

This skill needs a connected Figma MCP server. If the tools aren't available, the user needs to
authorize a Figma MCP connector first — e.g. via **claude.ai → Settings → Connectors**, or
`claude mcp` / `/mcp` for other setups.
