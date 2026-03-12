on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is greater than 1 then error "Usage: osascript scripts/reminder/overdue.applescript [list-name] [--format=plain|json]"

    set nowDate to current date
    set listName to missing value
    if (count of args) is 1 then set listName to item 1 of args

    set hits to my collectDueBefore(listName, nowDate, true)
    return my outputTextList(hits, outputFormat)
end run

on collectDueBefore(optionalListName, cutoffDate, requireIncomplete)
    set hits to {}

    tell application "Reminders"
        set listCollection to my selectedLists(optionalListName)

        repeat with currentList in listCollection
            set reminderNames to my normalizeToList(name of every reminder of currentList)

            repeat with reminderName in reminderNames
                set currentName to reminderName as text
                if requireIncomplete and ((completed of first reminder of currentList whose name is currentName) is true) then
                    -- skip completed
                else
                    set dueValue to due date of first reminder of currentList whose name is currentName
                    if dueValue is missing value then set dueValue to allday due date of first reminder of currentList whose name is currentName
                    if dueValue is not missing value and dueValue is less than cutoffDate then set end of hits to currentName
                end if
            end repeat
        end repeat
    end tell

    return hits
end collectDueBefore

on selectedLists(optionalListName)
    tell application "Reminders"
        if optionalListName is missing value then return every list
        if not (exists list optionalListName) then error "List does not exist: " & optionalListName
        return {first list whose name is optionalListName}
    end tell
end selectedLists

on normalizeToList(value)
    if value is missing value then return {}
    if class of value is list then return value
    return {value}
end normalizeToList

on outputTextList(textList, outputFormat)
    if outputFormat is "json" then return my textListToJson(textList)
    return textList
end outputTextList

on textListToJson(textList)
    set chunks to {}
    repeat with currentValue in textList
        set end of chunks to "\"" & my jsonEscape(currentValue as text) & "\""
    end repeat
    return "[" & my join(chunks, ",") & "]"
end textListToJson

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
