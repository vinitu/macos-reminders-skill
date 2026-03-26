#!/usr/bin/env bash
# Output: JSON (created reminder in AGENTS.md shape).
# Prefer: remindctl + jq for speed. Fallback: AppleScript + ReminderKit when remindctl is unavailable or fails.
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

[[ $# -lt 2 ]] && { echo "Usage: $(basename "$0") <list-name> <reminder-name> [body] [--due <date>] [--priority <none|low|medium|high>] [--flagged] [--urgent] [--parent-id <id>]" >&2; exit 1; }
list_name="$1"
reminder_name="$2"
shift 2
body=""
due_value=""
priority=""
flagged="false"
urgent="false"
parent_id=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --due) due_value="$2"; shift 2 ;;
    --priority) priority="$2"; shift 2 ;;
    --flagged) flagged="true"; shift ;;
    --urgent) urgent="true"; shift ;;
    --parent-id) parent_id="$2"; shift 2 ;;
    -*) echo "Unsupported flag: $1" >&2; exit 1 ;;
    *) body="$1"; shift ;;
  esac
done
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"
[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

resolved_parent_id=""
if [[ -n "$parent_id" ]]; then
  resolved_parent_id=$(resolve_full_reminder_id_or_error "$parent_id")
fi

created_json=""
post_create_mutation="false"
created_via_reminderkit="false"
cmd=(add --title "$reminder_name" --list "$list_name")
[[ -n "$body" ]] && cmd+=(--notes "$body")
[[ -n "$due_value" ]] && cmd+=(--due "$due_value")
[[ -n "$priority" ]] && cmd+=(--priority "$priority")

if raw=$(try_run_remindctl_json "${cmd[@]}"); then
  created_json=$(printf '%s' "$raw" | "$JQ_BIN" --arg body "${body:-}" '
    def first_reminder: if type == "array" then .[0] elif type == "object" then (.["reminder"]? // .["result"]? // .) else . end;
    (first_reminder) as $r |
    ($r | if .notes != null and .notes != "" then .notes else $body end) as $b |
     {id: $r.id, name: ($r.title // $r.name), list: ($r.listName // $r.list), body: (if $b != "" then $b else null end), completed: ($r.isCompleted // false),
     priority: (if $r.priority == null then "none" elif $r.priority == 0 or $r.priority == "none" then "none" elif $r.priority == 1 or $r.priority == "high" then "high" elif $r.priority == 5 or $r.priority == "medium" then "medium" elif $r.priority == 9 or $r.priority == "low" then "low" else "none" end),
     due_date: $r.dueDate}
  ')
else
  if created_json=$(run_reminderkit_helper create "$list_name" "$reminder_name" "${body:-}" "${due_value:-}" "${priority:-}" 2>/dev/null); then
    created_via_reminderkit="true"
  else
    created_json=$(run_reminder_applescript create.applescript "$list_name" "$reminder_name" "${body:-}" "${due_value:-}" "${priority:-}")
  fi
fi

created_id=$(printf '%s' "$created_json" | "$JQ_BIN" -r '.id')

if [[ "$flagged" == "true" ]]; then
  run_reminderkit_helper set-flagged "$created_id" true >/dev/null
  post_create_mutation="true"
fi

if [[ "$urgent" == "true" ]]; then
  run_reminderkit_helper set-urgent "$created_id" true >/dev/null
  post_create_mutation="true"
fi

if [[ -n "$parent_id" ]]; then
  run_reminderkit_helper reparent "$created_id" "$resolved_parent_id" >/dev/null
  post_create_mutation="true"
fi

if [[ "$created_via_reminderkit" == "true" ]]; then
  post_create_mutation="true"
fi

if [[ "$post_create_mutation" == "true" ]]; then
  if [[ "$created_via_reminderkit" == "true" ]]; then
    refreshed_json=""
    [[ -n "$priority" ]] && sleep 1
    for _attempt in 1 2 3 4 5 6 7 8 9 10; do
      refreshed_json=$("$(dirname "$0")/get.sh" --id "$created_id")
      refreshed_priority=$(printf '%s' "$refreshed_json" | "$JQ_BIN" -r '.priority')
      if [[ -z "$priority" || "$refreshed_priority" == "$priority" ]]; then
        printf '%s' "$refreshed_json"
        exit 0
      fi
      sleep 1
    done
    printf '%s' "$refreshed_json"
  else
    "$(dirname "$0")/get.sh" --id "$created_id"
  fi
else
  printf '%s' "$created_json" | augment_reminders_json
fi
