#!/usr/bin/env bash
# Output: JSON (default account).
# Requires: AppleScript backend.
# Example:
#   {
#     "id": "...",
#     "name": "iCloud",
#     "lists_count": 11,
#     "reminders_count": 42
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/account"

[[ $# -gt 0 ]] && { echo "Usage: $(basename "$0")" >&2; exit 1; }

name=$(/usr/bin/osascript "$OSA/default-account.applescript")
id=$(/usr/bin/osascript "$OSA/get.applescript" "$name" id --format=json | jq -r '.value')
name_val=$(/usr/bin/osascript "$OSA/get.applescript" "$name" name --format=json | jq -r '.value')
lists_count=$(/usr/bin/osascript "$OSA/get.applescript" "$name" lists_count --format=json | jq -r '.value')
reminders_count=$(/usr/bin/osascript "$OSA/get.applescript" "$name" reminders_count --format=json | jq -r '.value')
jq -n --arg id "$id" --arg name "$name_val" --argjson l "$lists_count" --argjson r "$reminders_count" '{id:$id,name:$name,lists_count:$l,reminders_count:$r}'
