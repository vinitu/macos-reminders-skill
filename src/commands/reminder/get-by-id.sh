#!/usr/bin/env bash
# Output: JSON (reminder object or {id, property, value} when property given).
# Delegates to get.sh (prefer remindctl, AppleScript fallback).
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

# Usage: [list-name] <id> [property] — list-name optional for disambiguation
if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") [list-name] <id> [property]" >&2
  exit 1
fi
if [[ $# -eq 1 ]]; then
  exec "$(dirname "$0")/get.sh" --id "$1"
fi
# 2+ args: could be <id> <property> or <list-name> <id> [property]
if [[ $# -eq 2 ]]; then
  if [[ "$2" == "id" || "$2" == "name" || "$2" == "list" || "$2" == "body" || "$2" == "completed" || "$2" == "priority" || "$2" == "due_date" ]]; then
    exec "$(dirname "$0")/get.sh" --id "$1" "$2"
  else
    exec "$(dirname "$0")/get.sh" --id "$2"
  fi
fi
# 3+ args: [list-name] <id> <property>
exec "$(dirname "$0")/get.sh" --id "$2" "$3"
