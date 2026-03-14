#!/usr/bin/env bash
# Output: JSON (show status).
# Requires: AppleScript backend.
# Example:
#   {
#     "shown": true,
#     "id": "...",
#     "name": "AccountName"
#   }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OSA="$REPO_ROOT/src/applescripts/account"

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <account-name>" >&2; exit 1; }

name="$1"
shown_id=$(/usr/bin/osascript "$OSA/show.applescript" "$name")
jq -n --arg id "$shown_id" --arg name "$name" '{shown:true,id:$id,name:$name}'
