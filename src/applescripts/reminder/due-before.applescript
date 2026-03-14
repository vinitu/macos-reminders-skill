-- Output: JSON array of reminders due before the given date. Usage: <date> [list-name]
on run argv
    set args to my stripFormatArg(argv)
    if (count of args) is less than 1 then error "Usage: osascript due-before.applescript <date> [list-name]"

    set cutoffDate to date (item 1 of args)
    set listName to missing value
    if (count of args) is greater than or equal to 2 then set listName to item 2 of args

    set hits to my collectDueBefore(listName, cutoffDate, true)
    return my encodeJson(hits)
end run

on collectDueBefore(optionalListName, cutoffDate, requireIncomplete)
    set out to {}

    tell application "Reminders"
        set listCollection to my selectedLists(optionalListName)
        repeat with L in listCollection
            set listName to name of L
            set rems to (every reminder of L whose completed is false)
            repeat with R in rems
                set dueVal to due date of R
                if dueVal is missing value then set dueVal to allday due date of R
                if dueVal is not missing value and dueVal < cutoffDate then
                    set end of out to my reminderRecord(R, listName, dueVal)
                end if
            end repeat
        end repeat
    end tell

    return out
end collectDueBefore

on reminderRecord(R, listName, dueVal)
    tell application "Reminders"
        return {id:id of R, name:name of R, list:listName, body:body of R, completed:completed of R, priority:my priorityLabel(priority of R), due_date:dueVal}
    end tell
end reminderRecord

on priorityLabel(p)
    if p is missing value then return "none"
    if p is 0 then return "none"
    if p is 1 then return "low"
    if p is 5 then return "medium"
    if p is 9 then return "high"
    return "none"
end priorityLabel

on isDueBeforeCutoff(dueValue, cutoffDate)
    if dueValue is missing value then return false
    if dueValue is greater than or equal to cutoffDate then return false
    return true
end isDueBeforeCutoff

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

on stripFormatArg(argv)
    if (count of argv) is 0 then return argv
    set lastArg to item -1 of argv as text
    if lastArg starts with "--format=" then
        if (count of argv) is 1 then return {}
        return items 1 thru -2 of argv
    end if
    return argv
end stripFormatArg

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
