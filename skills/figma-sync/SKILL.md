---
name: figma-sync
description: Track drift between Figma designs and generated code with the figma-sync CLI — map components to Figma nodes, baseline design + code hashes, and report SYNC / DESIGN_CHANGED / CODE_CHANGED status. Use after generating or editing components from Figma, when the user asks whether code still matches the design, before regenerating a component, or to set up a design-drift gate in CI.
metadata:
  version: 1.0.0
  author: ART+COM
---

# figma-sync

`figma-sync` is our synchronization layer between Figma and generated source code. It is **not** a
code generator — it answers "is this component still aligned with its Figma node?" after a
generator (you, via the `figma-to-react` skill or similar) produced the code. Use it to decide
*which* components need regeneration and to prove a repo is design-clean before commit or in CI.

## Prerequisites

- The consuming project depends on the public npm package
  [`@artcom/figma-sync`](https://www.npmjs.com/package/@artcom/figma-sync)
  (source: [github.com/artcom/figma-sync](https://github.com/artcom/figma-sync)):

  ```bash
  npm install --save-dev @artcom/figma-sync
  ```

  Installing exposes the `figma-sync` binary to npm scripts and the
  `import { loadProject } from "@artcom/figma-sync"` library entry. Only when developing the tool
  itself, a sibling checkout via `"@artcom/figma-sync": "file:../figma-sync"` works too.
- Always run it from the consuming project's root — it reads/writes `.figma-sync/` in the current
  working directory.
- Live design checks need a `FIGMA_TOKEN` env var (Figma personal access token, scope
  `file_content:read` is sufficient — see the package's `docs/token-setup.md`). The CLI auto-loads
  the project's gitignored `.env`. Without a token, commands warn and fall back to committed
  snapshots, so `status` still runs offline/CI — it just reflects the last `capture`, not live
  Figma.

## Core model (read this before acting)

1. **Mapping comment** — every generated component carries one machine-readable line:

   ```jsx
   // figma-sync: file=dSRhp9PHg4w9Gnco2R19dg node=2267:1644 name=StatusCard
   ```

   `file` is the Figma file key, `node` the node id **with a colon** (URLs show `node-id=2267-1644`
   with a dash — convert it), `name` an optional display name. Format is exact; don't reword it.

2. **Manifest** — `.figma-sync/manifest.json` stores, per file: node reference, a deep-link `url`
   to the node, a **design hash** (canonicalized node properties), and a **code hash**
   (normalized source). `figma-sync update-manifest` writes it; commit the whole `.figma-sync/`
   directory.

3. **Ignore regions** — handwritten logic inside markers never counts as code drift:

   ```jsx
   // figma-sync-ignore-start
   ...custom business logic...
   // figma-sync-ignore-end
   ```

## Commands

```bash
figma-sync scan              # list annotated components → nodes
figma-sync update-manifest   # baseline current design + code state
figma-sync status            # drift report; exit ≠ 0 on any drift (CI gate)
figma-sync diff StatusCard   # which design properties changed since baseline
figma-sync capture           # refresh committed snapshots from the REST API (needs FIGMA_TOKEN)
figma-sync doctor            # validate manifest / annotations / snapshots
```

Projects usually wrap these as `npm run figma:status` etc. — check `package.json` and prefer the
project's scripts. `--json` gives machine-readable output; `--backend=snapshot|rest` overrides the
configured backend.

## Workflows

### Setting up a new project

1. `npm install --save-dev @artcom/figma-sync`, then add npm scripts (`figma:scan`,
   `figma:status`, `figma:update-manifest`, `figma:diff`, `figma:capture`, `figma:doctor`)
   that call the `figma-sync` binary.
2. Create `.figma-sync/config.json`: `{ "backend": "rest", "srcDir": "src" }`.
3. Annotate each generated component with its mapping comment.
4. `figma-sync capture` (with token), then `figma-sync update-manifest`, then confirm
   `figma-sync status` reports everything `SYNC`. Commit `.figma-sync/`.

### After generating or regenerating a component from Figma

Immediately: add/keep the mapping comment, run `figma-sync capture` (or `update-manifest` alone if
no token), then `figma-sync update-manifest`. A generation task is not finished until `status`
shows the component `SYNC`.

### Interpreting `status` — and what to do

| State | Meaning | Action |
| --- | --- | --- |
| `SYNC` | design and code match the baseline | nothing |
| `DESIGN_CHANGED` | Figma moved on | `figma-sync diff <name>` to see what changed, regenerate the component (e.g. `figma-to-react` skill), then re-baseline |
| `CODE_CHANGED` | manual edits outside ignore regions | if intentional handwritten logic → move it into an ignore region; if a deliberate divergence from the design → confirm with the user, then `update-manifest` to accept |
| `BOTH_CHANGED` | both drifted | reconcile manually: diff the design, port code changes, regenerate, re-baseline |
| `NODE_DELETED` | node gone from Figma (or snapshot missing) | ask the user whether to remove the component or fix the mapping; `capture` first to rule out stale snapshots |
| `FILE_DELETED` | source file gone | remove the manifest entry via `update-manifest` after confirming the deletion was intended |
| `UNMAPPED` | annotated file not in manifest | run `update-manifest` |
| `UNKNOWN` | backend error | check token / network; try `--backend=snapshot` |

Never blind-run `update-manifest` to silence drift — it redefines the baseline. Understand the
drift first; re-baseline only when code and design are genuinely reconciled.

### CI gate

`figma-sync status` exits non-zero on any drift. Wire it before build/test (e.g. a
`figma:status` step, or `prebuild`). The snapshot fallback keeps it working without a token;
schedule or instruct a `capture` refresh to keep snapshots honest. Colors auto-disable when piped
(`NO_COLOR` also respected).

## Gotchas

- Node ids: manifest/annotations use `2267:1644`; Figma URLs use `2267-1644`. The manifest's `url`
  field deep-links each entry — use it to open the node.
- `capture` and explicit `--backend=rest` hard-require `FIGMA_TOKEN`; everything else falls back to
  snapshots with a warning.
- Snapshots captured via non-REST sources (e.g. Figma MCP metadata) contain structural properties
  only, so purely cosmetic fill/typography changes may not flip the design hash until a REST
  `capture` runs.
- The design hash is configurable via `designFields` in `.figma-sync/config.json` — don't edit it
  casually; changing it flips every hash and requires a re-baseline.

## Library API

For programmatic use (scripts, other skills):

```js
import { loadProject } from "@artcom/figma-sync"

const project = await loadProject()
const status = await project.status() // [{ filePath, state, detail, ... }]
const diff = await project.diff("StatusCard") // { changes: [{ path, before, after }] }
```
