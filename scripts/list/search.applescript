on run argv
    if (count of argv) is less than 2 then error "Usage: osascript scripts/list/search.applescript <exact-name|id|color|emblem|text> <query> [account-name]"

    set searchMode to item 1 of argv
    set queryText to item 2 of argv

    if searchMode is "exact-name" then
        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set accountName to item 3 of argv
                if not (exists account accountName) then error "Account does not exist: " & accountName
                set targetAccount to first account whose name is accountName
                return name of (every list of targetAccount whose name is queryText)
            end if

            return name of (every list whose name is queryText)
        end tell
    end if

    if searchMode is "id" then
        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set accountName to item 3 of argv
                if not (exists account accountName) then error "Account does not exist: " & accountName
                set targetAccount to first account whose name is accountName
                return name of (every list of targetAccount whose id is queryText)
            end if

            return name of (every list whose id is queryText)
        end tell
    end if

    if searchMode is "color" then
        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set accountName to item 3 of argv
                if not (exists account accountName) then error "Account does not exist: " & accountName
                set targetAccount to first account whose name is accountName
                return name of (every list of targetAccount whose color is queryText)
            end if

            return name of (every list whose color is queryText)
        end tell
    end if

    if searchMode is "emblem" then
        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set accountName to item 3 of argv
                if not (exists account accountName) then error "Account does not exist: " & accountName
                set targetAccount to first account whose name is accountName
                return name of (every list of targetAccount whose emblem is queryText)
            end if

            return name of (every list whose emblem is queryText)
        end tell
    end if

    if searchMode is "text" then
        tell application "Reminders"
            if (count of argv) is greater than or equal to 3 then
                set accountName to item 3 of argv
                if not (exists account accountName) then error "Account does not exist: " & accountName
                set targetAccount to first account whose name is accountName
                return my textSearch(lists of targetAccount, queryText)
            end if

            return my textSearch(lists, queryText)
        end tell
    end if

    error "Unsupported search mode: " & searchMode
end run

on textSearch(listCollection, queryText)
    set hits to {}

    repeat with currentList in listCollection
        set listName to name of currentList
        if listName contains queryText then set end of hits to listName
    end repeat

    return hits
end textSearch
