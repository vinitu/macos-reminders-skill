# macOS Reminders Skill

This repo stores a Codex skill for Apple Reminders.app on macOS.

The public interface is `src/commands`.
`src/applescripts` stores internal AppleScript backends and dictionary-aligned coverage.

## Installation

```bash
npx skills add vinitu/macos-reminders-skill
```

Or with [skills.sh](https://skills.sh):

```bash
skills.sh add vinitu/macos-reminders-skill
```

## Public Interface

Run skill actions with:

```bash
src/commands/<entity>/<action>.sh [args...]
```

Output rules:

- Default output is human-readable text.
- `--json` returns the normalized machine-readable contract.
- `--plain` is not supported.
- `--format=plain|json` is not supported.

## Backend Map

- `src/commands/account/*` -> AppleScript in `src/applescripts/account/*`
- `src/commands/list/*` -> AppleScript in `src/applescripts/list/*`
- `src/commands/reminder/*` -> `remindctl`

`src/applescripts` is internal. Do not call it directly from the skill instructions.

## Dependencies

- macOS Reminders.app
- `remindctl` and `jq` for all public reminder commands

Check reminder access with:

```bash
remindctl status
```

A clean macOS install does not include `remindctl`.

## Repo Layout

- `AGENTS.md` - repo rules for future agents.
- `SKILL.md` - the main skill workflow and command reference.
- `Makefile` - helper commands for dictionary dump, compile, and tests.
- `src/commands/` - public shell command interface.
- `src/applescripts/` - internal AppleScript backends in `<entity>/<action>.applescript` format.
- `tests/` - live integration checks.

## Command Surface

Account:

- `src/commands/account/list.sh`
- `src/commands/account/get.sh`
- `src/commands/account/search.sh`
- `src/commands/account/show.sh`
- `src/commands/account/default-account.sh`
- `src/commands/account/default-list.sh`

List:

- `src/commands/list/list.sh`
- `src/commands/list/create.sh`
- `src/commands/list/show.sh`
- `src/commands/list/edit.sh`
- `src/commands/list/delete.sh`
- `src/commands/list/search.sh`
- `src/commands/list/get.sh`
- `src/commands/list/exists.sh`

Reminder:

- `src/commands/reminder/list.sh`
- `src/commands/reminder/count.sh`
- `src/commands/reminder/today.sh`
- `src/commands/reminder/overdue.sh`
- `src/commands/reminder/upcoming.sh`
- `src/commands/reminder/due-before.sh`
- `src/commands/reminder/due-range.sh`
- `src/commands/reminder/today-or-overdue.sh`
- `src/commands/reminder/create.sh`
- `src/commands/reminder/get.sh`
- `src/commands/reminder/get-by-id.sh`
- `src/commands/reminder/edit.sh`
- `src/commands/reminder/edit-by-id.sh`
- `src/commands/reminder/delete.sh`
- `src/commands/reminder/delete-by-id.sh`
- `src/commands/reminder/complete.sh`
- `src/commands/reminder/move.sh`
- `src/commands/reminder/move-by-id.sh`
- `src/commands/reminder/exists.sh`
- `src/commands/reminder/search.sh`

Not published:

- `src/commands/reminder/show.sh`

## Examples

```bash
src/commands/account/list.sh --json
src/commands/account/default-list.sh
src/commands/list/create.sh "Errands" --json
src/commands/list/get.sh "Inbox" id --json
src/commands/reminder/today.sh --json
src/commands/reminder/create.sh "Inbox" "Buy milk" "2 liters" --priority high --json
src/commands/reminder/get.sh --id "REMINDER-ID" body --json
src/commands/reminder/edit.sh --id "REMINDER-ID" body "3 liters"
src/commands/reminder/complete.sh --id "REMINDER-ID"
src/commands/reminder/delete.sh --id "REMINDER-ID" --json
```

## Reminder Contract

- Public reminder identity is the `remindctl` reminder ID or unique prefix.
- Canonical reminder read and write commands use `--id`.
- Public reminder fields:
  - `id`
  - `name`
  - `list`
  - `body`
  - `completed`
  - `priority`
  - `due_date`
- Public priority values:
  - `none`
  - `low`
  - `medium`
  - `high`

These reminder features are not part of the public interface:

- `show`
- `flagged`
- `container`
- `creation_date`
- `modification_date`
- `completion_date`
- `allday_due_date`
- `remind_me_date`
- AppleScript reminder IDs

## Validation

```bash
make compile
make test
```
