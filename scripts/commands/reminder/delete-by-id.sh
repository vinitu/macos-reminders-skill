#!/usr/bin/env bash
# Output: JSON {deleted, id}.
# Delegates to delete.sh (prefer remindctl, AppleScript fallback).
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