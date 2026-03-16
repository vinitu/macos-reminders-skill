#!/usr/bin/env bash
# Output: JSON (account property or object).
# Requires: AppleScript backend.
# Example (object):
#   {
#     "id": "...",
#     "name": "iCloud",
#     "lists_count": 11,
#     "reminders_count": 42
#   }
# Example (property):
#   {
#     "id": "...",
#     "property": "name",
#     "value": "iCloud"
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OSA="$REPO_ROOT/scripts/applescripts/account"

[[ $# -ne 2 ]] && { echo "Usage: $(basename "$0") <account-name> <id|name|lists_count|reminders_count>" >&2; exit 1; }

account_name="$1"
property="${2//-/_}"
id=$(/usr/bin/osascript "$OSA/get.applescript" "$account_name" id | jq -r '.value')
val=$(/usr/bin/osascript "$OSA/get.applescript" "$account_name" "$property" | jq -r '.value')
if [[ "$property" == "lists_count" || "$property" == "reminders_count" ]]; then
  jq -n --arg id "$id" --arg name "$account_name" --arg prop "$property" --argjson v "$val" '{id:$id,name:$name,property:$prop,value:$v}'
else
  jq -n --arg id "$id" --arg name "$account_name" --arg prop "$property" --arg v "$val" '{id:$id,name:$name,property:$prop,value:$v}'
fi
