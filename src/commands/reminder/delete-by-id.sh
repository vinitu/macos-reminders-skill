#!/usr/bin/env bash
# Output: JSON {deleted, id}.
# Requires: remindctl, jq. Without remindctl prints "not implemented yet" and exits 1.
# Example:
#   {
#     "deleted": true,
#     "id": "..."
#   }
set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") [list-name] <id>" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") [list-name] <id>" >&2; exit 1; }
id_arg="${2:-$1}"

exec "$(dirname "$0")/delete.sh" --id "$id_arg"