#!/usr/bin/env bash
# Output: JSON (created list or status).
# Requires: AppleScript backend.
# Example:
#   {
#     "id": "...",
#     "name": "ListName",
#     "container": "iCloud",
#     "color": "...",
#     "emblem": "...",
#     "state": "created"
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OSA="$REPO_ROOT/scripts/applescripts/list"

[[ $# -lt 1 || $# -gt 3 ]] && { echo "Usage: $(basename "$0") <list-name> [color|missing] [emblem|missing]" >&2; exit 1; }

list_name="$1"
state=$(/usr/bin/osascript "$OSA/create.applescript" "$@")
id=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" id | jq -r '.value')
name_val=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" name | jq -r '.value')
container=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" container | jq -r '.value')
color=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" color | jq -r '.value')
emblem=$(/usr/bin/osascript "$OSA/get.applescript" "$list_name" emblem | jq -r '.value')
jq -n --arg id "$id" --arg name "$name_val" --arg container "$container" --arg color "$color" --arg emblem "$emblem" --arg state "$state" '{id:$id,name:$name,container:$container,color:$color,emblem:$emblem,state:$state}'
