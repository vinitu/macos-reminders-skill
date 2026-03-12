on run argv
    tell application "Reminders"
        if (count of argv) is 0 then return count reminders

        set listName to item 1 of argv
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        return count reminders of targetList
    end tell
end run
