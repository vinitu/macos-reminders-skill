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
    -*) echo "Unsupported flag: $1" >&2; exit 1 ;;
    *) body="$1"; shift ;;
  esac
done
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if [[ -n "$REMINDCTL_BIN" ]]; then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  cmd=(add --title "$reminder_name" --list "$list_name")
  [[ -n "$body" ]] && cmd+=(--notes "$body")
  [[ -n "$due_value" ]] && cmd+=(--due "$due_value")
  [[ -n "$priority" ]] && cmd+=(--priority "$priority")
  raw=$(run_remindctl_json "${cmd[@]}")
  printf '%s' "$raw" | "$JQ_BIN" --arg body "${body:-}" '
    def first_reminder: if type == "array" then .[0] elif type == "object" then (.["reminder"]? // .["result"]? // .) else . end;
    (first_reminder) as $r |
    ($r | if .notes != null and .notes != "" then .notes else $body end) as $b |
    {id: $r.id, name: ($r.title // $r.name), list: ($r.listName // $r.list), body: (if $b != "" then $b else null end), completed: ($r.isCompleted // false),
     priority: (if $r.priority == null then "none" elif $r.priority == 0 then "none" elif $r.priority == 1 then "low" elif $r.priority == 5 then "medium" elif $r.priority == 9 then "high" else "none" end),
     due_date: $r.dueDate}
  '
  exit 0
fi

# Pass list, name, body, due, priority (empty string = omit)
exec_reminder_applescript create.applescript "$list_name" "$reminder_name" "${body:-}" "${due_value:-}" "${priority:-}"
