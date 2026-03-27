#!/usr/bin/env bash
# Output: JSON (reminder object or {id, property, value} when property given).
# Prefer: remindctl + jq for speed. Fallback: AppleScript + ReminderKit when remindctl is unavailable or fails.
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
[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

emit_property_json() {
  local reminder_json="$1"
  local prop_key="$2"

  printf '%s' "$reminder_json" | "$JQ_BIN" -c --arg k "$prop_key" '
    if has($k) then
      {id: .id, property: $k, value: .[$k]}
    else
      error("Unsupported property: " + $k)
    end
  '
}

if raw=$(try_remindctl_show_all_json); then
  normalized=$(get_single_reminder_match_json "$id_arg" <<< "$raw" | normalize_single_reminder_json | augment_reminders_json)
  if [[ -z "$property" ]]; then
    printf '%s' "$normalized"
  else
    prop_key="${property//-/_}"
    emit_property_json "$normalized" "$prop_key"
  fi
  exit 0
fi

normalized=$(load_reminder_by_id_or_error "$id_arg" | augment_reminders_json)
if [[ -z "$property" ]]; then
  printf '%s' "$normalized"
else
  prop_key="${property//-/_}"
  emit_property_json "$normalized" "$prop_key"
fi
