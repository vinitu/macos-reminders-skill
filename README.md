# macOS Reminders Skill

This repo stores an AI agent skill for Apple Reminders.app on macOS.

The public interface is `scripts/commands`.
`scripts/applescripts` stores internal AppleScript backends and dictionary-aligned coverage.

## Installation

```bash
npx skills add vinitu/apple-reminders-skill
```

Or with [skills.sh](https://skills.sh):

```bash
skills.sh add vinitu/apple-reminders-skill
```

The installed global skill directory is usually `~/.agents/skills/macos-reminders`.
`skills check` and `skills update` may refer to the upstream package name `apple-reminders`.

## Public Interface

Run skill actions with:

```bash
scripts/commands/<entity>/<action>.sh [args...]
```

Output rules:

- Commands return JSON by default unless noted otherwise.
- `scripts/commands/account/show.sh` and `scripts/commands/list/show.sh` open the Reminders UI and return JSON like `{"shown": true, ...}`.
- `scripts/commands/reminder/show.sh` is not part of the public interface.
- `--json` is not supported.
- `--plain` is not supported.
- `--format=plain|json` is not supported.

## Backend Map

- `scripts/commands/account/*` -> AppleScript in `scripts/applescripts/account/*`
- `scripts/commands/list/*` -> AppleScript in `scripts/applescripts/list/*`
- `scripts/commands/reminder/*` -> prefer `remindctl` + jq; fallback to AppleScript when remindctl is missing

`scripts/applescripts` is internal. Do not call it directly from the skill instructions.

## Dependencies

- macOS Reminders.app
- `jq`
- Reminder commands: prefer `remindctl` and `jq`; first try `remindctl` from `PATH`, then `/opt/homebrew/bin/remindctl`, then AppleScript fallback
- Account and list command wrappers also use `jq` to produce JSON

Check remindctl access with `remindctl status` or `/opt/homebrew/bin/remindctl status`.

```bash
remindctl status
```

A clean macOS install does not include `remindctl`; the skill still works via AppleScript.

## Repo Layout

- `AGENTS.md` - repo rules for future agents.
- `SKILL.md` - the main skill workflow and command reference.
- `Makefile` - helper commands for dictionary dump, compile, and tests.
- `scripts/commands/` - public shell command interface.
- `scripts/applescripts/` - internal AppleScript backends in `<entity>/<action>.applescript` format.
- `scripts/tests/` - live integration checks.

## Command Surface

Account:

- `scripts/commands/account/list.sh`
- `scripts/commands/account/get.sh`
- `scripts/commands/account/search.sh`
- `scripts/commands/account/show.sh`
- `scripts/commands/account/default-account.sh`
- `scripts/commands/account/default-list.sh`

List:

- `scripts/commands/list/list.sh`
- `scripts/commands/list/create.sh`
- `scripts/commands/list/show.sh`
- `scripts/commands/list/edit.sh`
- `scripts/commands/list/delete.sh`
- `scripts/commands/list/search.sh`
- `scripts/commands/list/get.sh`
- `scripts/commands/list/exists.sh`

Reminder:

- `scripts/commands/reminder/list.sh`
- `scripts/commands/reminder/count.sh`
- `scripts/commands/reminder/today.sh`
- `scripts/commands/reminder/overdue.sh`
- `scripts/commands/reminder/upcoming.sh`
- `scripts/commands/reminder/due-before.sh`
- `scripts/commands/reminder/due-range.sh`
- `scripts/commands/reminder/today-or-overdue.sh`
- `scripts/commands/reminder/create.sh`
- `scripts/commands/reminder/get.sh`
- `scripts/commands/reminder/get-by-id.sh`
- `scripts/commands/reminder/edit.sh`
- `scripts/commands/reminder/edit-by-id.sh`
- `scripts/commands/reminder/reschedule.sh`
- `scripts/commands/reminder/reschedule-by-id.sh`
- `scripts/commands/reminder/delete.sh`
- `scripts/commands/reminder/delete-by-id.sh`
- `scripts/commands/reminder/complete.sh`
- `scripts/commands/reminder/move.sh`
- `scripts/commands/reminder/move-by-id.sh`
- `scripts/commands/reminder/exists.sh`
- `scripts/commands/reminder/search.sh`

Not published:

- `scripts/commands/reminder/show.sh`

## Examples

```bash
scripts/commands/account/list.sh
scripts/commands/account/default-list.sh
scripts/commands/list/create.sh "Errands"
scripts/commands/list/get.sh "Inbox" id
scripts/commands/reminder/today.sh
scripts/commands/reminder/create.sh "Inbox" "Buy milk" "2 liters" --priority high
scripts/commands/reminder/get.sh --id "REMINDER-ID" body
scripts/commands/reminder/edit.sh --id "REMINDER-ID" body "3 liters"
scripts/commands/reminder/reschedule.sh --id "REMINDER-ID" "2030-01-15"
scripts/commands/reminder/complete.sh --id "REMINDER-ID"
scripts/commands/reminder/delete.sh --id "REMINDER-ID"
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
- `exists.sh` returns `{"exists": false, "id": null}` when a reminder is not found.

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

`make test` runs live smoke checks against Reminders.app and expects working Reminders automation access. It also expects `remindctl` to be installed and reachable.
