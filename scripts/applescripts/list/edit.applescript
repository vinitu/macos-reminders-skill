on run argv
    if (count of argv) is less than 3 then error "Usage: osascript scripts/applescripts/list/edit.applescript <list-name> <name|color|emblem> <value>"

    set listName to item 1 of argv
    set propertyName to my normalizeProperty(item 2 of argv)
    set propertyValue to item 3 of argv

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName

        if propertyName is "name" then
            set name of targetList to propertyValue
            return name of targetList
        end if

        if propertyName is "color" then
            set color of targetList to propertyValue
            return color of targetList as text
        end if

        if propertyName is "emblem" then
            set emblem of targetList to propertyValue
            return emblem of targetList as text
        end if

        error "Unsupported property: " & propertyName
    end tell
end run

on normalizeProperty(propertyName)
    set normalizedName to propertyName as text
    set AppleScript's text item delimiters to "-"
    set normalizedName to text items of normalizedName
    set AppleScript's text item delimiters to "_"
    set normalizedName to normalizedName as text
    set AppleScript's text item delimiters to ""
    return normalizedName
end normalizeProperty
