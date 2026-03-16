#!/usr/bin/env bash
# Output: JSON (reminder object or {id, property, value} when property given).
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example (full reminder):
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": null
#   }
# Example (property):
#   {
#     "id": "...",
#     "property": "body",
#     "value": "Notes text"
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id> [property]" >&2; exit 1; }
id_arg="$2"
property="${3:-}"
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if [[ -n "$REMINDCTL_BIN" ]]; then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  raw=$(remindctl_show_all_json)
  normalized=$(get_single_reminder_match_json "$id_arg" <<< "$raw" | normalize_single_reminder_json)
  if [[ -z "$property" ]]; then
    printf '%s' "$normalized"
  else
    prop_key="${property//-/_}"
    value=$(printf '%s' "$normalized" | "$JQ_BIN" -r --arg k "$prop_key" '.[$k] // empty')
    full_id=$(printf '%s' "$normalized" | "$JQ_BIN" -r '.id')
    "$JQ_BIN" -n --arg id "$full_id" --arg property "$prop_key" --arg value "$value" '{id: $id, property: $property, value: $value}'
  fi
  exit 0
fi

exec_reminder_applescript_optional_last_arg get-reminder-by-id.applescript "$property" "$id_arg"
