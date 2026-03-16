# Repo Guide

This repo stores an AI agent skill for macOS Reminders.app.

Installed global skill directory: `~/.agents/skills/macos-reminders`.
`skills check` and `skills update` may refer to this skill by upstream package name `apple-reminders` from `vinitu/apple-reminders-skill`.

## Where to start

- Read this file, then `SKILL.md` for the full command list and usage.
- Run all commands from the **repo root**: `./scripts/commands/<entity>/<action>.sh` or `scripts/commands/...`
- Do not call `scripts/applescripts` directly; use only `scripts/commands`.

## Goal

- Keep the AppleScript coverage accurate to the live app dictionary.
- Keep the public `scripts/commands` interface accurate to the implemented behavior.
- Prefer runnable examples over long prose.
- Treat reminder data as real user data.

## Source of truth

- `make dictionary-reminders` / `make dictionary-standard`
- Live checks with `osascript` and `remindctl`
- Raw dictionary commands live only in this file and in the `Makefile`.

## Repo layout

- **SKILL.md** — main skill workflow and full command list; update when command coverage changes.
- **README.md** — repo overview for humans.
- **scripts/commands/** — public shell interface (run from repo root).
- **scripts/applescripts/account|list|reminder/** — internal AppleScript entrypoints (invoked via `osascript` by the command scripts).
- **scripts/commands/reminder/reminder_normalize.jq** — maps remindctl JSON to the reminder shape (priority can be `0/1/5/9` or `"none"/"low"/"medium"/"high"`); used by list, today, today-or-overdue, upcoming, due-before, due-range (overdue.sh uses inline jq).
- **scripts/tests/** — live integration checks for Reminders.app.

## Example (overdue)

```bash
./scripts/commands/reminder/overdue.sh
./scripts/commands/reminder/overdue.sh "Work / Productivity"
```

Pattern: reminder commands try `remindctl` first; if missing, use AppleScript fallback (same JSON contract). With remindctl: get JSON, then `jq` to filter and map via `reminder_normalize.jq` (or inline jq in overdue.sh).

## Backends

- **account**, **list**: AppleScript only (`osascript` + `scripts/applescripts/<entity>/*.applescript`). Output is always JSON.
- **reminder**: prefer `remindctl` + jq; fallback to AppleScript when remindctl is missing (same JSON shape). If remindctl is used and fails → "remindctl failed", exit 1.

## Reminder JSON shape

List/filter commands (`list`, `today`, `overdue`, `today-or-overdue`, `upcoming`, `due-before`, `due-range`, `search`) return a **JSON array** of objects in this shape. Single-reminder commands (`get`, `get-by-id`, `create`) return **one object** in the same shape (or `{id, property, value}` for get when a property is requested).

| Field        | Type    | Description                                          |
|-------------|---------|------------------------------------------------------|
| `id`        | string  | Reminder UUID                                        |
| `name`      | string  | Title                                                |
| `list`      | string  | List name                                            |
| `body`      | string? | Notes; `null` when empty                             |
| `completed` | boolean | Completion flag                                      |
| `priority`  | string  | `"none"` \| `"low"` \| `"medium"` \| `"high"`        |
| `due_date`  | string? | ISO 8601 date-time or `null`                         |

Example array: `[{"id":"...","name":"Task","list":"List","body":null,"completed":false,"priority":"none","due_date":"2026-03-13T12:00:00Z"}]`

## Do not

- Call `scripts/applescripts` from skill instructions; use only `scripts/commands`.
- Claim support for a feature unless it is in the app dictionary or verified with `osascript` / `remindctl`.
- Leave temporary data: use the `CodexTest_` prefix and always clean up test reminders and lists.

## Editing rules

- Keep docs in simple English.
- Update **SKILL.md** when command coverage changes.
- Keep **SKILL.md** and **README.md** about the public `scripts/commands` interface, not internal backends.
- Call out "declared by the standard suite" vs "verified in Reminders" when relevant.

## Validation

- After AppleScript or command changes: `make compile` then `make test`.
- Useful targets: `dictionary-reminders`, `dictionary-standard`, `compile`, `test`.
- Smoke tests (`test-smoke`) require Reminders.app (and optionally `remindctl`); they can be slow.
- Reminders automation may need **Reminders** or **Full Disk Access** (System Settings → Privacy & Security). Document TCC or app-state blocks clearly.
