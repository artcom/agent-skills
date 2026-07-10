#!/usr/bin/env bash
# Verify the config + asset externalization workspace is set up.
# Reports (without failing hard) whether the multi-root workspace mounts the
# Configuration Repository and Assets Server, and whether the storage volume is mounted.
#
# Usage: check-prerequisites.sh [path-to.code-workspace]
#        With no argument, uses the first *.code-workspace in the current directory.
set -u

ws="${1:-}"
if [ -z "$ws" ]; then
  ws=$(ls ./*.code-workspace 2>/dev/null | head -1)
fi

if [ -z "$ws" ] || [ ! -f "$ws" ]; then
  printf '%-26s %s\n' "workspace" "no *.code-workspace found — create one (see SKILL.md)"
  exit 0
fi

ws_dir=$(cd "$(dirname "$ws")" && pwd)
printf '%-26s %s\n' "workspace" "$ws"

check_folder() {
  local label="$1"
  if grep -q "\"$label\"" "$ws"; then
    printf '%-26s %s\n' "$label" "declared"
  else
    printf '%-26s %s\n' "$label" "MISSING — add a folder entry (see SKILL.md)"
  fi
}

check_folder "Configuration Repository"
check_folder "Assets Server"

# Pull every folder path and check the one pointing at a mounted volume.
found_asset_path=0
while IFS= read -r rel; do
  case "$rel" in
    *Volumes* )
      found_asset_path=1
      # Resolve relative to the workspace dir.
      resolved=$(cd "$ws_dir" 2>/dev/null && cd "$rel" 2>/dev/null && pwd)
      if [ -n "$resolved" ] && [ -d "$resolved" ]; then
        printf '%-26s %s\n' "assets volume" "mounted → $resolved"
      else
        printf '%-26s %s\n' "assets volume" "NOT mounted/accessible ($rel)"
      fi
      ;;
  esac
done < <(grep -oE '"path"[[:space:]]*:[[:space:]]*"[^"]*"' "$ws" | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')

if [ "$found_asset_path" -eq 0 ]; then
  printf '%-26s %s\n' "assets volume" "no /Volumes path in workspace folders"
fi
