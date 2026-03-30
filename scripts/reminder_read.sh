#!/bin/bash
# reminder_read.sh - 读取提醒事项列表

set -euo pipefail

# 系统检测
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERR|此功能仅支持 macOS 系统，当前系统不支持"
    exit 1
fi

LIST_NAME="${1:-}"
SHOW_COMPLETED="${2:-false}"

read -r -d '' APPLESCRIPT <<'APPLESCRIPT_EOF' || true
on run argv
    set listName to item 1 of argv
    set showCompleted to (item 2 of argv is "true")

    set output to ""

    tell application "Reminders"
        if listName is "" then
            set targetLists to every list
        else
            set targetLists to {list listName}
        end if

        repeat with aList in targetLists
            set lName to name of aList
            set allReminders to every reminder of aList
            repeat with r in allReminders
                set isCompleted to completed of r
                if showCompleted or (not isCompleted) then
                    set rName to name of r
                    set rDue to ""
                    try
                        if due date of r is not missing value then
                            set rDue to my formatDate(due date of r)
                        end if
                    end try
                    set rPriority to 0
                    try
                        set rPriority to priority of r
                    end try
                    set rNotes to ""
                    try
                        if body of r is not missing value then
                            set rNotes to body of r
                        end if
                    end try
                    set completedStr to "false"
                    if isCompleted then set completedStr to "true"

                    set output to output & rName & "|" & rDue & "|" & rPriority & "|" & completedStr & "|" & lName & "|" & rNotes & linefeed
                end if
            end repeat
        end repeat
    end tell

    return output
end run

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

osascript -e "$APPLESCRIPT" "$LIST_NAME" "$SHOW_COMPLETED"
