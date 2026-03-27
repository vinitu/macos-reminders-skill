#!/usr/bin/env bash
# Output: JSON (edited reminder in AGENTS.md shape).
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

[[ $# -lt 4 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id> <property> <value>" >&2; exit 1; }
id_arg="$2"
prop="${3}"
value="$4"
# shellcheck source=scripts/commands/reminder/_lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib/common.sh"
COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -n "$JQ_BIN" ]] || { echo "jq required" >&2; exit 1; }

normalize_bool_value() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

ensure_boolean_value() {
  local bool_value="$1"

  if [[ "$bool_value" != "true" && "$bool_value" != "false" ]]; then
    echo "Boolean value must be true or false" >&2
    exit 1
  fi
}

unsupported_parent_name() {
  echo "Nested reminder write operations require parent_id; parent_name is read-only" >&2
  exit 1
}

detach_subtask_to_top_level() {
  local reminder_json="$1"
  local full_id="$2"
  local list_name name body due_date priority completed flagged urgent
  local direct_children_json direct_child_id replacement_json replacement_id
  local create_cmd=()

  list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
  name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.name')
  body=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.body // ""')
  due_date=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.due_date // ""')
  priority=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.priority')
  completed=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.completed')
  flagged=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.flagged')
  urgent=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.urgent')

  create_cmd=("$COMMAND_DIR/create.sh" "$list_name" "$name")
  [[ -n "$body" ]] && create_cmd+=("$body")
  [[ -n "$due_date" ]] && create_cmd+=(--due "$due_date")
  [[ "$priority" != "none" ]] && create_cmd+=(--priority "$priority")
  [[ "$flagged" == "true" ]] && create_cmd+=(--flagged)
  [[ "$urgent" == "true" ]] && create_cmd+=(--urgent)

  replacement_json=$("${create_cmd[@]}")
  replacement_id=$(printf '%s' "$replacement_json" | "$JQ_BIN" -r '.id')

  direct_children_json=$(run_reminderkit_helper children "$full_id" "$list_name")
  while IFS= read -r direct_child_id; do
    [[ -n "$direct_child_id" ]] || continue
    run_reminderkit_helper reparent "$direct_child_id" "$replacement_id" >/dev/null
  done < <(printf '%s' "$direct_children_json" | "$JQ_BIN" -r '.[].id')

  if [[ "$completed" == "true" ]]; then
    "$COMMAND_DIR/complete.sh" --id "$replacement_id" >/dev/null
  fi

  "$COMMAND_DIR/delete.sh" --id "$full_id" >/dev/null
  "$COMMAND_DIR/get.sh" --id "$replacement_id"
}

if raw=$(try_remindctl_show_all_json); then
  resolved=$(resolve_reminder_id "$id_arg" <<< "$raw")
  prop_key="${prop//-/_}"
  reminder_json=$(get_single_reminder_match_json "$id_arg" <<< "$raw" | normalize_single_reminder_json | augment_reminders_json)
  list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
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
    flagged)
      bool_value=$(normalize_bool_value "$value")
      ensure_boolean_value "$bool_value"
      run_reminderkit_helper set-flagged "$resolved" "$bool_value" >/dev/null
      "$COMMAND_DIR/get.sh" --id "$resolved"
      exit 0
      ;;
    urgent)
      bool_value=$(normalize_bool_value "$value")
      ensure_boolean_value "$bool_value"
      run_reminderkit_helper set-urgent "$resolved" "$bool_value" >/dev/null
      "$COMMAND_DIR/get.sh" --id "$resolved"
      exit 0
      ;;
    parent_id)
      if [[ "$value" == "missing" ]]; then
        detach_subtask_to_top_level "$reminder_json" "$resolved"
        exit 0
      fi
      resolved_parent_id=$(resolve_reminder_id "$value" <<< "$raw")
      run_reminderkit_helper reparent "$resolved" "$resolved_parent_id" >/dev/null
      "$COMMAND_DIR/get.sh" --id "$resolved"
      exit 0
      ;;
    parent_name)
      unsupported_parent_name
      exit 1
      ;;
    *) echo "Unsupported property: $prop_key" >&2; exit 1 ;;
  esac
  if out=$(try_run_remindctl_json "${cmd[@]}"); then
    printf '%s' "$out" | normalize_single_reminder_json | augment_reminders_json
    exit 0
  fi
fi

reminder_json=$(load_reminder_by_id_or_error "$id_arg")
list_name=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.list')
full_id=$(printf '%s' "$reminder_json" | "$JQ_BIN" -r '.id')
prop_key="${prop//-/_}"
case "$prop_key" in
  flagged)
    bool_value=$(normalize_bool_value "$value")
    ensure_boolean_value "$bool_value"
    run_reminderkit_helper set-flagged "$full_id" "$bool_value" >/dev/null
    ;;
  urgent)
    bool_value=$(normalize_bool_value "$value")
    ensure_boolean_value "$bool_value"
    run_reminderkit_helper set-urgent "$full_id" "$bool_value" >/dev/null
    ;;
  parent_id)
    if [[ "$value" == "missing" ]]; then
      detach_subtask_to_top_level "$reminder_json" "$full_id"
      exit 0
    fi
    resolved_parent_id=$(resolve_full_reminder_id_or_error "$value")
    run_reminderkit_helper reparent "$full_id" "$resolved_parent_id" >/dev/null
    ;;
  parent_name)
    unsupported_parent_name
    ;;
  *)
    run_reminder_applescript edit-by-id.applescript "$list_name" "$full_id" "$prop" "$value" >/dev/null
    ;;
esac
run_reminder_applescript get-reminder-by-id.applescript "$full_id" | augment_reminders_json
