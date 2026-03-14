on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 2 then error "Usage: osascript src/applescripts/account/get.applescript <account-name> <id|name|lists_count|reminders_count> [--format=plain|json]"

    set accountName to item 1 of args
    set propertyName to my normalizeProperty(item 2 of args)

    tell application "Reminders"
        if not (exists account accountName) then error "Account does not exist: " & accountName
        set targetAccount to first account whose name is accountName
    end tell

    if propertyName is "id" then
        set valueText to my readStringValue("id", accountName)
    else if propertyName is "name" then
        set valueText to my readStringValue("name", accountName)
    else if propertyName is "lists_count" then
        set valueText to my countLists(accountName) as text
    else if propertyName is "reminders_count" then
        set valueText to my countReminders(accountName) as text
    else
        error "Unsupported property: " & propertyName
    end if

    if outputFormat is "json" then
        return "{\"account\":\"" & my jsonEscape(accountName) & "\",\"property\":\"" & my jsonEscape(propertyName) & "\",\"value\":\"" & my jsonEscape(valueText) & "\"}"
    end if

    return valueText
end run

on readStringValue(propertyName, accountName)
    tell application "Reminders"
        set targetAccount to first account whose name is accountName
        if propertyName is "id" then return id of targetAccount
        if propertyName is "name" then return name of targetAccount
    end tell

    error "Unsupported property: " & propertyName
end readStringValue

on countLists(accountName)
    tell application "Reminders"
        set targetAccount to first account whose name is accountName
        return count of lists of targetAccount
    end tell
end countLists

on countReminders(accountName)
    set totalCount to 0

    tell application "Reminders"
        set targetAccount to first account whose name is accountName
        repeat with currentList in lists of targetAccount
            set totalCount to totalCount + (count of reminders of currentList)
        end repeat
    end tell

    return totalCount
end countReminders

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
