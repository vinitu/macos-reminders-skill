-- Output: JSON array of reminders due today or overdue. Usage: [list-name]
on run argv
	set listName to missing value
	if (count of argv) is 1 then set listName to item 1 of argv
	set startOfToday to current date
	set startOfToday's hours to 0
	set startOfToday's minutes to 0
	set startOfToday's seconds to 0
	set startOfTomorrow to startOfToday + (1 * days)
	set hits to my collectDueBefore(listName, startOfTomorrow)
	return my encodeJson(hits)
end run

on collectDueBefore(optionalListName, cutoff)
	set out to {}
	tell application "Reminders"
		set listCollection to my getLists(optionalListName)
		repeat with L in listCollection
			set listName to name of L
			set rems to (every reminder of L whose completed is false)
			repeat with R in rems
				set dueVal to due date of R
				if dueVal is missing value then set dueVal to allday due date of R
				if dueVal is not missing value and dueVal < cutoff then
					set end of out to my reminderRecord(R, listName, dueVal)
				end if
			end repeat
		end repeat
	end tell
	return out
end collectDueBefore

on getLists(optionalListName)
	tell application "Reminders"
		if optionalListName is missing value then return every list
		if not (exists list optionalListName) then error "List does not exist: " & optionalListName
		return {first list whose name is optionalListName}
	end tell
end getLists

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
	set t to my replace(t, "\\", "\\\\")
	set t to my replace(t, "\"", "\\\"")
	set t to my replace(t, (character id 10), "\\n")
	return t
end escape

on join(lst, delim)
	if (count of lst) is 0 then return ""
	set old to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delim
	set s to lst as text
	set AppleScript's text item delimiters to old
	return s
end join

on replace(src, find, repl)
	set old to AppleScript's text item delimiters
	set AppleScript's text item delimiters to find
	set parts to text items of src
	set AppleScript's text item delimiters to repl
	set out to parts as text
	set AppleScript's text item delimiters to old
	return out
end replace
