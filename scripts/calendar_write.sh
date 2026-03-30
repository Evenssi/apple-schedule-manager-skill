#!/bin/bash
# calendar_write.sh - 写入新日历事件
# 用法: calendar_write.sh <title> <start_date> <end_date> [location] [notes] [all_day] [reminder_minutes] [recurrence] [calendar_name]
# 日期格式: YYYY-MM-DDTHH:MM:SS
# recurrence 格式: daily|weekly|monthly|yearly[:interval]  例如 weekly:1

set -euo pipefail

TITLE="${1:?用法: calendar_write.sh <title> <start_date> <end_date> ...}"
START_DATE="${2:?缺少 start_date}"
END_DATE="${3:?缺少 end_date}"
LOCATION="${4:-}"
NOTES="${5:-}"
ALL_DAY="${6:-false}"
REMINDER="${7:-15}"
RECURRENCE="${8:-}"
CALENDAR_NAME="${9:-}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set evtTitle to item 1 of argv
    set startDateStr to item 2 of argv
    set endDateStr to item 3 of argv
    set evtLocation to item 4 of argv
    set evtNotes to item 5 of argv
    set allDayStr to item 6 of argv
    set reminderMin to item 7 of argv as integer
    set recurrenceStr to item 8 of argv
    set calName to item 9 of argv

    set startDate to my parseDate(startDateStr)
    set endDate to my parseDate(endDateStr)
    set isAllDay to (allDayStr is "true")

    tell application "Calendar"
        -- 选择目标日历
        if calName is "" then
            set targetCal to first calendar whose name is (name of first calendar)
            -- 使用默认日历
            try
                set targetCal to first calendar whose name is "日历"
            end try
            try
                set targetCal to first calendar whose name is "Calendar"
            end try
        else
            set targetCal to calendar calName
        end if

        -- 创建事件
        set newEvent to make new event at end of events of targetCal with properties {summary:evtTitle, start date:startDate, end date:endDate, allday event:isAllDay}

        -- 设置地点
        if evtLocation is not "" then
            set location of newEvent to evtLocation
        end if

        -- 设置备注
        if evtNotes is not "" then
            set description of newEvent to evtNotes
        end if

        -- 设置提醒
        if reminderMin > 0 then
            make new display alarm at end of display alarms of newEvent with properties {trigger interval:(-reminderMin)}
        end if

        -- 设置重复规则
        if recurrenceStr is not "" then
            set recRule to my buildRecurrence(recurrenceStr)
            set recurrence of newEvent to recRule
        end if

        return "✅ 日程已创建: " & evtTitle & " (" & (start date of newEvent as text) & ")"
    end tell
end run

on buildRecurrence(recStr)
    -- recStr 格式: daily|weekly|monthly|yearly[:interval]
    set tid to AppleScript's text item delimiters
    set AppleScript's text item delimiters to ":"
    set parts to text items of recStr
    set AppleScript's text item delimiters to tid

    set freq to item 1 of parts
    set interval to 1
    if (count of parts) > 1 then
        set interval to item 2 of parts as integer
    end if

    -- 生成 iCal RRULE 格式
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

osascript -e "$APPLESCRIPT" "$TITLE" "$START_DATE" "$END_DATE" "$LOCATION" "$NOTES" "$ALL_DAY" "$REMINDER" "$RECURRENCE" "$CALENDAR_NAME"
