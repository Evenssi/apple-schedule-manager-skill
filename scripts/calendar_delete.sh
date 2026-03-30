#!/bin/bash
# calendar_delete.sh - 删除日历事件

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

TITLE="${1:?用法: calendar_delete.sh <title> <start_date> [calendar_name]}"
START_DATE="${2:?缺少 start_date}"
CALENDAR_NAME="${3:-}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set searchTitle to item 1 of argv
    set searchStartStr to item 2 of argv
    set calName to item 3 of argv

    set searchStart to my parseDate(searchStartStr)

    tell application "Calendar"
        if calName is "" then
            set targetCalendars to every calendar
        else
            set targetCalendars to {calendar calName}
        end if

        repeat with cal in targetCalendars
            set matchingEvents to (every event of cal whose summary is searchTitle and start date is searchStart)
            if (count of matchingEvents) > 0 then
                set evtTitle to summary of item 1 of matchingEvents
                delete item 1 of matchingEvents
                return "OK|日程已删除: " & evtTitle
            end if
        end repeat

        return "ERR|未找到匹配事件: " & searchTitle & " @ " & searchStartStr
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

osascript -e "$APPLESCRIPT" "$TITLE" "$START_DATE" "$CALENDAR_NAME"
