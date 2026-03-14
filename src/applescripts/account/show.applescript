on run argv
    if (count of argv) is less than 1 then error "Usage: osascript src/applescripts/account/show.applescript <account-name>"

    set accountName to item 1 of argv

    tell application "Reminders"
        if not (exists account accountName) then error "Account does not exist: " & accountName
        return id of (show first account whose name is accountName)
    end tell
end run
