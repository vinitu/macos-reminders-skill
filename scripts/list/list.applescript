on run argv
    tell application "Reminders"
        if (count of argv) is 0 then return name of every list

        set accountName to item 1 of argv
        if not (exists account accountName) then error "Account does not exist: " & accountName
        set targetAccount to first account whose name is accountName
        return name of every list of targetAccount
    end tell
end run
