on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    tell application "Reminders"
        if (count of args) is 0 then
            set countValue to count reminders
            set listName to missing value
        else
            set listName to item 1 of args
            if not (exists list listName) then error "List does not exist: " & listName
            set targetList to first list whose name is listName
            set countValue to count reminders of targetList
        end if
    end tell

    if outputFormat is "json" then
        if listName is missing value then
            return "{\"count\":" & (countValue as text) & "}"
        end if
        return "{\"list\":\"" & my jsonEscape(listName) & "\",\"count\":" & (countValue as text) & "}"
    end if

    return countValue as text
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
