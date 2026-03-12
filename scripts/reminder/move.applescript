on run argv
    if (count of argv) is less than 3 then error "Usage: osascript scripts/reminder/move.applescript <source-list> <reminder-name> <target-list>"

    set sourceListName to item 1 of argv
    set reminderName to item 2 of argv
    set targetListName to item 3 of argv

    tell application "Reminders"
        if not (exists list sourceListName) then error "Source list does not exist: " & sourceListName
        if not (exists list targetListName) then error "Target list does not exist: " & targetListName
        set sourceListObject to first list whose name is sourceListName
        set targetListObject to first list whose name is targetListName
        if not (exists (first reminder of sourceListObject whose name is reminderName)) then error "Reminder does not exist: " & reminderName
        move first reminder of sourceListObject whose name is reminderName to end of reminders of targetListObject
        return id of first reminder of targetListObject whose name is reminderName
    end tell
end run
