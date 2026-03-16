#!/usr/bin/env bash
# Output: opens Reminders UI (no JSON).
# Requires: AppleScript backend.
# Example: (opens Reminders.app)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
exec /usr/bin/osascript "$REPO_ROOT/scripts/applescripts/reminder/show.applescript" "$@"
