#!/usr/bin/env bash
# Output: JSON (default list).
# Requires: AppleScript backend.
# Example:
#   {
#     "id": "...",
#     "name": "Reminders",
#     "container": "iCloud",
#     "color": "...",
#     "emblem": "..."
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts"

[[ $# -gt 0 ]] && { echo "Usage: $(basename "$0")" >&2; exit 1; }

name=$(/usr/bin/osascript "$OSA/account/default-list.applescript")
id=$(/usr/bin/osascript "$OSA/list/get.applescript" "$name" id --format=json | jq -r '.value')
name_val=$(/usr/bin/osascript "$OSA/list/get.applescript" "$name" name --format=json | jq -r '.value')
container=$(/usr/bin/osascript "$OSA/list/get.applescript" "$name" container --format=json | jq -r '.value')
color=$(/usr/bin/osascript "$OSA/list/get.applescript" "$name" color --format=json | jq -r '.value')
emblem=$(/usr/bin/osascript "$OSA/list/get.applescript" "$name" emblem --format=json | jq -r '.value')
jq -n --arg id "$id" --arg name "$name_val" --arg container "$container" --arg color "$color" --arg emblem "$emblem" '{id:$id,name:$name,container:$container,color:$color,emblem:$emblem}'
