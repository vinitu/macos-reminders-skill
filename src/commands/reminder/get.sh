#!/usr/bin/env bash
# Output: JSON (reminder object or {id, property, value} when property given).
# Requires: remindctl, jq. Without remindctl prints "not implemented yet" and exits 1.
# Example (full reminder):
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": null
#   }
# Example (property):
#   {
#     "id": "...",
#     "property": "body",
#     "value": "Notes text"
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id> [property]" >&2; exit 1; }
id_arg="$2"
property="${3:-}"
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
matches=$(printf '%s' "$raw" | jq -c --arg id "$id_arg" '[.[] | select((.id | ascii_downcase) | startswith(($id | ascii_downcase)))]')
n=$(printf '%s' "$matches" | jq 'length')
if [[ "$n" -eq 0 ]]; then
  echo "Reminder not found for id: $id_arg" >&2
  exit 1
fi
if [[ "$n" -gt 1 ]]; then
  echo "Reminder id is ambiguous: $id_arg" >&2
  exit 1
fi
normalized=$(printf '%s' "$matches" | jq -c '.[0]' | jq -f "$REMINDER_DIR/reminder_normalize.jq" | jq -c '.[0]')
if [[ -z "$property" ]]; then
  printf '%s' "$normalized"
else
  prop_key="${property//-/_}"
  value=$(printf '%s' "$normalized" | jq -r --arg k "$prop_key" '.[$k] // empty')
  full_id=$(printf '%s' "$normalized" | jq -r '.id')
  jq -n --arg id "$full_id" --arg property "$prop_key" --arg value "$value" '{id: $id, property: $property, value: $value}'
fi
