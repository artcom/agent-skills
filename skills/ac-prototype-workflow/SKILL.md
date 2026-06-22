---
name: ac-prototype-workflow
description: Guide non-technical ART+COM users from an idea to a shareable web prototype. Use when a user wants to create or extend a prototype, check or install web-development tools, create a GitLab project under gitlab.artcom.de/prototypes, connect a Netlify site, choose between Astro, React, React Three Fiber, or optionally add MQTT.
---

# ART+COM Prototype Workflow

Take one understandable step at a time. Explain outcomes, not implementation details. Run commands and make technical decisions for the user; only ask questions that change the result or require their consent.

## 1. Start with a short conversation

Ask one question at a time, in this order:

1. “Are we starting a new prototype, or improving an existing folder?” If existing, ask them to choose the folder.
2. “In one or two sentences, what should people be able to see or do?”
3. “Will it contain a 3D scene or object that people can explore?”
4. If not 3D: “Is it mainly a content website with pages, text, images, and simple animations?”
5. “Does it need to show or control live data from an MQTT broker?” Explain that “I’m not sure” is a valid answer.
6. For a new project, ask for a simple project name. Derive a lowercase, hyphenated folder and repository name from it.

Do not ask non-technical users to choose a framework, GitLab group, build command, publish directory, or Netlify team. Use the defaults below and explain the choice in one sentence.

| What the user needs | Use | Explain it as |
| --- | --- | --- |
| 3D scene, spatial interaction, WebGL | React + TypeScript + Three.js via React Three Fiber | “A solid base for a real-time 3D experience.” |
| Content-led site, story, portfolio, information pages | Astro + TypeScript | “Fast pages that are simple to update.” |
| Interactive controls, visual UI, data display, or an app-like tool | React + TypeScript + Vite | “A flexible base for interactive experiences.” |
| Unclear | React + TypeScript + Vite | “A safe general-purpose starting point; we can change direction later.” |

Use MQTT only when the user explicitly wants it or confirms it after the plain-language question.

## 2. Make the computer ready before creating files

Run `bash scripts/check-prerequisites.sh` from this skill directory first. Give a short plain-language summary: what is ready, what is missing, and what happens next. Never print login tokens or environment-variable values.

Require:

- Homebrew
- Node.js 22 or later and its bundled npm
- GitLab CLI (`glab`) authenticated to `gitlab.artcom.de`
- Netlify CLI (`netlify`) authenticated to the intended ART+COM Netlify team

If anything is missing or outdated, say: “Your computer needs a few setup tools before we can start. Shall I install or update them now?” On confirmation, repair the prerequisites in this order:

1. If Homebrew is missing, ask separately before installing it because its official installer changes system-wide configuration. Do not run a curl-to-shell installer without that confirmation.
2. If Node.js is missing or older than 22, run `brew install node` or `brew upgrade node`.
3. If `glab` is missing, run `brew install glab`.
4. If `netlify` is missing, run `npm install --global netlify-cli` after Node/npm are ready.
5. Re-run the preflight script.

If GitLab login is missing, tell the user: “A browser window will open so you can sign in to ART+COM GitLab.” Then run `glab auth login --hostname gitlab.artcom.de` and wait for them to finish. If Netlify login is missing, say the equivalent and run `netlify login`. Re-run the preflight until every required item is ready. Do not ask users to copy tokens into chat or files.

## 3. Create the project

For a new project, create it only after all readiness checks succeed. Explain the selected stack in one sentence, then scaffold it:

```bash
# Content site
npm create astro@latest <project-name>

# Interactive or 3D experience
npm create vite@latest <project-name> -- --template react-ts
cd <project-name>
npm install

# Add this only for 3D
npm install three @react-three/fiber @react-three/drei
```

For an existing project, inspect `package.json`, identify its current framework and commands, and extend it without replacing its configuration, lockfile, or deployment setup.

Create a minimal working first screen that reflects the user’s description. For a 3D project, include a visible, interactive Three.js scene; do not merely install the packages. For a content site, include the requested page structure and sample content. For an interactive app, include the main interaction or data-state shape. Keep the first version small and runnable.

Create `.env.example` with names and safe placeholders only. Ensure real `.env*` files are ignored by Git. Never put real broker URLs, credentials, or Netlify secrets in source code, `netlify.toml`, commits, or output.

## 4. Add live MQTT data only when wanted

If MQTT is selected, fetch the current ART+COM MQTT skill from:

```text
https://raw.githubusercontent.com/artcom/agent-skills/main/skills/mqtt-topping/SKILL.md
```

After confirmation, run `npm install mqtt-topping`. It requires Node.js 22 or later.

Use `PUBLIC_BROKER` only for browser-safe, non-secret connection information. Keep `INTERNAL_BROKER` server-side; do not expose it through a `VITE_*` variable or browser code. Follow the MQTT skill's parse-error, background-error, QoS, and retained-message guidance. Explicitly use `retain: false` for transient commands and events.

## 5. Give every new prototype its shared home

New ART+COM prototypes belong in the `prototypes` group on `https://gitlab.artcom.de`. Do not ask the user to choose a namespace. Before creating the remote project, say: “I’ll create a private project at `https://gitlab.artcom.de/prototypes/<project-name>` and connect this folder to it. Shall I continue?”

After confirmation, initialise Git if necessary, then create the project with the ART+COM host explicitly selected:

```bash
GITLAB_HOST=gitlab.artcom.de glab repo create prototypes/<project-name> --private --defaultBranch main
```

Verify the `origin` remote points to `gitlab.artcom.de/prototypes/<project-name>`. Add or correct it only after checking that no intended remote already exists. Make the first commit and push only after the user approves the summary of files that will be shared.

For an existing project, retain its current remote unless the user explicitly asks to create or replace it with a project under `prototypes`.

## 6. Connect Netlify and broker configuration

From the project root, explain: “I’ll create a Netlify project for this prototype so it has a shareable link.” Obtain confirmation, then run `netlify init`, select the authenticated ART+COM team, and create a new site or link the exact existing site the user names. Keep `.netlify/state.json` local only.

Set the build command and publish directory for the selected framework. Run the local build first, then offer the first production deployment with `netlify deploy --prod` only after confirmation.

After linking, run `netlify env:list --json` and check only whether `PUBLIC_BROKER` and `INTERNAL_BROKER` exist with appropriate scopes and deploy contexts; never show their values. `INTERNAL_BROKER` needs the Functions scope when it is used by a Netlify Function.

Netlify CLI can create site variables, but ART+COM broker variables must remain shared team variables. If either name is missing, do not create a site-specific replacement. Tell the user which name is missing and ask a Netlify Team Owner to add it in Team settings → Environment variables, or obtain explicit approval to use the Netlify API for the selected team. Re-check once configured.

## 7. Finish in plain language

Summarize the prototype folder, chosen approach and reason, GitLab URL, Netlify URL, build/deploy result, and whether live MQTT was added. State any blocked step in ordinary language and give the one action the user needs to take next.
