on run argv
    if (count of argv) is less than 1 then error "Usage: osascript scripts/list/create.applescript <list-name> [color|missing] [emblem|missing]"

    set listName to item 1 of argv
    set colorValue to missing value
    set emblemValue to missing value

    if (count of argv) is greater than or equal to 2 then
        if item 2 of argv is not "missing" then set colorValue to item 2 of argv
    end if

    if (count of argv) is greater than or equal to 3 then
        if item 3 of argv is not "missing" then set emblemValue to item 3 of argv
    end if

    tell application "Reminders"
        if (exists list listName) then return "existing"

        if colorValue is missing value and emblemValue is missing value then
            make new list with properties {name:listName}
        else if emblemValue is missing value then
            make new list with properties {name:listName, color:colorValue}
        else if colorValue is missing value then
            make new list with properties {name:listName, emblem:emblemValue}
        else
            make new list with properties {name:listName, color:colorValue, emblem:emblemValue}
        end if

        return "created"
    end tell
end run
