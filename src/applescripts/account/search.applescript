on run argv
    set parsedArgs to my parseArgs(argv)
    set args to item 1 of parsedArgs
    set outputFormat to item 2 of parsedArgs

    if (count of args) is less than 2 then error "Usage: osascript src/applescripts/account/search.applescript <exact-name|id|text> <query> [--format=plain|json]"

    set searchMode to item 1 of args
    set queryText to my trimText(item 2 of args)
    if queryText is "" then error "Query must not be empty"

    tell application "Reminders"
        set accountCollection to every account
    end tell

    if searchMode is "exact-name" then
        return my outputTextList(my findByProperty(accountCollection, "name", queryText), outputFormat)
    end if

    if searchMode is "id" then
        return my outputTextList(my findByProperty(accountCollection, "id", queryText), outputFormat)
    end if

    if searchMode is "text" then
        return my outputTextList(my textSearch(accountCollection, queryText), outputFormat)
    end if

    error "Unsupported search mode: " & searchMode
end run

on findByProperty(accountCollection, propertyName, queryText)
    set hits to {}

    tell application "Reminders"
        repeat with currentAccount in accountCollection
            if propertyName is "name" then set sourceValue to name of currentAccount
            if propertyName is "id" then set sourceValue to id of currentAccount
            if my trimText(sourceValue) is queryText then set end of hits to name of currentAccount
        end repeat
    end tell

    return hits
end findByProperty

on textSearch(accountCollection, queryText)
    set hits to {}

    tell application "Reminders"
        repeat with currentAccount in accountCollection
            set accountName to name of currentAccount
            if my lowerText(accountName) contains my lowerText(queryText) then set end of hits to accountName
        end repeat
    end tell

    return hits
end textSearch

on parseArgs(argv)
    set outputFormat to "plain"
    set args to argv

    if (count of args) is greater than 0 then
        set lastArg to item -1 of args as text
        if lastArg starts with "--format=" then
            set outputFormat to text 10 thru -1 of lastArg
            if outputFormat is not "plain" and outputFormat is not "json" then error "Unsupported format: " & outputFormat
            if (count of args) is 1 then
                set args to {}
            else
                set args to items 1 thru -2 of args
            end if
        end if
    end if

    return {args, outputFormat}
end parseArgs

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

on lowerText(inputText)
    return do shell script "printf %s " & quoted form of (inputText as text) & " | tr '[:upper:]' '[:lower:]'"
end lowerText

on outputTextList(textList, outputFormat)
    if outputFormat is "json" then return my textListToJson(textList)
    return textList
end outputTextList

on textListToJson(textList)
    set chunks to {}
    repeat with currentValue in textList
        set end of chunks to "\"" & my jsonEscape(currentValue as text) & "\""
    end repeat
    return "[" & my join(chunks, ",") & "]"
end textListToJson

on join(textList, delimiterText)
    if (count of textList) is 0 then return ""
    set currentDelimiters to AppleScript's text item delimiters
    set AppleScript's text item delimiters to delimiterText
    set joinedText to textList as text
    set AppleScript's text item delimiters to currentDelimiters
    return joinedText
end join

on jsonEscape(valueText)
    set escaped to my replaceText("\\", "\\\\", valueText as text)
    set escaped to my replaceText("\"", "\\\"", escaped)
    set escaped to my replaceText(linefeed, "\\n", escaped)
    return escaped
end jsonEscape

on replaceText(findText, replacementText, sourceText)
    set AppleScript's text item delimiters to findText
    set textParts to text items of sourceText
    set AppleScript's text item delimiters to replacementText
    set replacedText to textParts as text
    set AppleScript's text item delimiters to ""
    return replacedText
end replaceText
