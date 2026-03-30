#!/bin/bash
# calendar_update.sh - 修改已有日历事件

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

SEARCH_TITLE="${1:?用法: calendar_update.sh <search_title> <search_start_date> [new_title] [new_start_date] [new_end_date] [new_location] [new_notes] [calendar_name]}"
SEARCH_START="${2:?缺少 search_start_date}"
NEW_TITLE="${3:-}"
NEW_START="${4:-}"
NEW_END="${5:-}"
NEW_LOCATION="${6:-}"
NEW_NOTES="${7:-}"
CALENDAR_NAME="${8:-}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set searchTitle to item 1 of argv
    set searchStartStr to item 2 of argv
    set newTitle to item 3 of argv
    set newStartStr to item 4 of argv
    set newEndStr to item 5 of argv
    set newLocation to item 6 of argv
    set newNotes to item 7 of argv
    set calName to item 8 of argv

    set searchStart to my parseDate(searchStartStr)

    tell application "Calendar"
        if calName is "" then
            set targetCalendars to every calendar
        else
            set targetCalendars to {calendar calName}
        end if

        set foundEvent to missing value
        repeat with cal in targetCalendars
            set matchingEvents to (every event of cal whose summary is searchTitle and start date is searchStart)
            if (count of matchingEvents) > 0 then
                set foundEvent to item 1 of matchingEvents
                exit repeat
            end if
        end repeat

        if foundEvent is missing value then
            return "ERR|未找到匹配事件: " & searchTitle & " @ " & searchStartStr
        end if

        if newTitle is not "" then
            set summary of foundEvent to newTitle
        end if
        if newStartStr is not "" then
            set start date of foundEvent to my parseDate(newStartStr)
        end if
        if newEndStr is not "" then
            set end date of foundEvent to my parseDate(newEndStr)
        end if
        if newLocation is not "" then
            set location of foundEvent to newLocation
        end if
        if newNotes is not "" then
            set description of foundEvent to newNotes
        end if

        return "OK|日程已更新: " & summary of foundEvent & " (" & (start date of foundEvent as text) & ")"
    end tell
end run

on parseDate(dateStr)
    set tid to AppleScript's text item delimiters
    if dateStr contains "T" then
        set AppleScript's text item delimiters to "T"
        set datePart to text item 1 of dateStr
        set timePart to text item 2 of dateStr
        set AppleScript's text item delimiters to "-"
        set y to text item 1 of datePart as integer
        set m to text item 2 of datePart as integer
        set d to text item 3 of datePart as integer
        set AppleScript's text item delimiters to ":"
        set h to text item 1 of timePart as integer
        set min to text item 2 of timePart as integer
        set s to 0
        try
            set s to text item 3 of timePart as integer
        end try
    else
        set AppleScript's text item delimiters to "-"
        set y to text item 1 of dateStr as integer
        set m to text item 2 of dateStr as integer
        set d to text item 3 of dateStr as integer
        set h to 0
        set min to 0
        set s to 0
    end if
    set AppleScript's text item delimiters to tid

    set theDate to current date
    set year of theDate to y
    set month of theDate to m
    set day of theDate to d
    set hours of theDate to h
    set minutes of theDate to min
    set seconds of theDate to s

    return theDate
end parseDate
APPLESCRIPT_EOF

osascript -e "$APPLESCRIPT" "$SEARCH_TITLE" "$SEARCH_START" "$NEW_TITLE" "$NEW_START" "$NEW_END" "$NEW_LOCATION" "$NEW_NOTES" "$CALENDAR_NAME"
