---
name: ac-prototype-workflow
description: Scaffold, connect, and deploy shareable ART+COM web prototypes. Use when a user wants to start or add a frontend prototype, prepare a project for GitLab and Netlify, check local frontend tooling, configure ART+COM broker variables, or optionally add MQTT with mqtt-topping.
---

# ART+COM Prototype Workflow

Guide the user from a local folder to a runnable, GitLab-hosted, Netlify-linked web prototype. Keep all external writes behind an explicit confirmation.

## 1. Establish the target

Ask first whether to add this capability to an **existing project/folder/repository** or create a **new project**. Do not assume that the current working directory is the target.

For an existing target, ask for its path, inspect its package manager and framework, and preserve its conventions. Do not replace an existing starter, build configuration, lockfile, or deployment configuration without approval.

For a new target, ask for the project directory, project name, GitLab namespace, Netlify team, and frontend framework. Recommend **Vite + React + TypeScript** when no framework is specified. Ask whether MQTT support is required.

Before any command that installs software, creates a GitLab project, creates or links a Netlify site, changes remote variables, or deploys, state exactly what it will change and obtain confirmation.

## 2. Run the local-tooling preflight

Run `bash scripts/check-prerequisites.sh` from this skill directory. Report the detected versions and authentication states without exposing tokens or environment-variable values.

Require all of the following before scaffolding or deploying:

- Homebrew (`brew`), unless the user selects another supported Node installation method.
- Node.js 22 or later and its bundled npm. Prefer the current Homebrew `node` formula so both are modern.
- GitLab CLI (`glab`) with a successful `glab auth status` for the intended GitLab host.
- Netlify CLI (`netlify`) with a successful `netlify status` for the intended account/team.

If Homebrew exists but Node.js or npm is absent or Node is older than 22, propose `brew install node` or `brew upgrade node`; show the version that will be replaced where applicable. If Homebrew is absent, ask permission before installing it; do not use a curl-to-shell installer without explicit approval. After Node is available, install missing CLIs with npm (`npm install --global @gitlab-org/cli` and `npm install --global netlify-cli`) only after approval, then re-run the preflight.

If `glab auth status` fails, use `glab auth login` interactively. If `netlify status` fails, use `netlify login` interactively. Do not request or paste access tokens into chat, files, shell history, or command arguments.

## 3. Scaffold or prepare the app

For a new Vite React TypeScript project, use the confirmed target directory and run:

```bash
npm create vite@latest <project-name> -- --template react-ts
cd <project-name>
npm install
```

For an existing project, install only the dependencies needed for the requested feature. Run its existing lint, typecheck, test, and build commands where available; otherwise run `npm run build` after inspecting `package.json`.

Create `.env.example` with only variable names and non-sensitive placeholders. Ensure real `.env*` files are ignored by Git. Never put real broker addresses or credentials in source files, `netlify.toml`, commits, or output.

## 4. Add MQTT only when requested

If MQTT is requested, first fetch the current ART+COM MQTT skill from:

```text
https://raw.githubusercontent.com/artcom/agent-skills/main/skills/mqtt-topping/SKILL.md
```

The documented package installation is `npm install mqtt-topping` (not an `npx` command). Install it only after confirmation. It requires Node.js 22 or later.

Use `PUBLIC_BROKER` only for non-secret browser-safe configuration. Keep `INTERNAL_BROKER` server-side: a Vite `VITE_*` variable is embedded into client code, so never expose `INTERNAL_BROKER` by renaming it or reading it in frontend code. Apply the MQTT skill's requirements, including parse-error handling and explicit `retain: false` for transient commands/events.

If ART+COM publishes a separate `npx` installer for the MQTT skill, ask for its exact package and command before using it. Do not infer one from the GitHub URL.

## 5. Create and link the GitLab and Netlify projects

After confirmation, initialise Git if necessary, create a GitLab project in the selected namespace with `glab repo create`, configure the remote, make an initial commit only with the user's approval, and push the default branch. Use the GitLab CLI's interactive prompts if namespace or visibility flags differ in the installed version.

From the project root, create/link the Netlify project interactively with:

```bash
netlify init
```

Select the confirmed Netlify team and either create a new site or link the existing intended site. Preserve the generated `.netlify/state.json` as a local-only file; do not commit it. Configure the build command and publish directory from the actual framework. Run `netlify build` before the first production deploy, then offer `netlify deploy --prod` only after confirmation.

## 6. Verify broker variables safely

After the site is linked, verify that `PUBLIC_BROKER` and `INTERNAL_BROKER` are available to the project with:

```bash
netlify env:list --json
```

Check names, scopes, and deploy contexts only; do not print values. Ensure `INTERNAL_BROKER` includes the Functions scope when it is used by Netlify Functions, and use the minimum scope needed for `PUBLIC_BROKER`.

Netlify CLI sets **site** variables. Shared **team** variables require a Team Owner and must be created through Netlify's API or the Team settings → Environment variables UI. If either required variable is missing, do not create a site-level override: report the missing name and ask the Team Owner to create the shared variable, or obtain explicit approval to use the Netlify API for the selected team. Re-run the safe verification after it is configured.

## 7. Finish with evidence

Report the target path, framework, Node/npm versions, GitLab project URL, Netlify site URL, successful build/deploy result, and which broker variable names were verified. State any intentionally skipped optional step and the reason.
