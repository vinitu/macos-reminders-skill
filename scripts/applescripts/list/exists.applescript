on run argv
    if (count of argv) is less than 1 then error "Usage: osascript src/applescripts/list/exists.applescript <list-name>"

    set listName to item 1 of argv

    tell application "Reminders"
        return (exists list listName)
    end tell
end run
