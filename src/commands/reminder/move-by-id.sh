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

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") [source-list] <id> <target-list>" >&2; exit 1; }
[[ $# -gt 3 ]] && { echo "Usage: $(basename "$0") [source-list] <id> <target-list>" >&2; exit 1; }
if [[ $# -eq 2 ]]; then
  exec "$(dirname "$0")/move.sh" --id "$1" "$2"
fi
exec "$(dirname "$0")/move.sh" --id "$2" "$3"