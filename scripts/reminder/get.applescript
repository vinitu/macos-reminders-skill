on run argv
    if (count of argv) is less than 3 then error "Usage: osascript scripts/reminder/get.applescript <list-name> <reminder-name> <property>"

    set listName to item 1 of argv
    set reminderName to item 2 of argv
    set propertyName to my normalizeProperty(item 3 of argv)

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if not (exists (first reminder of targetList whose name is reminderName)) then error "Reminder does not exist: " & reminderName

        set targetReminder to first reminder of targetList whose name is reminderName

        if propertyName is "name" then return name of targetReminder
        if propertyName is "id" then return id of targetReminder
        if propertyName is "container" then return name of container of targetReminder
        if propertyName is "creation_date" then return my stringify(creation date of targetReminder)
        if propertyName is "modification_date" then return my stringify(modification date of targetReminder)
        if propertyName is "body" then return my stringify(body of targetReminder)
        if propertyName is "completed" then return completed of targetReminder as text
        if propertyName is "completion_date" then return my stringify(completion date of targetReminder)
        if propertyName is "due_date" then return my stringify(due date of targetReminder)
        if propertyName is "allday_due_date" then return my stringify(allday due date of targetReminder)
        if propertyName is "remind_me_date" then return my stringify(remind me date of targetReminder)
        if propertyName is "priority" then return priority of targetReminder as text
        if propertyName is "flagged" then return flagged of targetReminder as text

        error "Unsupported property: " & propertyName
    end tell
end run

on normalizeProperty(propertyName)
    set normalizedName to propertyName as text
    set AppleScript's text item delimiters to " "
    set normalizedName to text items of normalizedName
    set AppleScript's text item delimiters to "_"
    set normalizedName to normalizedName as text
    set AppleScript's text item delimiters to "-"
    set normalizedName to text items of normalizedName
    set AppleScript's text item delimiters to "_"
    set normalizedName to normalizedName as text
    set AppleScript's text item delimiters to ""
    return normalizedName
end normalizeProperty

on stringify(value)
    if value is missing value then return "missing"
    return value as text
end stringify
