#!/usr/bin/env bash

REMINDCTL_BIN="${REMINDCTL_BIN:-}"
JQ_BIN="${JQ_BIN:-}"
SCRIPT_DIR="${SCRIPT_DIR:-}"
REPO_ROOT="${REPO_ROOT:-}"
REMINDER_OSA_DIR="${REMINDER_OSA_DIR:-}"
REMINDER_NORMALIZE_JQ="${REMINDER_NORMALIZE_JQ:-}"
REMINDERKIT_HELPER_SRC="${REMINDERKIT_HELPER_SRC:-}"
REMINDERKIT_HELPER_BIN="${REMINDERKIT_HELPER_BIN:-}"
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -n "$SCRIPT_DIR" ]] || SCRIPT_DIR="$(cd "$HELPER_DIR/.." && pwd)"
[[ -n "$REPO_ROOT" ]] || REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
[[ -n "$REMINDER_OSA_DIR" ]] || REMINDER_OSA_DIR="$REPO_ROOT/scripts/applescripts/reminder"
[[ -n "$REMINDER_NORMALIZE_JQ" ]] || REMINDER_NORMALIZE_JQ="$SCRIPT_DIR/reminder_normalize.jq"
[[ -n "$REMINDERKIT_HELPER_SRC" ]] || REMINDERKIT_HELPER_SRC="$REPO_ROOT/scripts/tools/reminderkit_helper.m"
[[ -n "$REMINDERKIT_HELPER_BIN" ]] || REMINDERKIT_HELPER_BIN="/tmp/macos-reminders-skill-reminderkit-helper"

if [[ -z "$REMINDCTL_BIN" ]]; then
  if REMINDCTL_BIN="$(command -v remindctl 2>/dev/null)"; then
    :
  elif [[ -x "/opt/homebrew/bin/remindctl" ]]; then
    REMINDCTL_BIN="/opt/homebrew/bin/remindctl"
  else
    REMINDCTL_BIN=""
  fi
fi

if [[ -z "$JQ_BIN" ]]; then
  if JQ_BIN="$(command -v jq 2>/dev/null)"; then
    :
  elif [[ -x "/opt/homebrew/bin/jq" ]]; then
    JQ_BIN="/opt/homebrew/bin/jq"
  else
    JQ_BIN=""
  fi
fi

ensure_reminderkit_helper() {
  [[ -f "$REMINDERKIT_HELPER_SRC" ]] || { echo "ReminderKit helper source is missing" >&2; exit 1; }

  if [[ ! -x "$REMINDERKIT_HELPER_BIN" || "$REMINDERKIT_HELPER_SRC" -nt "$REMINDERKIT_HELPER_BIN" ]]; then
    /usr/bin/clang -framework Foundation -o "$REMINDERKIT_HELPER_BIN" "$REMINDERKIT_HELPER_SRC" || {
      echo "Failed to compile ReminderKit helper" >&2
      exit 1
    }
  fi
}

run_reminderkit_helper() {
  ensure_reminderkit_helper
  "$REMINDERKIT_HELPER_BIN" "$@"
}

try_run_remindctl_json() {
  local raw

  [[ -n "$REMINDCTL_BIN" ]] || return 1
  raw=$("$REMINDCTL_BIN" "$@" --json --no-color --no-input 2>/dev/null) || return 1
  printf '%s' "$raw"
}

run_remindctl_json() {
  local raw

  raw=$(try_run_remindctl_json "$@") || {
    echo "remindctl failed" >&2
    exit 1
  }
  printf '%s' "$raw"
}

remindctl_show_all_json() {
  run_remindctl_json show all
}

try_remindctl_show_all_json() {
  try_run_remindctl_json show all
}

remindctl_list_json() {
  run_remindctl_json list "$1"
}

try_remindctl_list_json() {
  try_run_remindctl_json list "$1"
}

remindctl_all_or_list_json() {
  local list_name="${1:-}"

  if [[ -n "$list_name" ]]; then
    remindctl_list_json "$list_name"
  else
    remindctl_show_all_json
  fi
}

try_remindctl_all_or_list_json() {
  local list_name="${1:-}"

  if [[ -n "$list_name" ]]; then
    try_remindctl_list_json "$list_name"
  else
    try_remindctl_show_all_json
  fi
}

normalize_reminders_json() {
  "$JQ_BIN" -f "$REMINDER_NORMALIZE_JQ"
}

normalize_single_reminder_json() {
  "$JQ_BIN" 'if type == "array" then .[0] else . end' | "$JQ_BIN" -s . | normalize_reminders_json | "$JQ_BIN" -c '.[0]'
}

reminder_metadata_json() {
  local metadata_json
  local id_lines
  local args=()

  id_lines=$(cat)
  if [[ -n "$id_lines" ]]; then
    while IFS= read -r reminder_id; do
      [[ -n "$reminder_id" ]] || continue
      args+=("$reminder_id")
    done <<< "$id_lines"
  fi

  if [[ "${#args[@]}" -gt 0 ]]; then
    metadata_json=$(run_reminderkit_helper metadata "${args[@]}")
  else
    metadata_json='[]'
  fi
  printf '%s' "$metadata_json"
}

augment_reminders_json() {
  local payload_json
  local metadata_json
  local id_lines

  payload_json=$(cat)
  id_lines=$(printf '%s' "$payload_json" | "$JQ_BIN" -r '
    [
      if type == "array" then
        .[]
      elif type == "object" and (.id? != null) then
        .
      else
        empty
      end
      | select(.id != null)
      | .id
    ]
    | unique
    | .[]
  ')
  metadata_json=$(printf '%s' "$id_lines" | reminder_metadata_json)

  printf '%s' "$payload_json" | "$JQ_BIN" --argjson meta "$metadata_json" '
    def enrich($item; $index):
      ($index[$item.id] // {}) as $extra
      | $item + {
          flagged: ($extra.flagged // false),
          urgent: ($extra.urgent // false),
          parent_id: ($extra.parent_id // null),
          parent_name: ($extra.parent_name // null)
        };
    INDEX($meta[]; .id) as $index
    | if type == "array" then
        [ .[] | enrich(.; $index) ]
      elif type == "object" and (.id? != null) and (.name? != null) and (.list? != null) then
        enrich(.; $index)
      else
        .
      end
  '
}

find_reminder_matches_json() {
  local id_arg="$1"

  "$JQ_BIN" -c --arg id "$id_arg" '[.[] | select((.id | ascii_downcase) | startswith(($id | ascii_downcase)))]'
}

get_single_reminder_match_json() {
  local id_arg="$1"
  local matches
  local count

  matches=$(find_reminder_matches_json "$id_arg")
  count=$(printf '%s' "$matches" | "$JQ_BIN" 'length')

  if [[ "$count" -eq 0 ]]; then
    echo "Reminder not found for id: $id_arg" >&2
    exit 1
  fi

  if [[ "$count" -gt 1 ]]; then
    echo "Reminder id is ambiguous: $id_arg" >&2
    exit 1
  fi

  printf '%s' "$matches" | "$JQ_BIN" -c '.[0]'
}

resolve_reminder_id() {
  local id_arg="$1"
  local resolved

  resolved=$(find_reminder_matches_json "$id_arg" | "$JQ_BIN" -r 'if length == 0 then "NOT_FOUND" elif length > 1 then "AMBIGUOUS" else .[0].id end')

  if [[ "$resolved" == "NOT_FOUND" ]]; then
    echo "Reminder not found for id: $id_arg" >&2
    exit 1
  fi

  if [[ "$resolved" == "AMBIGUOUS" ]]; then
    echo "Reminder id is ambiguous: $id_arg" >&2
    exit 1
  fi

  printf '%s' "$resolved"
}

run_reminder_applescript() {
  local script_name="$1"
  shift

  /usr/bin/osascript "$REMINDER_OSA_DIR/$script_name" "$@"
}

exec_reminder_applescript() {
  local script_name="$1"
  shift

  exec /usr/bin/osascript "$REMINDER_OSA_DIR/$script_name" "$@"
}

exec_reminder_applescript_optional_last_arg() {
  local script_name="$1"
  local optional_arg="${2:-}"

  shift 2 || true

  if [[ -n "$optional_arg" ]]; then
    exec_reminder_applescript "$script_name" "$@" "$optional_arg"
  else
    exec_reminder_applescript "$script_name" "$@"
  fi
}

load_reminder_by_id_or_error() {
  local id_arg="$1"
  local reminder_json

  reminder_json=$(run_reminderkit_helper get "$id_arg") || {
    echo "Reminder not found for id: $id_arg" >&2
    exit 1
  }

  printf '%s' "$reminder_json"
}

resolve_full_reminder_id_or_error() {
  local id_arg="$1"
  local raw

  if raw=$(try_remindctl_show_all_json); then
    resolve_reminder_id "$id_arg" <<< "$raw"
    return
  fi

  load_reminder_by_id_or_error "$id_arg" | "$JQ_BIN" -r '.id'
}
