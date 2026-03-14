#!/usr/bin/env bash
# Output: always JSON (array of reminders due in the date range).
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

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") <start-date> <end-date> [list-name]" >&2; exit 1; }
[[ $# -gt 3 ]] && { echo "Usage: $(basename "$0") <start-date> <end-date> [list-name]" >&2; exit 1; }
start_date="$1"
end_date="$2"
list_name="${3:-}"

if command -v remindctl >/dev/null 2>&1; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq required when using remindctl" >&2
    exit 1
  fi
  REMINDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -n "$list_name" ]]; then
    raw=$(remindctl list "$list_name" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  else
    raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  fi
  jq -f "$REMINDER_DIR/reminder_normalize.jq" <<< "$raw" | jq --arg start "$start_date" --arg end "$end_date" '[.[] | select(.completed == false and .due_date != null and (.due_date | .[0:10]) >= $start and (.due_date | .[0:10]) <= $end)]'
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -n "$list_name" ]]; then
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/due-range.applescript" "$start_date" "$end_date" "$list_name"
else
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/due-range.applescript" "$start_date" "$end_date"
fi
