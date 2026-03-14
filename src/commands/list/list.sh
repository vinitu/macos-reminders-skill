#!/usr/bin/env bash
# Output: JSON (list of lists).
# Requires: AppleScript backend.
# Example:
#   [
#     {
#       "id": "...",
#       "name": "Reminders",
#       "container": "iCloud",
#       "color": "...",
#       "emblem": "..."
#     }
#   ]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/list"

[[ $# -gt 1 ]] && { echo "Usage: $(basename "$0") [account-name]" >&2; exit 1; }

args=()
[[ $# -eq 1 ]] && args=("$1")
names_json=$(/usr/bin/osascript "$OSA/list.applescript" "${args[@]}")
out="[]"
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  id=$(/usr/bin/osascript "$OSA/get.applescript" "$name" id | jq -r '.value')
  name_val=$(/usr/bin/osascript "$OSA/get.applescript" "$name" name | jq -r '.value')
  container=$(/usr/bin/osascript "$OSA/get.applescript" "$name" container | jq -r '.value')
  color=$(/usr/bin/osascript "$OSA/get.applescript" "$name" color | jq -r '.value')
  emblem=$(/usr/bin/osascript "$OSA/get.applescript" "$name" emblem | jq -r '.value')
  obj=$(jq -n --arg id "$id" --arg name "$name_val" --arg container "$container" --arg color "$color" --arg emblem "$emblem" '{id:$id,name:$name,container:$container,color:$color,emblem:$emblem}')
  out=$(jq -n --argjson arr "$out" --argjson obj "$obj" '$arr + [$obj]')
done < <(echo "$names_json" | jq -r '.[]')
echo "$out"
