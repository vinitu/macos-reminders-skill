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

has_pattern() {
  local pattern="$1"
  local file="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -q "$pattern" "$file"
  else
    grep -q -- "$pattern" "$file"
  fi
}

has_pattern '<command name="show"' "$tmp_reminders"
has_pattern '<class name="account"' "$tmp_reminders"
has_pattern '<class name="list"' "$tmp_reminders"
has_pattern '<class name="reminder"' "$tmp_reminders"
has_pattern '<property name="default account"' "$tmp_reminders"
has_pattern '<property name="default list"' "$tmp_reminders"
has_pattern '<property name="due date"' "$tmp_reminders"
has_pattern '<property name="flagged"' "$tmp_reminders"
has_pattern '<property name="container"' "$tmp_reminders"

has_pattern '<command name="count"' "$tmp_standard"
has_pattern '<command name="delete"' "$tmp_standard"
has_pattern '<command name="duplicate"' "$tmp_standard"
has_pattern '<command name="exists"' "$tmp_standard"
has_pattern '<command name="make"' "$tmp_standard"
has_pattern '<command name="move"' "$tmp_standard"

printf 'dictionary_contract: ok\n'
