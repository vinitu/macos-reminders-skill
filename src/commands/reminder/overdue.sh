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

if command -v remindctl >/dev/null 2>&1; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq required when using remindctl" >&2
    exit 1
  fi
  cutoff="$(date +%Y-%m-%d)"
  if [[ -n "$list_name" ]]; then
    raw=$(remindctl list "$list_name" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  else
    raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  fi
  printf '%s' "$raw" | jq --arg cutoff "$cutoff" '
    [.[] | select(.isCompleted == false and .dueDate != null and (.dueDate | .[0:10]) < $cutoff) |
     {id, name: .title, list: .listName, body: (if .notes == "" or .notes == null then null else .notes end), completed: .isCompleted, priority: (if .priority == null then "none" elif .priority == 0 then "none" elif .priority == 1 then "low" elif .priority == 5 then "medium" elif .priority == 9 then "high" else "none" end), due_date: .dueDate}]
  '
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [[ -n "$list_name" ]]; then
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/overdue.applescript" "$list_name"
else
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/overdue.applescript"
fi
