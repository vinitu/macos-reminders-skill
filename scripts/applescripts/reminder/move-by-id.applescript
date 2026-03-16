on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 3 then error "Usage: osascript scripts/applescripts/reminder/move-by-id.applescript <source-list-name> <reminder-id> <target-list-name> [--format=plain|json]"

    set sourceListName to item 1 of args
    set reminderId to my trimText(item 2 of args)
    set targetListName to item 3 of args
    if reminderId is "" then error "Reminder id must not be empty"

    tell application "Reminders"
        if not (exists list sourceListName) then error "Source list does not exist: " & sourceListName
        if not (exists list targetListName) then error "Target list does not exist: " & targetListName

        set sourceListObject to first list whose name is sourceListName
        if not (exists (first reminder of sourceListObject whose id is reminderId)) then error "Reminder does not exist in source list: " & reminderId

        set targetListObject to first list whose name is targetListName
        move first reminder of sourceListObject whose id is reminderId to end of reminders of targetListObject
    end tell

    if outputFormat is "json" then
        return "{\"status\":\"moved\",\"id\":\"" & my jsonEscape(reminderId) & "\",\"source_list\":\"" & my jsonEscape(sourceListName) & "\",\"target_list\":\"" & my jsonEscape(targetListName) & "\"}"
    end if

    return reminderId
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
