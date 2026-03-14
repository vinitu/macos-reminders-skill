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

## Dependencies

Reminder commands prefer `remindctl` and `jq`. They first try `remindctl` from `PATH`, then `/opt/homebrew/bin/remindctl`, and use AppleScript fallback only when neither is available. Some fallback paths still use `jq` for JSON output.

Check remindctl access with `remindctl status` or `/opt/homebrew/bin/remindctl status`.

```bash
remindctl status
```

A clean macOS install does not include `remindctl`; the skill still works via AppleScript.


## Accounts

List all accounts:

```bash
src/commands/account/list.sh
```

Read one account property:

```bash
src/commands/account/get.sh "iCloud" id
src/commands/account/get.sh "iCloud" reminders_count
```

Search accounts:

```bash
src/commands/account/search.sh exact-name "iCloud"
src/commands/account/search.sh text "cloud"
```

Default account and default list:

```bash
src/commands/account/default-account.sh
src/commands/account/default-list.sh
```

Show an account in the UI:

```bash
src/commands/account/show.sh "iCloud"
```

## Lists

List all lists or lists in one account:

```bash
src/commands/list/list.sh
src/commands/list/list.sh "iCloud"
```

Create, edit, delete, exists:

```bash
src/commands/list/create.sh "Errands"
src/commands/list/create.sh "Errands" "#34C759" "list.bullet"
src/commands/list/edit.sh "Errands" name "Today"
src/commands/list/edit.sh "Today" color "#34C759"
src/commands/list/delete.sh "Today"
src/commands/list/exists.sh "Inbox"
```

Get and search:

```bash
src/commands/list/get.sh "Inbox" id
src/commands/list/get.sh "Inbox" color
src/commands/list/search.sh exact-name "Inbox"
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
src/commands/reminder/list.sh "Inbox"
src/commands/reminder/count.sh "Inbox"
```

Date filters:

```bash
src/commands/reminder/today.sh
src/commands/reminder/today.sh "Inbox"
src/commands/reminder/overdue.sh "Inbox"
src/commands/reminder/upcoming.sh 7 "Inbox"
src/commands/reminder/due-before.sh "2030-01-01" "Inbox"
src/commands/reminder/due-range.sh "2030-01-01" "2030-01-31" "Inbox"
src/commands/reminder/today-or-overdue.sh "Inbox"
```

Create:

```bash
src/commands/reminder/create.sh "Inbox" "Buy milk"
src/commands/reminder/create.sh "Inbox" "Buy milk" "2 liters" --priority high
src/commands/reminder/create.sh "Inbox" "Buy milk" --due "2026-03-14 10:00"
```

Read:

```bash
src/commands/reminder/get.sh --id "REMINDER-ID"
src/commands/reminder/get.sh --id "REMINDER-ID" body
src/commands/reminder/get-by-id.sh "REMINDER-ID" priority
```

Edit, move, complete, delete:

```bash
src/commands/reminder/edit.sh --id "REMINDER-ID" body "3 liters"
src/commands/reminder/edit.sh --id "REMINDER-ID" due_date "missing"
src/commands/reminder/edit-by-id.sh "REMINDER-ID" priority medium
src/commands/reminder/reschedule.sh --id "REMINDER-ID" "2030-01-15"
src/commands/reminder/reschedule-by-id.sh "REMINDER-ID" "2030-01-15 12:00"
src/commands/reminder/move.sh --id "REMINDER-ID" "Errands"
src/commands/reminder/move-by-id.sh "REMINDER-ID" "Errands"
src/commands/reminder/complete.sh --id "REMINDER-ID"
src/commands/reminder/delete.sh --id "REMINDER-ID"
src/commands/reminder/delete-by-id.sh "REMINDER-ID"
```

Exists and search:

```bash
src/commands/reminder/exists.sh --id "REMINDER-ID"
src/commands/reminder/search.sh exact-name "Inbox" "Buy milk"
src/commands/reminder/search.sh id "REMINDER-ID"
src/commands/reminder/search.sh incomplete "Inbox"
src/commands/reminder/search.sh priority high "Inbox"
src/commands/reminder/search.sh has-due-date "Inbox"
src/commands/reminder/search.sh text "milk" "Inbox"
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
