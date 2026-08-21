# Changelog

## 1.1.0

- Document [`@artcom/mqtt-topping-react`](https://github.com/artcom/mqtt-topping-react) (verified
  against v3.2.1 source and published types, not just its README): `MqttProvider` props, all nine
  hooks exported from the package root, and a full provider + hooks example
- Correct two stale claims in the wrapper's README: `suspenseFallback` is not a real
  `MqttProvider` prop (use `useMqttStatus`/`useMqttSuspense`), and `useMqttQueryBatch` is not
  exported from the package root
- React gotchas: inline `options`/`httpOptions` objects cause a reconnect loop, WebSocket URIs in
  the browser, `useMqttSubscribe` handlers need no `useCallback` (kept in a ref), and
  `useMqttQuery` is a one-shot retained fetch rather than a live subscription
- Fix the base package name: `@artcom/mqtt-topping` (v5), not the stale unscoped `mqtt-topping`
  (v4) — install command and import in the main example updated

## 1.0.0

- Initial release
- MqttClient API reference: connect, subscribe, publish, unsubscribe, unpublish, disconnect
- HttpClient API reference: query, queryBatch, queryJson, queryJsonBatch
- Gotchas section covering retain defaults, silent parse errors, QoS 2, background errors
- Troubleshooting section with common error scenarios
- Link to upstream README for latest details
