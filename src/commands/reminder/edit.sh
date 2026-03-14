#!/usr/bin/env bash
# Output: JSON (edited reminder in AGENTS.md shape).
# Requires: remindctl, jq. Without remindctl prints "not implemented yet" and exits 1.
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

[[ $# -lt 4 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id> <property> <value>" >&2; exit 1; }
id_arg="$2"
prop="${3}"
value="$4"
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

prop_key="${prop//-/_}"
cmd=(remindctl edit "$resolved")
case "$prop_key" in
  name) cmd+=(--title "$value") ;;
  body) cmd+=(--notes "$value") ;;
  due_date)
    if [[ "$value" == "missing" ]]; then cmd+=(--clear-due); else cmd+=(--due "$value"); fi ;;
  priority) cmd+=(--priority "$value") ;;
  completed)
    if [[ "$(echo "$value" | tr '[:upper:]' '[:lower:]')" == "true" ]]; then cmd+=(--complete); else cmd+=(--incomplete); fi ;;
  list) cmd+=(--list "$value") ;;
  *) echo "Unsupported property: $prop_key" >&2; exit 1 ;;
esac
out=$("${cmd[@]}" --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
printf '%s' "$out" | jq 'if type == "array" then .[0] else . end' | jq -s . | jq -f "$REMINDER_DIR/reminder_normalize.jq" | jq -c '.[0]'