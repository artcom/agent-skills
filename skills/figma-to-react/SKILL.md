---
name: figma-to-react
description: Translate a Figma design into React code that matches the target project's own styling approach, design tokens, and components. Use whenever the user shares a Figma link/node, asks to implement or build UI from a Figma design, or wants existing UI matched 1:1 to Figma. Requires the Figma MCP connector.
metadata:
  version: 1.2.0
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

## Setup note

This skill needs a connected Figma MCP server. If the tools aren't available, the user needs to
authorize a Figma MCP connector first — e.g. via **claude.ai → Settings → Connectors**, or
`claude mcp` / `/mcp` for other setups.
