#!/usr/bin/env bash
# Output: JSON {exists, id}.
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example (found):
#   {
#     "exists": true,
#     "id": "..."
#   }
# Example (not found):
#   {
#     "exists": false,
#     "id": null
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
id_arg="$2"
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if [[ -n "$REMINDCTL_BIN" ]]; then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  raw=$(remindctl_show_all_json)
  matches=$(find_reminder_matches_json "$id_arg" <<< "$raw")
  count=$(printf '%s' "$matches" | "$JQ_BIN" 'length')
  if [[ "$count" -gt 1 ]]; then
    echo "Reminder id is ambiguous: $id_arg" >&2
    exit 1
  fi
  if [[ "$count" -eq 1 ]]; then
    full_id=$(printf '%s' "$matches" | "$JQ_BIN" -r '.[0].id')
    "$JQ_BIN" -n --arg id "$full_id" '{exists: true, id: $id}'
  else
    "$JQ_BIN" -n '{exists: false, id: null}'
  fi
  exit 0
fi

out=$(run_reminder_applescript get-reminder-by-id.applescript "$id_arg" 2>/dev/null) || true
if [[ -n "$out" ]] && [[ -n "$JQ_BIN" ]] && printf '%s' "$out" | "$JQ_BIN" -e '.id' >/dev/null 2>&1; then
  full_id=$(printf '%s' "$out" | "$JQ_BIN" -r '.id')
  "$JQ_BIN" -n --arg id "$full_id" '{exists: true, id: $id}'
else
  printf '{"exists":false,"id":null}\n'
fi
