on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 3 then error "Usage: osascript scripts/applescripts/reminder/get.applescript <list-name> <reminder-name> <property> [--format=plain|json]"

    set listName to item 1 of args
    set reminderName to item 2 of args
    set propertyName to my normalizeProperty(item 3 of args)

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if not (exists (first reminder of targetList whose name is reminderName)) then error "Reminder does not exist: " & reminderName
    end tell

    set valueText to my readPropertyValue(listName, reminderName, propertyName)

    if outputFormat is "json" then
        return "{\"list\":\"" & my jsonEscape(listName) & "\",\"reminder\":\"" & my jsonEscape(reminderName) & "\",\"property\":\"" & my jsonEscape(propertyName) & "\",\"value\":\"" & my jsonEscape(valueText) & "\"}"
    end if

    return valueText
end run

on readPropertyValue(listName, reminderName, propertyName)
    tell application "Reminders"
        set targetList to first list whose name is listName

        if propertyName is "name" then return name of first reminder of targetList whose name is reminderName
        if propertyName is "id" then return id of first reminder of targetList whose name is reminderName
        if propertyName is "container" then return name of container of first reminder of targetList whose name is reminderName
        if propertyName is "creation_date" then return my stringify(creation date of first reminder of targetList whose name is reminderName)
        if propertyName is "modification_date" then return my stringify(modification date of first reminder of targetList whose name is reminderName)
        if propertyName is "body" then return my stringify(body of first reminder of targetList whose name is reminderName)
        if propertyName is "completed" then return completed of first reminder of targetList whose name is reminderName as text
        if propertyName is "completion_date" then return my stringify(completion date of first reminder of targetList whose name is reminderName)
        if propertyName is "due_date" then return my stringify(due date of first reminder of targetList whose name is reminderName)
        if propertyName is "allday_due_date" then return my stringify(allday due date of first reminder of targetList whose name is reminderName)
        if propertyName is "remind_me_date" then return my stringify(remind me date of first reminder of targetList whose name is reminderName)
        if propertyName is "priority" then return priority of first reminder of targetList whose name is reminderName as text
        if propertyName is "flagged" then return flagged of first reminder of targetList whose name is reminderName as text
    end tell

    error "Unsupported property: " & propertyName
end readPropertyValue

on parseArgs(argv)
    set outputFormat to "plain"
    set args to argv

    if (count of args) is greater than 0 then
        set lastArg to item -1 of args as text
        if lastArg starts with "--format=" then
            set outputFormat to text 10 thru -1 of lastArg
            if outputFormat is not "plain" and outputFormat is not "json" then error "Unsupported format: " & outputFormat
            if (count of args) is 1 then
                set args to {}
            else
                set args to items 1 thru -2 of args
            end if
        end if
    end if

    return {args, outputFormat}
end parseArgs

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

on jsonEscape(valueText)
    set escaped to my replaceText("\\", "\\\\", valueText as text)
    set escaped to my replaceText("\"", "\\\"", escaped)
    set escaped to my replaceText(linefeed, "\\n", escaped)
    return escaped
end jsonEscape

on replaceText(findText, replacementText, sourceText)
    set AppleScript's text item delimiters to findText
    set textParts to text items of sourceText
    set AppleScript's text item delimiters to replacementText
    set replacedText to textParts as text
    set AppleScript's text item delimiters to ""
    return replacedText
end replaceText
