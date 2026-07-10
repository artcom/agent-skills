# Changelog

## 1.0.0

- Initial release
- How to add a Story Publisher (`stp`) story to an installation app: `story` npm script plus a
  `story/` folder with `config.cjs` and `story.cjs`, and a README section documenting how to run it
- Canonical story recipe: print webapp URI, `tourListener.onChange`, MQTT logging, keypress menu
- Reference of the `runStory({ bootstrapData, mqttClient, httpClient, tour, config, macros, utils,
  displays, tourListener })` context object
- Full `macros` reference table (print/get webapp URI, start use case, open display, publish, etc.)
- Running a story: `ENVIRONMENT` / `CONFIGURATION_PATH` env vars and the `-t` / `-l` / default
  (existing tour) run modes, plus `stp` flags
- Gotchas: `.cjs`/CommonJS requirement, trailing-slash `CONFIGURATION_PATH`, keypress label names,
  macOS-only window macros, global install of `stp`
- `references/config.cjs` and `references/story.cjs` scaffolds to copy into an app
