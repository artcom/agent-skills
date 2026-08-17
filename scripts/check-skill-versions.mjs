#!/usr/bin/env node
// Guards the two ways skill versions have actually drifted in this repo:
//   1. SKILL.md's metadata.version and CHANGELOG.md's newest entry disagree
//      (a version was bumped past its changelog, or an entry was never written).
//   2. SKILL.md changed without metadata.version changing at all.
//
// Usage:
//   node scripts/check-skill-versions.mjs              # check (1) for every skill
//   node scripts/check-skill-versions.mjs --since main # also check (2) against a git ref
//
// No dependencies — runs anywhere node does.

import { readFileSync, readdirSync, existsSync } from "node:fs"
import { execFileSync } from "node:child_process"
import { join } from "node:path"

const SKILLS_DIR = "skills"
const sinceIndex = process.argv.indexOf("--since")
const since = sinceIndex === -1 ? null : process.argv[sinceIndex + 1]

const errors = []

const versionOf = (source, label) => {
  const match = source.match(/^\s*version:\s*(\S+)\s*$/m)
  if (!match) errors.push(`${label}: no metadata.version in the frontmatter`)
  return match?.[1]
}

const newestChangelogEntry = (source) => source.match(/^##\s+(\S+)/m)?.[1]

const gitShow = (ref, path) => {
  try {
    return execFileSync("git", ["show", `${ref}:${path}`], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] })
  } catch {
    return null // the file did not exist at that ref — a new skill, nothing to compare
  }
}

const skills = readdirSync(SKILLS_DIR, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort()

for (const skill of skills) {
  const skillPath = join(SKILLS_DIR, skill, "SKILL.md")
  const changelogPath = join(SKILLS_DIR, skill, "CHANGELOG.md")
  if (!existsSync(skillPath)) {
    errors.push(`${skill}: no SKILL.md`)
    continue
  }

  const source = readFileSync(skillPath, "utf8")
  const version = versionOf(source, skill)

  if (!existsSync(changelogPath)) {
    errors.push(`${skill}: no CHANGELOG.md (SKILL.md declares ${version})`)
  } else {
    const newest = newestChangelogEntry(readFileSync(changelogPath, "utf8"))
    if (version && newest && version !== newest) {
      errors.push(
        `${skill}: SKILL.md declares ${version} but the newest CHANGELOG entry is ${newest}` +
          ` — bump one or add the missing entry`
      )
    }
  }

  if (since) {
    const before = gitShow(since, skillPath)
    if (before !== null && before !== source) {
      const previousVersion = before.match(/^\s*version:\s*(\S+)\s*$/m)?.[1]
      if (previousVersion === version) {
        errors.push(
          `${skill}: SKILL.md changed since ${since} but metadata.version is still ${version}` +
            ` — patch for corrections, minor for new guidance (see README)`
        )
      }
    }
  }
}

if (errors.length) {
  console.error(`✗ ${errors.length} skill version problem(s):\n`)
  for (const error of errors) console.error(`  - ${error}`)
  process.exit(1)
}

console.log(`✓ ${skills.length} skills: version and changelog agree${since ? `, bumped where changed since ${since}` : ""}`)
