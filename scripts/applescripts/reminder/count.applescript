on run argv
    set listName to missing value
    if (count of argv) is 1 then set listName to item 1 of argv

    tell application "Reminders"
        if listName is missing value then
            set countValue to count reminders
        else
            if not (exists list listName) then error "List does not exist: " & listName
            set targetList to first list whose name is listName
            set countValue to count reminders of targetList
        end if
    end tell

    if listName is missing value then
        return "{\"count\":" & (countValue as text) & ",\"list\":null}"
    end if
    return "{\"count\":" & (countValue as text) & ",\"list\":\"" & my jsonEscape(listName) & "\"}"
end run

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
