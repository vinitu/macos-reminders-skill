on run argv
    if (count of argv) is less than 1 then error "Usage: osascript scripts/applescripts/list/delete.applescript <list-name>"

    set listName to item 1 of argv

    tell application "Reminders"
        if not (exists list listName) then return "already-missing"
        delete list listName
        return "deleted"
    end tell
end run
