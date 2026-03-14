#!/usr/bin/env bash
# Output: JSON (moved reminder in AGENTS.md shape).
# Requires: remindctl, jq. Without remindctl prints "not implemented yet" and exits 1.
# Example:
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "OtherList",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": null
#   }
set -euo pipefail

[[ $# -lt 3 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id> <target-list>" >&2; exit 1; }
[[ $# -gt 3 ]] && { echo "Usage: $(basename "$0") --id <id> <target-list>" >&2; exit 1; }
id_arg="$2"
target_list="$3"
REMINDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v remindctl >/dev/null 2>&1; then
  echo "not implemented yet" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq required when using remindctl" >&2
  exit 1
fi

raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
resolved=$(printf '%s' "$raw" | jq -r --arg id "$id_arg" '[.[] | select((.id | ascii_downcase) | startswith(($id | ascii_downcase)))] | if length == 0 then "NOT_FOUND" elif length > 1 then "AMBIGUOUS" else .[0].id end')
if [[ "$resolved" == "NOT_FOUND" ]]; then
  echo "Reminder not found for id: $id_arg" >&2
  exit 1
fi
if [[ "$resolved" == "AMBIGUOUS" ]]; then
  echo "Reminder id is ambiguous: $id_arg" >&2
  exit 1
fi
out=$(remindctl edit "$resolved" --list "$target_list" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
printf '%s' "$out" | jq 'if type == "array" then .[0] else . end' | jq -s . | jq -f "$REMINDER_DIR/reminder_normalize.jq" | jq -c '.[0]'