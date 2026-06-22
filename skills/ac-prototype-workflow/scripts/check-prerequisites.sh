#!/usr/bin/env bash
# Report local prerequisite availability without printing credentials or secrets.
set -u

report_command() {
  local label="$1"
  local command="$2"

  if command -v "$command" >/dev/null 2>&1; then
    printf '%-14s installed  %s\n' "$label" "$(command -v "$command")"
  else
    printf '%-14s missing\n' "$label"
  fi
}

report_version() {
  local label="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    printf '%-14s %s\n' "$label" "$("$@")"
  else
    printf '%-14s unavailable\n' "$label"
  fi
}

report_command "brew" "brew"
report_version "node" node --version
report_version "npm" npm --version
report_command "glab" "glab"
report_command "netlify" "netlify"

if command -v glab >/dev/null 2>&1 && glab auth status >/dev/null 2>&1; then
  printf '%-14s authenticated\n' "glab auth"
else
  printf '%-14s needs login\n' "glab auth"
fi

if command -v netlify >/dev/null 2>&1 && netlify status >/dev/null 2>&1; then
  printf '%-14s authenticated\n' "netlify auth"
else
  printf '%-14s needs login\n' "netlify auth"
fi
