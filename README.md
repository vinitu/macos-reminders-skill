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
- `scripts/commands/reminder/*` -> optional `remindctl` fast path; required fallback is AppleScript + ReminderKit

`scripts/applescripts` is internal. Do not call it directly from the skill instructions.

## Dependencies

- macOS Reminders.app
- `jq`
- Reminder commands: AppleScript + ReminderKit are the required functional backend
- `remindctl` is optional and used only as a fast path when it is available and healthy
- Account and list command wrappers also use `jq` to produce JSON
- ReminderKit is compiled from `scripts/tools/reminderkit_helper.m` during `make compile` or on first use

Check remindctl access with `remindctl status` or `/opt/homebrew/bin/remindctl status`.

```bash
remindctl status
```

A clean macOS install does not include `remindctl`; the skill still works through AppleScript + ReminderKit.

Backend policy:

- `remindctl` only accelerates reminder commands
- Missing `remindctl` must not break the public reminder interface
- Failing `remindctl` calls must fall back to AppleScript + ReminderKit
- `urgent` and nested reminder operations are implemented through ReminderKit, not through `remindctl`

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
scripts/commands/reminder/create.sh "Inbox" "Buy milk" --flagged
scripts/commands/reminder/create.sh "Inbox" "Buy milk" --urgent
scripts/commands/reminder/create.sh "Inbox" "Buy milk" --parent-id "PARENT-ID"
scripts/commands/reminder/get.sh --id "REMINDER-ID" body
scripts/commands/reminder/get.sh --id "REMINDER-ID" flagged
scripts/commands/reminder/get.sh --id "REMINDER-ID" urgent
scripts/commands/reminder/edit.sh --id "REMINDER-ID" body "3 liters"
scripts/commands/reminder/edit.sh --id "REMINDER-ID" flagged true
scripts/commands/reminder/edit.sh --id "REMINDER-ID" urgent true
scripts/commands/reminder/edit.sh --id "REMINDER-ID" parent_id "PARENT-ID"
scripts/commands/reminder/edit.sh --id "REMINDER-ID" parent_id missing
scripts/commands/reminder/search.sh flagged "Inbox"
scripts/commands/reminder/search.sh urgent "Inbox"
scripts/commands/reminder/search.sh nested "Inbox"
scripts/commands/reminder/reschedule.sh --id "REMINDER-ID" "2030-01-15"
scripts/commands/reminder/complete.sh --id "REMINDER-ID"
scripts/commands/reminder/delete.sh --id "REMINDER-ID"
```

## Reminder Contract

- Public reminder identity is the reminder UUID or a unique UUID prefix.
- Canonical reminder read and write commands use `--id`.
- Public reminder fields:
  - `id`
  - `name`
  - `list`
  - `body`
  - `completed`
  - `priority`
  - `due_date`
  - `flagged`
  - `urgent`
  - `parent_id`
  - `parent_name`
- Public priority values:
  - `none`
  - `low`
  - `medium`
  - `high`
- `exists.sh` returns `{"exists": false, "id": null}` when a reminder is not found.
- Nested reminder metadata is public through `parent_id` and `parent_name`.
- Nested reminder writes are public through `create.sh --parent-id` and `edit.sh parent_id`.
- Detaching a subtask with `edit.sh --id ... parent_id missing` may return a new reminder UUID because the fallback lifts the subtask to top level and deletes the old child.
- `urgent` is public and is backed by ReminderKit, not by AppleScript or `remindctl`.

These reminder features are not part of the public interface:

- `show`
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

`make test` runs live smoke checks against Reminders.app and expects working Reminders automation access. `remindctl` is optional.
