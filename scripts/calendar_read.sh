#!/bin/bash
# calendar_read.sh - 读取指定时间范围内的日历事件
# 用法: calendar_read.sh <start_date> <end_date> [calendar_name]
# 日期格式: YYYY-MM-DD 或 YYYY-MM-DDTHH:MM:SS
# 输出: 每行一个事件，格式为 TITLE|START|END|LOCATION|NOTES

set -euo pipefail

START_DATE="${1:?用法: calendar_read.sh <start_date> <end_date> [calendar_name]}"
END_DATE="${2:?用法: calendar_read.sh <start_date> <end_date> [calendar_name]}"
CALENDAR_NAME="${3:-}"

# 构建 AppleScript
read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set startDateStr to item 1 of argv
    set endDateStr to item 2 of argv
    set calName to item 3 of argv

    set startDate to my parseDate(startDateStr)
    set endDate to my parseDate(endDateStr)

    set output to ""

    tell application "Calendar"
        if calName is "" then
            set targetCalendars to every calendar
        else
            set targetCalendars to {calendar calName}
        end if

        repeat with cal in targetCalendars
            set calendarName to name of cal
            set matchingEvents to (every event of cal whose start date ≥ startDate and start date ≤ endDate)
            repeat with evt in matchingEvents
                set evtTitle to summary of evt
                set evtStart to start date of evt
                set evtEnd to end date of evt
                set evtLocation to ""
                try
                    set evtLocation to location of evt
                end try
                if evtLocation is missing value then set evtLocation to ""
                set evtNotes to ""
                try
                    set evtNotes to description of evt
                end try
                if evtNotes is missing value then set evtNotes to ""
                set evtAllDay to allday event of evt

                set startStr to my formatDate(evtStart)
                set endStr to my formatDate(evtEnd)

                set output to output & evtTitle & "|" & startStr & "|" & endStr & "|" & evtLocation & "|" & evtNotes & "|" & calendarName & "|" & evtAllDay & linefeed
            end repeat
        end repeat
    end tell

    return output
end run

on parseDate(dateStr)
    -- Handle ISO 8601 format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS
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

    -- Create date object
    set theDate to current date
    set year of theDate to y
    set month of theDate to m
    set day of theDate to d
    set hours of theDate to h
    set minutes of theDate to min
    set seconds of theDate to s

    return theDate
end parseDate

on formatDate(theDate)
    set y to year of theDate
    set m to (month of theDate as integer)
    set d to day of theDate
    set h to hours of theDate
    set min to minutes of theDate

    set mStr to text -2 thru -1 of ("0" & m)
    set dStr to text -2 thru -1 of ("0" & d)
    set hStr to text -2 thru -1 of ("0" & h)
    set minStr to text -2 thru -1 of ("0" & min)

    return (y as text) & "-" & mStr & "-" & dStr & "T" & hStr & ":" & minStr
end formatDate
APPLESCRIPT_EOF

osascript -e "$APPLESCRIPT" "$START_DATE" "$END_DATE" "$CALENDAR_NAME"
