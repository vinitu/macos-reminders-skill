#!/usr/bin/env bash
# Output: JSON (created reminder in AGENTS.md shape).
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing (supports --due and --priority).
# Example:
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": null
#   }
set -euo pipefail

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") <list-name> <reminder-name> [body] [--due <date>] [--priority <none|low|medium|high>]" >&2; exit 1; }
list_name="$1"
reminder_name="$2"
shift 2
body=""
due_value=""
priority=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --due) due_value="$2"; shift 2 ;;
    --priority) priority="$2"; shift 2 ;;
    --json) shift ;;
    -*) echo "Unsupported flag: $1" >&2; exit 1 ;;
    *) body="$1"; shift ;;
  esac
done

if command -v remindctl >/dev/null 2>&1; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq required when using remindctl" >&2
    exit 1
  fi
  cmd=(remindctl add --title "$reminder_name" --list "$list_name")
  [[ -n "$body" ]] && cmd+=(--notes "$body")
  [[ -n "$due_value" ]] && cmd+=(--due "$due_value")
  [[ -n "$priority" ]] && cmd+=(--priority "$priority")
  raw=$("${cmd[@]}" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
  printf '%s' "$raw" | jq --arg body "${body:-}" '
    def first_reminder: if type == "array" then .[0] elif type == "object" then (.["reminder"]? // .["result"]? // .) else . end;
    (first_reminder) as $r |
    ($r | if .notes != null and .notes != "" then .notes else $body end) as $b |
    {id: $r.id, name: ($r.title // $r.name), list: ($r.listName // $r.list), body: (if $b != "" then $b else null end), completed: ($r.isCompleted // false),
     priority: (if $r.priority == null then "none" elif $r.priority == 0 then "none" elif $r.priority == 1 then "low" elif $r.priority == 5 then "medium" elif $r.priority == 9 then "high" else "none" end),
     due_date: $r.dueDate}
  '
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Pass list, name, body, due, priority (empty string = omit)
exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/create.applescript" "$list_name" "$reminder_name" "${body:-}" "${due_value:-}" "${priority:-}"
