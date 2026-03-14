#!/usr/bin/env bash
# Output: always JSON {count, list}.
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
# {
#   "count": 42,
#   "list": null
# }
set -euo pipefail

[[ $# -gt 1 ]] && { echo "Usage: $(basename "$0") [list-name]" >&2; exit 1; }
list_name="${1:-}"
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if [[ -n "$REMINDCTL_BIN" ]]; then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  raw=$(remindctl_all_or_list_json "$list_name")
  printf '%s' "$raw" | "$JQ_BIN" --arg list "$list_name" '{count: length, list: (if $list == "" then null else $list end)}'
  exit 0
fi

exec_reminder_applescript_optional_last_arg count.applescript "$list_name"
