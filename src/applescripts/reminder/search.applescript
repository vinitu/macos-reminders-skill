on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 1 then error "Usage: osascript src/applescripts/reminder/search.applescript <exact-name|id|incomplete|flagged|priority|has-due-date|text> [args] [--format=plain|json]"

    set searchMode to item 1 of args

    if searchMode is "exact-name" then
        if (count of args) is less than 3 then error "Usage: osascript src/applescripts/reminder/search.applescript exact-name <list-name> <reminder-name> [--format=plain|json]"
        set listName to item 2 of args
        set reminderNameQuery to my trimText(item 3 of args)
        if reminderNameQuery is "" then error "Reminder name query must not be empty"

        tell application "Reminders"
            if not (exists list listName) then error "List does not exist: " & listName
            set targetList to first list whose name is listName
            set hits to name of (every reminder of targetList whose name is reminderNameQuery)
        end tell

        return my outputTextList(my normalizeToList(hits), outputFormat)
    end if

    if searchMode is "id" then
        if (count of args) is less than 2 then error "Usage: osascript src/applescripts/reminder/search.applescript id <reminder-id> [--format=plain|json]"
        set reminderIdQuery to my trimText(item 2 of args)
        if reminderIdQuery is "" then error "Reminder id query must not be empty"

        return my outputTextList(my remindersById(reminderIdQuery), outputFormat)
    end if

    if searchMode is "incomplete" then
        set listName to missing value
        if (count of args) is greater than or equal to 2 then set listName to item 2 of args
        set hits to my remindersByProperty(listName, "completed", false)
        return my outputTextList(hits, outputFormat)
    end if

    if searchMode is "flagged" then
        set listName to missing value
        if (count of args) is greater than or equal to 2 then set listName to item 2 of args
        set hits to my remindersByProperty(listName, "flagged", true)
        return my outputTextList(hits, outputFormat)
    end if

    if searchMode is "priority" then
        if (count of args) is less than 2 then error "Usage: osascript src/applescripts/reminder/search.applescript priority <priority> [list-name] [--format=plain|json]"
        set priorityValue to item 2 of args as integer
        set listName to missing value
        if (count of args) is greater than or equal to 3 then set listName to item 3 of args
        set hits to my remindersByPriority(listName, priorityValue)
        return my outputTextList(hits, outputFormat)
    end if

    if searchMode is "has-due-date" then
        set listName to missing value
        if (count of args) is greater than or equal to 2 then set listName to item 2 of args
        set hits to my remindersWithAnyDueDate(listName)
        return my outputTextList(hits, outputFormat)
    end if

    if searchMode is "text" then
        if (count of args) is less than 2 then error "Usage: osascript src/applescripts/reminder/search.applescript text <query> [list-name] [--format=plain|json]"
        set queryText to my trimText(item 2 of args)
        if queryText is "" then error "Text query must not be empty"

        set listName to missing value
        if (count of args) is greater than or equal to 3 then set listName to item 3 of args
        set hits to my remindersByText(listName, queryText)
        return my outputTextList(hits, outputFormat)
    end if

    error "Unsupported search mode: " & searchMode
end run

on remindersByProperty(optionalListName, propertyName, propertyValue)
    tell application "Reminders"
        if optionalListName is missing value then
            if propertyName is "completed" then return my normalizeToList(name of (every reminder whose completed is propertyValue))
            if propertyName is "flagged" then return my normalizeToList(name of (every reminder whose flagged is propertyValue))
        end if

        if not (exists list optionalListName) then error "List does not exist: " & optionalListName
        set targetList to first list whose name is optionalListName
        if propertyName is "completed" then return my normalizeToList(name of (every reminder of targetList whose completed is propertyValue))
        if propertyName is "flagged" then return my normalizeToList(name of (every reminder of targetList whose flagged is propertyValue))
    end tell

    return {}
end remindersByProperty

on remindersById(reminderIdQuery)
    set hits to {}

    tell application "Reminders"
        repeat with currentList in every list
            set listHits to my normalizeToList(name of (every reminder of currentList whose id is reminderIdQuery))
            repeat with currentValue in listHits
                if (hits does not contain (currentValue as text)) then set end of hits to currentValue as text
            end repeat
        end repeat
    end tell

    return hits
end remindersById

on remindersByPriority(optionalListName, priorityValue)
    tell application "Reminders"
        if optionalListName is missing value then return my normalizeToList(name of (every reminder whose priority is priorityValue))
        if not (exists list optionalListName) then error "List does not exist: " & optionalListName
        set targetList to first list whose name is optionalListName
        return my normalizeToList(name of (every reminder of targetList whose priority is priorityValue))
    end tell
end remindersByPriority

on remindersWithAnyDueDate(optionalListName)
    tell application "Reminders"
        if optionalListName is missing value then
            set dueByDate to my normalizeToList(name of (every reminder whose due date is not missing value))
            set dueByAllDay to my normalizeToList(name of (every reminder whose allday due date is not missing value))
            return my uniqueConcat(dueByDate, dueByAllDay)
        end if

        if not (exists list optionalListName) then error "List does not exist: " & optionalListName
        set targetList to first list whose name is optionalListName
        set dueByDate to my normalizeToList(name of (every reminder of targetList whose due date is not missing value))
        set dueByAllDay to my normalizeToList(name of (every reminder of targetList whose allday due date is not missing value))
        return my uniqueConcat(dueByDate, dueByAllDay)
    end tell
end remindersWithAnyDueDate

on remindersByText(optionalListName, queryText)
    tell application "Reminders"
        if optionalListName is missing value then
            set byName to my normalizeToList(name of (every reminder whose name contains queryText))
            set byBody to my normalizeToList(name of (every reminder whose body contains queryText))
            return my uniqueConcat(byName, byBody)
        end if

        if not (exists list optionalListName) then error "List does not exist: " & optionalListName
        set targetList to first list whose name is optionalListName
        set byName to my normalizeToList(name of (every reminder of targetList whose name contains queryText))
        set byBody to my normalizeToList(name of (every reminder of targetList whose body contains queryText))
        return my uniqueConcat(byName, byBody)
    end tell
end remindersByText

on normalizeToList(value)
    if value is missing value then return {}
    if class of value is list then return value
    return {value}
end normalizeToList

on uniqueConcat(listA, listB)
    set outList to {}

    repeat with currentValue in listA
        if (outList does not contain (currentValue as text)) then set end of outList to currentValue as text
    end repeat

    repeat with currentValue in listB
        if (outList does not contain (currentValue as text)) then set end of outList to currentValue as text
    end repeat

    return outList
end uniqueConcat

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

on trimText(inputText)
    set textValue to inputText as text
    set whitespaceChars to {space, tab, return, linefeed}

    repeat while textValue is not "" and (character 1 of textValue) is in whitespaceChars
        if (count of characters of textValue) is 1 then return ""
        set textValue to text 2 thru -1 of textValue
    end repeat

    repeat while textValue is not "" and (character -1 of textValue) is in whitespaceChars
        if (count of characters of textValue) is 1 then return ""
        set textValue to text 1 thru -2 of textValue
    end repeat

    return textValue
end trimText

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
