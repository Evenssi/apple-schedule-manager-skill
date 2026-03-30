#!/bin/bash
# reminder_delete.sh - 删除提醒事项

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

TITLE="${1:?用法: reminder_delete.sh <title> [list_name]}"
LIST_NAME="${2:-}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set searchTitle to item 1 of argv
    set listName to item 2 of argv

    tell application "Reminders"
        if listName is "" then
            set targetLists to every list
        else
            set targetLists to {list listName}
        end if

        repeat with aList in targetLists
            set matchReminders to (every reminder of aList whose name is searchTitle)
            if (count of matchReminders) > 0 then
                delete item 1 of matchReminders
                return "OK|提醒已删除: " & searchTitle
            end if
        end repeat

        return "ERR|未找到提醒: " & searchTitle
    end tell
end run
APPLESCRIPT_EOF

osascript -e "$APPLESCRIPT" "$TITLE" "$LIST_NAME"
