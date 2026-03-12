---
name: apple-reminders
description: Use this skill when you need to control Apple Reminders.app on macOS with AppleScript. Covers list and reminder CRUD, property updates, search, and UI reveal.
---

# Apple Reminders AppleScript

Use this skill when the task is about Apple Reminders.app on macOS and AppleScript is the required interface.

This guide only covers working with Reminders.

## Main Rule

Do not put inline AppleScript in the answer when this repo already has a script for the action.
Run the scripts in `scripts/account`, `scripts/list`, and `scripts/reminder`.

## Script Layout

- `scripts/account/list.applescript`
- `scripts/list/list.applescript`
- `scripts/list/create.applescript`
- `scripts/list/show.applescript`
- `scripts/list/edit.applescript`
- `scripts/list/delete.applescript`
- `scripts/list/search.applescript`
- `scripts/list/get.applescript`
- `scripts/list/exists.applescript`
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

## Accounts

List all accounts:

```bash
osascript scripts/account/list.applescript
```

## Lists

List all lists:

```bash
osascript scripts/list/list.applescript
```

List lists in one account:

```bash
osascript scripts/list/list.applescript "iCloud"
```

Create a list:

```bash
osascript scripts/list/create.applescript "Errands"
```

Create a list with color and emblem:

```bash
osascript scripts/list/create.applescript "Errands" "#34C759" "list.bullet"
```

Show a list in the UI:

```bash
osascript scripts/list/show.applescript "Inbox"
```

Rename a list:

```bash
osascript scripts/list/edit.applescript "Inbox" name "Today"
```

Set list color:

```bash
osascript scripts/list/edit.applescript "Today" color "#34C759"
```

Set list emblem:

```bash
osascript scripts/list/edit.applescript "Today" emblem "list.bullet"
```

Delete a list:

```bash
osascript scripts/list/delete.applescript "Errands"
```

Check that a list exists:

```bash
osascript scripts/list/exists.applescript "Inbox"
```

Read a list property:

```bash
osascript scripts/list/get.applescript "Inbox" id
```

Supported list properties:

- `id`
- `name`
- `container`
- `color`
- `emblem`

Search lists by exact name:

```bash
osascript scripts/list/search.applescript exact-name "Inbox"
```

Search lists by id:

```bash
osascript scripts/list/search.applescript id "x-apple-reminder://LIST-ID"
```

Search lists by color:

```bash
osascript scripts/list/search.applescript color "#34C759"
```

Search lists by emblem:

```bash
osascript scripts/list/search.applescript emblem "list.bullet"
```

Search lists by text in the list name:

```bash
osascript scripts/list/search.applescript text "Err"
```

Search lists with JSON output:

```bash
osascript scripts/list/search.applescript text "Err" --format=json
```

## Reminders

List all reminders:

```bash
osascript scripts/reminder/list.applescript
```

List reminders in one list:

```bash
osascript scripts/reminder/list.applescript "Inbox"
```

Count reminders in one list:

```bash
osascript scripts/reminder/count.applescript "Inbox"
```

List reminders due today in all lists:

```bash
osascript scripts/reminder/today.applescript
```

List reminders due today in one list:

```bash
osascript scripts/reminder/today.applescript "Inbox"
```

List overdue reminders in all lists:

```bash
osascript scripts/reminder/overdue.applescript
```

List overdue reminders in one list:

```bash
osascript scripts/reminder/overdue.applescript "Inbox"
```

List reminders due in the next 7 days:

```bash
osascript scripts/reminder/upcoming.applescript 7
```

List reminders due before a date:

```bash
osascript scripts/reminder/due-before.applescript "1/1/2030"
```

List reminders due in a date range:

```bash
osascript scripts/reminder/due-range.applescript "1/1/2020" "1/1/2030"
```

List focus reminders (today + overdue):

```bash
osascript scripts/reminder/today-or-overdue.applescript
```

Create a reminder:

```bash
osascript scripts/reminder/create.applescript "Inbox" "Buy milk" "2 liters"
```

Show a reminder in the UI:

```bash
osascript scripts/reminder/show.applescript "Inbox" "Buy milk"
```

Edit one reminder property:

```bash
osascript scripts/reminder/edit.applescript "Inbox" "Buy milk" body "3 liters"
```

Set reminder priority:

```bash
osascript scripts/reminder/edit.applescript "Inbox" "Buy milk" priority 1
```

Set reminder flagged:

```bash
osascript scripts/reminder/edit.applescript "Inbox" "Buy milk" flagged true
```

Set reminder due date:

```bash
osascript scripts/reminder/edit.applescript "Inbox" "Buy milk" due_date "March 13, 2026 10:00"
```

Clear reminder due date:

```bash
osascript scripts/reminder/edit.applescript "Inbox" "Buy milk" due_date missing
```

Delete a reminder:

```bash
osascript scripts/reminder/delete.applescript "Inbox" "Buy milk"
```

Check that a reminder exists:

```bash
osascript scripts/reminder/exists.applescript "Inbox" "Buy milk"
```

Read a reminder property:

```bash
osascript scripts/reminder/get.applescript "Inbox" "Buy milk" body
```

Read a reminder property by id:

```bash
osascript scripts/reminder/get-by-id.applescript "Inbox" "x-apple-reminder://1234-ABCD" body
```

Edit a reminder by id:

```bash
osascript scripts/reminder/edit-by-id.applescript "Inbox" "x-apple-reminder://1234-ABCD" priority 1
```

Delete a reminder by id:

```bash
osascript scripts/reminder/delete-by-id.applescript "Inbox" "x-apple-reminder://1234-ABCD"
```

Supported reminder properties:

- `name`
- `id`
- `container`
- `creation_date`
- `modification_date`
- `body`
- `completed`
- `completion_date`
- `due_date`
- `allday_due_date`
- `remind_me_date`
- `priority`
- `flagged`

Complete a reminder:

```bash
osascript scripts/reminder/complete.applescript "Inbox" "Buy milk"
```

Move a reminder to another list:

```bash
osascript scripts/reminder/move.applescript "Inbox" "Buy milk" "Errands"
```

Move a reminder to another list by id:

```bash
osascript scripts/reminder/move-by-id.applescript "Inbox" "x-apple-reminder://1234-ABCD" "Errands"
```

Any reminder query script can return JSON:

```bash
osascript scripts/reminder/today.applescript --format=json
osascript scripts/reminder/overdue.applescript "Inbox" --format=json
osascript scripts/reminder/search.applescript text "milk" "Inbox" --format=json
```

## Search

There is no native AppleScript command named `search` in Reminders.
Search means lookup by name or id, filtering with `whose`, or manual text scan.
Search in this skill trims surrounding spaces and matches case-insensitive text.

Find one reminder by exact name inside one list:

```bash
osascript scripts/reminder/search.applescript exact-name "Inbox" "Buy milk"
```

Find one reminder by id:

```bash
osascript scripts/reminder/search.applescript id "x-apple-reminder://1234-ABCD"
```

Find incomplete reminders in all lists:

```bash
osascript scripts/reminder/search.applescript incomplete
```

Find incomplete reminders in one list:

```bash
osascript scripts/reminder/search.applescript incomplete "Inbox"
```

Find flagged reminders:

```bash
osascript scripts/reminder/search.applescript flagged
```

Find reminders by priority:

```bash
osascript scripts/reminder/search.applescript priority 1 "Inbox"
```

Find reminders that have a due date:

```bash
osascript scripts/reminder/search.applescript has-due-date "Inbox"
```

Find reminders by free text in title or notes:

```bash
osascript scripts/reminder/search.applescript text "milk" "Inbox"
```

Find reminders by text with JSON output:

```bash
osascript scripts/reminder/search.applescript text "  MILK  " "Inbox" --format=json
```

## AppleScript Command Map

These are the published Reminders AppleScript actions and the script to use for each one.

- `show`: `scripts/list/show.applescript`, `scripts/reminder/show.applescript`
- `count`: `scripts/reminder/count.applescript`
- `delete`: `scripts/list/delete.applescript`, `scripts/reminder/delete.applescript`
- `exists`: `scripts/list/exists.applescript`, `scripts/reminder/exists.applescript`
- `make`: `scripts/list/create.applescript`, `scripts/reminder/create.applescript`
- `move`: `scripts/reminder/move.applescript`
- `get`: `scripts/list/get.applescript`, `scripts/reminder/get.applescript`
- `set`: `scripts/list/edit.applescript`, `scripts/reminder/edit.applescript`
- `id-scoped reminder actions`: `scripts/reminder/get-by-id.applescript`, `scripts/reminder/edit-by-id.applescript`, `scripts/reminder/delete-by-id.applescript`, `scripts/reminder/move-by-id.applescript`
- `date filters`: `scripts/reminder/today.applescript`, `scripts/reminder/overdue.applescript`, `scripts/reminder/upcoming.applescript`, `scripts/reminder/due-before.applescript`, `scripts/reminder/due-range.applescript`, `scripts/reminder/today-or-overdue.applescript`
- `output format`: query and search scripts accept `--format=plain|json`
- `duplicate`: exposed by the app, but unreliable for reminders. Do not use it as a normal workflow.
- `open`, `close`, `save`, `print`, `quit`: standard app and window actions. They are not part of reminder data work and are not wrapped here.

## Limits

- `show-*` opens the Reminders UI.
- `duplicate` can fail with error `-1717`.
- Date setters accept a macOS date string that AppleScript can parse on this Mac, or `missing` to clear the field.
- Date filter scripts (`due-before`, `due-range`) also use macOS date parsing on this Mac.
- There is no published AppleScript API for tags, smart lists, recurrence rules, attachments, shared assignees, URLs, or section grouping.
- A reminder can report a `container` of type `reminder`, but the dictionary does not expose `reminders of reminder`, so subtask creation is not available as a normal operation.
