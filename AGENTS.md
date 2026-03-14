# Repo Guide

This repo stores a Codex skill for macOS Reminders.app.

## Goal

- Keep the AppleScript coverage accurate to the live app dictionary.
- Keep the public `src/commands` interface accurate to the implemented behavior.
- Prefer runnable examples over long prose.
- Treat reminder data as real user data.

## Source Of Truth

- `make dictionary-reminders`
- `make dictionary-standard`
- Live checks with `osascript`
- Live checks with `remindctl`

The raw dictionary commands live only in this file and in `Makefile`.

## Repo Layout

- `SKILL.md` is the main skill workflow and full command list; update it when command coverage changes.
- `README.md` is the repo overview for humans.
- `src/commands/` is the public shell interface; run from repo root (see Example below).
- `src/applescripts/account/`, `src/applescripts/list/`, and `src/applescripts/reminder/` are internal AppleScript entrypoints.
- `src/commands/reminder/reminder_normalize.jq` maps remindctl JSON to the reminder shape (priority 0/1/5/9 → "none"/"low"/"medium"/"high"); used by list, today, today-or-overdue, upcoming, due-before, due-range (overdue.sh uses inline jq).
- `tests/` stores live integration checks for Reminders.app.

## Example (overdue)

Run from repo root:

```bash
./src/commands/reminder/overdue.sh
./src/commands/reminder/overdue.sh "Work / Productivity"
```

Reference: `src/commands/reminder/overdue.sh`. Pattern: get JSON from `remindctl`, then one `jq` that filters (e.g. `select(.isCompleted == false and .dueDate ...)`) and maps to the reminder shape. Other list/filter commands use `reminder_normalize.jq` + a second `jq` for the filter.

## Reminder command backends

- **account** and **list**: AppleScript only (via `applescript_backend.jxa`).
- **reminder**: only bash + `remindctl` + jq. Require `remindctl` (and `jq` for list/filter/count/search/get); if missing, print "not implemented yet" and exit 1. No AppleScript fallback. Failed remindctl → "remindctl failed", exit 1.

## Reminder JSON (list/filter output)

List/filter commands return a JSON array of objects in this shape: `list`, `today`, `overdue`, `today-or-overdue`, `upcoming`, `due-before`, `due-range`, `search`.

| Field       | Type    | Description                          |
|------------|---------|--------------------------------------|
| `id`       | string  | Reminder UUID                        |
| `name`     | string  | Title                                |
| `list`     | string  | List name                            |
| `body`     | string? | Notes; `null` when empty             |
| `completed`| boolean | Completion flag                     |
| `priority` | string  | `"none"` \| `"low"` \| `"medium"` \| `"high"` |
| `due_date` | string? | ISO 8601 date-time or `null`        |

Example: `[{"id":"...","name":"Task","list":"List","body":null,"completed":false,"priority":"none","due_date":"2026-03-13T12:00:00Z"}]`

## Editing Rules

- Keep docs in simple English.
- Update `SKILL.md` when command coverage changes.
- Keep `SKILL.md` and `README.md` on the public `src/commands` interface, not on internal backends.
- Do not claim support for a feature unless it is in the dictionary or verified with `osascript`.
- Call out the difference between "declared by the standard suite" and "verified in Reminders".
- Use the `CodexTest_` prefix for temporary test data.
- Always clean temporary reminders and lists.

## Validation

- After AppleScript edits: `make compile` then `make test`. Useful targets: `dictionary-reminders`, `dictionary-standard`, `compile`, `test`.
- Reminders automation may need **Reminders** or **Full Disk Access** (System Settings → Privacy & Security). Document TCC or app-state blocks clearly.
