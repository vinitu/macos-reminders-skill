#!/usr/bin/env bash
# Output: JSON (completed reminder in AGENTS.md shape).
# Prefer: remindctl + jq for speed. Fallback: AppleScript + ReminderKit when remindctl is unavailable or fails.
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

if raw=$(try_remindctl_show_all_json); then
  resolved=$(resolve_reminder_id "$id_arg" <<< "$raw")
  if out=$(try_run_remindctl_json complete "$resolved"); then
    printf '%s' "$out" | normalize_single_reminder_json | augment_reminders_json
    exit 0
  fi
fi

reminder_json=$(load_reminder_by_id_or_error "$id_arg")
list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
reminder_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.name')
run_reminder_applescript complete.applescript "$list_name" "$reminder_name" >/dev/null
run_reminder_applescript get-reminder-by-id.applescript "$id_arg" | augment_reminders_json
