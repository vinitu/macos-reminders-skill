on run argv
    if (count of argv) is less than 2 then error "Usage: osascript scripts/applescripts/reminder/exists.applescript <list-name> <reminder-name>"

    set listName to item 1 of argv
    set reminderName to item 2 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        return (exists (first reminder of targetList whose name is reminderName))
    end tell
end run
