on run argv
    if (count of argv) is less than 2 then error "Usage: osascript scripts/list/get.applescript <list-name> <id|name|container|color|emblem>"

    set listName to item 1 of argv
    set propertyName to my normalizeProperty(item 2 of argv)

    tell application "Reminders"
        if not (exists list listName) then error "List does not exist: " & listName
        set targetList to first list whose name is listName

        if propertyName is "id" then return id of targetList
        if propertyName is "name" then return name of targetList
        if propertyName is "container" then return name of container of targetList
        if propertyName is "color" then return my stringify(color of targetList)
        if propertyName is "emblem" then return my stringify(emblem of targetList)

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

on stringify(value)
    if value is missing value then return "missing"
    return value as text
end stringify
