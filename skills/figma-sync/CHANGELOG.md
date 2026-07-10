# Changelog

## 1.0.0

- Initial release
- Documents the published [`@artcom/figma-sync`](https://www.npmjs.com/package/@artcom/figma-sync)
  npm package (CLI + library): mapping comments, manifest with design/code hashes and node deep
  links, snapshot vs REST backends, and `FIGMA_TOKEN` setup (`file_content:read`)
- Workflows: project setup, re-baselining after (re)generation, and a state-by-state action table
  for `status` output (`SYNC` … `UNKNOWN`)
- Guardrail: never blind-run `update-manifest` to silence drift — reconcile first
- CI-gate guidance (non-zero exit on drift, offline snapshot fallback) and node-id / URL gotchas
