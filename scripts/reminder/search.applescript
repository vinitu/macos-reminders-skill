on run argv
    if (count of argv) is less than 1 then error "Usage: osascript scripts/reminder/search.applescript <exact-name|id|incomplete|flagged|priority|has-due-date|text> [args]"

    set searchMode to item 1 of argv

    if searchMode is "exact-name" then
        if (count of argv) is less than 3 then error "Usage: osascript scripts/reminder/search.applescript exact-name <list-name> <reminder-name>"
        set listName to item 2 of argv
        set reminderName to item 3 of argv

        tell application "Reminders"
            if not (exists list listName) then error "List does not exist: " & listName
            set targetList to first list whose name is listName
            return name of (every reminder of targetList whose name is reminderName)
        end tell
    end if

    if searchMode is "id" then
        if (count of argv) is less than 2 then error "Usage: osascript scripts/reminder/search.applescript id <reminder-id>"
        set reminderId to item 2 of argv

        tell application "Reminders"
            return name of (every reminder whose id is reminderId)
        end tell
    end if

    if searchMode is "incomplete" then
        tell application "Reminders"
            return name of my remindersForBooleanSearch(argv, false)
        end tell
    end if

    if searchMode is "flagged" then
        tell application "Reminders"
            return name of my flaggedReminders(argv)
        end tell
    end if

    if searchMode is "priority" then
        if (count of argv) is less than 2 then error "Usage: osascript scripts/reminder/search.applescript priority <priority> [list-name]"
        set priorityValue to item 2 of argv as integer

        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set listName to item 3 of argv
                if not (exists list listName) then error "List does not exist: " & listName
                set targetList to first list whose name is listName
                return name of (every reminder of targetList whose priority is priorityValue)
            end if

            return name of (every reminder whose priority is priorityValue)
        end tell
    end if

    if searchMode is "has-due-date" then
        tell application "Reminders"
            if (count of argv) is greater than or equal to 2 then
                set listName to item 2 of argv
                if not (exists list listName) then error "List does not exist: " & listName
                set targetList to first list whose name is listName
                return name of (every reminder of targetList whose due date is not missing value)
            end if

            return name of (every reminder whose due date is not missing value)
        end tell
    end if

    if searchMode is "text" then
        if (count of argv) is less than 2 then error "Usage: osascript scripts/reminder/search.applescript text <query> [list-name]"
        set queryText to item 2 of argv

        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set listName to item 3 of argv
                if not (exists list listName) then error "List does not exist: " & listName
                set targetList to first list whose name is listName
                return my textSearch(reminders of targetList, queryText)
            end if

            return my textSearch(reminders, queryText)
        end tell
    end if

    error "Unsupported search mode: " & searchMode
end run

on remindersForBooleanSearch(argv, completedValue)
    if (count of argv) is greater than or equal to 2 then
        set listName to item 2 of argv
        tell application "Reminders"
            if not (exists list listName) then error "List does not exist: " & listName
            set targetList to first list whose name is listName
            return every reminder of targetList whose completed is completedValue
        end tell
    end if

    tell application "Reminders"
        return every reminder whose completed is completedValue
    end tell
end remindersForBooleanSearch

on flaggedReminders(argv)
    if (count of argv) is greater than or equal to 2 then
        set listName to item 2 of argv
        tell application "Reminders"
            if not (exists list listName) then error "List does not exist: " & listName
            set targetList to first list whose name is listName
            return every reminder of targetList whose flagged is true
        end tell
    end if

    tell application "Reminders"
        return every reminder whose flagged is true
    end tell
end flaggedReminders

on textSearch(reminderCollection, queryText)
    set hits to {}

    repeat with currentReminder in reminderCollection
        set reminderName to name of currentReminder
        set reminderBody to body of currentReminder

        if reminderName contains queryText then
            set end of hits to reminderName
        else if reminderBody is not missing value and reminderBody contains queryText then
            set end of hits to reminderName
        end if
    end repeat

    return hits
end textSearch
