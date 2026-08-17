---
name: prototyping
description: Guide non-technical ART+COM users from an idea to a shareable internal web prototype. Use when a user wants to create or extend a prototype, choose its target display and input, check or install web-development tools, create a GitLab project under gitlab.artcom.de/prototypes, connect a Netlify site, keep a deployed prototype private with a password and out of search engines, choose between Astro, React, React Three Fiber, or optionally add MQTT.
---

# ART+COM Prototyping

Take one understandable step at a time. Explain outcomes, not implementation details. Run commands and make technical decisions for the user. Proceed automatically through the standard workflow; ask questions only when the answer changes the prototype, an interactive login needs the user, permissions are missing, or an existing project could be overwritten.

## 1. Make the computer ready first

Run `bash scripts/check-prerequisites.sh` from this skill directory first. Give a short plain-language summary: what is ready, what is missing, and what happens next. Never print login tokens or environment-variable values.

Require:

- Homebrew
- Node.js 22 or later and its bundled npm
- GitLab CLI (`glab`) authenticated to `gitlab.artcom.de`
- Netlify CLI (`netlify`) authenticated to the intended ART+COM Netlify team

If anything is missing or outdated, briefly say which tools will be installed or updated, then repair the prerequisites automatically in this order:

1. If Homebrew is missing, use its official installer and respect any macOS administrator or password prompt.
2. If Node.js is missing or older than 22, run `brew install node` or `brew upgrade node`.
3. If `glab` is missing, run `brew install glab`.
4. If `netlify` is missing, run `npm install --global netlify-cli` after Node/npm are ready.
5. Re-run the preflight script.

If GitLab login is missing, ask the user for a personal access token: tell them to open `https://gitlab.artcom.de/-/user_settings/personal_access_tokens`, create a token with the `api` scope, and paste it into the chat. Then log in by piping the token to `glab auth login --hostname gitlab.artcom.de --stdin`. Never echo the token back, store it in a file, or include it in any output. If Netlify login is missing, tell the user a browser window will open and run `netlify login`. Re-run the preflight until every required item is ready.

Then confirm the Netlify login is the company account, not a personal one:

```bash
netlify status
```

The listed team must be `ART+COM`. If it is a personal team, tell the user in plain language that they are signed in with a private Netlify account, then run `netlify logout` and `netlify login` again so they can pick their ART+COM account. Do not continue with a personal account: it cannot password-protect a prototype and has none of the shared broker variables.

## 2. Gather a short prototype brief

Ask one question at a time, in this order:

1. “Are we starting a new prototype, or improving an existing folder?” If existing, ask them to choose the folder.
2. “In one or two sentences, what should people be able to see or do?”
3. “Which ART+COM project is this prototype for?” Derive a lowercase, hyphenated `project-slug` from the answer.
4. “Should the app be portrait or landscape?”
5. “Will people use touch input? Answer yes or no.”
6. “Will it contain a 3D scene or object that people can explore?”
7. If not 3D: “Is it mainly a content website with pages, text, images, and simple animations?”
8. “Does it need to show or control live data from an MQTT broker?” Explain that “I’m not sure” is a valid answer; treat it as no MQTT for now.
9. For a new prototype, ask for a simple prototype name. Derive a lowercase, hyphenated `prototype-name` for its local folder. Use `<project-slug>-<prototype-name>` as its `repository-name`.
10. “Is this prototype covered by a strict client NDA, so it needs its own password instead of the shared ART+COM preview password?” Say that either way nobody reaches it without a password; the only difference is which one. Treat “I’m not sure” as no.

For a new prototype, use `~/Documents/prototypes/<prototype-name>` unless the user already supplied a destination. Create the `prototypes` folder if needed. If that prototype folder already exists, do not overwrite it; ask the user whether to use that folder or a different name.

Do not ask non-technical users to choose a framework, GitLab group, build command, publish directory, or Netlify team. Use the defaults below and explain the choice in one sentence.

| What the user needs | Use | Explain it as |
| --- | --- | --- |
| 3D scene, spatial interaction, WebGL | React + TypeScript + Three.js via React Three Fiber | “A solid base for a real-time 3D experience.” |
| Content-led site, story, portfolio, information pages | Astro + TypeScript | “Fast pages that are simple to update.” |
| Interactive controls, visual UI, data display, or an app-like tool | React + TypeScript + Vite | “A flexible base for interactive experiences.” |
| Unclear | React + TypeScript + Vite | “A safe general-purpose starting point; we can change direction later.” |

Use MQTT only when the user explicitly selects it in the plain-language question.

## 3. Create the project

For a new project, create it only after all readiness checks succeed. Explain the selected stack in one sentence, then scaffold it:

```bash
# Content site
npm create astro@latest <prototype-name>

# Interactive or 3D experience
npm create vite@latest <prototype-name> -- --template react-ts
cd <prototype-name>
npm install

# Add this only for 3D
npm install three @react-three/fiber @react-three/drei
```

Immediately after scaffolding a new project, create `AGENTS.md` with these project constraints:

```md
# ART+COM internal prototype

This is an ART+COM internal prototype. Do not add accessibility features or responsive layouts. Build only for the agreed orientation and touch-input mode.

This prototype is private. It is password protected on Netlify and its pages carry `noindex` headers. Never remove the password, the `X-Robots-Tag` headers, or `robots.txt`.

Commit changes regularly while working. After each commit, update the Netlify deployment by running `netlify deploy --prod --build` once the site is connected to Netlify.

Regularly update the installed ART+COM skills so the newest version is always used: `npx skills add artcom/agent-skills --skill prototyping`
```

Also create `CLAUDE.md` containing only the line `@AGENTS.md`, so Claude Code imports the same constraints.

For an existing project, inspect `package.json`, identify its current framework and commands, and extend it without replacing its configuration, lockfile, or deployment setup.

Create a minimal working first screen that reflects the user’s description and the agreed orientation and touch-input mode. Do not add responsive layouts or accessibility features. For a 3D project, include a visible, interactive Three.js scene; do not merely install the packages. For a content site, include the requested page structure and sample content. For an interactive app, include the main interaction or data-state shape. Keep the first version small and runnable.

Create `.env.example` with names and safe placeholders only. Ensure real `.env*` files are ignored by Git. Never put real broker URLs, credentials, or Netlify secrets in source code, `netlify.toml`, commits, or output.

Create a `netlify.toml` with the actual build command, `dist` as the publish directory for Astro and Vite, and headers that keep the prototype out of search results:

```toml
[[headers]]
  for = "/*"
  [headers.values]
    X-Robots-Tag = "noindex, nofollow, noarchive"
```

Netlify adds this header to deploy previews on its own, but never to the production URL the user will share, so set it explicitly. Also create `public/robots.txt` with:

```text
User-agent: *
Disallow: /
```

Run `npm run build`; a successful build is sufficient verification.

## 4. Add live MQTT data only when wanted

If MQTT is selected, fetch the current ART+COM MQTT skill from:

```text
https://raw.githubusercontent.com/artcom/agent-skills/main/skills/mqtt-topping/SKILL.md
```

Run `npm install mqtt-topping`. It requires Node.js 22 or later.

Use `PUBLIC_BROKER` only for browser-safe, non-secret connection information. Keep `INTERNAL_BROKER` server-side; do not expose it through a `VITE_*` variable or browser code. Follow the MQTT skill's parse-error, background-error, QoS, and retained-message guidance. Explicitly use `retain: false` for transient commands and events.

## 5. Give every new prototype its shared home

New ART+COM prototypes belong in the `prototypes` group on `https://gitlab.artcom.de`. Do not ask the user to choose a namespace or confirm this standard setup. Once the local prototype builds successfully, automatically create its private project at `https://gitlab.artcom.de/prototypes/<repository-name>` and connect the folder to it. Always prefix `repository-name` with `project-slug`.

Initialise Git if necessary. Check whether the GitLab project already exists before creating it; if it does, connect only when it is the intended `prototypes/<repository-name>` project. Otherwise create it with the ART+COM host explicitly selected:

```bash
GITLAB_HOST=gitlab.artcom.de glab repo create prototypes/<repository-name> --private --defaultBranch main
```

Verify the `origin` remote points to `gitlab.artcom.de/prototypes/<repository-name>`. Never replace a different existing remote. Before the first commit, verify that `.env`, `.env.*` except `.env.example`, `node_modules`, and build output are not staged. Automatically make the initial commit and push the new prototype once the project is connected. Report the GitLab URL and commit after the push completes.

For an existing project, retain its current remote unless the user explicitly asks to create or replace it with a project under `prototypes`.

## 6. Connect Netlify and broker configuration

From the project root, state that the prototype is being connected to Netlify. Do not use `netlify init`: it configures continuous deployment and introduces interactive Git-provider setup. List accessible Netlify teams, select the one clearly named ART+COM, and create a directly deployable site with:

```bash
netlify sites:create --name <repository-name> --account-slug <artcom-team-slug>
```

Use the same `<project-slug>-<prototype-name>` value as the GitLab repository. A Netlify site name is a globally unique public subdomain, so an unprefixed name like `kiosk` both collides with other Netlify customers and makes the prototype easy to guess.

This creates and links an empty project to the current folder. If a site of that name already exists, link it only when it belongs to the intended ART+COM team; otherwise create `<repository-name>-<yyyymmdd>`. Keep `.netlify/state.json` local only. Do not configure GitLab continuous deployment in this initial flow.

Make the site private as described in section 7 **before** the first production deploy. Then run the local build and deploy with `netlify deploy --prod --build`.

After linking, check whether `PUBLIC_BROKER` and `INTERNAL_BROKER` exist as shared team variables with appropriate scopes and deploy contexts. Do not use `netlify env:list`: it prints values, including the shared preview password. List names and scopes only:

```bash
netlify api getEnvVars --data '{"account_id":"<account-id>"}' \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{for(const v of JSON.parse(s)) console.log(v.key, "|", (v.scopes||[]).join(","), "|", (v.values||[]).map(x=>x.context).join(","))})'
```

`INTERNAL_BROKER` needs the Functions scope when it is used by a Netlify Function.

Netlify CLI can create site variables, but ART+COM broker variables must remain shared team variables. If either name is missing, do not create a site-specific replacement. If the authenticated account has Team Owner access, create the missing shared variable through the Netlify API; otherwise, state which name is missing and that a Netlify Team Owner must add it in Team settings → Environment variables. Re-check once configured.

## 7. Keep every prototype private

A Netlify site is public and searchable the moment it is deployed. Every ART+COM prototype must be password protected before its first production deploy. Do not ask the user whether they want this; it is the standard setup.

ART+COM uses one shared preview password for all prototypes. Netlify's team-wide default Password Protection is an Enterprise feature, so on the ART+COM Pro plan every site must be set individually. Do not look for a team setting that applies it automatically; there is none.

Which password depends on the NDA answer from the brief.

For a normal prototype, the shared password is stored as the team environment variable `ARTCOM_PREVIEW_PASSWORD`, so do not ask the user for it. Read the ART+COM `account_id` once from `netlify api listAccountsForUser`, then fetch and apply the password in a way that keeps it out of the chat:

```bash
PREVIEW_PW=$(netlify api getEnvVar --data "{\"account_id\":\"<account-id>\",\"key\":\"ARTCOM_PREVIEW_PASSWORD\"}" \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const o=JSON.parse(s);const v=(o.values||[]).find(x=>x.context==="all")||(o.values||[])[0];process.stdout.write(v&&v.value?v.value:"")})')

netlify api updateSite --data "$(PW="$PREVIEW_PW" SID="<site-id>" node -e 'process.stdout.write(JSON.stringify({site_id:process.env.SID,body:{password:process.env.PW}}))')" > /dev/null
```

The value stays in a shell variable and is never printed. If `PREVIEW_PW` comes back empty the variable is missing: ask the user for the shared password, pass it to the same `updateSite` call, and offer to store it for next time so nobody is asked again:

```bash
netlify api createEnvVars --data "$(PW="<shared-password>" node -e 'process.stdout.write(JSON.stringify({account_id:"<account-id>",body:[{key:"ARTCOM_PREVIEW_PASSWORD",scopes:["functions"],values:[{context:"all",value:process.env.PW}]}]}))')"
```

Keep that variable non-secret, because a Netlify secret variable cannot be read back. The `functions` scope keeps it out of every build environment while leaving it readable through the API.

Never write the shared password into this skill, a prototype repository, or any other file: this skill is published in a public repository.

For a prototype under a strict client NDA, do not use the shared password. Offer to generate one instead:

```bash
node -e 'console.log(require("crypto").randomBytes(9).toString("base64url"))'
```

Report that generated password once in the chat and tell the user to store it in their password manager, because Netlify will never show it again. Accept a password of the user's own choosing just as readily.

Either way, set it on the new site:

```bash
netlify api updateSite --data '{"site_id":"<site-id>","body":{"password":"<password>"}}'
```

Never echo the shared password back, write any password to a file, commit one, or include one in later output. Netlify does not return it either, so confirm the result with:

```bash
netlify api getSite --data '{"site_id":"<site-id>"}' \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).has_password))'
```

This is the only check available and it is safe to run. Deploy only once it prints `true`. If the user does not know the password, stop before deploying and say plainly that the prototype would otherwise be readable by anyone on the internet.

This protects the production URL and every deploy URL together. Visitors get a neutral password page and stay signed in for that browser session.

Never remove a password on your own. If the user explicitly asks for a link that needs no password, tell them plainly that the prototype then becomes visible to anyone who has the URL, and only then run:

```bash
netlify api updateSite --data '{"site_id":"<site-id>","body":{"password":""}}'
```

For a prototype that runs unattended on a display in the office, offer firewall traffic rules instead: a Team Owner allows the office IP range under Project configuration → Access & security → Firewall traffic rules, so nobody has to type a password after a reboot.

## 8. Finish in plain language

Summarize the prototype folder, chosen approach and reason, GitLab URL, Netlify URL, build/deploy result, and whether live MQTT was added. State that the prototype is password protected and say which password opens it: the shared ART+COM preview password, or this prototype's own password for an NDA prototype. Never print the shared password. State any blocked step in ordinary language and give the one action the user needs to take next.
