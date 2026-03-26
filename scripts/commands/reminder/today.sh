#!/usr/bin/env bash
# Output: always JSON (array of reminders due today).
# Prefer: remindctl + jq for speed. Fallback: AppleScript + ReminderKit when remindctl is unavailable or fails.
# Example:
# [
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": "2026-03-13T12:00:00Z"
#   }
# ]
set -euo pipefail

list_name="${1:-}"
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if raw=$(try_remindctl_all_or_list_json "$list_name"); then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  today="$(date +%Y-%m-%d)"
  normalize_reminders_json <<< "$raw" | augment_reminders_json | "$JQ_BIN" --arg today "$today" '
    def local_due_date:
      try (fromdateiso8601 | strflocaltime("%Y-%m-%d"))
      catch .[0:10];
    [.[] | select(.completed == false and .due_date != null and (.due_date | local_due_date) == $today)]
  '
  exit 0
fi

if [[ -n "$list_name" ]]; then
  run_reminder_applescript today.applescript "$list_name" | augment_reminders_json
else
  run_reminder_applescript today.applescript | augment_reminders_json
fi
