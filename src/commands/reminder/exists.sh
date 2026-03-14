#!/usr/bin/env bash
# Output: JSON {exists, id}.
# Requires: remindctl, jq. Without remindctl prints "not implemented yet" and exits 1.
# Example (found):
#   {
#     "exists": true,
#     "id": "..."
#   }
# Example (not found):
#   {
#     "exists": false,
#     "id": null
#   }
set -euo pipefail

[[ $# -lt 2 || "$1" != "--id" ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
[[ $# -gt 2 ]] && { echo "Usage: $(basename "$0") --id <id>" >&2; exit 1; }
id_arg="$2"

if ! command -v remindctl >/dev/null 2>&1; then
  echo "not implemented yet" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq required when using remindctl" >&2
  exit 1
fi

raw=$(remindctl show all --json --no-color --no-input) || { echo "remindctl failed" >&2; exit 1; }
matches=$(printf '%s' "$raw" | jq -c --arg id "$id_arg" '[.[] | select((.id | ascii_downcase) | startswith(($id | ascii_downcase)))]')
n=$(printf '%s' "$matches" | jq 'length')
if [[ "$n" -gt 1 ]]; then
  echo "Reminder id is ambiguous: $id_arg" >&2
  exit 1
fi
if [[ "$n" -eq 1 ]]; then
  full_id=$(printf '%s' "$matches" | jq -r '.[0].id')
  jq -n --arg id "$full_id" '{exists: true, id: $id}'
else
  jq -n '{exists: false, id: null}'
fi