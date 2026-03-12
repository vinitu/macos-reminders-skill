on run argv
    if (count of argv) is less than 4 then error "Usage: osascript scripts/reminder/edit.applescript <list-name> <reminder-name> <property> <value>"

    set listName to item 1 of argv
    set reminderName to item 2 of argv
    set propertyName to my normalizeProperty(item 3 of argv)
    set propertyValue to item 4 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if not (exists (first reminder of targetList whose name is reminderName)) then error "Reminder does not exist: " & reminderName

        set targetReminder to first reminder of targetList whose name is reminderName

        if propertyName is "name" then
            set name of targetReminder to propertyValue
            return name of targetReminder
        end if

        if propertyName is "body" then
            set body of targetReminder to propertyValue
            return my stringify(body of targetReminder)
        end if

        if propertyName is "completed" then
            set completed of targetReminder to my parseBoolean(propertyValue)
            return completed of targetReminder as text
        end if

        if propertyName is "priority" then
            set priority of targetReminder to propertyValue as integer
            return priority of targetReminder as text
        end if

        if propertyName is "flagged" then
            set flagged of targetReminder to my parseBoolean(propertyValue)
            return flagged of targetReminder as text
        end if

        if propertyName is "due_date" then
            set due date of targetReminder to my parseDateValue(propertyValue)
            return my stringify(due date of targetReminder)
        end if

        if propertyName is "allday_due_date" then
            set allday due date of targetReminder to my parseDateValue(propertyValue)
            return my stringify(allday due date of targetReminder)
        end if

        if propertyName is "remind_me_date" then
            set remind me date of targetReminder to my parseDateValue(propertyValue)
            return my stringify(remind me date of targetReminder)
        end if

        if propertyName is "completion_date" then
            set completion date of targetReminder to my parseDateValue(propertyValue)
            return my stringify(completion date of targetReminder)
        end if

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

on parseBoolean(valueText)
    if valueText is "true" then return true
    if valueText is "false" then return false
    error "Boolean value must be true or false"
end parseBoolean

on parseDateValue(valueText)
    if valueText is "missing" then return missing value
    return date valueText
end parseDateValue

on stringify(value)
    if value is missing value then return "missing"
    return value as text
end stringify
