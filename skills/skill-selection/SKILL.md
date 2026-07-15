---
name: skill-selection
description: Choose the right skill when several match, and follow the chosen skill's required flow to completion instead of stopping at "it renders". Use at the START of any task that could match a skill — especially design-to-code, Figma, or any request where both a custom/org skill and a bundled plugin skill could apply.
metadata:
  version: 1.0.0
  author: ART+COM
---

# Skill selection & adherence

A guard against two recurring failure modes: (a) picking a generic plugin skill when a
custom/org skill fits better, and (b) invoking a skill but skipping its mandatory steps.
Read this before deciding which skill to run.

## 1. Pick the most specific matching skill

When more than one available skill matches the task, rank them and pick deliberately —
do **not** grab the first recognizable one.

Priority, highest first:

1. **Project-scoped skills** (from the repo's `.claude/skills/` or named for a directory).
2. **User/org custom skills** (e.g. author `ART+COM` in the frontmatter) — these encode
   local conventions and override generic behavior.
3. **Bundled plugin skills** (e.g. `figma:*` from an installed plugin) — generic
   fallbacks. Use only when no custom skill covers the task.

Concrete rule for Figma → code: **`figma-to-react` (custom) beats `figma:figma-design-to-code`
(plugin).** If both are listed, load `figma-to-react`.

Before committing to a skill, scan the *whole* available-skills list for a more specific
match. If two plausibly apply and the choice changes the outcome, say which you picked and
why in one line.

## 2. A skill's "required"/"do not skip" steps are contractual

Once you invoke a skill, complete its flow — not just the part that produces visible output.
Skipping steps because the result "already renders" is the failure this skill exists to stop.

Before marking a skilled task done, confirm every one of these that the skill defines:

- **Structure decision made explicitly.** If the skill dictates component granularity
  (e.g. `figma-to-react` §1: one component per meaningful node in an empty/near-empty
  project), follow it. Do **not** collapse a multi-part design into one monolithic file
  with inline helpers. A bare starter (`App.jsx` counter) is not a convention to preserve.
- **Companion-skill offer made.** If the skill says to ask the user once (multi-select)
  which optional companion skills to use (e.g. `config-content-assets`, `figma-sync`,
  `react-pixel-overlay`), ask **before implementing**. Non-interactive run → skip and note
  the assumption. Never silently omit the question.
- **Content/assets externalized when a skill covers it.** Don't hardcode strings and media
  into components when `config-content-assets` (or the project convention) applies.
- **Verification done, not just a build.** Run the skill's verification: re-fetch the
  design screenshot and compare 1:1, run the app with its real dev command, and run the
  project's lint. `vite build` passing is necessary, not sufficient. Fix lint warnings you
  introduced.
- **Anti-hallucination respected.** Add only styles/colors present in the source (Figma
  node data or project tokens). No invented emoji icons, gradients, shadows, or guessed
  numeric values that the design doesn't specify. If something is genuinely missing and
  matters, ask rather than invent — and if you must use a placeholder, flag it explicitly.
**Pixel-fidelity is part of the contract too, but its detailed checklist lives with the
skill that does the work.** When the chosen skill is `figma-to-react`, its §7 "Pixel-fidelity
checklist" is the authoritative list of gotchas that make a "done" screen actually match the
design (resolving real tokens vs `var()` fallbacks, exact per-node type + numeral features, real
icon assets, the surface-elevation ladder, size constraints, fixed pitch vs `space-between`,
cache/delivery staleness, overlay sync, etc.). Don't duplicate it here — run through it there
before calling a Figma implementation done.

## 3. Self-check before finishing

Ask: "Did I run the skill the task actually called for, and did I complete its
non-optional steps — structure, companion-skill ask, verification, anti-hallucination?"
If any answer is no, finish those steps or state clearly what was skipped and why.
