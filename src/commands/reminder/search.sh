#!/usr/bin/env bash
# Output: JSON (array of reminders). Modes: exact-name, id, incomplete, priority, has-due-date, text.
# Prefer: remindctl + jq. Fallback: AppleScript when remindctl is missing.
# Example:
#   [
#     {
#       "id": "...",
#       "name": "Task",
#       "list": "List",
#       "body": null,
#       "completed": false,
#       "priority": "none",
#       "due_date": "2026-03-13T12:00:00Z"
#     }
#   ]
set -euo pipefail

[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <exact-name|id|incomplete|priority|has-due-date|text> [args...]" >&2; exit 1; }
mode="$1"
shift
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"

if [[ -n "$REMINDCTL_BIN" ]]; then
  [[ -n "$JQ_BIN" ]] || { echo "jq required when using remindctl" >&2; exit 1; }
  list_name=""
  case "$mode" in
      exact-name) [[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") exact-name <list-name> <reminder-name>" >&2; exit 1; }; list_name="$1"; exact_title="$2"; shift 2 ;;
    id) [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") id <id>" >&2; exit 1; }; id_arg="$1"; shift ;;
    incomplete) list_name="${1:-}"; shift ;;
    priority) [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") priority <none|low|medium|high> [list-name]" >&2; exit 1; }; pri="$1"; list_name="${2:-}"; shift 2 ;;
    has-due-date) list_name="${1:-}"; shift ;;
    text) [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") text <query> [list-name]" >&2; exit 1; }; query="$1"; list_name="${2:-}"; shift 2 ;;
    *) echo "Unsupported search mode: $mode" >&2; exit 1 ;;
  esac

  raw=$(remindctl_all_or_list_json "$list_name")

  case "$mode" in
    exact-name)
      printf '%s' "$raw" | "$JQ_BIN" -c --arg title "$exact_title" '[.[] | select(.title == $title)]' | normalize_reminders_json
      ;;
    id)
      match=$(get_single_reminder_match_json "$id_arg" <<< "$raw")
      printf '%s' "$match" | "$JQ_BIN" -s . | normalize_reminders_json
      ;;
    incomplete)
      printf '%s' "$raw" | "$JQ_BIN" -c '[.[] | select(.isCompleted == false)]' | normalize_reminders_json
      ;;
    priority)
      pri_num="none"
      case "$(echo "$pri" | tr '[:upper:]' '[:lower:]')" in
        none) pri_num=0 ;;
        low) pri_num=1 ;;
        medium) pri_num=5 ;;
        high) pri_num=9 ;;
        *) echo "Unsupported priority: $pri" >&2; exit 1 ;;
      esac
      printf '%s' "$raw" | "$JQ_BIN" -c --argjson p "$pri_num" '[.[] | select(.priority == $p)]' | normalize_reminders_json
      ;;
    has-due-date)
      printf '%s' "$raw" | "$JQ_BIN" -c '[.[] | select(.dueDate != null and .dueDate != "")]' | normalize_reminders_json
      ;;
    text)
      [[ -z "$(echo "$query" | tr -d ' ')" ]] && { echo "Query must not be empty" >&2; exit 1; }
      q_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')
      printf '%s' "$raw" | "$JQ_BIN" -c --arg q "$q_lower" '[.[] | select((.title | ascii_downcase | index($q)) or ((.notes // "" | ascii_downcase) | index($q)))]' | normalize_reminders_json
      ;;
  esac
  exit 0
fi

# AppleScript fallback: same usage, build args for search.applescript
search_args=("$mode")
case "$mode" in
  exact-name)
    [[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") exact-name <list-name> <reminder-name>" >&2; exit 1; }
    search_args+=("$1" "$2")
    ;;
  id)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") id <id>" >&2; exit 1; }
    search_args+=("$1")
    ;;
  incomplete)
    [[ -n "${1:-}" ]] && search_args+=("$1")
    ;;
  priority)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") priority <none|low|medium|high> [list-name]" >&2; exit 1; }
    pri_val="$1"
    case "$(echo "$pri_val" | tr '[:upper:]' '[:lower:]')" in
      none) pri_num=0 ;;
      low) pri_num=1 ;;
      medium) pri_num=5 ;;
      high) pri_num=9 ;;
      *) echo "Unsupported priority: $pri_val" >&2; exit 1 ;;
    esac
    search_args+=("$pri_num")
    [[ -n "${2:-}" ]] && search_args+=("$2")
    ;;
  has-due-date)
    [[ -n "${1:-}" ]] && search_args+=("$1")
    ;;
  text)
    [[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") text <query> [list-name]" >&2; exit 1; }
    [[ -z "$(echo "$1" | tr -d ' ')" ]] && { echo "Query must not be empty" >&2; exit 1; }
    search_args+=("$1")
    [[ -n "${2:-}" ]] && search_args+=("$2")
    ;;
  *)
    echo "Unsupported search mode: $mode" >&2
    exit 1
    ;;
esac
exec /usr/bin/osascript "$REPO_ROOT/src/applescripts/reminder/search.applescript" "${search_args[@]}"
