---
name: story-publisher
description: Add and drive a Story Publisher (stp) story for an ART+COM app to test use-case flows end-to-end against the broker, tours, and remote/local configuration. Use when the user wants to add a story to an app, print a webapp URI with the bootstrap query parameters, create a tour, open a webapp display, start a use case, publish to the broker, or debug MQTT for a use case. Also use when you encounter a `story/` folder, a `story` npm script, or `stp -s ... -c ...` in an app.
metadata:
  version: 1.0.0
  author: ART+COM
---

# Story Publisher

**Story Publisher** (CLI binaries `stp` / `story-publisher`) is ART+COM's tool for testing
installation **use-case flows** end-to-end. It bootstraps a device, creates or reuses a **tour**,
connects to the MQTT broker, and gives a story script a set of **macros** to open webapp
displays, start use cases, publish to the broker, and — most commonly — **print a webapp URI**
carrying all the bootstrap query parameters a webapp needs to run.

- Repository: the internal ART+COM Story Publisher repo (ask your team for the URL).
- Runs on Node.js 22. Installed globally from its repo: `cd <story-publisher-repo> && npm i -g`
  (registers the `stp` and `story-publisher` binaries).

**It is good practice to ship a story with every app.** A story lets anyone bring up the app
against staging/production with a fresh or existing tour, print a ready-to-open URI, and trigger
the app's use case — without wiring bootstrap params by hand.

## The two ways to give an app a story

1. **Add a story to an app** (the common request): create a `story/` folder with `config.cjs`
   and `story.cjs`, and add a `story` npm script. See _Adding a story to an app_ below.
2. **Drive / extend an existing story**: edit `story.cjs` to add macros, keypress actions, or
   change the printed URI, then run it. See _Running a story_.

Do not edit the Story Publisher repo itself unless the user asks — apps consume it as a globally
installed CLI. Shared helpers (`macros.js`, `utils.js`) live there; per-app logic lives in the
app's `story.cjs`.

## Adding a story to an app

Model the folder on an existing app's `story/` directory. Replicate that shape.

**1. Add the npm script** to the app's `package.json`:

```json
"scripts": {
  "story": "stp -s story/story.cjs -c story/config.cjs"
}
```

**2. Create `story/config.cjs`** — see `references/config.cjs`. Adjust `GUIDE_DEVICE`,
`DISPLAY_DEVICE`, and `TOUR_CONFIGURATION` for the target app/device. `CONFIGURATION_PATH` and
`ENVIRONMENT` come from env vars so the same file works for everyone. Only export the extra
fields the story actually uses (e.g. `DOMAIN` for a `janusServerUri`).

**3. Create `story/story.cjs`** — see `references/story.cjs`. Start from the canonical recipe
below rather than a blank file.

> Files use the `.cjs` extension because `stp` loads them with `require()` (CommonJS,
> `module.exports = runStory`). Do not use ESM `export`.

**4. Document it in the app's `README.md`** so the next person knows how to run the story. Add a
section like this (keep the flags in sync with the run modes below):

````markdown
### Run Story with Story-Publisher

Prerequisite: Story-Publisher is globally installed

**Set environment variables**

```bash
export ENVIRONMENT=<put environment here> # [staging | production]
export CONFIGURATION_PATH=<put path to config repo here>
```

**Run Story with remote config**

```bash
npm run story -- -t
```

**Run Story with local config**

```bash
npm run story -- -l
```

**Run Story against the existing tour**

```bash
npm run story
```
````

## The canonical story recipe

Almost every app story does the same four things. Mirror this structure:

```js
async function runStory({
  macros,
  utils,
  config,
  tour,
  mqttClient,
  tourListener,
  displays,
}) {
  const { DISPLAY_DEVICE, DOMAIN } = config;
  const useCaseName = "tvApp"; // the app's use case path
  const baseTopic = `tours/${tour}/useCases/${useCaseName}`;
  const localDevUrl = "http://localhost:5173"; // vite dev server

  // 1) Print the webapp URI (the most common action) — all bootstrap params + your own
  const printWebappUri = () =>
    macros.printWebappUri(localDevUrl, `baseTopic=${baseTopic}`);
  printWebappUri();

  // 2) On tour change (only fires with local config, -l), re-print and (re)start the use case
  tourListener.onChange = () => {
    printWebappUri();
    macros.startUseCase(useCaseName);
    macros.bringWebappDisplaysToTheFront();
  };

  // 3) MQTT logging helpers for the use case's subtree
  const logMqtt = (payload, topic) =>
    console.log(`${topic}: ${JSON.stringify(payload)}`);

  // 4) Keypress actions — the interactive menu. Function NAMES are shown in the menu.
  const actions = {
    s: function startUseCase() {
      macros.startUseCase(useCaseName);
    },
    p: printWebappUri,
    o: function openWebappDisplay() {
      macros.openWebappDisplay(
        DISPLAY_DEVICE,
        displays[DISPLAY_DEVICE]?.bounds,
      );
    },
    m: function startMqttLog() {
      mqttClient.subscribe(`${baseTopic}/#`, logMqtt);
    },
    u: function stopMqttLog() {
      mqttClient.unsubscribe(`${baseTopic}/#`, logMqtt);
    },
    a: function printActions() {
      utils.printKeypressActions(actions);
    },
    q: macros.killAllWebappDisplays,
  };
  utils.printKeypressActions(actions);
  await utils.keypressHandler(actions);
}

module.exports = runStory;
```

`printWebappUri(origin, params)` prepends the bootstrap query parameters
(`backendHost`, `httpBrokerUri`, `wsBrokerUri`, `configServerUri`, `storageServerUri`, `tour`,
`tourTopic`) to `origin`, then appends your `params`. So a webapp opened from the printed URI is
fully wired to the broker/config for that tour. Point `origin` at `localDevUrl` for local dev, or
at a backend service like `http://mockup-player.${bootstrapData.backendHost}` for staging.

## `runStory` arguments

`stp` calls `runStory(context)` with a single destructurable object:

| Key             | What it is                                                                                                                                                                             |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bootstrapData` | Resolved bootstrap: `backendHost`, `backendComposeHost`, `httpBrokerUri`, `wsBrokerUri`, `tcpBrokerUri`, `configServerUri`, `storageServerUri`, `device`, `tourAdministratorApiUri`, … |
| `mqttClient`    | Connected `@artcom/mqtt-topping` client — `publish` / `subscribe` / `unsubscribe`                                                                                                      |
| `httpClient`    | `@artcom/mqtt-topping` `HttpClient` for querying retained topics over HTTP                                                                                                             |
| `tour`          | The tour id (created with `-t`/`-l`, or the existing one bound to the guide device)                                                                                                    |
| `config`        | Everything exported from `config.cjs`                                                                                                                                                  |
| `macros`        | High-level actions (table below)                                                                                                                                                       |
| `utils`         | Helpers: `keypressHandler`, `printKeypressActions`, `logAndWait`, `sleep`, `colorize`, …                                                                                               |
| `displays`      | Display-device geometry presets (bounds, resolution, orientation)                                                                                                                      |
| `tourListener`  | Set `tourListener.onChange = () => {…}`; fires on config file change (local config)                                                                                                    |

## Macros reference

All macros come from the Story Publisher repo's `src/macros.js`. Device defaults to
`config.DISPLAY_DEVICE` when omitted.

| Macro                                                                                                  | Purpose                                                                   |
| ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| `printWebappUri(origin, params, bootstrapData?, tour?)`                                                | Print a full webapp URI (bootstrap params + `params`). **Most common.**   |
| `getWebappUri(origin, params, …)`                                                                      | Same, but returns the string instead of printing                          |
| `startUseCase(useCase)`                                                                                | Publish `doExecuteActionList` for `tours/<tour>/useCases/<useCase>/start` |
| `startWebApp(uri, options?)`                                                                           | Tell a device to open a webapp (`doStartWebApp`)                          |
| `stopWebApp(layer, device?)`                                                                           | Stop a webapp layer on a device                                           |
| `startBackgroundImageWebApp(imageUri)` / `startBackgroundVideoWebApp(videoUri, layer?, loop?)`         | Show media via the media-player webapp                                    |
| `openWebappDisplay(device, bounds?, url?, deviceEmulation?, customConfigJson?)`                        | Launch the native `webapp-display` app for a device                       |
| `openWebappCompositor(device?, bounds?, isBorderless?)`                                                | Open the webapp compositor in Chrome                                      |
| `openWebappLocal(url)` / `openInChrome(url, args?)` / `setChromeUrl(url)`                              | Open/point a local browser                                                |
| `killAllWebappDisplays()` / `bringWebappDisplaysToTheFront()` / `hideAllWindowsExceptWebappDisplays()` | Manage `webapp-display` windows (macOS)                                   |
| `clearWebappDisplayCache(device?)`                                                                     | `doClearCacheAndRestart` on a device                                      |
| `executeTopicActionList(path, params?)` / `executeConfigActionList(path, params?)`                     | Trigger a broker/config action list                                       |
| `enterTuioObject(device, id)` / `leaveTuioObject(device, id)`                                          | Simulate TUIO object presence events                                      |
| `sendAreaToSleep(area)`                                                                                | Put a gallery area to sleep                                               |
| `openGalleryControlInChrome(device?)` / `openGalleryControlInWebappDisplay(guideDevice?, bounds?)`     | Open Gallery Control                                                      |

For raw broker access, use `mqttClient.publish(topic, payload)` directly (see the mqtt-topping
skill). Command/event topics named `do…`/`on…` default to `retain: false`.

## Running a story

**Set env vars** (consumed by `config.cjs`):

```bash
export ENVIRONMENT=staging          # staging | production
export CONFIGURATION_PATH=/absolute/path/to/configuration-repo/   # trailing slash!
```

**Run:**

```bash
npm run story -- -t     # create a NEW tour from remote config (TOUR_CONFIGURATION)
npm run story -- -l     # create a NEW tour from LOCAL config at CONFIGURATION_PATH, and
                        #   watch it — file edits recreate the tour and fire tourListener.onChange
npm run story           # reuse the EXISTING tour bound to the guide device
```

`--` forwards flags through npm to `stp`. Flags (from `stp -h`):

| Flag                    | Effect                                                         |
| ----------------------- | -------------------------------------------------------------- |
| `-t`, `--create-tour`   | Create a new tour for the device/guide using remote config     |
| `-l`, `--local-config`  | Create a new tour from local config and watch for changes      |
| `-s`, `--story <path>`  | Story file (the `story` script already sets `story/story.cjs`) |
| `-c`, `--config <path>` | Config file (already set to `story/config.cjs`)                |
| `-h`, `--help`          | Usage                                                          |

**Lifecycle:** `stp` prints config, waits at `-- GO --` for a keypress, runs `runStory`, then
waits at `-- END --`. Interactive stories block inside `utils.keypressHandler(actions)` until you
press `q`/Ctrl-C, so the menu stays live.

## Gotchas

- **`.cjs`, not `.js`/ESM.** `stp` `require()`s the files; use `module.exports = runStory`.
- **Trailing slash on `CONFIGURATION_PATH`** — the file-watch/local-config path assumes it.
- **`-l` requires a valid local configuration repo** at `CONFIGURATION_PATH`; without a config
  repo, use `-t` (remote) or no flag (existing tour).
- **Keypress menu labels are function names** — `utils.printKeypressActions` shows `fn.name`, so
  name your action functions (`function startUseCase() {}`) or use named macro references.
- **`ENVIRONMENT` drives the domain** — `config.cjs` maps it to the production or staging backend
  host; a missing/typo'd value silently points you at the wrong backend.
- **macOS-only window macros** — `killAllWebappDisplays`, `bringWebappDisplaysToTheFront`, etc.
  shell out to `killall`/`osascript` and are no-ops elsewhere.
- **Story Publisher must be installed globally** — if `stp` is not found, install it from its
  repo with `npm i -g`.
