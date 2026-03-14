#!/usr/bin/env bash
# Output: always JSON {count, list}.
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
# {
#   "count": 42,
#   "list": null
# }
set -euo pipefail

[[ $# -gt 1 ]] && { echo "Usage: $(basename "$0") [list-name]" >&2; exit 1; }
list_name="${1:-}"

if command -v remindctl >/dev/null 2>&1; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq required when using remindctl" >&2
    exit 1
  fi
  if [[ -n "$list_name" ]]; then
    raw=$(remindctl list "$list_name" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  else
    raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  fi
  printf '%s' "$raw" | jq --arg list "$list_name" '{count: length, list: (if $list == "" then null else $list end)}'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -n "$list_name" ]]; then
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/count.applescript" "$list_name"
else
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/count.applescript"
fi
