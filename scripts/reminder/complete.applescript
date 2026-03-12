on run argv
    if (count of argv) is less than 2 then error "Usage: osascript scripts/reminder/complete.applescript <list-name> <reminder-name>"

    set listName to item 1 of argv
    set reminderName to item 2 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if not (exists (first reminder of targetList whose name is reminderName)) then error "Reminder does not exist: " & reminderName
        tell first reminder of targetList whose name is reminderName
            set completed to true
            return completion date as text
        end tell
    end tell
end run
