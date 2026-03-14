#!/usr/bin/env bash
# Output: JSON (edited reminder in AGENTS.md shape).
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
#   {
#     "id": "...",
#     "name": "Task",
#     "list": "List",
#     "body": null,
#     "completed": false,
#     "priority": "none",
#     "due_date": null
#   }
set -euo pipefail

[[ $# -lt 4 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id> <property> <value>" >&2; exit 1; }
id_arg="$2"
prop="${3}"
value="$4"
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

if [[ -n "$REMINDCTL_BIN" ]]; then
  raw=$(remindctl_show_all_json)
  resolved=$(resolve_reminder_id "$id_arg" <<< "$raw")
  prop_key="${prop//-/_}"
  cmd=(edit "$resolved")
  case "$prop_key" in
    name) cmd+=(--title "$value") ;;
    body) cmd+=(--notes "$value") ;;
    due_date)
      if [[ "$value" == "missing" ]]; then cmd+=(--clear-due); else cmd+=(--due "$value"); fi ;;
    priority) cmd+=(--priority "$value") ;;
    completed)
      if [[ "$(echo "$value" | tr '[:upper:]' '[:lower:]')" == "true" ]]; then cmd+=(--complete); else cmd+=(--incomplete); fi ;;
    list) cmd+=(--list "$value") ;;
    *) echo "Unsupported property: $prop_key" >&2; exit 1 ;;
  esac
  out=$(run_remindctl_json "${cmd[@]}")
  printf '%s' "$out" | normalize_single_reminder_json
  exit 0
fi

reminder_json=$(load_reminder_by_id_or_error "$id_arg")
list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
full_id=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.id')
run_reminder_applescript edit-by-id.applescript "$list_name" "$full_id" "$prop" "$value" >/dev/null
run_reminder_applescript get-reminder-by-id.applescript "$id_arg"
