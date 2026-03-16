#!/usr/bin/env bash

REMINDCTL_BIN="${REMINDCTL_BIN:-}"
JQ_BIN="${JQ_BIN:-}"
SCRIPT_DIR="${SCRIPT_DIR:-}"
REPO_ROOT="${REPO_ROOT:-}"
REMINDER_OSA_DIR="${REMINDER_OSA_DIR:-}"
REMINDER_NORMALIZE_JQ="${REMINDER_NORMALIZE_JQ:-}"
HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -n "$SCRIPT_DIR" ]] || SCRIPT_DIR="$(cd "$HELPER_DIR/.." && pwd)"
[[ -n "$REPO_ROOT" ]] || REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
[[ -n "$REMINDER_OSA_DIR" ]] || REMINDER_OSA_DIR="$REPO_ROOT/src/applescripts/reminder"
[[ -n "$REMINDER_NORMALIZE_JQ" ]] || REMINDER_NORMALIZE_JQ="$SCRIPT_DIR/reminder_normalize.jq"

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

run_remindctl_json() {
  local raw

  raw=$("$REMINDCTL_BIN" "$@" --json --no-color --no-input) || {
    echo "remindctl failed" >&2
    exit 1
  }
  printf '%s' "$raw"
}

remindctl_show_all_json() {
  run_remindctl_json show all
}

remindctl_list_json() {
  run_remindctl_json list "$1"
}

remindctl_all_or_list_json() {
  local list_name="${1:-}"

  if [[ -n "$list_name" ]]; then
    remindctl_list_json "$list_name"
  else
    remindctl_show_all_json
  fi
}

normalize_reminders_json() {
  "$JQ_BIN" -f "$REMINDER_NORMALIZE_JQ"
}

normalize_single_reminder_json() {
  "$JQ_BIN" 'if type == "array" then .[0] else . end' | "$JQ_BIN" -s . | normalize_reminders_json | "$JQ_BIN" -c '.[0]'
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

  reminder_json=$(run_reminder_applescript get-reminder-by-id.applescript "$id_arg") || {
    echo "Reminder not found for id: $id_arg" >&2
    exit 1
  }

  printf '%s' "$reminder_json"
}
