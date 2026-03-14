-- Output: JSON array of account names. Usage: (no args)
on run argv
    tell application "Reminders"
        set accountNames to name of every account
    end tell
    set jsonStr to my textListToJson(my normalizeToList(accountNames))
    return jsonStr as text
end run

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
