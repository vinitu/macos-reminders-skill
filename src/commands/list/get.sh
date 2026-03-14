#!/usr/bin/env bash
# Output: JSON (list property or object).
# Requires: AppleScript backend.
# Example (object):
#   {
#     "id": "...",
#     "name": "ListName",
#     "container": "iCloud",
#     "color": "...",
#     "emblem": "...",
#     "state": "..."
#   }
# Example (property):
#   {
#     "id": "...",
#     "property": "name",
#     "value": "ListName"
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/list"

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") <list-name> <id|name|container|color|emblem>" >&2; exit 1; }

list_name="$1"
property="${2//-/_}"
id=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" id | jq -r '.value')
val=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" "$property" | jq -r '.value')
jq -n --arg id "$id" --arg name "$list_name" --arg prop "$property" --arg v "$val" '{id:$id,name:$name,property:$prop,value:$v}'
