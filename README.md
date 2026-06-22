# ART+COM Agent Skills

A collection of reusable [AI agent skills](https://skills.sh/) by [ART+COM](https://artcom.de). Each skill gives AI coding agents domain-specific knowledge so they can work effectively with our libraries and tools.

## Available Skills

| Skill                                         | Description                                                                                                                                         |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| [ac-prototype-workflow](/skills/ac-prototype-workflow/SKILL.md) | Scaffold and deploy ART+COM web prototypes with GitLab, Netlify, and optional MQTT support |
| [mqtt-topping](/skills/mqtt-topping/SKILL.md) | Connect to MQTT brokers, subscribe/publish messages, and query retained data over HTTP using [mqtt-topping](https://github.com/artcom/mqtt-topping) |

## Installation

Install skills with the [skills CLI](https://github.com/vercel-labs/skills):

```bash
# List available skills in this repo
npx skills add artcom/agent-skills --list

# Install a specific skill
npx skills add artcom/agent-skills --skill mqtt-topping

# Install the prototype workflow skill
npx skills add artcom/agent-skills --skill ac-prototype-workflow

# Install all skills
npx skills add artcom/agent-skills --all

# Install to specific agents only
npx skills add artcom/agent-skills --skill mqtt-topping -a claude-code

# Install globally (available across all projects)
npx skills add artcom/agent-skills --skill mqtt-topping -g
```

Skills are symlinked into your project's `.agents/skills/` directory and become available to your AI agent automatically. Use `--copy` if you prefer independent copies instead of symlinks.

## Repository Structure

This repository hosts multiple skills side-by-side. Each skill lives in its own directory under `skills/`:

```
skills/
├── ac-prototype-workflow/
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
