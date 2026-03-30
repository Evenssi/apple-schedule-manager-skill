#!/bin/bash
# calendar_list.sh - 列出所有可用的日历

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run
    set output to ""

    tell application "Calendar"
        repeat with cal in (every calendar)
            set calName to name of cal
            set calWritable to writable of cal

            if calWritable then
                set wStr to "true"
            else
                set wStr to "false"
            end if

            set output to output & calName & "|" & wStr & linefeed
        end repeat
    end tell

    return output
end run
APPLESCRIPT_EOF

osascript -e "$APPLESCRIPT"
