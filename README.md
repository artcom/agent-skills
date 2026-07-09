# ART+COM Agent Skills

A collection of reusable [AI agent skills](https://skills.sh/) by [ART+COM](https://artcom.de). Each skill gives AI coding agents domain-specific knowledge so they can work effectively with our libraries and tools.

## Available Skills

| Skill                                         | Description                                                                                                                                         |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| [prototyping](/skills/prototyping/SKILL.md) | Scaffold and deploy ART+COM web prototypes with GitLab, Netlify, and optional MQTT support |
| [mqtt-topping](/skills/mqtt-topping/SKILL.md) | Connect to MQTT brokers, subscribe/publish messages, and query retained data over HTTP using [mqtt-topping](https://github.com/artcom/mqtt-topping) |
| [figma-to-react](/skills/figma-to-react/SKILL.md) | Translate a Figma design into React code that matches the target project's own styling, tokens, and components |

## Installation

Install skills with the [skills CLI](https://github.com/vercel-labs/skills):

```bash
# List available skills in this repo
npx skills add artcom/agent-skills --list

# Install a specific skill
npx skills add artcom/agent-skills --skill mqtt-topping

# Install the prototyping skill
npx skills add artcom/agent-skills --skill prototyping

# Install all skills
npx skills add artcom/agent-skills --all

# Install to specific agents only
npx skills add artcom/agent-skills --skill mqtt-topping -a claude-code

# Install globally (available across all projects)
npx skills add artcom/agent-skills --skill mqtt-topping -g
```

Skills are symlinked into your project's `.agents/skills/` directory and become available to your AI agent automatically. Use `--copy` if you prefer independent copies instead of symlinks.

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
