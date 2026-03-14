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

[[ $# -lt 3 ]] && { echo "Usage: $(basename "$0") [list-name] <id> <property> <value>" >&2; exit 1; }
if [[ $# -eq 3 ]]; then
  exec "$(dirname "$0")/edit.sh" --id "$1" "$2" "$3"
fi
exec "$(dirname "$0")/edit.sh" --id "$2" "$3" "$4"