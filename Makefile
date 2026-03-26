.PHONY: dictionary dictionary-reminders dictionary-standard compile test test-dictionary test-smoke

dictionary:
	@printf '### Reminders.app\n'
	@sdef /System/Applications/Reminders.app
	@printf '\n### CocoaStandard.sdef\n'
	@cat /System/Library/ScriptingDefinitions/CocoaStandard.sdef

dictionary-reminders:
	@sdef /System/Applications/Reminders.app

dictionary-standard:
	@cat /System/Library/ScriptingDefinitions/CocoaStandard.sdef

compile:
	@set -euo pipefail; \
	find scripts/applescripts -name '*.applescript' -print | while IFS= read -r file; do \
		osacompile -o /tmp/$$(echo "$$file" | tr '/' '_' | sed 's/\.applescript$$/.scpt/') "$$file"; \
	done; \
	clang -framework Foundation -o /tmp/macos-reminders-skill-reminderkit-helper scripts/tools/reminderkit_helper.m

test: test-dictionary test-smoke

test-dictionary:
	@bash scripts/tests/dictionary_contract.sh

test-smoke:
	@bash scripts/tests/smoke_reminders.sh
