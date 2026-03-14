#!/usr/bin/env bash
# Output: JSON (edited reminder in AGENTS.md shape).
# Sets due_date to the provided date or date-time string.
# Example:
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": "2026-03-21T12:00:00Z"
#   }
set -euo pipefail

[[ $# -lt 3 ]] && { echo "Usage: $(basename "$0") --id <id> <date>" >&2; exit 1; }
[[ $# -gt 3 ]] && { echo "Usage: $(basename "$0") --id <id> <date>" >&2; exit 1; }
[[ "$1" == "--id" ]] || { echo "Usage: $(basename "$0") --id <id> <date>" >&2; exit 1; }

id_arg="$2"
date_value="$3"

exec "$(dirname "$0")/edit.sh" --id "$id_arg" due_date "$date_value"
