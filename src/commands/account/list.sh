#!/usr/bin/env bash
# Output: JSON (list of accounts).
# Requires: AppleScript backend.
# Example:
#   [
#     {
#       "id": "...",
#       "name": "iCloud",
#       "lists_count": 11,
#       "reminders_count": 42
#     }
#   ]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/account"

[[ $# -gt 0 ]] && { echo "Usage: $(basename "$0")" >&2; exit 1; }

names_json=$(/usr/bin/osascript "$OSA/list.applescript" --format=json)
out="[]"
while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  id=$(/usr/bin/osascript "$OSA/get.applescript" "$name" id --format=json | jq -r '.value')
  lists_count=$(/usr/bin/osascript "$OSA/get.applescript" "$name" lists_count --format=json | jq -r '.value')
  reminders_count=$(/usr/bin/osascript "$OSA/get.applescript" "$name" reminders_count --format=json | jq -r '.value')
  obj=$(jq -n --arg id "$id" --arg name "$name" --argjson l "$lists_count" --argjson r "$reminders_count" '{id:$id,name:$name,lists_count:$l,reminders_count:$r}')
  out=$(jq -n --argjson arr "$out" --argjson obj "$obj" '$arr + [$obj]')
done < <(echo "$names_json" | jq -r '.[]')
echo "$out"
