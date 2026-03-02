---
name: mqtt-topping
description: Use mqtt-topping to connect to MQTT brokers and query MQTT data over HTTP. Use when the user says "connect to MQTT", "subscribe to a topic", "publish a message", "query MQTT data", or "clear retained messages". Also use for pub/sub patterns, IoT applications, HiveMQ integration, or debugging MQTT connection and subscription issues — even if mqtt-topping isn't mentioned by name. Use when you encounter mqtt-topping imports in existing code.
metadata:
  version: 1.0.0
  author: ART+COM
---

# MQTT Topping

**mqtt-topping** is ART+COM's TypeScript library for MQTT communication and HTTP-based topic querying. It wraps [MQTT.js](https://github.com/mqttjs/MQTT.js) with a promise-based API and pairs it with an `HttpClient` for querying retained messages via the [HiveMQ Retained Message Query Plugin](https://github.com/artcom/hivemq-retained-message-query-plugin).

- Repository: https://github.com/artcom/mqtt-topping
- ESM-only, requires Node.js >= 22.0.0
- Install: `npm install mqtt-topping`

> **For the latest API details**, fetch the current README:
> https://raw.githubusercontent.com/artcom/mqtt-topping/master/README.md
>
> This skill covers the essentials and gotchas. If you need specifics on a method signature, option, or edge case not covered here, read the README — it is the authoritative source.

## Gotchas — Read These First

These are the behaviors that most commonly cause bugs:

1. **Retain defaults to `true`** — every `publish()` call retains by default. The only exception: topics matching `on[A-Z]*` or `do[A-Z]*` (e.g. `onUpdate`, `doAction`) auto-default to `retain: false` because they represent transient events/commands. If you're publishing a command or event on a normal topic, set `retain: false` explicitly or you'll leave stale messages on the broker.

2. **Silent parse errors** — if you don't pass `onParseError` when connecting, JSON parse failures in incoming messages are silently ignored (the subscription callback simply never fires). Always provide `onParseError` so bad payloads don't disappear into the void.

3. **Default QoS is 2** — unlike most MQTT libraries that default to 0, mqtt-topping defaults to QoS 2 for both subscribe and publish. This is safe but can impact throughput. Lower it explicitly when fire-and-forget is acceptable.

4. **Background errors need a listener** — the library attaches a no-op `"error"` listener to the underlying mqtt.js client to prevent crashes, but this means errors are swallowed unless you add your own listener via `client.underlyingClient.on("error", ...)`.

5. **`queryJson` doesn't support wildcards** — `httpClient.queryJson()` and `queryJsonBatch()` throw `HttpQueryError` if you pass `+` or `#`. Use `query()` for wildcard patterns.

## Complete Example

```typescript
import { MqttClient, HttpClient } from "mqtt-topping";

// Connect — always provide onParseError
const client = await MqttClient.connect("mqtt://broker.example.com", {
  clientId: `my-app-${Date.now()}`,
  onParseError: (error, topic) =>
    console.warn(`Bad payload on ${topic}:`, error.message),
});

// Listen for background MQTT errors
client.underlyingClient.on("error", (err) => console.error("MQTT error:", err));

// Subscribe — default parseType is "json", default QoS is 2
await client.subscribe("sensors/+/reading", (payload, topic) => {
  const data = payload as { temperature: number };
  console.log(`${topic}: ${data.temperature}°C`);
});

// Publish JSON (retained by default)
await client.publish("device/status", { online: true, ts: Date.now() });

// Publish a command (retain=false because topic starts with "do")
await client.publish("cmd/doRestart", { reason: "update" });

// Clear a retained message
await client.unpublish("device/old-status");

// Unsubscribe a specific handler, or force-remove all
await client.unsubscribe("sensors/+/reading", myHandler);
await client.forceUnsubscribe("alerts/#");

// Disconnect gracefully
await client.disconnect();

// --- HTTP queries (requires HiveMQ Retained Message Query Plugin) ---
const http = new HttpClient("http://mqtt-http-endpoint.com", {
  requestTimeoutMs: 10000,
});
const result = await http.query({ topic: "home/livingroom", depth: 2 });
const asObject = await http.queryJson("home/livingroom");
```

## MqttClient API

### `MqttClient.connect(brokerUrl, options)` → `Promise<MqttClient>`

Create and connect. Options extend standard [MQTT.js options](https://github.com/mqttjs/MQTT.js#client) plus `onParseError`.

### `subscribe(topic, callback, opts?)` → `Promise<void>`

Attach a handler. Multiple handlers per topic are supported. Wildcards (`+`, `#`) work.

| Option         | Type                                         | Default  | Notes                            |
| -------------- | -------------------------------------------- | -------- | -------------------------------- |
| `qos`          | `0 \| 1 \| 2`                                | `2`      |                                  |
| `parseType`    | `"json" \| "string" \| "buffer" \| "custom"` | `"json"` | Determines callback payload type |
| `customParser` | `(buf: Buffer) => unknown`                   | —        | Only with `parseType: "custom"`  |

**Callback payload types:** `"json"` → `unknown`, `"string"` → `string`, `"buffer"` → `Buffer`, `"custom"` → `unknown`

### `publish(topic, data, opts?)` → `Promise<void>`

No wildcards allowed in topic.

| Option      | Type                             | Default                                    | Notes                                |
| ----------- | -------------------------------- | ------------------------------------------ | ------------------------------------ |
| `qos`       | `0 \| 1 \| 2`                    | `2`                                        |                                      |
| `retain`    | `boolean`                        | `true` (except `on`/`do` topics → `false`) | See gotcha #1                        |
| `parseType` | `"json" \| "string" \| "buffer"` | `"json"`                                   | `"custom"` not supported for publish |

### `unsubscribe(topic, callback, opts?)` → `Promise<void>`

Remove a specific handler. Unsubscribes from broker if it was the last handler.

### `forceUnsubscribe(topic, opts?)` → `Promise<void>`

Remove all handlers for a topic and unsubscribe from broker.

### `unpublish(topic)` → `Promise<void>`

Clear a retained message (publishes empty payload with `retain: true`, QoS 2).

### `disconnect(force?)` → `Promise<void>`

Graceful by default (unsubscribes first). Pass `true` to force-close the socket.

### `isConnected()` / `isReconnecting()` → `boolean`

## HttpClient API

Queries retained MQTT data over HTTP. Requires the [HiveMQ Retained Message Query Plugin](https://github.com/artcom/hivemq-retained-message-query-plugin).

### `new HttpClient(baseUrl, opts?)`

`opts.requestTimeoutMs` defaults to 30000.

### `query(queryObj)` / `queryBatch(queryObjs[])`

Query one or many topics. Returns `HttpQueryResult` or array.

| Query option | Type      | Default     | Notes                   |
| ------------ | --------- | ----------- | ----------------------- |
| `topic`      | `string`  | —           | Required                |
| `depth`      | `number`  | API default | -1 = all, 0 = self only |
| `flatten`    | `boolean` | `false`     | Flat array vs nested    |
| `parseJson`  | `boolean` | `true`      | Parse payloads as JSON  |

### `queryJson(topic)` / `queryJsonBatch(topics[])`

Convenience: returns topic data as a plain JS object. **No wildcards** — throws `HttpQueryError`.

## Error Types

All extend `MqttToppingError`. Use `instanceof` to check.

| Category               | Errors                                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **MQTT** (`MqttError`) | `MqttConnectionError`, `MqttSubscribeError`, `MqttUnsubscribeError`, `MqttPublishError`, `MqttPayloadError`, `MqttUsageError`, `MqttDisconnectError`, `InvalidTopicError` |
| **HTTP** (`HttpError`) | `HttpNetworkError`, `HttpTimeoutError`, `HttpRequestError`, `HttpQueryError`, `HttpPayloadParseError`, `HttpServerError`, `HttpProcessingError`                           |

## Troubleshooting

### Subscription callback never fires

**Cause:** Payload fails JSON parse and no `onParseError` was provided — errors are silently swallowed.
**Fix:** Add `onParseError` in connect options. Check that the publisher is sending valid JSON.

### Messages unexpectedly retained on broker

**Cause:** `publish()` defaults to `retain: true`. Events and commands stay on the broker when they shouldn't.
**Fix:** Set `retain: false` explicitly, or use the `on`/`do` topic naming convention (e.g. `doRestart`, `onUpdate`) which auto-defaults to `retain: false`.

### `HttpQueryError` when using `queryJson`

**Cause:** Wildcards (`+`, `#`) passed to `queryJson()` or `queryJsonBatch()`.
**Fix:** Use `query()` for wildcard patterns. `queryJson` only works with exact topic paths.

### Connection drops silently

**Cause:** Background errors swallowed by the default no-op error listener.
**Fix:** Add `client.underlyingClient.on("error", ...)` and also listen for `"close"`, `"reconnect"`, `"offline"` events.

### Slow publish/subscribe throughput

**Cause:** Default QoS is 2 (exactly once delivery), which requires a 4-packet handshake.
**Fix:** Lower to QoS 0 or 1 when guaranteed delivery isn't critical.
