#!/usr/bin/env bash
#
# dev-link.sh — live-edit skills from this repo in your coding agent(s).
#
# Symlinks a skill's folder in this repo directly into an agent's skills
# directory, so edits to skills/<name>/SKILL.md are picked up immediately —
# no reinstall between iterations. Use this while developing a skill; when
# you're done, `unlink` and go back to the published version via
# `npx skills update`.
#
# Links go into the agent's GLOBAL skills dir by default. Pass --project to
# scope them to a single application repo instead, so an in-development skill
# doesn't leak into every project on the machine.
#
# Usage:
#   ./dev-link.sh link   [skill|all] [agent ...] [--project[=PATH]]
#   ./dev-link.sh unlink [skill|all] [agent ...] [--project[=PATH]]
#   ./dev-link.sh status [agent ...]             [--project[=PATH]]
#   ./dev-link.sh help
#
# --project, -p        link into $PWD instead of $HOME (e.g. .claude/skills)
# --project=PATH       link into PATH instead of $HOME
#
# Examples:
#   ./dev-link.sh link                          # link every skill to Claude Code, globally
#   ./dev-link.sh link prototyping              # link one skill, globally
#   ./dev-link.sh link prototyping claude-code github-copilot
#   ./dev-link.sh link all --project=../my-app  # scope to one application repo
#   ./dev-link.sh status --project              # what's linked in the current repo
#   ./dev-link.sh unlink all --project=../my-app
#
# Tip: the symlinks are untracked files in the application repo. Keep its
# `git status` clean without committing anything by adding `.claude/skills/`
# to that repo's .git/info/exclude.
#
set -euo pipefail

# --- locate the repo (this script lives at the repo root) -------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "  $*"; }

# --- where skills live, relative to the base dir ----------------------------
# Add more agents here as needed (names match the `skills` CLI --agent values).
# Only claude-code's project-local convention is verified; the others reuse
# their global subdir name.
agent_subdir() {
  case "$1" in
    claude-code)     echo ".claude/skills" ;;
    github-copilot)  echo ".copilot/skills" ;;
    cursor)          echo ".cursor/skills" ;;
    codex)           echo ".codex/skills" ;;
    *) echo "" ;;
  esac
}

# Base dir for every link: $HOME (global) or a project root (--project).
BASE_DIR="$HOME"

set_base() {
  local p="$1"
  [ -d "$p" ] || die "not a directory: $p"
  BASE_DIR="$(cd "$p" && pwd)"
}

agent_dir() {
  local sub; sub="$(agent_subdir "$1")"
  [ -n "$sub" ] || { echo ""; return; }
  echo "$BASE_DIR/$sub"
}

# --- resolve the list of skills --------------------------------------------
all_skills() {
  find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d \
    -exec test -f '{}/SKILL.md' \; -print \
    | while read -r d; do basename "$d"; done | sort
}

resolve_skills() {
  local arg="${1:-all}"
  if [ "$arg" = "all" ]; then
    all_skills
  else
    [ -f "$SKILLS_DIR/$arg/SKILL.md" ] || die "no skill '$arg' (expected $SKILLS_DIR/$arg/SKILL.md)"
    echo "$arg"
  fi
}

# --- commands ---------------------------------------------------------------
do_link() {
  local skill="$1" agent="$2"
  local dir; dir="$(agent_dir "$agent")"
  [ -n "$dir" ] || die "unknown agent '$agent' — add it to agent_subdir() in this script"
  local src="$SKILLS_DIR/$skill" dst="$dir/$skill"

  mkdir -p "$dir"
  if [ -L "$dst" ]; then
    rm "$dst"                                    # replace an existing symlink
  elif [ -e "$dst" ]; then
    die "$dst exists and is NOT a symlink — remove/back it up first (won't clobber real files)"
  fi
  ln -s "$src" "$dst"
  info "linked  $agent  $skill -> $src"
}

do_unlink() {
  local skill="$1" agent="$2"
  local dir; dir="$(agent_dir "$agent")"
  [ -n "$dir" ] || die "unknown agent '$agent'"
  local dst="$dir/$skill"
  if [ -L "$dst" ]; then
    rm "$dst"; info "unlinked $agent  $skill"
  elif [ -e "$dst" ]; then
    info "skip    $agent  $skill (real files, not a dev symlink — left untouched)"
  else
    info "skip    $agent  $skill (nothing linked)"
  fi
}

do_status() {
  local agent="$1"
  local dir; dir="$(agent_dir "$agent")"
  [ -n "$dir" ] || die "unknown agent '$agent'"
  echo "[$agent] $dir"
  [ -d "$dir" ] || { info "(none)"; return; }
  local found=0
  for entry in "$dir"/*; do
    [ -e "$entry" ] || continue
    if [ -L "$entry" ]; then
      info "$(basename "$entry") -> $(readlink "$entry")"
      found=1
    fi
  done
  [ "$found" -eq 1 ] || info "(no dev symlinks)"
}

# --- arg parsing ------------------------------------------------------------
# Pull --project out of argv first, so it can appear anywhere.
positional=()                                    # bash 3.2 (macOS) compatible
for arg in "$@"; do
  case "$arg" in
    --project|-p) set_base "$PWD" ;;
    --project=*)  set_base "${arg#--project=}" ;;
    -h|--help)    positional+=("$arg") ;;
    -*)           die "unknown option '$arg' (try: --project[=PATH])" ;;
    *)            positional+=("$arg") ;;
  esac
done
set -- ${positional[@]+"${positional[@]}"}

cmd="${1:-help}"; shift || true

case "$cmd" in
  link|unlink)
    skill_arg="${1:-all}"; [ $# -gt 0 ] && shift || true
    agents=("$@"); [ ${#agents[@]} -eq 0 ] && agents=(claude-code)
    skills=()
    while IFS= read -r line; do skills+=("$line"); done < <(resolve_skills "$skill_arg")
    for a in "${agents[@]}"; do
      for s in "${skills[@]}"; do
        [ "$cmd" = "link" ] && do_link "$s" "$a" || do_unlink "$s" "$a"
      done
    done
    ;;
  status)
    agents=("$@"); [ ${#agents[@]} -eq 0 ] && agents=(claude-code)
    for a in "${agents[@]}"; do do_status "$a"; done
    ;;
  help|-h|--help)
    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"
    ;;
  *)
    die "unknown command '$cmd' (try: link | unlink | status | help)"
    ;;
esac
