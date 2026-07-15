# ART+COM Agent Skills

A collection of reusable [AI agent skills](https://skills.sh/) by [ART+COM](https://artcom.de). Each skill gives AI coding agents domain-specific knowledge so they can work effectively with our libraries and tools.

## Available Skills

| Skill                                                           | Description                                                                                                                                                                                          |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [prototyping](/skills/prototyping/SKILL.md)                     | Scaffold and deploy ART+COM web prototypes with GitLab, Netlify, and optional MQTT support                                                                                                           |
| [mqtt-topping](/skills/mqtt-topping/SKILL.md)                   | Connect to MQTT brokers, subscribe/publish messages, and query retained data over HTTP using [mqtt-topping](https://github.com/artcom/mqtt-topping)                                                  |
| [figma-to-react](/skills/figma-to-react/SKILL.md)               | Translate a Figma design into React code that matches the target project's own styling, tokens, and components                                                                                       |
| [skill-selection](/skills/skill-selection/SKILL.md)             | Pick the most specific matching skill (project > org/custom > bundled plugin) and complete its required steps instead of stopping at "it renders"                                                    |
| [config-content-assets](/skills/config-content-assets/SKILL.md) | Externalize hard-coded texts and media into the configuration repository and storage/asset server (via `${storageServerUri}`) so content and assets update without redeploying                       |
| [react-pixel-overlay](/skills/react-pixel-overlay/SKILL.md)     | Set up and use [react-pixel-overlay](https://github.com/artcom/react-pixel-overlay), the PerfectPixel-style design overlay for verifying pixel-perfect React implementations against design exports  |
| [figma-sync](/skills/figma-sync/SKILL.md)                       | Track drift between Figma designs and generated code with the `figma-sync` CLI — baseline design + code hashes, report sync status per component, and gate CI on design drift                        |
| [story-publisher](/skills/story-publisher/SKILL.md)             | Add and drive a Story Publisher (`stp`) story for an app — print the bootstrap-wired webapp URI, create tours, open displays, start use cases, and test use-case flows end-to-end against the broker |

## Installation

Install skills with the [skills CLI](https://github.com/vercel-labs/skills):

```bash
# List available skills in this repo
npx skills add artcom/agent-skills --list

# Install a specific skill
npx skills add artcom/agent-skills --skill mqtt-topping

# Install the prototyping skill
npx skills add artcom/agent-skills --skill prototyping

# Install all skills, to every detected agent
npx skills add artcom/agent-skills --all

# Install to specific agents only
npx skills add artcom/agent-skills --skill mqtt-topping -a claude-code

# Install globally (available across all projects)
npx skills add artcom/agent-skills --skill mqtt-topping -g

# Install all skills, globally, to Claude Code only
npx skills add artcom/agent-skills --skill '*' -a claude-code -g -y
```

> **Gotcha:** `--all` always installs to every detected agent and ignores an `-a` filter — running
> `--all -a claude-code` still fans out into every agent's folder. To scope "all skills" to one
> agent, use `--skill '*'` instead of `--all`, as in the last example above.

Skills are symlinked into your project's `.agents/skills/` directory and become available to your AI agent automatically. Use `--copy` if you prefer independent copies instead of symlinks.

Confirm what's installed for one agent with `npx skills ls -g -a claude-code`. If a previous `--all` run left skills in the wrong agents' folders, clean them up and reinstall scoped:

```bash
# Remove all globally-installed skills from every agent
npx skills remove --skill '*' --agent '*' -g -y

# Then reinstall scoped to the agent you actually want
npx skills add artcom/agent-skills --skill '*' -a claude-code -g -y
```

## Updating installed skills

Update an installed skill to the latest published version with:

```bash
npx skills update prototyping -p -y
```

Skills.sh updates from the original source; it does not define a per-skill version field. Use annotated, per-skill Semantic Versioning Git tags for immutable releases, for example `prototyping-v1.0.0`. Create a patch tag for fixes, a minor tag for backwards-compatible behavior, and a major tag for breaking workflow changes. Keep `main` as the latest version.

## Versioning and releasing skills

Version each skill independently with an annotated tag named `<skill-name>-vMAJOR.MINOR.PATCH`. The tag, not the repository-wide commit count, is the immutable release identifier. `main` remains the current development and installation source.

- **Patch** (`v0.1.1`): Correct instructions, scripts, or examples without changing the expected workflow.
- **Minor** (`v0.2.0`): Add a backwards-compatible capability, integration, or optional workflow step.
- **Major** (`v1.0.0`): Remove or rename a skill, or change required workflow behavior, defaults, or integration contracts in a way that existing users must adapt to.

For each release:

1. Merge the skill change to `main` and validate the affected skill.
2. Create an annotated tag on that exact commit, with a short release summary:

   ```bash
   git tag -a prototyping-v1.0.1 -m "Release prototyping v1.0.1"
   git push origin prototyping-v1.0.1
   ```

3. Describe the user-visible change in the annotated tag message or the Git hosting release notes.

`skills-lock.json` records a content hash for an installed copy. It helps detect whether a local copy matches its source, but it is not a release version. To identify a release, use the per-skill Git tag.

## Repository Structure

This repository hosts multiple skills side-by-side. Each skill lives in its own directory under `skills/`:

```
skills/
├── prototyping/
│   ├── SKILL.md
│   └── scripts/
├── mqtt-topping/
│   └── SKILL.md
└── <future-skill>/
    └── SKILL.md
```

Every skill directory must contain a `SKILL.md` with YAML frontmatter (`name`, `description`) and markdown instructions. The description drives when the AI agent activates the skill — it should cover both what the skill does and the contexts in which it's useful.

## Developing a Skill Locally

Installing via `npx skills add` copies or symlinks a snapshot — editing `skills/<name>/SKILL.md` afterward doesn't affect what your agent sees. `dev-link.sh` symlinks a skill's folder straight from this repo into an agent's global skills directory, so edits are picked up immediately with no reinstall step:

```bash
./dev-link.sh link              # link every skill to Claude Code
./dev-link.sh link prototyping  # link just one skill
./dev-link.sh status            # show what's currently linked
./dev-link.sh unlink prototyping
```

When you're done, `unlink` and go back to the published version with `npx skills update`.

## Adding a New Skill

1. Create a new directory under `skills/<skill-name>/`
2. Add a `SKILL.md` with frontmatter and instructions:

   ```markdown
   ---
   name: my-skill
   description: Short description of what this skill does and when to use it.
   ---

   # My Skill

   Instructions for the AI agent...
   ```

3. Optionally add supporting files (`scripts/`, `references/`, `assets/`)
4. Add an entry to the **Available Skills** table above
5. Commit and push

## Resources

- [skills.sh](https://skills.sh/) — Skill discovery and leaderboard
- [Skills CLI docs](https://skills.sh/docs/cli)
- [Claude Code skills guide](https://code.claude.com/docs/en/skills)
- [Why agent skills?](https://agentskills.io/home#why-agent-skills)
- [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
