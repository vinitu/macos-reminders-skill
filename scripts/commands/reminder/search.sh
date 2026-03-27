#!/usr/bin/env bash
# Output: JSON (array of reminders).
# Modes: exact-name, id, incomplete, priority, has-due-date, text, flagged, urgent, nested, top-level, parent-id.
# Prefer: remindctl + jq for speed. Fallback: AppleScript + ReminderKit when remindctl is unavailable or fails.
# Example:
#   [
#     {
#       "id": "...",
#       "name": "Task",
#       "list": "List",
#       "body": null,
#       "completed": false,
#       "priority": "none",
#       "due_date": "2026-03-13T12:00:00Z",
#       "flagged": false,
#       "urgent": false,
#       "parent_id": null,
#       "parent_name": null
#     }
#   ]
set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <exact-name|id|incomplete|priority|has-due-date|text|flagged|urgent|nested|top-level|parent-id> [args...]" >&2; exit 1; }
mode="$1"
shift
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"
[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

load_base_json() {
  local requested_list="${1:-}"
  local raw

  if raw=$(try_remindctl_all_or_list_json "$requested_list"); then
    normalize_reminders_json <<< "$raw" | augment_reminders_json
  else
    if [[ -n "$requested_list" ]]; then
      run_reminder_applescript list.applescript "$requested_list" | augment_reminders_json
    else
      run_reminder_applescript list.applescript | augment_reminders_json
    fi
  fi
}

case "$mode" in
  exact-name)
    [[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") exact-name <list-name> <reminder-name>" >&2; exit 1; }
    list_name="$1"
    exact_title="$2"
    if raw=$(try_remindctl_all_or_list_json "$list_name"); then
      filtered=$(normalize_reminders_json <<< "$raw" | "$JQ_BIN" -c --arg title "$exact_title" '[.[] | select(.name == $title)]')
      printf '%s' "$filtered" | augment_reminders_json
    else
      run_reminderkit_helper search-exact-name "$list_name" "$exact_title" | augment_reminders_json
    fi
    ;;
  id)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") id <id>" >&2; exit 1; }
    id_arg="$1"
    base_json=$(load_base_json)
    match=$(get_single_reminder_match_json "$id_arg" <<< "$base_json")
    printf '%s' "$match" | "$JQ_BIN" -s -c .
    ;;
  incomplete)
    list_name="${1:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c '[.[] | select(.completed == false)]'
    ;;
  priority)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") priority <none|low|medium|high> [list-name]" >&2; exit 1; }
    pri="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    case "$pri" in
      none|low|medium|high) ;;
      *) echo "Unsupported priority: $1" >&2; exit 1 ;;
    esac
    list_name="${2:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c --arg p "$pri" '[.[] | select(.priority == $p)]'
    ;;
  has-due-date)
    list_name="${1:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c '[.[] | select(.due_date != null and .due_date != "")]'
    ;;
  text)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") text <query> [list-name]" >&2; exit 1; }
    [[ -z "$(echo "$1" | tr -d ' ')" ]] && { echo "Query must not be empty" >&2; exit 1; }
    query="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    list_name="${2:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c --arg q "$query" '[.[] | select((.name | ascii_downcase | index($q)) or ((.body // "" | ascii_downcase) | index($q)))]'
    ;;
  flagged)
    list_name="${1:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c '[.[] | select(.flagged == true)]'
    ;;
  urgent)
    list_name="${1:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c '[.[] | select(.urgent == true)]'
    ;;
  nested)
    list_name="${1:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c '[.[] | select(.parent_id != null)]'
    ;;
  top-level)
    list_name="${1:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c '[.[] | select(.parent_id == null)]'
    ;;
  parent-id)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") parent-id <parent-id> [list-name]" >&2; exit 1; }
    parent_id_prefix="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    list_name="${2:-}"
    base_json=$(load_base_json "$list_name")
    printf '%s' "$base_json" | "$JQ_BIN" -c --arg prefix "$parent_id_prefix" '[.[] | select(.parent_id != null and ((.parent_id | ascii_downcase) | startswith($prefix)))]'
    ;;
  *)
    echo "Unsupported search mode: $mode" >&2
    exit 1
    ;;
esac
