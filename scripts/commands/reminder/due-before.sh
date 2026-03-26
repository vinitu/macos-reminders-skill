#!/usr/bin/env bash
# Output: always JSON (array of reminders due before the given date).
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

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <date> [list-name]" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") <date> [list-name]" >&2; exit 1; }
cutoff_date="$1"
list_name="${2:-}"
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if raw=$(try_remindctl_all_or_list_json "$list_name"); then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  normalize_reminders_json <<< "$raw" | augment_reminders_json | "$JQ_BIN" --arg cutoff "$cutoff_date" '
    def local_due_date:
      try (fromdateiso8601 | strflocaltime("%Y-%m-%d"))
      catch .[0:10];
    [.[] | select(.completed == false and .due_date != null and (.due_date | local_due_date) < $cutoff)]
  '
  exit 0
fi

if [[ -n "$list_name" ]]; then
  run_reminder_applescript due-before.applescript "$cutoff_date" "$list_name" | augment_reminders_json
else
  run_reminder_applescript due-before.applescript "$cutoff_date" | augment_reminders_json
fi
