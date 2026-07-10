// story/story.cjs — the app's Story Publisher story.
// Loaded by `stp` via require(); must export runStory (CommonJS).
//
// Replace `useCaseName` with this app's use-case path, and point `localDevUrl`
// at your dev server. Add/trim keypress actions as the app needs.

async function runStory({
  bootstrapData,
  mqttClient,
  tour,
  config,
  macros,
  utils,
  tourListener,
  displays,
}) {
  const { DISPLAY_DEVICE } = config
  const useCaseName = "area/myApp" // TODO: this app's use-case path
  const baseTopic = `tours/${tour}/useCases/${useCaseName}`
  const localDevUrl = "http://localhost:5173" // vite dev server

  // The most common action: print a fully-wired webapp URI (bootstrap params + baseTopic).
  const printWebappUri = () => macros.printWebappUri(localDevUrl, `baseTopic=${baseTopic}`)
  printWebappUri()

  // Fires only with local config (-l): re-print the URI and (re)start the use case on change.
  tourListener.onChange = () => {
    printWebappUri()
    macros.startUseCase(useCaseName)
    macros.bringWebappDisplaysToTheFront()
  }

  const logMqtt = (payload, topic) => console.log(`${topic}: ${JSON.stringify(payload)}`)

  // Keypress menu — function names are shown as labels, so keep them named.
  const actions = {
    s: function startUseCase() {
      macros.startUseCase(useCaseName)
    },
    p: printWebappUri,
    o: function openWebappDisplay() {
      macros.openWebappDisplay(DISPLAY_DEVICE, displays[DISPLAY_DEVICE]?.bounds)
    },
    m: function startMqttLog() {
      mqttClient.subscribe(`${baseTopic}/#`, logMqtt)
    },
    u: function stopMqttLog() {
      mqttClient.unsubscribe(`${baseTopic}/#`, logMqtt)
    },
    a: function printActions() {
      utils.printKeypressActions(actions)
    },
    q: macros.killAllWebappDisplays,
  }

  utils.printKeypressActions(actions)
  await utils.keypressHandler(actions)
}

module.exports = runStory
