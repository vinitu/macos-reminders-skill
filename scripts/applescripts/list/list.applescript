-- Output: JSON array of list names. Usage: [account-name]
on run argv
    set args to my stripFormatArg(argv)
    tell application "Reminders"
        if (count of args) is 0 then
            set listNames to name of every list
        else
            set accountName to item 1 of args
            if not (exists account accountName) then error "Account does not exist: " & accountName
            set targetAccount to first account whose name is accountName
            set listNames to name of every list of targetAccount
        end if
    end tell
    set jsonStr to my textListToJson(my normalizeToList(listNames))
    return jsonStr as text
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

on normalizeToList(value)
    if value is missing value then return {}
    if class of value is list then return value
    return {value}
end normalizeToList

on textListToJson(textList)
    set chunks to {}
    repeat with currentValue in textList
        set end of chunks to "\"" & my jsonEscape(currentValue as text) & "\""
    end repeat
    return ("[" & my join(chunks, ",") & "]") as text
end textListToJson

on join(textList, delimiterText)
    if (count of textList) is 0 then return ""
    set currentDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to delimiterText
    set joinedText to textList as text
    set AppleScript's text item delimiters to currentDelimiters
    return joinedText
end join

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
