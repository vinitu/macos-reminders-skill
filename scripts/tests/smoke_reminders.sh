#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=src/commands/reminder/_lib/common.sh
source "$REPO_ROOT/src/commands/reminder/_lib/common.sh"

prefix="CodexTest_$(date +%s)"
source_list="${prefix}_src"
target_list="${prefix}_dst"
filter_list="${prefix}_filters"
extra_list="${prefix}_extra"
reminder_name="${prefix}_reminder"
wrapper_reminder_name="${prefix}_wrapper"
today_reminder="${prefix}_today"
today_completed_reminder="${prefix}_today_completed"
overdue_reminder="${prefix}_overdue"
upcoming_reminder="${prefix}_upcoming"
future_reminder="${prefix}_future"
tomorrow_early_reminder="${prefix}_tomorrow_early"

date_text() {
  local day_offset="$1"
  local hour_value="$2"
  local minute_value="$3"
  local day_modifier

  if (( day_offset >= 0 )); then
    day_modifier="+${day_offset}d"
  else
    day_modifier="${day_offset}d"
  fi

  /bin/date -v"${day_modifier}" -v0H -v0M -v0S -v"${hour_value}"H -v"${minute_value}"M +"%Y-%m-%d %H:%M"
}

json_matches() {
  local payload="$1"
  local expr="$2"

  PAYLOAD="$payload" EXPR="$expr" /usr/bin/osascript -l JavaScript <<'JXA' >/dev/null
ObjC.import("Foundation");
ObjC.import("stdlib");

const env = $.NSProcessInfo.processInfo.environment;
const payload = JSON.parse(ObjC.unwrap(env.objectForKey("PAYLOAD")));
const expr = ObjC.unwrap(env.objectForKey("EXPR"));

if (!eval(expr)) {
  $.exit(1);
}
JXA
}

json_assert() {
  local payload="$1"
  local expr="$2"
  local message="$3"

  if ! json_matches "$payload" "$expr"; then
    printf 'smoke_reminders: %s\n' "$message" >&2
    exit 1
  fi
}

json_get() {
  local payload="$1"
  local expr="$2"

  PAYLOAD="$payload" EXPR="$expr" /usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import("Foundation");

const env = $.NSProcessInfo.processInfo.environment;
const payload = JSON.parse(ObjC.unwrap(env.objectForKey("PAYLOAD")));
const expr = ObjC.unwrap(env.objectForKey("EXPR"));
const value = eval(expr);

if (value === null || typeof value === "undefined") {
  "";
} else if (typeof value === "string") {
  value;
} else {
  JSON.stringify(value);
}
JXA
}

wait_for_list() {
  local list_name="$1"
  local attempt=0

  while [[ "$attempt" -lt 20 ]]; do
    if json_matches "$("$REMINDCTL_BIN" list --json --no-color --no-input)" 'payload.some(item => item.title === "'"$list_name"'")'; then
      return
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  printf 'smoke_reminders: remindctl did not observe list: %s\n' "$list_name" >&2
  exit 1
}

cleanup() {
  osascript <<APPLESCRIPT >/dev/null 2>&1 || true
tell application "Reminders"
    if (exists list "$source_list") then delete list "$source_list"
    if (exists list "$target_list") then delete list "$target_list"
    if (exists list "$filter_list") then delete list "$filter_list"
    if (exists list "$extra_list") then delete list "$extra_list"
end tell
APPLESCRIPT
}
trap cleanup EXIT

osascript -e 'tell application "Reminders" to version' >/dev/null
[[ -n "$REMINDCTL_BIN" ]] || { printf 'smoke_reminders: remindctl is not available\n' >&2; exit 1; }
status_output="$("$REMINDCTL_BIN" status)"
if [[ "$status_output" != *"access"* && "$status_output" != *"Access"* ]]; then
  printf 'smoke_reminders: remindctl status is unexpected: %s\n' "$status_output" >&2
  exit 1
fi

while IFS= read -r file; do
  if [[ ! -x "$file" ]]; then
    printf 'smoke_reminders: command is not executable: %s\n' "$file" >&2
    exit 1
  fi
done < <(find src/commands -type f -name '*.sh' ! -path '*/_lib/*' | sort)

if src/commands/account/list.sh --plain >/dev/null 2>&1; then
  printf 'smoke_reminders: --plain should fail\n' >&2
  exit 1
fi

if src/commands/reminder/today.sh --format=json >/dev/null 2>&1; then
  printf 'smoke_reminders: --format=json should fail\n' >&2
  exit 1
fi

default_account_json="$(src/commands/account/default-account.sh)"
default_account="$(json_get "$default_account_json" 'payload.name')"
direct_default_account="$(osascript -e 'tell application "Reminders" to name of default account')"
if [[ "$default_account" != "$direct_default_account" ]]; then
  printf 'smoke_reminders: unexpected default account: %s\n' "$default_account" >&2
  exit 1
fi

default_list_json="$(src/commands/account/default-list.sh)"
default_list="$(json_get "$default_list_json" 'payload.name')"
direct_default_list="$(osascript -e 'tell application "Reminders" to name of default list')"
if [[ "$default_list" != "$direct_default_list" ]]; then
  printf 'smoke_reminders: unexpected default list: %s\n' "$default_list" >&2
  exit 1
fi

account_get_json="$(src/commands/account/get.sh "$default_account" id)"
json_assert "$account_get_json" 'payload.name === "'"$default_account"'" && payload.property === "id" && payload.value !== ""' "account get json is invalid"

account_list_text="$(src/commands/account/list.sh)"
if [[ "$account_list_text" != *"$default_account"* ]]; then
  printf 'smoke_reminders: account list is missing default account\n' >&2
  exit 1
fi

account_search_text="$(src/commands/account/search.sh exact-name "$default_account")"
if [[ "$account_search_text" != *"$default_account"* ]]; then
  printf 'smoke_reminders: account search exact-name failed\n' >&2
  exit 1
fi

src_create_json="$(src/commands/list/create.sh "$source_list")"
src_create_state="$(json_get "$src_create_json" 'payload.state')"
if [[ "$src_create_state" != "created" && "$src_create_state" != "existing" ]]; then
  printf 'smoke_reminders: source list create returned unexpected state: %s\n' "$src_create_state" >&2
  exit 1
fi

src/commands/list/create.sh "$target_list" >/dev/null
src/commands/list/create.sh "$filter_list" >/dev/null
src/commands/list/create.sh "$extra_list" >/dev/null
wait_for_list "$source_list"
wait_for_list "$target_list"
wait_for_list "$filter_list"

list_exists_json="$(src/commands/list/exists.sh "$source_list")"
list_exists_text="$(json_get "$list_exists_json" 'payload.exists')"
if [[ "$list_exists_text" != "true" ]]; then
  printf 'smoke_reminders: list exists returned unexpected value: %s\n' "$list_exists_text" >&2
  exit 1
fi

src/commands/list/edit.sh "$extra_list" name "${extra_list}_renamed" >/dev/null
edited_exists="$(json_get "$(src/commands/list/exists.sh "${extra_list}_renamed")" 'payload.exists')"
if [[ "$edited_exists" != "true" ]]; then
  printf 'smoke_reminders: list edit did not rename list\n' >&2
  exit 1
fi

list_delete_json="$(src/commands/list/delete.sh "${extra_list}_renamed")"
json_assert "$list_delete_json" 'payload.deleted === true && payload.name === "'"${extra_list}_renamed"'"' "list delete json is invalid"

create_json="$(src/commands/reminder/create.sh "$source_list" "$reminder_name" "Smoke body" --priority high)"
reminder_id="$(json_get "$create_json" 'payload.id')"
json_assert "$create_json" 'payload != null && payload.id !== null && payload.name === "'"$reminder_name"'" && payload.list' "reminder create json is invalid"

wrapper_create_json="$(src/commands/reminder/create.sh "$source_list" "$wrapper_reminder_name" "Wrapper body" --priority low)"
wrapper_id="$(json_get "$wrapper_create_json" 'payload.id')"

reminder_list_json="$(src/commands/reminder/list.sh "$source_list")"
json_assert "$reminder_list_json" 'payload.some(item => item.id === "'"$reminder_id"'") && payload.some(item => item.id === "'"$wrapper_id"'")' "reminder list json is missing created reminders"

count_json="$(src/commands/reminder/count.sh "$source_list")"
source_count="$(json_get "$count_json" 'payload.count')"
if [[ "$source_count" != "2" ]]; then
  printf 'smoke_reminders: reminder count is unexpected: %s\n' "$source_count" >&2
  exit 1
fi
json_assert "$count_json" 'payload.count === 2 && payload.list === "'"$source_list"'"' "reminder count json is invalid"

get_body_json="$(src/commands/reminder/get.sh --id "$reminder_id" body)"
reminder_body="$(json_get "$get_body_json" 'payload.value')"
if [[ "$reminder_body" != "Smoke body" ]]; then
  printf 'smoke_reminders: reminder get body is unexpected: %s\n' "$reminder_body" >&2
  exit 1
fi
json_assert "$get_body_json" 'payload.id === "'"$reminder_id"'" && payload.property === "body" && payload.value === "Smoke body"' "reminder get json is invalid"

get_wrapper_json="$(src/commands/reminder/get-by-id.sh "$wrapper_id" body)"
wrapper_body="$(json_get "$get_wrapper_json" 'payload.value')"
if [[ "$wrapper_body" != "Wrapper body" ]]; then
  printf 'smoke_reminders: reminder get-by-id body is unexpected: %s\n' "$wrapper_body" >&2
  exit 1
fi

src/commands/reminder/edit.sh --id "$reminder_id" body "Updated body" >/dev/null
edited_body="$(json_get "$(src/commands/reminder/get.sh --id "$reminder_id" body)" 'payload.value')"
if [[ "$edited_body" != "Updated body" ]]; then
  printf 'smoke_reminders: reminder edit did not update body: %s\n' "$edited_body" >&2
  exit 1
fi

src/commands/reminder/edit-by-id.sh "$wrapper_id" priority medium >/dev/null
wrapper_priority="$(json_get "$(src/commands/reminder/get.sh --id "$wrapper_id" priority)" 'payload.value')"
if [[ "$wrapper_priority" != "medium" ]]; then
  printf 'smoke_reminders: reminder edit-by-id did not update priority: %s\n' "$wrapper_priority" >&2
  exit 1
fi

rescheduled_due="$(date_text 4 12 0)"
expected_rescheduled_date="${rescheduled_due:0:10}"
src/commands/reminder/reschedule.sh --id "$wrapper_id" "$rescheduled_due" >/dev/null
wrapper_due_date="$(json_get "$(src/commands/reminder/get.sh --id "$wrapper_id" due_date)" 'payload.value')"
if [[ "${wrapper_due_date:0:10}" != "$expected_rescheduled_date" ]]; then
  printf 'smoke_reminders: reminder reschedule did not update due date: %s\n' "$wrapper_due_date" >&2
  exit 1
fi

search_exact_json="$(src/commands/reminder/search.sh exact-name "$source_list" "$reminder_name")"
json_assert "$search_exact_json" 'payload.length === 1 && payload[0].id === "'"$reminder_id"'"' "reminder exact-name search failed"

search_incomplete_json="$(src/commands/reminder/search.sh incomplete "$source_list")"
json_assert "$search_incomplete_json" 'payload.length >= 2 && payload.some(item => item.name === "'"$reminder_name"'") && payload.some(item => item.name === "'"$wrapper_reminder_name"'")' "incomplete search is missing reminders"

src/commands/reminder/move.sh --id "$reminder_id" "$target_list" >/dev/null
moved_list="$(json_get "$(src/commands/reminder/get.sh --id "$reminder_id" list)" 'payload.value')"
if [[ "$moved_list" != "$target_list" ]]; then
  printf 'smoke_reminders: reminder move did not change list: %s\n' "$moved_list" >&2
  exit 1
fi

src/commands/reminder/move-by-id.sh "$wrapper_id" "$target_list" >/dev/null
wrapper_moved_list="$(json_get "$(src/commands/reminder/get.sh --id "$wrapper_id" list)" 'payload.value')"
if [[ "$wrapper_moved_list" != "$target_list" ]]; then
  printf 'smoke_reminders: reminder move-by-id did not change list: %s\n' "$wrapper_moved_list" >&2
  exit 1
fi

src/commands/reminder/complete.sh --id "$reminder_id" >/dev/null
completed_state="$(json_get "$(src/commands/reminder/get.sh --id "$reminder_id" completed)" 'payload.value')"
if [[ "$completed_state" != "true" ]]; then
  printf 'smoke_reminders: reminder complete did not update state: %s\n' "$completed_state" >&2
  exit 1
fi

exists_json="$(src/commands/reminder/exists.sh --id "$reminder_id")"
json_assert "$exists_json" 'payload.exists === true && payload.id === "'"$reminder_id"'"' "reminder exists json is invalid"

delete_json="$(src/commands/reminder/delete.sh --id "$reminder_id")"
json_assert "$delete_json" 'payload.deleted === true && payload.id === "'"$reminder_id"'"' "reminder delete json is invalid"

exists_after_delete="$(json_get "$(src/commands/reminder/exists.sh --id "$reminder_id")" 'payload.exists')"
if [[ "$exists_after_delete" != "false" ]]; then
  printf 'smoke_reminders: reminder still exists after delete\n' >&2
  exit 1
fi

delete_by_id_json="$(src/commands/reminder/delete-by-id.sh "$wrapper_id")"
json_assert "$delete_by_id_json" 'payload.deleted === true && payload.id === "'"$wrapper_id"'"' "reminder delete-by-id json is invalid"

wrapper_exists_after_delete="$(json_get "$(src/commands/reminder/exists.sh --id "$wrapper_id")" 'payload.exists')"
if [[ "$wrapper_exists_after_delete" != "false" ]]; then
  printf 'smoke_reminders: wrapper reminder still exists after delete\n' >&2
  exit 1
fi

today_due="$(date_text 0 12 0)"
today_start="$(date_text 0 0 0)"
overdue_due="$(date_text -1 12 0)"
upcoming_due="$(date_text 2 12 0)"
future_due="$(date_text 10 12 0)"
tomorrow_early_due="$(date_text 1 0 30)"
range_start="$(date_text 1 0 0)"
range_end="$(date_text 3 23 59)"

today_json="$(src/commands/reminder/create.sh "$filter_list" "$today_reminder" --due "$today_due" --priority high)"
today_id="$(json_get "$today_json" 'payload.id')"

today_completed_json="$(src/commands/reminder/create.sh "$filter_list" "$today_completed_reminder" --due "$today_due")"
today_completed_id="$(json_get "$today_completed_json" 'payload.id')"
src/commands/reminder/complete.sh --id "$today_completed_id" >/dev/null

overdue_json="$(src/commands/reminder/create.sh "$filter_list" "$overdue_reminder" --due "$overdue_due")"
overdue_id="$(json_get "$overdue_json" 'payload.id')"

upcoming_json="$(src/commands/reminder/create.sh "$filter_list" "$upcoming_reminder" --due "$upcoming_due" --priority medium)"
upcoming_id="$(json_get "$upcoming_json" 'payload.id')"

future_json="$(src/commands/reminder/create.sh "$filter_list" "$future_reminder" --due "$future_due")"
future_id="$(json_get "$future_json" 'payload.id')"

tomorrow_early_json="$(src/commands/reminder/create.sh "$filter_list" "$tomorrow_early_reminder" --due "$tomorrow_early_due")"
tomorrow_early_id="$(json_get "$tomorrow_early_json" 'payload.id')"

today_filter_json="$(src/commands/reminder/today.sh "$filter_list")"
json_assert "$today_filter_json" 'payload.length === 1 && payload[0].id === "'"$today_id"'"' "today filter is unexpected"
json_assert "$today_filter_json" '!payload.some(item => item.id === "'"$tomorrow_early_id"'")' "today filter included tomorrow boundary reminder"

overdue_filter_json="$(src/commands/reminder/overdue.sh "$filter_list")"
json_assert "$overdue_filter_json" 'payload.length === 1 && payload[0].id === "'"$overdue_id"'"' "overdue filter is unexpected"

upcoming_filter_json="$(src/commands/reminder/upcoming.sh 3 "$filter_list")"
json_assert "$upcoming_filter_json" 'payload.length === 1 && payload[0].id === "'"$upcoming_id"'"' "upcoming filter is unexpected"

due_before_json="$(src/commands/reminder/due-before.sh "$today_start" "$filter_list")"
json_assert "$due_before_json" 'payload.length === 1 && payload[0].id === "'"$overdue_id"'"' "due-before filter is unexpected"

due_range_json="$(src/commands/reminder/due-range.sh "$range_start" "$range_end" "$filter_list")"
json_assert "$due_range_json" 'payload.length === 1 && payload[0].id === "'"$upcoming_id"'"' "due-range filter is unexpected"

focus_json="$(src/commands/reminder/today-or-overdue.sh "$filter_list")"
json_assert "$focus_json" 'payload.map(item => item.id).sort().join(",") === ["'"$today_id"'","'"$overdue_id"'"].sort().join(",")' "today-or-overdue filter is unexpected"

search_priority_json="$(src/commands/reminder/search.sh priority high "$filter_list")"
json_assert "$search_priority_json" 'payload.length === 1 && payload[0].id === "'"$today_id"'"' "priority search is unexpected"

search_due_json="$(src/commands/reminder/search.sh has-due-date "$filter_list")"
json_assert "$search_due_json" 'payload.some(item => item.name === "'"$today_reminder"'") && payload.some(item => item.name === "'"$upcoming_reminder"'")' "has-due-date search is missing reminders"

search_text_json="$(src/commands/reminder/search.sh text "$future_reminder" "$filter_list")"
json_assert "$search_text_json" 'payload.length === 1 && payload[0].id === "'"$future_id"'"' "text search is unexpected"

printf 'smoke_reminders: ok\n'
