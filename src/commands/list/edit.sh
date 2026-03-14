#!/usr/bin/env bash
# Output: JSON (updated list or status).
# Requires: AppleScript backend.
# Example:
#   {
#     "id": "...",
#     "name": "NewName",
#     "container": "iCloud",
#     "color": "...",
#     "emblem": "..."
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/list"

[[ $# -ne 3 ]] && { echo "Usage: $(basename "$0") <list-name> <name|color|emblem> <value>" >&2; exit 1; }

list_name="$1"
prop="${2//-/_}"
value="$3"
result=$(/usr/bin/osascript "$OSA/edit.applescript" "$list_name" "$prop" "$value")
if [[ "$prop" == "name" ]]; then
  target_name="$result"
else
  target_name="$list_name"
fi
id=$(/usr/bin/osascript "$OSA/get.applescript" "$target_name" id | jq -r '.value')
name_val=$(/usr/bin/osascript "$OSA/get.applescript" "$target_name" name | jq -r '.value')
container=$(/usr/bin/osascript "$OSA/get.applescript" "$target_name" container | jq -r '.value')
color=$(/usr/bin/osascript "$OSA/get.applescript" "$target_name" color | jq -r '.value')
emblem=$(/usr/bin/osascript "$OSA/get.applescript" "$target_name" emblem | jq -r '.value')
jq -n --arg id "$id" --arg name "$name_val" --arg container "$container" --arg color "$color" --arg emblem "$emblem" '{id:$id,name:$name,container:$container,color:$color,emblem:$emblem}'
