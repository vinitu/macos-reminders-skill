#!/usr/bin/env bash
# Output: JSON (completed reminder in AGENTS.md shape).
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": true,
#     "priority": "none",
#     "due_date": null
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
id_arg="$2"
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

if [[ -n "$REMINDCTL_BIN" ]]; then
  raw=$(remindctl_show_all_json)
  resolved=$(resolve_reminder_id "$id_arg" <<< "$raw")
  out=$(run_remindctl_json complete "$resolved")
  printf '%s' "$out" | normalize_single_reminder_json
  exit 0
fi

reminder_json=$(load_reminder_by_id_or_error "$id_arg")
list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
reminder_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.name')
run_reminder_applescript complete.applescript "$list_name" "$reminder_name" >/dev/null
printf '%s' "$reminder_json" | "$JQ_BIN" -c '.completed = true'
