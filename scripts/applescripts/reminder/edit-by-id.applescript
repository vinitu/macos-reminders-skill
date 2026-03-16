on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 4 then error "Usage: osascript scripts/applescripts/reminder/edit-by-id.applescript <list-name> <reminder-id> <property> <value> [--format=plain|json]"

    set listName to item 1 of args
    set reminderId to my trimText(item 2 of args)
    set propertyName to my normalizeProperty(item 3 of args)
    set propertyValue to item 4 of args
    if reminderId is "" then error "Reminder id must not be empty"

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if not (exists (first reminder of targetList whose id is reminderId)) then error "Reminder does not exist in list: " & reminderId
    end tell

    set updatedValue to my updatePropertyById(listName, reminderId, propertyName, propertyValue)

    if outputFormat is "json" then
        return "{\"status\":\"updated\",\"list\":\"" & my jsonEscape(listName) & "\",\"id\":\"" & my jsonEscape(reminderId) & "\",\"property\":\"" & my jsonEscape(propertyName) & "\",\"value\":\"" & my jsonEscape(updatedValue) & "\"}"
    end if

    return updatedValue
end run

on updatePropertyById(listName, reminderId, propertyName, propertyValue)
    tell application "Reminders"
        set targetList to first list whose name is listName

        if propertyName is "name" then
            set name of first reminder of targetList whose id is reminderId to propertyValue
            return name of first reminder of targetList whose id is reminderId
        end if

        if propertyName is "body" then
            set body of first reminder of targetList whose id is reminderId to propertyValue
            return my stringify(body of first reminder of targetList whose id is reminderId)
        end if

        if propertyName is "completed" then
            set completed of first reminder of targetList whose id is reminderId to my parseBoolean(propertyValue)
            return completed of first reminder of targetList whose id is reminderId as text
        end if

        if propertyName is "priority" then
            set priority of first reminder of targetList whose id is reminderId to propertyValue as integer
            return priority of first reminder of targetList whose id is reminderId as text
        end if

        if propertyName is "flagged" then
            set flagged of first reminder of targetList whose id is reminderId to my parseBoolean(propertyValue)
            return flagged of first reminder of targetList whose id is reminderId as text
        end if

        if propertyName is "due_date" then
            set due date of first reminder of targetList whose id is reminderId to my parseDateValue(propertyValue)
            return my stringify(due date of first reminder of targetList whose id is reminderId)
        end if

        if propertyName is "allday_due_date" then
            set allday due date of first reminder of targetList whose id is reminderId to my parseDateValue(propertyValue)
            return my stringify(allday due date of first reminder of targetList whose id is reminderId)
        end if

        if propertyName is "remind_me_date" then
            set remind me date of first reminder of targetList whose id is reminderId to my parseDateValue(propertyValue)
            return my stringify(remind me date of first reminder of targetList whose id is reminderId)
        end if

        if propertyName is "completion_date" then
            set completion date of first reminder of targetList whose id is reminderId to my parseDateValue(propertyValue)
            return my stringify(completion date of first reminder of targetList whose id is reminderId)
        end if
    end tell

    error "Unsupported property: " & propertyName
end updatePropertyById

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

on trimText(inputText)
    return do shell script "printf %s " & quoted form of (inputText as text) & " | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'"
end trimText

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
