#!/bin/bash
# reminder_write.sh - 写入提醒事项
# 用法: reminder_write.sh <title> [due_date] [notes] [priority] [list_name]
# due_date 格式: YYYY-MM-DDTHH:MM:SS 或 YYYY-MM-DD
# priority: 0(无) 1(低) 5(中) 9(高)，默认 0

set -euo pipefail

TITLE="${1:?用法: reminder_write.sh <title> [due_date] [notes] [priority] [list_name]}"
DUE_DATE="${2:-}"
NOTES="${3:-}"
PRIORITY="${4:-0}"
LIST_NAME="${5:-}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set reminderTitle to item 1 of argv
    set dueDateStr to item 2 of argv
    set reminderNotes to item 3 of argv
    set reminderPriority to item 4 of argv as integer
    set listName to item 5 of argv

    tell application "Reminders"
        -- 选择目标列表
        if listName is "" then
            set targetList to default list
        else
            try
                set targetList to list listName
            on error
                -- 列表不存在则创建
                set targetList to make new list with properties {name:listName}
            end try
        end if

        -- 创建提醒事项
        set props to {name:reminderTitle}

        if reminderNotes is not "" then
            set props to props & {body:reminderNotes}
        end if

        if reminderPriority > 0 then
            set props to props & {priority:reminderPriority}
        end if

        set newReminder to make new reminder at end of reminders of targetList with properties props

        -- 设置截止日期
        if dueDateStr is not "" then
            set dueDate to my parseDate(dueDateStr)
            set due date of newReminder to dueDate
            set remind me date of newReminder to dueDate
        end if

        return "✅ 提醒已创建: " & reminderTitle
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
        set h to 9
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

osascript -e "$APPLESCRIPT" "$TITLE" "$DUE_DATE" "$NOTES" "$PRIORITY" "$LIST_NAME"
