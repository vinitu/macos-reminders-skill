-- Output: JSON array of full reminder objects (id, name, list, body, completed, priority, due_date).
-- Usage: <exact-name|id|incomplete|flagged|priority|has-due-date|text> [args]
on run argv
    set args to my stripFormatArg(argv)
    if (count of args) is less than 1 then error "Usage: osascript search.applescript <exact-name|id|incomplete|priority|has-due-date|text> [args]"

    set searchMode to item 1 of args

    if searchMode is "exact-name" then
        if (count of args) is less than 3 then error "Usage: osascript search.applescript exact-name <list-name> <reminder-name>"
        set listName to item 2 of args
        set reminderNameQuery to my trimText(item 3 of args)
        if reminderNameQuery is "" then error "Reminder name query must not be empty"
        set hits to my collectExactName(listName, reminderNameQuery)
        return my encodeJson(hits)
    end if

    if searchMode is "id" then
        if (count of args) is less than 2 then error "Usage: osascript search.applescript id <reminder-id>"
        set reminderIdQuery to my trimText(item 2 of args)
        if reminderIdQuery is "" then error "Reminder id query must not be empty"
        set hits to my collectById(reminderIdQuery)
        return my encodeJson(hits)
    end if

    if searchMode is "incomplete" then
        set listName to missing value
        if (count of args) is greater than or equal to 2 then set listName to item 2 of args
        set hits to my collectByProperty(listName, "completed", false)
        return my encodeJson(hits)
    end if

    if searchMode is "flagged" then
        set listName to missing value
        if (count of args) is greater than or equal to 2 then set listName to item 2 of args
        set hits to my collectByProperty(listName, "flagged", true)
        return my encodeJson(hits)
    end if

    if searchMode is "priority" then
        if (count of args) is less than 2 then error "Usage: osascript search.applescript priority <priority> [list-name]"
        set priorityValue to item 2 of args as integer
        set listName to missing value
        if (count of args) is greater than or equal to 3 then set listName to item 3 of args
        set hits to my collectByPriority(listName, priorityValue)
        return my encodeJson(hits)
    end if

    if searchMode is "has-due-date" then
        set listName to missing value
        if (count of args) is greater than or equal to 2 then set listName to item 2 of args
        set hits to my collectWithDueDate(listName)
        return my encodeJson(hits)
    end if

    if searchMode is "text" then
        if (count of args) is less than 2 then error "Usage: osascript search.applescript text <query> [list-name]"
        set queryText to my trimText(item 2 of args)
        if queryText is "" then error "Text query must not be empty"
        set listName to missing value
        if (count of args) is greater than or equal to 3 then set listName to item 3 of args
        set hits to my collectByText(listName, queryText)
        return my encodeJson(hits)
    end if

    error "Unsupported search mode: " & searchMode
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

on reminderRecordFromReminder(R, listName)
    tell application "Reminders"
        set dueVal to due date of R
        if dueVal is missing value then set dueVal to allday due date of R
        return {id:id of R, name:name of R, list:listName, body:body of R, completed:completed of R, priority:my priorityLabel(priority of R), due_date:dueVal}
    end tell
end reminderRecordFromReminder

on collectExactName(listName, reminderNameQuery)
    set out to {}
    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        set rems to (every reminder of targetList whose name is reminderNameQuery)
        repeat with R in rems
            set end of out to my reminderRecordFromReminder(R, listName)
        end repeat
    end tell
    return out
end collectExactName

on collectById(reminderIdQuery)
    set out to {}
    tell application "Reminders"
        repeat with L in every list
            set listName to name of L
            repeat with R in (every reminder of L)
                set rid to id of R as text
                if rid is reminderIdQuery or (rid starts with reminderIdQuery) then
                    set end of out to my reminderRecordFromReminder(R, listName)
                end if
            end repeat
        end repeat
    end tell
    return out
end collectById

on collectByProperty(optionalListName, propertyName, propertyValue)
    set out to {}
    tell application "Reminders"
        set listCollection to my selectedLists(optionalListName)
        repeat with L in listCollection
            set listName to name of L
            set rems to {}
            if propertyName is "completed" then set rems to (every reminder of L whose completed is propertyValue)
            if propertyName is "flagged" then set rems to (every reminder of L whose flagged is propertyValue)
            repeat with R in rems
                set end of out to my reminderRecordFromReminder(R, listName)
            end repeat
        end repeat
    end tell
    return out
end collectByProperty

on collectByPriority(optionalListName, priorityValue)
    set out to {}
    tell application "Reminders"
        set listCollection to my selectedLists(optionalListName)
        repeat with L in listCollection
            set listName to name of L
            set rems to (every reminder of L whose priority is priorityValue)
            repeat with R in rems
                set end of out to my reminderRecordFromReminder(R, listName)
            end repeat
        end repeat
    end tell
    return out
end collectByPriority

on collectWithDueDate(optionalListName)
    set out to {}
    tell application "Reminders"
        set listCollection to my selectedLists(optionalListName)
        repeat with L in listCollection
            set listName to name of L
            set rems to (every reminder of L)
            repeat with R in rems
                set dueVal to due date of R
                if dueVal is missing value then set dueVal to allday due date of R
                if dueVal is not missing value then
                    set end of out to my reminderRecordFromReminder(R, listName)
                end if
            end repeat
        end repeat
    end tell
    return out
end collectWithDueDate

on collectByText(optionalListName, queryText)
    set out to {}
    tell application "Reminders"
        set listCollection to my selectedLists(optionalListName)
        repeat with L in listCollection
            set listName to name of L
            set rems to (every reminder of L)
            repeat with R in rems
                set matchName to (name of R as text) contains queryText
                set matchBody to (body of R as text) contains queryText
                if matchName or matchBody then
                    set end of out to my reminderRecordFromReminder(R, listName)
                end if
            end repeat
        end repeat
    end tell
    return out
end collectByText

on selectedLists(optionalListName)
    tell application "Reminders"
        if optionalListName is missing value then return every list
        if not (exists list optionalListName) then error "List does not exist: " & optionalListName
        return {first list whose name is optionalListName}
    end tell
end selectedLists

on priorityLabel(p)
    if p is missing value then return "none"
    if p is 0 then return "none"
    if p is 1 then return "low"
    if p is 5 then return "medium"
    if p is 9 then return "high"
    return "none"
end priorityLabel

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

on encodeJson(recList)
    set parts to {}
    repeat with rec in recList
        set end of parts to my encodeOne(rec)
    end repeat
    return "[" & my join(parts, ",") & "]"
end encodeJson

on encodeOne(rec)
    set bid to my jsonStr(id of rec)
    set bname to my jsonStr(name of rec)
    set blist to my jsonStr(list of rec)
    set bbody to my jsonNull(body of rec)
    set bcompleted to (completed of rec as text = "true")
    set bpriority to my jsonStr(priority of rec)
    set bdue to my jsonDate(due_date of rec)
    return "{\"id\":" & bid & ",\"name\":" & bname & ",\"list\":" & blist & ",\"body\":" & bbody & ",\"completed\":" & bcompleted & ",\"priority\":" & bpriority & ",\"due_date\":" & bdue & "}"
end encodeOne

on jsonStr(val)
    if val is missing value then return "\"\""
    return "\"" & my escape(val as text) & "\""
end jsonStr

on jsonNull(val)
    if val is missing value or (val as text) is "" then return "null"
    return "\"" & my escape(val as text) & "\""
end jsonNull

on jsonDate(d)
    if d is missing value then return "null"
    set y to year of d
    set m to my monthToNumber(month of d)
    set dday to day of d
    set h to hours of d
    set min to minutes of d
    set s to seconds of d
    set t to (y as text) & "-" & my pad(m, 2) & "-" & my pad(dday, 2) & "T" & my pad(h, 2) & ":" & my pad(min, 2) & ":" & my pad(s, 2)
    return "\"" & t & "\""
end jsonDate

on monthToNumber(monthConst)
    set months to {January, February, March, April, May, June, July, August, September, October, November, December}
    repeat with i from 1 to 12
        if item i of months is monthConst then return i
    end repeat
    return 1
end monthToNumber

on pad(n, w)
    set t to n as text
    repeat while (length of t) < w
        set t to "0" & t
    end repeat
    return t
end pad

on escape(t)
    set t to my replaceText("\\", "\\\\", t as text)
    set t to my replaceText("\"", "\\\"", t)
    set t to my replaceText(linefeed, "\\n", t)
    return t
end escape

on join(textList, delimiterText)
    if (count of textList) is 0 then return ""
    set currentDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to delimiterText
    set joinedText to textList as text
    set AppleScript's text item delimiters to currentDelimiters
    return joinedText
end join

on replaceText(findText, replacementText, sourceText)
    set AppleScript's text item delimiters to findText
    set textParts to text items of sourceText
    set AppleScript's text item delimiters to replacementText
    set replacedText to textParts as text
    set AppleScript's text item delimiters to ""
    return replacedText
end replaceText
