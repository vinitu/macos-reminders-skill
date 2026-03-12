on run argv
    if (count of argv) is less than 2 then error "Usage: osascript scripts/reminder/create.applescript <list-name> <reminder-name> [body]"

    set listName to item 1 of argv
    set reminderName to item 2 of argv
    set reminderBody to ""
    if (count of argv) is greater than or equal to 3 then set reminderBody to item 3 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if reminderBody is "" then
            make new reminder at end of reminders of targetList with properties {name:reminderName}
        else
            make new reminder at end of reminders of targetList with properties {name:reminderName, body:reminderBody}
        end if
        return "created"
    end tell
end run
