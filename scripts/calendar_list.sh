#!/bin/bash
# calendar_list.sh - 列出所有可用的日历
# 用法: calendar_list.sh
# 输出: 每行一个日历，格式为 NAME|COLOR|WRITABLE

set -euo pipefail

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run
    set output to "📒 可用日历列表:" & linefeed
    set output to output & "━━━━━━━━━━━━━━━━━━" & linefeed

    tell application "Calendar"
        repeat with cal in (every calendar)
            set calName to name of cal
            set calWritable to writable of cal
            set calColor to color of cal

            if calWritable then
                set wStr to "可写入"
            else
                set wStr to "只读"
            end if

            set output to output & "  📅 " & calName & " (" & wStr & ")" & linefeed
        end repeat
    end tell

    return output
end run
APPLESCRIPT_EOF

osascript -e "$APPLESCRIPT"
