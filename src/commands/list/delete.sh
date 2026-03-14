#!/usr/bin/env bash
# Output: JSON (deletion status).
# Requires: AppleScript backend.
# Example:
#   {
#     "deleted": true,
#     "name": "ListName"
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/list"

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <list-name>" >&2; exit 1; }

name="$1"
state=$(/usr/bin/osascript "$OSA/delete.applescript" "$name")
deleted=false
[[ "$state" == "deleted" ]] && deleted=true
jq -n --arg name "$name" --argjson deleted "$deleted" '{deleted:$deleted,name:$name}'
