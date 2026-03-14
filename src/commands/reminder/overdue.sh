#!/usr/bin/env bash
# Output: always JSON (array of overdue reminders).
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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
[[ $# -gt 1 ]] && { echo "Usage: $(basename "$0") [list-name]" >&2; exit 1; }
list_name="${1:-}"

if command -v remindctl >/dev/null 2>&1; then
  if [[ -n "$list_name" ]]; then
    raw=$(remindctl list "$list_name" --json --no-color --no-input)
  else
    raw=$(remindctl show all --json --no-color --no-input)
  fi
  printf '%s' "$raw" | jq --arg cutoff "$(date +%Y-%m-%d)" '
    [.[] | select(.isCompleted == false and .dueDate != null and (.dueDate | .[0:10]) < $cutoff) |
     {id, name: .title, list: .listName, body: (if .notes == "" then null else .notes end), completed: .isCompleted, priority: .priority, due_date: .dueDate}]
  '
else
  exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/overdue.applescript" ${list_name:+$list_name} --format=json
fi
