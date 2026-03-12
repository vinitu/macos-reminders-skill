#!/usr/bin/env bash
set -euo pipefail

tmp_reminders="$(mktemp)"
tmp_standard="$(mktemp)"
cleanup() {
  rm -f "$tmp_reminders" "$tmp_standard"
}
trap cleanup EXIT

make --no-print-directory dictionary-reminders >"$tmp_reminders"
make --no-print-directory dictionary-standard >"$tmp_standard"

rg -q '<command name="show"' "$tmp_reminders"
rg -q '<class name="account"' "$tmp_reminders"
rg -q '<class name="list"' "$tmp_reminders"
rg -q '<class name="reminder"' "$tmp_reminders"
rg -q '<property name="default list"' "$tmp_reminders"
rg -q '<property name="due date"' "$tmp_reminders"
rg -q '<property name="flagged"' "$tmp_reminders"

rg -q '<command name="count"' "$tmp_standard"
rg -q '<command name="delete"' "$tmp_standard"
rg -q '<command name="duplicate"' "$tmp_standard"
rg -q '<command name="exists"' "$tmp_standard"
rg -q '<command name="make"' "$tmp_standard"
rg -q '<command name="move"' "$tmp_standard"

printf 'dictionary_contract: ok\n'
