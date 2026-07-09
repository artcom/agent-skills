---
name: figma-to-react
description: Translate a Figma design into React code that matches the target project's own styling approach, design tokens, and components. Use whenever the user shares a Figma link/node, asks to implement or build UI from a Figma design, or wants existing UI matched 1:1 to Figma. Requires the Figma MCP connector.
metadata:
  version: 1.0.0
  author: ART+COM
---

# Figma → React

Rules for turning a Figma design into React code. This skill is deliberately stack-agnostic: detect
the target project's real conventions first, then follow them — never impose a styling system,
resolution, or constraint the project doesn't already have.

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

## 2. Required flow (do not skip)

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
   implement.
7. **Verify 1:1** against the screenshot (see Verification) before marking the task complete.

## 3. Implementation rules

- Treat MCP output as a *representation* of design and behavior, not as final code. Rewrite it into
  the project's own idioms (its component style, file layout, and styling approach).
- Map Figma **Auto Layout** directly to `display: flex` / `display: grid` (or the equivalent utility
  classes) with the exact gaps, padding, and sizes from the node data — do not approximate spacing.
- Reuse tokens, existing components, and typography wherever possible. Match the surrounding code's
  naming and structure.
- Respect existing routing, state, and data-fetch patterns already in the repo.
- When Figma and an existing token conflict, prefer the token and adjust spacing/size minimally to
  match, rather than hardcoding the Figma value.

### Components

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
  etc.) for any typeface Figma specifies.

## 4. Anti-hallucination constraints

- **No guessing styles.** If a property (`border`, `box-shadow`, `border-radius`…) is not in the
  Figma node data, do not add it to the CSS.
- **Color integrity.** Only use colors defined in Figma variables or existing project tokens. If a
  hex is within ~5% brightness of an existing token, use the token. If there's no close match,
  **ask before proceeding** — never invent a value.
- **Ghost outlines.** Only add `outline`/`border` if it exists as an explicit **Stroke** in Figma.
  Never add borders for visual separation the design doesn't have.
- **No absolute positioning** unless the Figma layer is explicitly "Absolute position".
- **Zero-margin policy.** All spacing comes from Figma Auto Layout → tokens/px. Don't rely on
  default browser margins/paddings.
- **Truncated data:** never fill gaps with assumptions — use `get_metadata` then re-fetch the real
  node(s).

## 5. Verification

- After the first implementation, re-fetch `get_screenshot` and compare against the rendered code.
- Fix any layout drift, spacing mismatch, wrong color, or extra border **before** finishing. If the
  screenshot has a clean background but your CSS added a border, remove it.
- Run the app with its own dev command from `package.json` (a `/run` skill, if installed, can launch
  it for you) to visually confirm.
- Lint using the project's own lint command before finishing.

## Setup note

This skill needs a connected Figma MCP server. If the tools aren't available, the user needs to
authorize a Figma MCP connector first — e.g. via **claude.ai → Settings → Connectors**, or
`claude mcp` / `/mcp` for other setups.
