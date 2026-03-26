#!/usr/bin/env bash
# Output: always JSON (array of reminders).
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
  normalize_reminders_json <<< "$raw" | augment_reminders_json
  exit 0
fi

if [[ -n "$list_name" ]]; then
  run_reminder_applescript list.applescript "$list_name" | augment_reminders_json
else
  run_reminder_applescript list.applescript | augment_reminders_json
fi
