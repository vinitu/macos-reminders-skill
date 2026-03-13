# Repo Guide

This repo stores a Codex skill for macOS Reminders.app.

## Goal

- Keep the AppleScript coverage accurate to the live app dictionary.
- Prefer runnable examples over long prose.
- Treat reminder data as real user data.

## Source Of Truth

- `make dictionary-reminders`
- `make dictionary-standard`
- Live checks with `osascript`

The raw dictionary commands live only in this file and in `Makefile`.

## Repo Layout

- `SKILL.md` is the main skill workflow.
- `README.md` is the repo overview for humans.
- `scripts/account/`, `scripts/list/`, and `scripts/reminder/` store the AppleScript entrypoints.
- `tests/` stores live integration checks for Reminders.app.

## Editing Rules

- Keep docs in simple English.
- Update `SKILL.md` when command coverage changes.
- Do not claim support for a feature unless it is in the dictionary or verified with `osascript`.
- Call out the difference between "declared by the standard suite" and "verified in Reminders".
- Use the `CodexTest_` prefix for temporary test data.
- Always clean temporary reminders and lists.

## Validation

- Run `make test`.
- Run `make compile` after AppleScript edits.
- If a test is blocked by TCC permissions or app state, document the block clearly.
