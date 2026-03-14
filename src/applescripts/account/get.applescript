-- Output: JSON {account, property, value}. Usage: <account-name> <property>
on run argv
    set args to my stripFormatArg(argv)
    if (count of args) is less than 2 then error "Usage: osascript account/get.applescript <account-name> <id|name|lists_count|reminders_count>"

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

    return "{\"account\":\"" & my jsonEscape(accountName) & "\",\"property\":\"" & my jsonEscape(propertyName) & "\",\"value\":\"" & my jsonEscape(valueText) & "\"}"
end run

on stripFormatArg(argv)
    if (count of argv) is 0 then return argv
    set lastArg to item -1 of argv as text
    if lastArg starts with "--format=" then
        if (count of argv) is 1 then return {}
        return items 1 thru -2 of argv
    end if
    return argv
end stripFormatArg

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
