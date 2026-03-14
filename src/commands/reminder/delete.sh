#!/usr/bin/env bash
# Output: JSON {deleted, id}.
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
#   {
#     "deleted": true,
#     "id": "..."
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
id_arg="$2"

if command -v remindctl >/dev/null 2>&1; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq required when using remindctl" >&2
    exit 1
  fi
  raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  resolved=$(printf '%s' "$raw" | jq -r --arg id "$id_arg" '[.[] | select((.id | ascii_downcase) | startswith(($id | ascii_downcase)))] | if length == 0 then "NOT_FOUND" elif length > 1 then "AMBIGUOUS" else .[0].id end')
  if [[ "$resolved" == "NOT_FOUND" ]]; then
    echo "Reminder not found for id: $id_arg" >&2
    exit 1
  fi
  if [[ "$resolved" == "AMBIGUOUS" ]]; then
    echo "Reminder id is ambiguous: $id_arg" >&2
    exit 1
  fi
  remindctl delete "$resolved" --force --json --no-color --no-input >/dev/null || { echo "remindctl failed" >&2; exit 1; }
  jq -n --arg id "$resolved" '{deleted: true, id: $id}'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
reminder_json=$(/usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/get-reminder-by-id.applescript" "$id_arg") || { echo "Reminder not found for id: $id_arg" >&2; exit 1; }
list_name=$(printf '%s' "$reminder_json" | jq -r '.list')
full_id=$(printf '%s' "$reminder_json" | jq -r '.id')
/usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/delete-by-id.applescript" "$list_name" "$full_id" >/dev/null
jq -n --arg id "$full_id" '{deleted: true, id: $id}'