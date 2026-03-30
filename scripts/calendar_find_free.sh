#!/bin/bash
# calendar_find_free.sh - 查找指定日期的空闲时段
# 用法: calendar_find_free.sh <date> [duration_minutes] [work_hours_only]
# date 格式: YYYY-MM-DD
# duration_minutes: 需要的空闲时长，默认 60
# work_hours_only: true/false，是否只查找工作时间内的空闲段，默认 true

set -euo pipefail

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

    -- 收集当天所有事件
    set busySlots to {}
    tell application "Calendar"
        repeat with cal in (every calendar)
            set dayEvents to (every event of cal whose start date ≥ dayStart and start date < dayEnd)
            repeat with evt in dayEvents
                if allday event of evt is false then
                    set end of busySlots to {startTime:start date of evt, endTime:end date of evt, eventName:summary of evt}
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

    -- 查找空闲时段
    set output to "📊 " & targetDateStr & " 日程安排:" & linefeed
    set output to output & "━━━━━━━━━━━━━━━━━━" & linefeed

    -- 显示已有事件
    if n > 0 then
        set output to output & "已有日程:" & linefeed
        repeat with slot in busySlots
            set output to output & "  🔴 " & my formatTime(startTime of slot) & " - " & my formatTime(endTime of slot) & " " & eventName of slot & linefeed
        end repeat
        set output to output & linefeed
    else
        set output to output & "  当天暂无日程安排" & linefeed & linefeed
    end if

    -- 查找空闲段
    set output to output & "空闲时段 (≥" & durationMin & "分钟):" & linefeed
    set freeStart to dayStart
    set foundFree to false

    repeat with slot in busySlots
        set slotStart to startTime of slot
        -- 计算空闲段
        set gapMinutes to ((slotStart - freeStart) / 60) as integer
        if gapMinutes ≥ durationMin then
            set output to output & "  🟢 " & my formatTime(freeStart) & " - " & my formatTime(slotStart) & " (" & gapMinutes & "分钟)" & linefeed
            set foundFree to true
        end if
        -- 更新搜索起点
        if endTime of slot > freeStart then
            set freeStart to endTime of slot
        end if
    end repeat

    -- 检查最后一段
    set gapMinutes to ((dayEnd - freeStart) / 60) as integer
    if gapMinutes ≥ durationMin then
        set output to output & "  🟢 " & my formatTime(freeStart) & " - " & my formatTime(dayEnd) & " (" & gapMinutes & "分钟)" & linefeed
        set foundFree to true
    end if

    if not foundFree then
        set output to output & "  ⚠️ 当天无足够空闲时段" & linefeed
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
