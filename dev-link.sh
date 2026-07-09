#!/usr/bin/env bash
#
# dev-link.sh — live-edit skills from this repo in your coding agent(s).
#
# Symlinks a skill's folder in this repo directly into an agent's GLOBAL
# skills directory, so edits to skills/<name>/SKILL.md are picked up
# immediately — no reinstall between iterations. Use this while developing
# a skill; when you're done, `unlink` and go back to the published version
# via `npx skills update`.
#
# Usage:
#   ./dev-link.sh link   [skill|all] [agent ...]   # default: all skills -> claude-code
#   ./dev-link.sh unlink [skill|all] [agent ...]
#   ./dev-link.sh status [agent ...]
#   ./dev-link.sh help
#
# Examples:
#   ./dev-link.sh link                          # link every skill to Claude Code
#   ./dev-link.sh link prototyping              # link one skill to Claude Code
#   ./dev-link.sh link prototyping claude-code github-copilot
#   ./dev-link.sh unlink prototyping            # remove the dev symlink
#   ./dev-link.sh status                        # show what's currently linked
#
set -euo pipefail

# --- locate the repo (this script lives at the repo root) -------------------
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# --- map an agent name to its GLOBAL skills directory -----------------------
# Add more agents here as needed (names match the `skills` CLI --agent values).
agent_dir() {
  case "$1" in
    claude-code)     echo "$HOME/.claude/skills" ;;
    github-copilot)  echo "$HOME/.copilot/skills" ;;
    cursor)          echo "$HOME/.cursor/skills" ;;
    codex)           echo "$HOME/.codex/skills" ;;
    *) echo "" ;;
  esac
}

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "  $*"; }

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
  [ -n "$dir" ] || die "unknown agent '$agent' — add it to agent_dir() in this script"
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
cmd="${1:-help}"; shift || true

case "$cmd" in
  link|unlink)
    skill_arg="${1:-all}"; [ $# -gt 0 ] && shift || true
    agents=("$@"); [ ${#agents[@]} -eq 0 ] && agents=(claude-code)
    skills=()                                    # bash 3.2 (macOS) compatible
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
