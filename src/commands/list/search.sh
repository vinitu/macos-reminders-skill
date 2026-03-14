#!/usr/bin/env bash
# Output: JSON (list list or match).
# Requires: AppleScript backend.
# Example:
#   [
#     {
#       "id": "...",
#       "name": "ListName",
#       "container": "iCloud",
#       "color": "...",
#       "emblem": "..."
#     }
#   ]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/list"

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") <exact-name|id|color|emblem|text> <query> [account-name]" >&2; exit 1; }

mode="$1"
query="$2"
shift 2
args=("$mode" "$query")
[[ $# -ge 1 ]] && args+=("$1")
names_json=$(/usr/bin/osascript "$OSA/search.applescript" "${args[@]}" --format=json)
out="[]"
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  id=$(/usr/bin/osascript "$OSA/get.applescript" "$name" id --format=json | jq -r '.value')
  name_val=$(/usr/bin/osascript "$OSA/get.applescript" "$name" name --format=json | jq -r '.value')
  container=$(/usr/bin/osascript "$OSA/get.applescript" "$name" container --format=json | jq -r '.value')
  color=$(/usr/bin/osascript "$OSA/get.applescript" "$name" color --format=json | jq -r '.value')
  emblem=$(/usr/bin/osascript "$OSA/get.applescript" "$name" emblem --format=json | jq -r '.value')
  obj=$(jq -n --arg id "$id" --arg name "$name_val" --arg container "$container" --arg color "$color" --arg emblem "$emblem" '{id:$id,name:$name,container:$container,color:$color,emblem:$emblem}')
  out=$(jq -n --argjson arr "$out" --argjson obj "$obj" '$arr + [$obj]')
done < <(echo "$names_json" | jq -r '.[]')
echo "$out"
