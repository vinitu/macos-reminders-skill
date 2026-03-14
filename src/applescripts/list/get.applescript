on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 2 then error "Usage: osascript src/applescripts/list/get.applescript <list-name> <id|name|container|color|emblem> [--format=plain|json]"

    set listName to item 1 of args
    set propertyName to my normalizeProperty(item 2 of args)

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName

        if propertyName is "id" then set valueText to id of targetList
        if propertyName is "name" then set valueText to name of targetList
        if propertyName is "container" then set valueText to name of container of targetList
        if propertyName is "color" then set valueText to my stringify(color of targetList)
        if propertyName is "emblem" then set valueText to my stringify(emblem of targetList)
    end tell

    if valueText is missing value then error "Unsupported property: " & propertyName

    if outputFormat is "json" then
        return "{\"list\":\"" & my jsonEscape(listName) & "\",\"property\":\"" & my jsonEscape(propertyName) & "\",\"value\":\"" & my jsonEscape(valueText) & "\"}"
    end if

    return valueText
end run

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
