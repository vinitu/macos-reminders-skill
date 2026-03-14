on run argv
    if (count of argv) is less than 2 then error "Usage: osascript src/applescripts/reminder/delete.applescript <list-name> <reminder-name>"

    set listName to item 1 of argv
    set reminderName to item 2 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if not (exists (first reminder of targetList whose name is reminderName)) then return "already-missing"
        set reminderId to id of first reminder of targetList whose name is reminderName
    end tell

    tell application "Reminders"
        set targetList to first list whose name is listName
        delete first reminder of targetList whose id is reminderId
    end tell

    return "deleted"
end run
