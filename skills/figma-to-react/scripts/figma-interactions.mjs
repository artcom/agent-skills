#!/usr/bin/env node
// Fetches a Figma file (or specific nodes) once via the REST API and prints the
// click -> next-frame wiring, per figma-to-react SKILL.md "Prototype interactions".
// Usage: node scripts/figma-interactions.mjs <fileKey> [nodeId...]
// Env:   FIGMA_TOKEN (required)

const [fileKey, ...nodeIds] = process.argv.slice(2)

if (!fileKey) {
  console.error("usage: figma-interactions.mjs <fileKey> [nodeId...]")
  process.exit(1)
}

const token = process.env.FIGMA_TOKEN
if (!token) {
  console.error("FIGMA_TOKEN is not set")
  process.exit(1)
}

const url =
  nodeIds.length > 0
    ? `https://api.figma.com/v1/files/${fileKey}/nodes?ids=${nodeIds.join(",")}`
    : `https://api.figma.com/v1/files/${fileKey}`

const response = await fetch(url, { headers: { "X-Figma-Token": token } })
if (!response.ok) {
  console.error(`Figma API error: ${response.status} ${response.statusText}`)
  process.exit(1)
}
const body = await response.json()

// One or more root documents depending on which endpoint was used.
const roots =
  nodeIds.length > 0
    ? Object.values(body.nodes ?? {}).map((entry) => entry.document)
    : [body.document]

const names = new Map()
const wired = [] // { id, name, trigger, destinationId, type }
const frames = [] // top-level-ish frame candidates, for the orphan check

const walk = (node, depth) => {
  names.set(node.id, node.name)
  if (node.type === "FRAME" || node.type === "COMPONENT" || node.type === "INSTANCE") {
    frames.push({ id: node.id, name: node.name, depth })
  }
  for (const interaction of node.interactions ?? []) {
    const trigger = interaction.trigger?.type ?? "UNKNOWN_TRIGGER"
    for (const action of interaction.actions ?? [interaction.action].filter(Boolean)) {
      if (action?.destinationId) {
        wired.push({
          id: node.id,
          name: node.name,
          trigger,
          destinationId: action.destinationId,
          navType: action.navigation ?? action.type,
        })
      }
    }
  }
  for (const child of node.children ?? []) walk(child, depth + 1)
}

for (const root of roots) walk(root, 0)

console.log(`=== Click wiring (${wired.length} reaction${wired.length === 1 ? "" : "s"}) ===`)
if (wired.length === 0) {
  console.log("(none found — this file/selection has no ON_CLICK-style reactions)")
} else {
  for (const w of wired) {
    const destName = names.get(w.destinationId) ?? "(unresolved — outside fetched selection)"
    console.log(
      `${w.name} (${w.id}) --[${w.trigger}]--> ${w.navType} --> ${destName} (${w.destinationId})`,
    )
  }
}

const destinationIds = new Set(wired.map((w) => w.destinationId))
const orphaned = frames.filter((f) => f.depth <= 1 && !destinationIds.has(f.id))
console.log(`\n=== Frames never reached as a destination (${orphaned.length}) ===`)
if (orphaned.length === 0) {
  console.log("(none — every top-level frame is reachable)")
} else {
  console.log("Not necessarily a bug — a frame reached only by scroll, or the flow's own entry")
  console.log("point, is expected here. Treat this as a checklist, not an error list.")
  for (const f of orphaned) console.log(`${f.name} (${f.id})`)
}
