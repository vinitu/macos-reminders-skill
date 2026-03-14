---
name: macos-reminders
description: Use this skill when you need to control Apple Reminders.app on macOS. The public interface is src/commands. Account and list commands use AppleScript backends. Reminder data commands use remindctl.
---

# macOS Reminders

Use this skill when the task is about Apple Reminders.app on macOS.

## Main Rule

Use only the commands in `src/commands`.
Do not call `src/applescripts` directly in the answer.

Public interface:

- `src/commands/account/*`
- `src/commands/list/*`
- `src/commands/reminder/*`

Internal backends:

- `src/applescripts/account/*`
- `src/applescripts/list/*`
- `src/applescripts/reminder/*`

Backend map:

- `account/*` -> AppleScript
- `list/*` -> AppleScript
- `reminder/*` -> `remindctl`

## Output Rules

- Default output is human-readable text.
- `--json` returns the normalized machine-readable contract.
- `--plain` is not supported.
- `--format=plain|json` is not supported.

If the user needs structured output, use `--json`.

## Dependencies

Public reminder commands require `remindctl` and `jq`.

Check access with:

```bash
remindctl status
```

A clean macOS install does not include `remindctl`.

## Public Commands

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

Do not publish:

- `src/commands/reminder/show.sh`

## Accounts

List all accounts:

```bash
src/commands/account/list.sh
src/commands/account/list.sh --json
```

Read one account property:

```bash
src/commands/account/get.sh "iCloud" id
src/commands/account/get.sh "iCloud" reminders_count --json
```

Search accounts:

```bash
src/commands/account/search.sh exact-name "iCloud"
src/commands/account/search.sh text "cloud" --json
```

Default account and default list:

```bash
src/commands/account/default-account.sh
src/commands/account/default-account.sh --json
src/commands/account/default-list.sh
src/commands/account/default-list.sh --json
```

Show an account in the UI:

```bash
src/commands/account/show.sh "iCloud"
```

## Lists

List all lists or lists in one account:

```bash
src/commands/list/list.sh
src/commands/list/list.sh "iCloud" --json
```

Create, edit, delete, exists:

```bash
src/commands/list/create.sh "Errands"
src/commands/list/create.sh "Errands" "#34C759" "list.bullet" --json
src/commands/list/edit.sh "Errands" name "Today"
src/commands/list/edit.sh "Today" color "#34C759" --json
src/commands/list/delete.sh "Today" --json
src/commands/list/exists.sh "Inbox"
```

Get and search:

```bash
src/commands/list/get.sh "Inbox" id
src/commands/list/get.sh "Inbox" color --json
src/commands/list/search.sh exact-name "Inbox" --json
src/commands/list/search.sh text "Err" "iCloud"
```

Show a list in the UI:

```bash
src/commands/list/show.sh "Inbox"
```

## Reminders

Canonical reminder identity is the `remindctl` reminder ID or a unique prefix.
Prefer `--id` for reminder read and write commands.

List and count:

```bash
src/commands/reminder/list.sh
src/commands/reminder/list.sh "Inbox" --json
src/commands/reminder/count.sh "Inbox"
src/commands/reminder/count.sh "Inbox" --json
```

Date filters:

```bash
src/commands/reminder/today.sh
src/commands/reminder/today.sh "Inbox" --json
src/commands/reminder/overdue.sh "Inbox"
src/commands/reminder/upcoming.sh 7 "Inbox" --json
src/commands/reminder/due-before.sh "2030-01-01" "Inbox" --json
src/commands/reminder/due-range.sh "2030-01-01" "2030-01-31" "Inbox"
src/commands/reminder/today-or-overdue.sh "Inbox" --json
```

Create:

```bash
src/commands/reminder/create.sh "Inbox" "Buy milk"
src/commands/reminder/create.sh "Inbox" "Buy milk" "2 liters" --priority high --json
src/commands/reminder/create.sh "Inbox" "Buy milk" --due "2026-03-14 10:00"
```

Read:

```bash
src/commands/reminder/get.sh --id "REMINDER-ID"
src/commands/reminder/get.sh --id "REMINDER-ID" body
src/commands/reminder/get.sh --id "REMINDER-ID" body --json
src/commands/reminder/get-by-id.sh "REMINDER-ID" priority
```

Edit, move, complete, delete:

```bash
src/commands/reminder/edit.sh --id "REMINDER-ID" body "3 liters"
src/commands/reminder/edit.sh --id "REMINDER-ID" due_date "missing"
src/commands/reminder/edit-by-id.sh "REMINDER-ID" priority medium
src/commands/reminder/move.sh --id "REMINDER-ID" "Errands"
src/commands/reminder/move-by-id.sh "REMINDER-ID" "Errands"
src/commands/reminder/complete.sh --id "REMINDER-ID"
src/commands/reminder/delete.sh --id "REMINDER-ID" --json
src/commands/reminder/delete-by-id.sh "REMINDER-ID"
```

Exists and search:

```bash
src/commands/reminder/exists.sh --id "REMINDER-ID"
src/commands/reminder/exists.sh --id "REMINDER-ID" --json
src/commands/reminder/search.sh exact-name "Inbox" "Buy milk"
src/commands/reminder/search.sh id "REMINDER-ID" --json
src/commands/reminder/search.sh incomplete "Inbox"
src/commands/reminder/search.sh priority high "Inbox" --json
src/commands/reminder/search.sh has-due-date "Inbox"
src/commands/reminder/search.sh text "milk" "Inbox" --json
```

## Normalized JSON Contract

Account object:

- `id`
- `name`
- `lists_count`
- `reminders_count`

List object:

- `id`
- `name`
- `container`
- `color`
- `emblem`

Reminder object:

- `id`
- `name`
- `list`
- `body`
- `completed`
- `priority`
- `due_date`

Reminder priority values:

- `none`
- `low`
- `medium`
- `high`

Scalar envelopes:

- `count`: `{"count": N, "list": "..."}`
- `exists`: `{"exists": true|false, "id": "..."}`
- property read: `{"id": "...", "property": "...", "value": ...}`
- delete: `{"deleted": true, "id": "..."}`

## Public Reminder Limits

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
