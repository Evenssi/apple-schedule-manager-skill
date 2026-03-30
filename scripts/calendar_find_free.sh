#!/bin/bash
# calendar_find_free.sh - 查找指定日期的空闲时段

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

TARGET_DATE="${1:?用法: calendar_find_free.sh <date> [duration_minutes] [work_hours_only]}"
DURATION="${2:-60}"
WORK_HOURS_ONLY="${3:-true}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set targetDateStr to item 1 of argv
    set durationMin to item 2 of argv as integer
    set workHoursOnly to (item 3 of argv is "true")

    -- 解析目标日期
    set tid to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "-"
    set y to text item 1 of targetDateStr as integer
    set m to text item 2 of targetDateStr as integer
    set d to text item 3 of targetDateStr as integer
    set AppleScript's text item delimiters to tid

    -- 设置搜索范围
    set dayStart to current date
    set year of dayStart to y
    set month of dayStart to m
    set day of dayStart to d

    if workHoursOnly then
        set hours of dayStart to 9
        set minutes of dayStart to 0
        set seconds of dayStart to 0
        set dayEnd to current date
        set year of dayEnd to y
        set month of dayEnd to m
        set day of dayEnd to d
        set hours of dayEnd to 18
        set minutes of dayEnd to 0
        set seconds of dayEnd to 0
    else
        set hours of dayStart to 7
        set minutes of dayStart to 0
        set seconds of dayStart to 0
        set dayEnd to current date
        set year of dayEnd to y
        set month of dayEnd to m
        set day of dayEnd to d
        set hours of dayEnd to 22
        set minutes of dayEnd to 0
        set seconds of dayEnd to 0
    end if

    -- 设置前一天零点，用于捕获跨日事件
    set prevDayStart to current date
    set year of prevDayStart to y
    set month of prevDayStart to m
    set day of prevDayStart to d
    set hours of prevDayStart to 0
    set minutes of prevDayStart to 0
    set seconds of prevDayStart to 0
    set prevDayStart to prevDayStart - (24 * 60 * 60) -- 前一天零点

    -- 收集与当天时间窗口有交集的所有事件（包括跨日事件）
    set busySlots to {}
    tell application "Calendar"
        repeat with cal in (every calendar)
            -- 查询：开始时间在前一天之后 且 开始时间在当天结束之前
            set candidateEvents to (every event of cal whose start date ≥ prevDayStart and start date < dayEnd)
            repeat with evt in candidateEvents
                if allday event of evt is false then
                    set evtStart to start date of evt
                    set evtEnd to end date of evt
                    -- 只保留与 [dayStart, dayEnd] 有交集的事件
                    if evtEnd > dayStart and evtStart < dayEnd then
                        -- 裁剪到当天窗口
                        if evtStart < dayStart then set evtStart to dayStart
                        if evtEnd > dayEnd then set evtEnd to dayEnd
                        set end of busySlots to {startTime:evtStart, endTime:evtEnd, eventName:summary of evt}
                    end if
                end if
            end repeat
        end repeat
    end tell

    -- 按开始时间排序（简单冒泡排序）
    set n to count of busySlots
    repeat with i from 1 to n - 1
        repeat with j from 1 to n - i
            if startTime of item j of busySlots > startTime of item (j + 1) of busySlots then
                set temp to item j of busySlots
                set item j of busySlots to item (j + 1) of busySlots
                set item (j + 1) of busySlots to temp
            end if
        end repeat
    end repeat

    set output to ""

    -- 输出已有事件 (BUSY 行)
    repeat with slot in busySlots
        set output to output & "BUSY|" & my formatTime(startTime of slot) & "|" & my formatTime(endTime of slot) & "|" & eventName of slot & linefeed
    end repeat

    -- 查找空闲段
    set freeStart to dayStart
    set foundFree to false

    repeat with slot in busySlots
        set slotStart to startTime of slot
        set gapMinutes to ((slotStart - freeStart) / 60) as integer
        if gapMinutes ≥ durationMin then
            set output to output & "FREE|" & my formatTime(freeStart) & "|" & my formatTime(slotStart) & "|" & gapMinutes & linefeed
            set foundFree to true
        end if
        if endTime of slot > freeStart then
            set freeStart to endTime of slot
        end if
    end repeat

    -- 检查最后一段
    set gapMinutes to ((dayEnd - freeStart) / 60) as integer
    if gapMinutes ≥ durationMin then
        set output to output & "FREE|" & my formatTime(freeStart) & "|" & my formatTime(dayEnd) & "|" & gapMinutes & linefeed
        set foundFree to true
    end if

    if not foundFree then
        set output to output & "NONE" & linefeed
    end if

    return output
end run

on formatTime(theDate)
    set h to hours of theDate
    set m to minutes of theDate
    set hStr to text -2 thru -1 of ("0" & h)
    set mStr to text -2 thru -1 of ("0" & m)
    return hStr & ":" & mStr
end formatTime
APPLESCRIPT_EOF

osascript -e "$APPLESCRIPT" "$TARGET_DATE" "$DURATION" "$WORK_HOURS_ONLY"
