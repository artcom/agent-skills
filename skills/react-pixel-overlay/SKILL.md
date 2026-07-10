---
name: react-pixel-overlay
description: Set up and use react-pixel-overlay, ART+COM's PerfectPixel-style design overlay for React apps — it renders exported design images (e.g. Figma artboards) semi-transparently over the live page to verify pixel-perfect implementation. Use when the user says "pixel overlay", "design overlay", "onion skin", "PerfectPixel", "compare against the design", "check pixel-perfect", or wants to validate an implemented screen against a Figma/design export. Also use when adding new overlay images to an app that already uses the library, or when you encounter react-pixel-overlay or virtual:pixel-overlay-sources in existing code.
metadata:
  version: 1.0.0
  author: ART+COM
---

# React Pixel Overlay

**react-pixel-overlay** is ART+COM's in-project alternative to the PerfectPixel browser extension: a React component that overlays a semi-transparent design image (e.g. an exported Figma artboard) on the live page so implementation and design can be compared pixel by pixel. Because it's checked into the project instead of installed per-browser, every developer, reviewer, and agent-driven screenshot sees the same QA tool.

- Repository: https://github.com/artcom/react-pixel-overlay
- Plain React + CSS modules, no styling-library dependency; rendered via a portal on `document.body`; SSR-safe
- Peer deps: `react` and `react-dom` >= 17

> **For the latest API details**, read the package README — it is the authoritative source. This skill covers setup, the intended workflow, and the gotchas.

## What it provides

- **Overlay images** from a `sources` list, selectable in a dropdown — or drop/paste any PNG/JPG/SVG onto the page at runtime
- **Blend modes**: normal, **difference** (identical pixels go black, deviations light up — try this first), multiply, overlay, plus color invert
- **Pixel positioning**: drag the image, nudge with arrow keys (Shift = 10 px), numeric X/Y/scale inputs
- **Click-through lock** so the page beneath stays usable while the overlay is shown
- **Persistence** of all settings (and dropped images) in `localStorage`, namespaced per `storageKey`
- Keyboard shortcuts: `O` show/hide · `L` lock · `B` blend · `I` invert · arrows move · `1`–`9`/`0` opacity

## Setup in a Vite + React app

1. **Install** (match the project's convention for `dependencies` vs `devDependencies` — some deployment setups need everything in `dependencies`):

   ```sh
   npm install react-pixel-overlay
   ```

   If the package isn't available from the registry yet, install it as a git dependency (`"react-pixel-overlay": "github:artcom/react-pixel-overlay"`) or from a local checkout (`"file:../react-pixel-overlay"`).

2. **Create the overlay folder** and put design exports in it: `public/design-overlays/`. Export each design at the app's exact target resolution (e.g. a 3840×2160 artboard for a 4K screen) — the image renders at natural size from the page's top-left corner. Name files after the screen they show (`app.png`, `settings.png`).

3. **Register the Vite plugin**, which scans that folder at dev/build time and exposes the file list as a virtual module (a browser can't list a server directory):

   ```js
   // vite.config.js
   import { pixelOverlaySources } from "react-pixel-overlay/vite"

   export default defineConfig({
     plugins: [react(), pixelOverlaySources()], // default folder: public/design-overlays/
   })
   ```

   In dev the folder is watched — adding or removing an image reloads with an updated dropdown.

4. **Mount the component, gated so it never ships to end users.** The established ART+COM pattern is dev builds plus a `?overlay` URL escape hatch for production builds:

   ```jsx
   import { PixelOverlay } from "react-pixel-overlay"
   // eslint-disable-next-line import/no-unresolved -- exports subpath, resolved by Vite
   import "react-pixel-overlay/styles.css"
   // eslint-disable-next-line import/no-unresolved -- virtual module from pixelOverlaySources()
   import overlaySources from "virtual:pixel-overlay-sources"

   const overlayEnabled =
     import.meta.env.DEV || new URLSearchParams(window.location.search).has("overlay")

   // in the root component's render:
   {overlayEnabled && <PixelOverlay sources={overlaySources} storageKey="<app-name>-overlay" />}
   ```

   Give every app a unique `storageKey` — settings live in `localStorage`, and apps sharing an origin (common with local dev servers) would otherwise overwrite each other.

## Props

| Prop         | Type                              | Default           | Description |
| ------------ | --------------------------------- | ----------------- | ----------- |
| `sources`    | `Array<string \| { label, src }>` | `[]`              | Overlay images for the dropdown; string entries are labeled by filename |
| `src`        | `string`                          | –                 | Shorthand for a single image; prepended to `sources` |
| `storageKey` | `string`                          | `"pixel-overlay"` | `localStorage` namespace for settings and the dropped image |
| `zIndex`     | `number`                          | `2147482000`      | z-index of the image; the panel uses `zIndex + 1` |

## Gotchas — Read These First

1. **Local/git checkouts need React dedupe.** With a symlinked `file:` dependency, Vite resolves the package's own `node_modules/react`, bundling two React copies → "invalid hook call". Add to the consuming app's Vite config:

   ```js
   resolve: { dedupe: ["react", "react-dom"] }
   ```

   Not needed for a registry install.

2. **Images render at natural size.** There is no automatic fit-to-viewport. Export designs at the exact target resolution; the panel's scale input is a fallback, not the workflow.

3. **`import/no-unresolved` false positives.** `eslint-plugin-import` can't resolve the `react-pixel-overlay/styles.css` exports subpath or the `virtual:pixel-overlay-sources` module. Both need an `// eslint-disable-next-line import/no-unresolved` (see the mount example above).

4. **Not using Vite?** Skip the plugin and pass any `string[]` or `{ label, src }[]` to `sources` — e.g. from a hand-written manifest file. Only the folder-scanning plugin is Vite-specific; the component itself is bundler-agnostic.

5. **Dropped images and the localStorage quota.** Dropped/pasted images are persisted as data URLs; images beyond the ~5 MB quota still work but won't survive a reload (a console warning is logged). Images from `sources` are unaffected.

6. **TypeScript consumers**: type the virtual module by referencing `react-pixel-overlay/virtual` in tsconfig `types`.

## Typical QA workflow

1. Export the Figma artboard at target resolution into `public/design-overlays/`.
2. Start the dev server; the panel appears top-right (or use `?overlay` on a build).
3. Pick the image in the dropdown, press `O` to show it, set opacity ~50% to eyeball alignment.
4. Switch blend mode to **difference**: matching areas go black, any misalignment lights up as ghost edges. Nudge with arrow keys to measure offsets in pixels.
5. Fix the CSS, watch the ghosting disappear, hide with `O`.

When verifying a change with an agent-driven screenshot (headless Chrome etc.), the overlay state can be pre-seeded before page load by writing the settings JSON to `localStorage` under the app's `storageKey` (e.g. `{"visible":true,"opacity":1,"blend":"difference"}`).
