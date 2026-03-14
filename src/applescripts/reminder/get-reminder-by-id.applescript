-- Output: full reminder JSON or {id, property, value}. Usage: <id> [property]
-- Finds reminder by id prefix across all lists (case-insensitive).
on run argv
	if (count of argv) is less than 1 then error "Usage: osascript get-reminder-by-id.applescript <id> [property]"
	set idQuery to my trimText(item 1 of argv as text)
	if idQuery is "" then error "Id must not be empty"
	set propertyName to missing value
	if (count of argv) is greater than or equal to 2 then set propertyName to my normalizeProperty(item 2 of argv as text)

	set {foundList, foundReminder} to my findReminderById(idQuery)
	if foundList is missing value then error "Reminder not found for id: " & idQuery

	set listName to name of foundList
	set rec to my reminderRecord(foundReminder, listName)
	if propertyName is missing value then
		return my encodeOne(rec)
	end if

	set propKey to propertyName
	set val to my getPropertyFromRecord(rec, propKey)
	set fullId to id of rec
	return "{\"id\":\"" & my escape(fullId) & "\",\"property\":\"" & my escape(propKey) & "\",\"value\":" & my valueToJson(val) & "}"
end run

on findReminderById(idQuery)
	set idLower to my toLower(idQuery)
	tell application "Reminders"
		set foundList to missing value
		set foundReminder to missing value
		set matchCount to 0
		repeat with L in every list
			repeat with R in every reminder of L
				set rid to id of R as text
				set ridLen to length of rid
				set queryLen to length of idLower
				if ridLen is greater than or equal to queryLen then
					if (my toLower(rid) starts with idLower) then
						set matchCount to matchCount + 1
						if matchCount is greater than 1 then error "Reminder id is ambiguous: " & idQuery
						set foundList to L
						set foundReminder to R
					end if
				end if
			end repeat
		end repeat
	end tell
	return {foundList, foundReminder}
end findReminderById

on reminderRecord(R, listName)
	tell application "Reminders"
		set dueVal to due date of R
		if dueVal is missing value then set dueVal to allday due date of R
		return {id:id of R, name:name of R, list:listName, body:body of R, completed:completed of R, priority:my priorityLabel(priority of R), due_date:dueVal}
	end tell
end reminderRecord

on getPropertyFromRecord(rec, propKey)
	if propKey is "id" then return id of rec
	if propKey is "name" then return name of rec
	if propKey is "list" then return list of rec
	if propKey is "body" then return body of rec
	if propKey is "completed" then return (completed of rec as text = "true")
	if propKey is "priority" then return priority of rec
	if propKey is "due_date" then return due_date of rec
	error "Unsupported property: " & propKey
end getPropertyFromRecord

on valueToJson(val)
	if val is missing value then return "null"
	if (class of val is boolean) then
		if val then return "true"
		return "false"
	end if
	if (class of val is date) then return "\"" & my dateToIso(val) & "\""
	return "\"" & my escape(val as text) & "\""
end valueToJson

on priorityLabel(p)
	if p is missing value then return "none"
	if p is 0 then return "none"
	if p is 1 then return "low"
	if p is 5 then return "medium"
	if p is 9 then return "high"
	return "none"
end priorityLabel

on normalizeProperty(propertyName)
	set normalizedName to propertyName as text
	set AppleScript's text item delimiters to " "
	set normalizedName to text items of normalizedName
	set AppleScript's text item delimiters to "_"
	set normalizedName to normalizedName as text
	set AppleScript's text item delimiters to "-"
	set normalizedName to text items of normalizedName
	set AppleScript's text item delimiters to "_"
	set normalizedName to normalizedName as text
	set AppleScript's text item delimiters to ""
	return normalizedName
end normalizeProperty

on toLower(s)
	set out to ""
	repeat with c in every character of (s as text)
		set cid to id of c
		if cid ≥ 65 and cid ≤ 90 then
			set out to out & (character id (cid + 32))
		else
			set out to out & c
		end if
	end repeat
	return out
end toLower

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

on dateToIso(d)
	if d is missing value then return ""
	set y to year of d
	set m to my monthToNumber(month of d)
	set dday to day of d
	set h to hours of d
	set min to minutes of d
	set s to seconds of d
	return (y as text) & "-" & my pad(m, 2) & "-" & my pad(dday, 2) & "T" & my pad(h, 2) & ":" & my pad(min, 2) & ":" & my pad(s, 2)
end dateToIso

on jsonDate(d)
	if d is missing value then return "null"
	return "\"" & my dateToIso(d) & "\""
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

on replace(src, find, repl)
	set old to AppleScript's text item delimiters
	set AppleScript's text item delimiters to find
	set parts to text items of src
	set AppleScript's text item delimiters to repl
	set out to parts as text
	set AppleScript's text item delimiters to old
	return out
end replace
