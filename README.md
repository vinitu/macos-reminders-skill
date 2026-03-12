# Apple Reminders AppleScript Skill

This repo stores a Codex skill for Apple Reminders.app on macOS.

It documents the live AppleScript surface of Reminders.app and includes runnable scripts.

## Installation

Install with `skills.sh`:

```bash
skills.sh add vinitu/apple-reminders-skill
```

If you use the npm installer instead:

```bash
npx skills add vinitu/apple-reminders-skill
```

## Scope

- Full dictionary-defined command inventory from Reminders.app plus the AppleScript verbs needed to use it.
- CRUD for lists and reminders.
- Search and filtering with AppleScript object specifiers.
- Safe examples for property updates, moving reminders, and UI reveal.

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

The command surface is split into three parts:

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
osascript scripts/list/list.applescript
osascript scripts/list/create.applescript "Errands"
osascript scripts/reminder/create.applescript "Inbox" "Buy milk" "2 liters"
osascript scripts/reminder/search.applescript incomplete "Inbox"
```

For the full command set and arguments, use `SKILL.md`.

## Important Limits

- `show` opens or focuses the UI. Do not use it in headless smoke tests.
- `duplicate` is declared by the standard suite, but live tests on Reminders `7.0` failed for reminders with AppleScript error `-1717`.
- The dictionary says a reminder `container` can be a reminder, but the class does not expose `reminders` as an element of `reminder`, so subtask creation is not available as a published AppleScript operation.
