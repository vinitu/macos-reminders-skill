# macOS Reminders AppleScript Skill

This repo stores a Codex skill for Apple Reminders.app on macOS.

It documents the live AppleScript surface of Reminders.app and includes runnable scripts.

## Installation

```bash
npx skills add vinitu/macos-reminders-skill
```

Or with [skills.sh](https://skills.sh):

```bash
skills.sh add vinitu/macos-reminders-skill
```

## Scope

- Account discovery, account lookup, and default account or list lookup.
- Full dictionary-defined command inventory from Reminders.app plus the AppleScript verbs needed to use it.
- CRUD for lists and reminders.
- Search and filtering with AppleScript object specifiers.
- Safe examples for property updates, moving reminders, UI reveal, and JSON output for read-heavy scripts.

## Tested Base

- macOS `26.3.1`
- Reminders `7.0`

## Repo Layout

- `AGENTS.md` - repo rules for future agents.
- `SKILL.md` - the full skill and full AppleScript reference.
- `Makefile` - helper commands for dictionary dump, compile, and tests.
- `scripts/account/` - account AppleScript entrypoints.
- `scripts/list/` - list AppleScript entrypoints.
- `scripts/reminder/` - reminder AppleScript entrypoints.
- `tests/` - live checks for the current Reminders.app behavior.

## Command Surface

Account commands:

- `scripts/account/list.applescript`
- `scripts/account/get.applescript`
- `scripts/account/search.applescript`
- `scripts/account/show.applescript`
- `scripts/account/default-account.applescript`
- `scripts/account/default-list.applescript`

List commands:

- `scripts/list/list.applescript`
- `scripts/list/create.applescript`
- `scripts/list/show.applescript`
- `scripts/list/edit.applescript`
- `scripts/list/delete.applescript`
- `scripts/list/search.applescript`
- `scripts/list/get.applescript`
- `scripts/list/exists.applescript`

Reminder commands:

- `scripts/reminder/list.applescript`
- `scripts/reminder/create.applescript`
- `scripts/reminder/show.applescript`
- `scripts/reminder/edit.applescript`
- `scripts/reminder/edit-by-id.applescript`
- `scripts/reminder/delete.applescript`
- `scripts/reminder/delete-by-id.applescript`
- `scripts/reminder/search.applescript`
- `scripts/reminder/get.applescript`
- `scripts/reminder/get-by-id.applescript`
- `scripts/reminder/exists.applescript`
- `scripts/reminder/count.applescript`
- `scripts/reminder/today.applescript`
- `scripts/reminder/overdue.applescript`
- `scripts/reminder/upcoming.applescript`
- `scripts/reminder/due-before.applescript`
- `scripts/reminder/due-range.applescript`
- `scripts/reminder/today-or-overdue.applescript`
- `scripts/reminder/complete.applescript`
- `scripts/reminder/move.applescript`
- `scripts/reminder/move-by-id.applescript`

Dictionary-level notes:

- Reminders suite: `show`
- Standard suite: `open`, `close`, `save`, `print`, `quit`, `count`, `delete`, `duplicate`, `exists`, `make`, `move`
- AppleScript language verbs used with the dictionary: `get`, `set`, `tell`, `whose`

See `SKILL.md` for the full matrix, notes, and examples.

## How To Use

Run skill actions with:

```bash
osascript scripts/<entity>/<action>.applescript [args...]
```

Examples:

```bash
osascript scripts/account/list.applescript
osascript scripts/account/get.applescript "iCloud" id
osascript scripts/account/default-list.applescript
osascript scripts/list/list.applescript
osascript scripts/list/list.applescript "iCloud" --format=json
osascript scripts/list/create.applescript "Errands"
osascript scripts/reminder/create.applescript "Inbox" "Buy milk" "2 liters"
osascript scripts/reminder/count.applescript "Inbox" --format=json
osascript scripts/reminder/search.applescript incomplete "Inbox"
```

For the full command set and arguments, use `SKILL.md`.

## Important Limits

- `show` opens or focuses the UI. Do not use account, list, or reminder `show` scripts in headless smoke tests.
- `duplicate` is declared by the standard suite, but live tests on Reminders `7.0` failed for reminders with AppleScript error `-1717`.
- `open`, `close`, `save`, `print`, and `quit` are standard app or window actions. They are documented by the dictionary, but this repo does not publish wrapper scripts for them.
- The dictionary says a reminder `container` can be a reminder, but the class does not expose `reminders` as an element of `reminder`, so subtask creation is not available as a published AppleScript operation.
