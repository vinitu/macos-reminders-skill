#!/usr/bin/env bash
set -euo pipefail

prefix="CodexTest_$(date +%s)"
source_list="${prefix}_src"
target_list="${prefix}_dst"
reminder_name="${prefix}_reminder"

cleanup() {
  osascript <<APPLESCRIPT >/dev/null 2>&1 || true
tell application "Reminders"
    if (exists list "$source_list") then delete list "$source_list"
    if (exists list "$target_list") then delete list "$target_list"
end tell
APPLESCRIPT
}
trap cleanup EXIT

osascript -e 'tell application "Reminders" to version' >/dev/null

osascript scripts/list/create.applescript "$source_list" >/dev/null
osascript scripts/list/create.applescript "$target_list" >/dev/null
osascript scripts/reminder/create.applescript "$source_list" "$reminder_name" "Smoke body" >/dev/null
osascript scripts/reminder/edit.applescript "$source_list" "$reminder_name" priority 5 >/dev/null
osascript scripts/reminder/edit.applescript "$source_list" "$reminder_name" flagged true >/dev/null

created_state="$(osascript scripts/reminder/exists.applescript "$source_list" "$reminder_name")"
if [[ "$created_state" != "true" ]]; then
  printf 'smoke_reminders: reminder was not created\n' >&2
  exit 1
fi

osascript scripts/reminder/edit.applescript "$source_list" "$reminder_name" body "Updated body" >/dev/null
osascript scripts/reminder/edit.applescript "$source_list" "$reminder_name" priority 1 >/dev/null
osascript scripts/reminder/edit.applescript "$source_list" "$reminder_name" flagged false >/dev/null

updated_state="$(printf '%s|%s|%s' \
  "$(osascript scripts/reminder/get.applescript "$source_list" "$reminder_name" body)" \
  "$(osascript scripts/reminder/get.applescript "$source_list" "$reminder_name" priority)" \
  "$(osascript scripts/reminder/get.applescript "$source_list" "$reminder_name" flagged)")"
if [[ "$updated_state" != "Updated body|1|false" ]]; then
  printf 'smoke_reminders: unexpected reminder state: %s\n' "$updated_state" >&2
  exit 1
fi

source_count="$(osascript scripts/reminder/count.applescript "$source_list")"
if [[ "$source_count" -lt 1 ]]; then
  printf 'smoke_reminders: source list count is too low: %s\n' "$source_count" >&2
  exit 1
fi

found_in_incomplete_search="$(osascript scripts/reminder/search.applescript incomplete "$source_list")"
if [[ "$found_in_incomplete_search" != *"$reminder_name"* ]]; then
  printf 'smoke_reminders: reminder not found in incomplete search\n' >&2
  exit 1
fi

osascript scripts/reminder/move.applescript "$source_list" "$reminder_name" "$target_list" >/dev/null

exists_in_source="$(osascript scripts/reminder/exists.applescript "$source_list" "$reminder_name")"
exists_in_target="$(osascript scripts/reminder/exists.applescript "$target_list" "$reminder_name")"

if [[ "$exists_in_source" != "false" ]]; then
  printf 'smoke_reminders: reminder still exists in source list\n' >&2
  exit 1
fi

if [[ "$exists_in_target" != "true" ]]; then
  printf 'smoke_reminders: reminder was not moved to target list\n' >&2
  exit 1
fi

osascript scripts/reminder/complete.applescript "$target_list" "$reminder_name" >/dev/null

completed_state="$(osascript scripts/reminder/get.applescript "$target_list" "$reminder_name" completed)"
if [[ "$completed_state" != "true" ]]; then
  printf 'smoke_reminders: reminder was not completed\n' >&2
  exit 1
fi

found_in_completed_search="$(osascript scripts/reminder/search.applescript id "$(osascript scripts/reminder/get.applescript "$target_list" "$reminder_name" id)")"
if [[ "$found_in_completed_search" != *"$reminder_name"* ]]; then
  printf 'smoke_reminders: reminder not found by id search\n' >&2
  exit 1
fi

osascript scripts/reminder/delete.applescript "$target_list" "$reminder_name" >/dev/null

exists_after_delete="$(osascript scripts/reminder/exists.applescript "$target_list" "$reminder_name")"
if [[ "$exists_after_delete" != "false" ]]; then
  printf 'smoke_reminders: reminder still exists after delete\n' >&2
  exit 1
fi

printf 'smoke_reminders: ok\n'
