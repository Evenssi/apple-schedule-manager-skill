#!/bin/bash
# calendar_write_batch.sh - 批量写入日历事件

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

JSON_FILE="${1:?用法: calendar_write_batch.sh <json_file>}"

if [ ! -f "$JSON_FILE" ]; then
    echo "ERR|文件不存在: $JSON_FILE"
    exit 1
fi

# 提取事件数量
COUNT=$(python3 -c "import json,sys; data=json.load(open(sys.argv[1])); print(len(data))" "$JSON_FILE")

if [ "$COUNT" -eq 0 ]; then
    echo "ERR|JSON 文件中无事件数据"
    exit 1
fi

# 将 JSON 转为 AppleScript 可读的管道分隔格式，每行一个事件
EVENTS_DATA=$(python3 -c "
import json, sys
data = json.load(open(sys.argv[1]))
for e in data:
    fields = [
        e.get('title',''),
        e.get('start_date',''),
        e.get('end_date',''),
        e.get('location',''),
        e.get('notes',''),
        str(e.get('all_day', False)).lower(),
        str(e.get('reminder', 15)),
        e.get('recurrence',''),
        e.get('calendar_name','')
    ]
    print('|||'.join(fields))
" "$JSON_FILE")

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set eventsRaw to item 1 of argv

    -- 按换行分隔每个事件
    set tid to AppleScript's text item delimiters
    set AppleScript's text item delimiters to linefeed
    set eventLines to text items of eventsRaw
    set AppleScript's text item delimiters to tid

    set output to ""

    tell application "Calendar"
        -- 预先查找可写日历
        set defaultCal to missing value
        repeat with aCal in calendars
            if writable of aCal then
                set defaultCal to aCal
                exit repeat
            end if
        end repeat
        if defaultCal is missing value then
            return "ERR|未找到可写日历"
        end if

        repeat with aLine in eventLines
            if (length of aLine) > 0 then
                set tid2 to AppleScript's text item delimiters
                set AppleScript's text item delimiters to "|||"
                set fields to text items of (aLine as text)
                set AppleScript's text item delimiters to tid2

                set evtTitle to item 1 of fields
                set startDateStr to item 2 of fields
                set endDateStr to item 3 of fields
                set evtLocation to item 4 of fields
                set evtNotes to item 5 of fields
                set allDayStr to item 6 of fields
                set reminderMin to item 7 of fields as integer
                set recurrenceStr to item 8 of fields
                set calName to item 9 of fields

                try
                    set startDate to my parseDate(startDateStr)
                    set endDate to my parseDate(endDateStr)
                    set isAllDay to (allDayStr is "true")

                    if calName is "" then
                        set targetCal to defaultCal
                    else
                        set targetCal to calendar calName
                    end if

                    set newEvent to make new event at end of events of targetCal with properties {summary:evtTitle, start date:startDate, end date:endDate, allday event:isAllDay}

                    if evtLocation is not "" then
                        set location of newEvent to evtLocation
                    end if
                    if evtNotes is not "" then
                        set description of newEvent to evtNotes
                    end if
                    if reminderMin > 0 then
                        make new display alarm at end of display alarms of newEvent with properties {trigger interval:(-reminderMin)}
                    end if
                    if recurrenceStr is not "" then
                        set recRule to my buildRecurrence(recurrenceStr)
                        set recurrence of newEvent to recRule
                    end if

                    set output to output & "OK|" & evtTitle & linefeed
                on error errMsg
                    set output to output & "ERR|" & evtTitle & "|" & errMsg & linefeed
                end try
            end if
        end repeat
    end tell

    return output
end run

on buildRecurrence(recStr)
    set tid to AppleScript's text item delimiters
    set AppleScript's text item delimiters to ":"
    set parts to text items of recStr
    set AppleScript's text item delimiters to tid

    set freq to item 1 of parts
    set interval to 1
    if (count of parts) > 1 then
        set interval to item 2 of parts as integer
    end if

    if freq is "daily" then
        return "FREQ=DAILY;INTERVAL=" & interval
    else if freq is "weekly" then
        return "FREQ=WEEKLY;INTERVAL=" & interval
    else if freq is "monthly" then
        return "FREQ=MONTHLY;INTERVAL=" & interval
    else if freq is "yearly" then
        return "FREQ=YEARLY;INTERVAL=" & interval
    else
        return ""
    end if
end buildRecurrence

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

osascript -e "$APPLESCRIPT" "$EVENTS_DATA"
