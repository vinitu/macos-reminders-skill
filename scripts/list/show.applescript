on run argv
    if (count of argv) is less than 1 then error "Usage: osascript scripts/list/show.applescript <list-name>"

    set listName to item 1 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        return id of (show first list whose name is listName)
    end tell
end run
