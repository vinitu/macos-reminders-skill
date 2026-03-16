#!/usr/bin/env bash
# Output: always JSON (array of overdue reminders).
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
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
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if [[ -n "$REMINDCTL_BIN" ]]; then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  cutoff="$(date +%Y-%m-%d)"
  raw=$(remindctl_all_or_list_json "$list_name")
  normalize_reminders_json <<< "$raw" | "$JQ_BIN" --arg cutoff "$cutoff" '
    def local_due_date:
      try (fromdateiso8601 | strflocaltime("%Y-%m-%d"))
      catch .[0:10];
    [.[] | select(.completed == false and .due_date != null and (.due_date | local_due_date) < $cutoff)]
  '
  exit 0
fi

exec_reminder_applescript_optional_last_arg overdue.applescript "$list_name"
