---
name: design-diff
description: Verify a rendered screen matches its Figma design reference, and diagnose why it doesn't, with the design-diff CLI — a programmatic pass/fail gate plus a ranked diagnosis (font-metrics mismatch, uniform offset, DOM-attributed hotspots) instead of a bare pixel-diff percentage. Use after implementing or updating a screen from Figma, when a difference-blend overlay shows drift you can't explain by eye, when the user asks whether a screen is pixel-perfect, or to set up a visual-regression gate in CI.
metadata:
  version: 1.0.0
  author: ART+COM
---

# design-diff

`design-diff` is a CLI and library that answers "does this render match its design
reference, and if not, why?" It is **not** a code generator — it measures what
[`figma-to-react`](../figma-to-react/SKILL.md) (or any other pipeline) produced. Use it to
turn "looks slightly off" into a specific element and a specific cause, and to gate a
build on visual regressions instead of eyeballing a screenshot.

Companion to [`figma-measure`](../figma-measure/SKILL.md): that skill covers the general
measurement mechanisms (overlay, box geometry, pixel statistics) and when to reach for
which. This skill is the deep reference for one of them — prefer `design-diff` over
hand-rolling a pixel-statistics script whenever it's available in the project.

## Prerequisites

- The consuming project depends on the public npm package
  [`@artcom/design-diff`](https://www.npmjs.com/package/@artcom/design-diff)
  (source: [github.com/artcom/design-diff](https://github.com/artcom/design-diff)):

  ```bash
  npm install --save-dev @artcom/design-diff
  npx playwright install chromium     # or point DESIGN_DIFF_CHROMIUM at a binary
  ```

- A `design-diff.config.js` at the project root (see Config below).
- `capture` (exporting reference PNGs from Figma) needs a `FIGMA_TOKEN` env var. `verify`
  and `explain` don't — they only read PNGs already on disk, so they run fine in CI
  without a token as long as references are committed.
- The app must actually be running at `config.baseUrl` before `verify`/`explain`/`capture`
  — this tool does not start a dev server for you.

## Core model

`design-diff.config.js`:

```js
export default {
  baseUrl: "http://localhost:5173",
  viewport: { width: 1080, height: 1920 },
  referenceDir: "public/design-overlays",
  outDir: "design-diff-output",
  figma: { fileKey: "…" },
  hide: ["[class*='_devPanel_']"],
  overlay: { storageKey: "my-app-overlay" },
  mqtt: { brokerUrl: "mqtt://localhost:1883", baseTopic: "app" },
  scenarios: [
    { name: "ready", node: "4814:189355", prepare: [{ click: 'button:text-is("ready")' }] },
    { name: "detail", node: "4814:188845", path: "/?step=detail" },
  ],
}
```

- **`referenceDir`** defaults to the folder
  [`@artcom/react-pixel-overlay`](https://github.com/artcom/react-pixel-overlay) already
  scans — if the project uses that skill's overlay too, the same exports serve both.
- **`scenarios[].node`** is a Figma node id (colon or dash form — a URL's `node-id=4814-189355`
  works as-is). Required for `capture`, not for `verify`/`explain` once a reference PNG exists.
- **`prepare`** steps are declarative on purpose (`click`, `waitFor`, `waitMs`, `key`, `type`,
  `mqtt`) — Playwright can't serialise a closure into the page, so callbacks aren't an option.
  `mqtt` publishes `{ topic, payload, retain?, qos? }` for apps whose state is driven over a
  message broker rather than the DOM; `topic` resolves against `mqtt.baseTopic` unless it
  starts with `/`.
- **`hide`** lists selectors for dev-only chrome (a debug panel, a scenario switcher) that
  must never appear in a capture. `vite-error-overlay` is always hidden and always still
  checked for, since a hidden-but-present error overlay means the app actually broke.
- **References must match `viewport` exactly** — a scaled reference produces plausible-looking
  numbers that mean nothing, so a mismatch is a hard error, not a warning.

## Commands

```bash
design-diff doctor                  # preflight: browser, dev server, reference sizes, hide list
design-diff capture [scenario...]   # export reference PNGs from Figma (needs FIGMA_TOKEN)
design-diff verify  [scenario...]   # verdict per scenario; --json; exit 1 on mismatch
design-diff explain <scenario>      # ranked diagnosis of why it differs
```

`verify` and `explain` accept `--save-captures`, which writes the raw capture and a
`difference`-blend PNG (capture composited on the reference; matching pixels go black) per
scenario into `config.outDir`. Reach for this when you need to actually look at a
mismatch rather than just read the numbers — it's the same overlay technique
`figma-to-react`'s default fidelity pass already uses, produced without opening a browser.

## Workflows

### Setting up a new project

1. `npm install --save-dev @artcom/design-diff`, `npx playwright install chromium`.
2. Write `design-diff.config.js` with one scenario per screen/state that matters.
3. `design-diff capture` (needs `FIGMA_TOKEN`) to populate `referenceDir`.
4. `design-diff doctor` to confirm the setup, then `design-diff verify` to baseline.

### After implementing or regenerating a screen from Figma

Run `design-diff verify <scenario>` as part of verification, not instead of reading the
export by eye — this tool finds pixel mismatches, not wrong copy or a stale value (see
"Read the design, don't just diff it" in `figma-to-react`). If it fails, `design-diff
explain <scenario>` before touching any CSS: the findings are ordered so the first one is
the thing worth acting on, and later findings are often downstream symptoms of the first.

### Reading `explain`'s findings, in order

1. **environment** — dev-only UI still visible, a Vite error overlay, page errors. Nothing
   else is trustworthy until this is clean; a large diff is a reason to doubt the capture
   before touching any CSS.
2. **font-metrics** — an offset that *grows with font size*. That signature means the app
   isn't loading the files the design composes text from (typically a variable font
   against static per-weight faces), not that a margin is wrong — see `figma-to-react` §4
   Tokens. A ≤1px spread across sizes is the baseline-rounding floor, not a defect: browsers
   snap glyph baselines to whole pixels where Figma places them on fractions.
3. **uniform-offset** — one global shift. Demoted to an informational note when the font
   probe already explains it, since chasing container padding for a font problem wastes a
   step.
4. **hotspots** — blocks where a large share of pixels differ by a moderate amount or more,
   attributed to the DOM element under them (`div.circle.active`, not `block (60,180)`).
   This catches a sharp, high-contrast mismatch (wrong text) *and* a large, lower-contrast
   one (a whole icon that's missing or extra) — block coverage is what's ranked, not the
   single darkest pixel in it.
5. **baseline-rounding** — the residual floor on a passing scenario, labelled as expected.

### CI gate

`design-diff verify` exits non-zero on any mismatch. Wire it as a build/test step; it
needs the app running and references already committed, but no `FIGMA_TOKEN` unless the
step also runs `capture` first to refresh them.

## Gotchas

- **Offset scans are integer-only.** Sub-pixel transforms don't move text — browsers snap
  glyph baselines to whole pixels — so don't expect (or chase) sub-pixel offsets.
- **The comparison runs inside the page via `<canvas>`**, so there's no image library in
  the Node dependency tree and nothing extra to install beyond Playwright's browser.
- **A capture against a dev server must never include the dev server's own chrome.**
  Project-specific dev-only UI needs its own selector in `hide`; `design-diff doctor`
  reports which selectors are actually active, so you can tell defaults from what a
  project added.
- **`verify`'s gate also fails on a single bad block** (`tolerance.worstBlockPct`, default
  20%), not just on the frame-wide mean — a small, entirely-wrong control barely moves a
  whole-screen average, so a mean-only gate would pass right over it.
- **Suppress any design-overlay component during capture** via `config.overlay.storageKey`
  (matching [`react-pixel-overlay`](../../react-pixel-overlay/SKILL.md)'s storage key) —
  otherwise the render gets diffed against the reference already composited on top of
  itself, which reads as a ~75% difference and nothing else the checklist above says
  points at the real cause.

## Library API

For programmatic use (scripts, other tooling):

```js
import { loadConfig, verify, explain } from "@artcom/design-diff"

const config = await loadConfig()
const results = await verify(config) // VerifyResult[]
const diagnosis = await explain(config, "ready") // ExplainResult
```

## Setup note

Needs a project with a running dev server and, for `capture`, a Figma personal access
token (`FIGMA_TOKEN`, scope `file_content:read` is sufficient). `verify`/`explain` need
only committed reference PNGs and work fully offline/CI once those exist.
