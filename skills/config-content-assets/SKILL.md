---
name: config-content-assets
description: Externalize a web app's hard-coded texts and media (images, icons, SVGs) into ART+COM's configuration repository and storage/asset server, referenced via the ${storageServerUri} variable, so content and assets can be updated without redeploying the app. Use when moving strings/images out of code into a remote config, wiring an app to consume that config, setting up the three-folder Application/Configuration/Assets workspace, or when Figma-generated assets that would normally land in public/ should instead be hosted on the asset server and referenced from config.
metadata:
  version: 1.0.0
  author: ART+COM
---

# Config-driven content & assets

ART+COM installation apps ship the _code_ separately from their _content_. Copy, labels, numbers,
and media are pulled at runtime from a **configuration repository** (delivered as JSON, usually over
MQTT) and a **storage/asset server** (static files served over HTTP). This lets an operator change a
headline or swap an image by editing config or replacing a file on the asset server — **no rebuild,
no redeploy**.

This skill covers moving hard-coded content out of an app into that pipeline, and the reverse-safe
conventions for referencing it. It is deliberately **stack-agnostic**: detect how the target app
already loads config and hosts assets, then follow that — don't impose a new mechanism.

> When this skill conflicts with the project's own `AGENTS.md` / `CLAUDE.md`, the project wins.

## The three moving parts

| Part                         | What it holds                                                       | How the app gets it                                       |
| ---------------------------- | ------------------------------------------------------------------- | --------------------------------------------------------- |
| **Application Repository**   | Code only. Reads content/assets at runtime.                         | this repo                                                 |
| **Configuration Repository** | `index.json` (+ action lists etc.) with all text and asset **URLs** | fetched at runtime (MQTT retained topic / HTTP)           |
| **Assets Server**            | The actual binary files (png, jpg, mp4, static svg…)                | served over HTTP; mounted locally as a volume for editing |

The Configuration Repository never stores binaries — it stores **references** to files on the Assets
Server, built from the `${storageServerUri}` variable.

## Prerequisite: the three-folder workspace

Work happens in a VS Code multi-root workspace that mounts all three parts side by side. If it isn't
set up yet, create/extend a `*.code-workspace` in the app repo. Example for an app called `tvApp`:

```jsonc
{
  "folders": [
    { "path": ".", "name": "Application Repository" },
    {
      "path": "../configuration-production/tour/useCases/areas/home/tvApp",
      "name": "Configuration Repository",
    },
    {
      "path": "../../../../../../Volumes/storage-service/config/tour/data/useCases/home/tvApp",
      "name": "Assets Server",
    },
  ],
  "settings": {},
}
```

Notes:

- **The two paths are not the same shape.** The config folder lives under
  `configuration-production/tour/useCases/<useCasePath>`, while the asset folder lives under the
  mounted storage volume at `config/tour/data/useCases/<useCasePath>` — and the asset path drops the
  leading `areas/` segment (e.g. config `areas/home/tvApp` ↔ assets `home/tvApp`). Confirm the exact
  layout against a sibling use case that already ships assets rather than guessing.
- **The storage volume must be mounted** (SMB/AFP) to write files locally. Its mount name varies per
  environment (e.g. `storage-service`) — which is exactly why the
  config references `${storageServerUri}` and never a literal host.
- Relative paths in a workspace resolve from the workspace file's directory. To compute the `../…`
  hop to the mounted volume:
  `python3 -c "import os,sys;print(os.path.relpath(sys.argv[1], sys.argv[2]))" /Volumes/<storage>/config/tour/data/useCases/<useCasePath> "$PWD"`
- `scripts/check-prerequisites.sh` in this skill verifies the workspace has both extra folders and
  that the Assets Server volume is mounted.

## Step 1 — Learn the app's config plumbing before editing anything

Do **not** assume a mechanism. Find the real one:

- How is config delivered and read? Look for a config provider/hook (e.g. a `useConfig()` hook, a
  context provider, an MQTT query on a `baseTopic`). Grep for `useConfig`, `ConfigProvider`,
  `baseTopic`, `configTopic`, `storageServerUri`.
- **Is rendering gated on config?** If the provider shows a fallback (“Loading configuration…”)
  until the config arrives, then every component below it can read config unconditionally — a
  _config-only_ migration (no in-code fallbacks) is safe. If components can render _before_ config
  loads, keep in-code fallbacks. Decide this explicitly (ask the user if unclear).
- **How are variables resolved?** Values like `${tour}` and `${storageServerUri}` in the config are
  substituted **server-side before the app receives them** (confirm by checking whether existing
  config values with `${…}` are used verbatim by the app). This is why the config repo always keeps
  the _variable_ — the app receives an already-resolved URL/host and needs no resolution logic.
- Note existing conventions for asset filenames — a linter may enforce **camelCase** file names
  (names starting with a digit or containing hyphens will warn).

## Step 2 — Shape the config

Add (or extend) two blocks in the Configuration Repository's `index.json`. Group by feature/screen so
an operator can find things:

```jsonc
{
  // …existing config…
  "assets": {
    "heroImage": "${storageServerUri}/config/tour/data/useCases/home/tvApp/heroImage.png",
    "logo": "${storageServerUri}/config/tour/data/useCases/home/tvApp/logo.png",
  },
  "content": {
    "home": {
      "title": "Welcome",
      "subtitle": "Tap to begin",
      "cta": "Start",
    },
    "items": [
      { "id": "a", "label": "First", "value": "42%" },
      { "id": "b", "label": "Second", "value": "17%" },
    ],
  },
}
```

Conventions:

- **Text → `content`.** Every user-visible string: titles, labels, button text, copy, units,
  formatted values, fallback display values.
- **Media → `assets`.** Each value is a full URL built from `${storageServerUri}` — always the
  variable, never a literal host. Path mirrors the Assets Server folder:
  `${storageServerUri}/config/tour/data/useCases/<useCasePath>/<file>`.
- **Keep structure/behavior in code.** IDs, icon keys, tone flags, sort order, `locked` states, and
  animation params are code concerns — put the _text_ of a list item in config, keep the wiring
  (which icon component, which handler) in code, and join them by a stable `id`.
- Multi-line copy: store as an array of lines (`["line one","line two"]`) and join with `<br/>` at
  render time, rather than embedding markup in the string.

## Step 3 — Refactor components to read from config

- Replace each literal with a read from the config hook (`const { home } = useConfig().content`).
- Replace each bundled asset import (`import logo from "../assets/logo.png"`) with the config URL
  (`const { logo } = useConfig().assets` → `<img src={logo} />`). Then the file no longer needs to be
  in the app bundle.
- **Module-level constant tables can't call a hook.** If titles/labels live in a plain module (e.g. a
  screen-definitions table), thread `config.content` in from the nearest hook/component and read text
  from it there; leave the structural table in the module.
- **Keep inline, animated SVGs in code.** Hand-authored SVG React components (framer-motion draws,
  computed paths, gradients) are code, not assets — externalizing them to static `.svg` files loses
  the animation. Only externalize their _text/values_. Externalize genuine static media (raster
  images, standalone static svgs/icons, video) to the asset server.
- After migrating, **remove the now-dead literals and imports** (unless you deliberately kept
  fallbacks). Grep to confirm none remain: `grep -rn "assets/" src` should be empty of asset imports.

## Step 4 — Host the assets

- Copy each externalized file into the **Assets Server** workspace folder, renaming to the project's
  convention (camelCase; no leading digits or hyphens). Keep the config `assets` URL filename in sync.
- If the storage volume isn't mounted, you can't write the files — say so and hand the upload to the
  user (with the source→target filename mapping), or ask them to mount it. Don't silently skip it.
- **Never delete anything from the Assets Server.** Adding or overwriting files is fine; removing
  them is **always a human action**. The asset server is shared and other apps/config may reference a
  file — if something looks unused or stale, flag it for the user to remove, never delete it yourself.
- The old in-repo asset files (inside the Application Repository) become unused once nothing imports
  them; delete those **after** they're confirmed on the asset server. This applies only to the app
  repo — never to the Assets Server.

## Figma → React: send exported assets to the asset server, not `public/`

In a Figma-to-code flow, `download_assets` / codegen will export images and reference them by a
static bundle path (commonly `public/…` or a bundled import). In this pipeline, **redirect that
last step**:

1. Export the asset from Figma as usual.
2. Save it into the **Assets Server** folder (camelCase name) instead of `public/`.
3. Add an `assets` entry in the config repo pointing at it via `${storageServerUri}/…`.
4. In the component, read the URL from config and render it — do **not** bundle the file or hardcode a
   `/public` path.

This keeps Figma-sourced imagery updatable without a redeploy and out of the app bundle, consistent
with the rest of the app's content.

## Verification

- Config JSON parses: `node -e "JSON.parse(require('fs').readFileSync('<index.json>','utf8'))"`
  (note: `*.code-workspace` files are JSONC and may contain trailing commas — that's fine there, but
  `index.json` must be strict JSON).
- Run the app's own lint and build commands (from `package.json`; a `/run` skill can launch it).
- No stray literals/imports remain (grep as above).
- Every `assets` URL resolves once the volume is mounted (the config-repo linter reports missing
  resolved paths until the files exist on the server).
- Confirm text and images render from config in the running app.

## Gotchas

- **Never delete files from the Assets Server** — it's shared and may be referenced elsewhere.
  Deletion is always a human action; flag stale files, don't remove them.
- **Never hardcode the storage host.** Always `${storageServerUri}`; the mount/host differs per
  environment and is resolved outside the app.
- **Config-only reads are only safe when rendering is gated on config.** Otherwise keep fallbacks.
- **The config path and asset path differ** (`areas/` present in config, absent in the asset path) —
  mirror an existing use case, don't assume symmetry.
- **Don't externalize animated inline SVGs** into static files; you'll lose behavior.
- **Filename convention matters** — a linter may reject non-camelCase asset names.
