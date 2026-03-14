on run argv
    set outputFormat to "plain"
    set propertyName to "name"

    if (count of argv) is greater than 0 then
        set firstArg to item 1 of argv as text
        if firstArg starts with "--format=" then
            set outputFormat to text 10 thru -1 of firstArg
        else
            set propertyName to my normalizeProperty(firstArg)
            if (count of argv) is greater than 1 then
                set secondArg to item 2 of argv as text
                if secondArg starts with "--format=" then set outputFormat to text 10 thru -1 of secondArg
            end if
        end if
    end if

    if outputFormat is not "plain" and outputFormat is not "json" then error "Unsupported format: " & outputFormat
    if propertyName is not "name" and propertyName is not "id" then error "Unsupported property: " & propertyName

    tell application "Reminders"
        set targetList to default list
        if propertyName is "id" then
            set valueText to id of targetList
        else
            set valueText to name of targetList
        end if
    end tell

    if outputFormat is "json" then
        return "{\"property\":\"" & my jsonEscape(propertyName) & "\",\"value\":\"" & my jsonEscape(valueText) & "\"}"
    end if

    return valueText
end run

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
