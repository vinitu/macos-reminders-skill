on run argv
    if (count of argv) is less than 3 then error "Usage: osascript scripts/applescripts/reminder/move.applescript <source-list> <reminder-name> <target-list>"

    set sourceListName to item 1 of argv
    set reminderName to item 2 of argv
    set targetListName to item 3 of argv

    tell application "Reminders"
        if not (exists list sourceListName) then error "Source list does not exist: " & sourceListName
        if not (exists list targetListName) then error "Target list does not exist: " & targetListName
        set sourceListObject to first list whose name is sourceListName
        if not (exists (first reminder of sourceListObject whose name is reminderName)) then error "Reminder does not exist: " & reminderName
        set reminderId to id of first reminder of sourceListObject whose name is reminderName
    end tell

    tell application "Reminders"
        set sourceListObject to first list whose name is sourceListName
        set targetListObject to first list whose name is targetListName
        move first reminder of sourceListObject whose id is reminderId to end of reminders of targetListObject
    end tell

    return reminderId
end run
