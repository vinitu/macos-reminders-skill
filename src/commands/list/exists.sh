#!/usr/bin/env bash
# Output: JSON (exists flag).
# Requires: AppleScript backend.
# Example:
#   {
#     "exists": true,
#     "name": "ListName",
#     "id": "..."
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/list"

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <list-name>" >&2; exit 1; }

name="$1"
exists_raw=$(/usr/bin/osascript "$OSA/exists.applescript" "$name")
if [[ "$exists_raw" == "true" ]]; then
  id=$(/usr/bin/osascript "$OSA/get.applescript" "$name" id --format=json | jq -r '.value')
  jq -n --arg name "$name" --arg id "$id" '{exists:true,name:$name,id:$id}'
else
  jq -n --arg name "$name" '{exists:false,name:$name,id:null}'
fi
