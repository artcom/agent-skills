---
name: figma-preflight
description: Preflight a Figma file for design-to-code fidelity BEFORE generating React. Detects source-fixable defects — unbound colors, collapsed surface-elevation tokens, wrong page-bg binding, off-ramp/overridden type, substituted brand fonts, unpinned theme modes, packing/constraint gaps — then either reports them for the designer to fix or, when the user owns the file, repairs them in Figma. Use before `figma-to-react` codegen, when a generated screen keeps reading "slightly off" and the root cause is the source node, or when the user asks to prepare/audit/clean up a Figma file for handoff. Requires the Figma MCP connector.
metadata:
  version: 1.0.0
  author: ART+COM
---

# Figma preflight (prepare the source before codegen)

Many "the screen is slightly off" bugs are not code-reading failures — they are **Figma hygiene
problems** the codegen is being asked to paper over. Fixing the source node is strictly better than
compensating downstream every time the design is regenerated: an unbound color, a collapsed
elevation ladder, or a substituted brand font will re-break on the next export no matter how
carefully the last implementation compensated.

This skill runs **before** [`figma-to-react`](../figma-to-react/SKILL.md) codegen (or when a
"done" screen keeps reading off and you suspect the source). It walks the source-fixable items from
that skill's §7 pixel-fidelity checklist, detects which are present, and resolves each — either by
**reporting** it for the designer or by **fixing** it in Figma when that's in remit.

Scope note: this catches the items that can move upstream (tokens/color binding, type/fonts, theme
mode, layout packing). It does **not** replace §7 — data-driven marks, `font-feature-settings`,
icon export/reading, baked-content decisions, and all verify/deliver concerns have no Figma
equivalent and stay in `figma-to-react`. Each check below cross-references its §7 bullet.

## 1. Choose the mode (ask once, up front)

This skill can operate two ways. Editing a source file may not be within the implementer's remit —
the file is often the designer's. So **ask the user once, before inspecting** (e.g. via
`AskUserQuestion`) which mode applies for this run:

- **Report mode** — read-only. Detect every source-fixable defect and produce a checklist to
  **verify or request** from whoever owns the design. Never call a Figma write tool. This is the
  safe default and matches `figma-to-react`'s read-only stance. Use it whenever the implementer does
  not clearly own or co-own the file.
- **Fix mode** — read-write. The user owns/co-owns the file and wants defects **repaired in Figma**
  (bind variables, apply text styles, pin modes, etc.) via the write-capable Figma MCP tools. Before
  any write, load the **`figma-use`** skill (MANDATORY prerequisite for `use_figma`) and confirm the
  target file/branch. Make changes on a branch or with the user's explicit go-ahead — never edit a
  shared design file silently.

In a non-interactive run where the user cannot be asked, default to **report mode** and note the
assumption in the summary. If the user picks fix mode but a specific defect is outside their remit
(e.g. a library-level variable owned by another team), report that one instead of forcing a write.

## 2. Gather source context

Same read flow as `figma-to-react` §3 — do this once for the node(s) in scope:

1. `get_design_context` for the target node(s) (some connectors: `get_code`). If truncated, use
   `get_metadata` for the node map and re-fetch the needed children.
2. `get_variable_defs` for the variable bindings actually present.
3. `get_screenshot` (aka `get_image`) of the full frame for the ground-truth render — used to sanity
   the isolated-mode and elevation checks.

Keep the full-frame export as ground truth; isolated component previews can differ from it (see the
theme-mode check).

## 3. Preflight checks

For each check: **detect** from the context above, then in report mode record a checklist line, or
in fix mode apply the repair (loading `figma-use` first). Order roughly clearest-win first.

### Tokens & color

- **Unbound colors → generic `var(--token, black)` fallback.** *Detect:* colors in
  `get_design_context` that carry no variable binding, or `get_variable_defs` that omits fills the
  design clearly uses; codegen then writes literal `black`/`white` fallbacks. *Fix:* bind every color
  layer to the correct semantic variable so `get_variable_defs` is authoritative. *Report:* list each
  unbound layer and the variable it should bind to. (Prevents §7 "Never trust the fallback literal in
  `var(--token, fallback)`.")
- **Page background not bound to a background token.** *Detect:* the top frame's fill is a raw hex, or
  a token whose name doesn't match its role (e.g. a `surface` screen filled with the near-black
  `background` token). *Fix:* bind the frame fill to the correct semantic variable. *Report:* name the
  frame and the intended token. (Prevents §7 "Don't assume the page background is the `background`
  token.")
- **Collapsed surface-elevation ladder.** *Detect:* adjacent surfaces (page / card / tile / inset)
  share one variable or use raw near-identical neutrals, so nested insets have no contrast. *Fix:*
  bind each elevation level to a distinct semantic variable (`surface/page`, `surface/card`,
  `surface/inset`) preserving relative order. *Report:* list the levels that collapsed and the
  distinct tokens they need. (Prevents §7 "Preserve the surface-elevation ladder.")

### Type & fonts

- **Substituted brand font (`font-['Inter:…']` in codegen).** *Detect:* codegen emits a system/Inter
  family on layers that should be the brand font — the file is missing that brand-font *weight* and
  Figma substituted. *Fix:* install/embed the correct brand-font weight in the file so codegen emits
  the real font. *Report:* flag as a decision (embed brand weight vs. intentionally match the
  substituted mockup) — don't silently "correct" it. (Prevents §7 "An off-brand `font-['Inter:…']`
  usually means the file is missing that weight.")
- **Off-ramp / manually-overridden type.** *Detect:* text nodes with sizes/weights/line-heights
  outside the design's shared text styles (e.g. `24px` when the ramp is 20/26/40/72), or ad-hoc
  overrides instead of an applied text style. *Fix:* apply the shared Figma text styles so every node
  reports a consistent, on-ramp spec. *Report:* list the off-ramp nodes and the style they should
  use. (Prevents §7 "Read exact type per text node" churn and the eyeballed-size tell.)

### Theme mode

- **Instances with no pinned variable mode.** *Detect:* component instances whose mode is unset, so an
  isolated render can appear in a different theme than the screen. *Fix:* pin the explicit mode on the
  instances so the isolated preview matches the full-frame export. *Report:* list the instances and
  the mode to pin. (Prevents §7 "An isolated component render can be in a different theme mode.")

### Layout (partial — better source reduces guessing, reading discipline still needed)

- **Packing instead of fixed pitch / missing size constraints.** *Detect:* auto-layout set to
  "space between" where the design intends fixed pitch, or frames lacking real `min`/`max` width so
  codegen can't emit `gap` + constraints. *Fix:* configure auto-layout with a fixed gap and real
  min/max on the relevant frames. *Report:* name the frames and the intended gap/constraints. (Reduces
  §7 "`space-between` is not evenly-spaced fixed pitch" and "carry min/max constraints" — but the
  code-side reading in `figma-to-react` still applies.)
- **Auto-layout alignment (`items-end` vs `center`).** *Detect:* alignment that doesn't match the
  design intent. *Fix:* set the correct auto-layout alignment. *Report:* note the frame. (Partial —
  still a reading step in codegen.)

### Not covered here (stays in figma-to-react §7)

Data-driven mark color, `font-feature-settings`, real-icon export / per-node icon fetch / no
hand-drawn paths, layer-name-vs-geometry flips, don't-double-render baked content and image crops,
and everything under "Verify & deliver" (difference overlay, cache-busting, stale delivery,
`react-pixel-overlay` sync). These are inherent to codegen or delivery and can't move upstream —
handle them during and after implementation per §7.

## 4. Output

- **Report mode:** a grouped checklist (tokens & color / type & fonts / theme mode / layout), each
  line naming the specific node, the defect, and the concrete source fix to request — ready to hand
  to the designer. State clearly that codegen should wait on the token/font items, since those
  silently invert colors or ship the wrong typeface.
- **Fix mode:** a summary of what was changed in Figma (per node), what was left as a report item
  (out of remit or ambiguous), and confirmation to re-run `get_variable_defs` / `get_design_context`
  so the downstream `figma-to-react` run sees the repaired source.

Then hand off to `figma-to-react` for the actual codegen — the remaining §7 items apply there.

## Setup note

This skill needs a connected Figma MCP server (read tools always; write tools for fix mode). If the
tools aren't available, the user needs to authorize a Figma MCP connector first — e.g. via
**claude.ai → Settings → Connectors**, or `claude mcp` / `/mcp` for other setups.
