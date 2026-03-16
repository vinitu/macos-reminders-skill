#!/usr/bin/env bash
# Output: JSON {deleted, id}.
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
#   {
#     "deleted": true,
#     "id": "..."
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
id_arg="$2"
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

if [[ -n "$REMINDCTL_BIN" ]]; then
  raw=$(remindctl_show_all_json)
  resolved=$(resolve_reminder_id "$id_arg" <<< "$raw")
  run_remindctl_json delete "$resolved" --force >/dev/null
  "$JQ_BIN" -n --arg id "$resolved" '{deleted: true, id: $id}'
  exit 0
fi

reminder_json=$(load_reminder_by_id_or_error "$id_arg")
list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
full_id=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.id')
run_reminder_applescript delete-by-id.applescript "$list_name" "$full_id" >/dev/null
"$JQ_BIN" -n --arg id "$full_id" '{deleted: true, id: $id}'
