#!/usr/bin/env bash
# Output: JSON (array of reminders). Modes: exact-name, id, incomplete, priority, has-due-date, text.
# Requires: remindctl, jq. Without remindctl prints "not implemented yet" and exits 1.
# Example:
#   [
#     {
#       "id": "...",
#       "name": "Task",
#       "list": "List",
#       "body": null,
#       "completed": false,
#       "priority": "none",
#       "due_date": "2026-03-13T12:00:00Z"
#     }
#   ]
set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <exact-name|id|incomplete|priority|has-due-date|text> [args...]" >&2; exit 1; }
mode="$1"
shift
REMINDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v remindctl >/dev/null 2>&1; then
  echo "not implemented yet" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq required when using remindctl" >&2
  exit 1
fi

list_name=""
case "$mode" in
  exact-name) [[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") exact-name <list-name> <reminder-name>" >&2; exit 1; }; list_name="$1"; exact_title="$2"; shift 2 ;;
  id) [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") id <id>" >&2; exit 1; }; id_arg="$1"; shift ;;
  incomplete) list_name="${1:-}"; shift ;;
  priority) [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") priority <none|low|medium|high> [list-name]" >&2; exit 1; }; pri="$1"; list_name="${2:-}"; shift 2 ;;
  has-due-date) list_name="${1:-}"; shift ;;
  text) [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") text <query> [list-name]" >&2; exit 1; }; query="$1"; list_name="${2:-}"; shift 2 ;;
  *) echo "Unsupported search mode: $mode" >&2; exit 1 ;;
esac

if [[ -n "$list_name" ]]; then
  raw=$(remindctl list "$list_name" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
else
  raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
fi

case "$mode" in
  exact-name)
    printf '%s' "$raw" | jq -c --arg title "$exact_title" '[.[] | select(.title == $title)]' | jq -f "$REMINDER_DIR/reminder_normalize.jq"
    ;;
  id)
    matches=$(printf '%s' "$raw" | jq -c --arg id "$id_arg" '[.[] | select((.id | ascii_downcase) | startswith(($id | ascii_downcase)))]')
    n=$(printf '%s' "$matches" | jq 'length')
    if [[ "$n" -eq 0 ]]; then echo "Reminder not found for id: $id_arg" >&2; exit 1; fi
    if [[ "$n" -gt 1 ]]; then echo "Reminder id is ambiguous: $id_arg" >&2; exit 1; fi
    printf '%s' "$matches" | jq -f "$REMINDER_DIR/reminder_normalize.jq"
    ;;
  incomplete)
    printf '%s' "$raw" | jq -c '[.[] | select(.isCompleted == false)]' | jq -f "$REMINDER_DIR/reminder_normalize.jq"
    ;;
  priority)
    pri_num="none"
    case "$(echo "$pri" | tr '[:upper:]' '[:lower:]')" in
      none) pri_num=0 ;;
      low) pri_num=1 ;;
      medium) pri_num=5 ;;
      high) pri_num=9 ;;
      *) echo "Unsupported priority: $pri" >&2; exit 1 ;;
    esac
    printf '%s' "$raw" | jq -c --argjson p "$pri_num" '[.[] | select(.priority == $p)]' | jq -f "$REMINDER_DIR/reminder_normalize.jq"
    ;;
  has-due-date)
    printf '%s' "$raw" | jq -c '[.[] | select(.dueDate != null and .dueDate != "")]' | jq -f "$REMINDER_DIR/reminder_normalize.jq"
    ;;
  text)
    [[ -z "$(echo "$query" | tr -d ' ')" ]] && { echo "Query must not be empty" >&2; exit 1; }
    q_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')
    printf '%s' "$raw" | jq -c --arg q "$q_lower" '[.[] | select((.title | ascii_downcase | index($q)) or ((.notes // "" | ascii_downcase) | index($q)))]' | jq -f "$REMINDER_DIR/reminder_normalize.jq"
    ;;
esac