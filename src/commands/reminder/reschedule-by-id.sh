#!/usr/bin/env bash
# Output: JSON (edited reminder in AGENTS.md shape).
# Delegates to reschedule.sh.
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

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") [list-name] <id> <date>" >&2; exit 1; }
[[ $# -gt 3 ]] && { echo "Usage: $(basename "$0") [list-name] <id> <date>" >&2; exit 1; }

if [[ $# -eq 2 ]]; then
  exec "$(dirname "$0")/reschedule.sh" --id "$1" "$2"
fi

exec "$(dirname "$0")/reschedule.sh" --id "$2" "$3"
