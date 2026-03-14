-- Output: JSON (created reminder in AGENTS.md shape).
-- Usage: <list-name> <reminder-name> [body] [due-date-string] [priority-word]
-- body, due-date-string, priority can be empty string to omit.
on run argv
    if (count of argv) is less than 2 then error "Usage: osascript create.applescript <list-name> <reminder-name> [body] [due] [priority]"

    set listName to item 1 of argv
    set reminderName to item 2 of argv
    set reminderBody to ""
    if (count of argv) is greater than or equal to 3 then set reminderBody to my trimText(item 3 of argv)
    set dueStr to ""
    if (count of argv) is greater than or equal to 4 then set dueStr to my trimText(item 4 of argv)
    set priorityStr to ""
    if (count of argv) is greater than or equal to 5 then set priorityStr to my trimText(item 5 of argv)

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName
        if reminderBody is "" then
            set newReminder to (make new reminder at end of reminders of targetList with properties {name:reminderName})
        else
            set newReminder to (make new reminder at end of reminders of targetList with properties {name:reminderName, body:reminderBody})
        end if
        if dueStr is not "" then
            try
                set dueDate to date dueStr
                set due date of newReminder to dueDate
            end try
        end if
        if priorityStr is not "" then
            set priority of newReminder to my priorityFromLabel(priorityStr)
        end if
        set dueVal to due date of newReminder
        if dueVal is missing value then set dueVal to allday due date of newReminder
        set rec to {id:id of newReminder, name:name of newReminder, list:listName, body:body of newReminder, completed:completed of newReminder, priority:my priorityLabel(priority of newReminder), due_date:dueVal}
    end tell
    return my encodeOne(rec)
end run

on trimText(inputText)
    set textValue to inputText as text
    set whitespaceChars to {space, tab, return, linefeed}
    repeat while (count of textValue) > 0 and (character 1 of textValue) is in whitespaceChars
        if (count of characters of textValue) is 1 then return ""
        set textValue to text 2 thru -1 of textValue
    end repeat
    repeat while (count of textValue) > 0 and (character -1 of textValue) is in whitespaceChars
        if (count of characters of textValue) is 1 then return ""
        set textValue to text 1 thru -2 of textValue
    end repeat
    return textValue
end trimText

on priorityFromLabel(label)
    set lowerLabel to label as text
    if lowerLabel is "none" then return 0
    if lowerLabel is "low" then return 1
    if lowerLabel is "medium" then return 5
    if lowerLabel is "high" then return 9
    return 0
end priorityFromLabel

on priorityLabel(p)
    if p is missing value then return "none"
    if p is 0 then return "none"
    if p is 1 then return "low"
    if p is 5 then return "medium"
    if p is 9 then return "high"
    return "none"
end priorityLabel

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

on replaceText(findText, replacementText, sourceText)
    set AppleScript's text item delimiters to findText
    set parts to text items of sourceText
    set AppleScript's text item delimiters to replacementText
    set out to parts as text
    set AppleScript's text item delimiters to ""
    return out
end replaceText
