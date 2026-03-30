# Apple Schedule Manager Skill 📅

An AI-powered schedule management skill that extracts events from natural language and writes them to **Apple Calendar** & **Reminders** via AppleScript.

> ⚠️ **macOS only** — relies on `osascript` and native macOS apps (Calendar.app, Reminders.app).

## Features

- **Natural language parsing** — understands inputs like *"meeting with John tomorrow at 3pm for an hour"*
- **Apple Calendar integration** — create, query, and manage calendar events
- **Reminders integration** — create to-do items in Apple Reminders
- **Conflict detection** — checks existing events before writing, suggests alternative time slots
- **Smart scheduling** — finds free slots and recommends optimal times
- **Recurring events** — supports daily / weekly / monthly / yearly recurrence

## Project Structure

```
├── SKILL.md                  # Skill definition (triggers, workflows, prompts)
└── scripts/
    ├── calendar_read.sh      # Query events by date range
    ├── calendar_write.sh     # Create calendar events
    ├── calendar_find_free.sh # Find free time slots
    ├── calendar_list.sh      # List available calendars
    └── reminder_write.sh     # Create reminders
```

## Installation

Clone the repo and make scripts executable:

```bash
git clone https://github.com/Evenssi/apple-schedule-manager-skill.git
cd apple-schedule-manager-skill
chmod +x scripts/*.sh
```

## Usage

### Scripts

```bash
# List all calendars
./scripts/calendar_list.sh

# Read events for a date range
./scripts/calendar_read.sh "2026-03-28" "2026-03-29"

# Find free slots (date, min_duration_minutes, work_hours_only)
./scripts/calendar_find_free.sh "2026-03-28" 60 true

# Create a calendar event
./scripts/calendar_write.sh "Team Meeting" "2026-03-28T14:00:00" "2026-03-28T15:00:00" \
  "Room A" "Weekly sync" "false" "15" "weekly" "Work"

# Create a reminder
./scripts/reminder_write.sh "Buy groceries" "2026-03-28T18:00:00" "For dinner" "0" ""
```

### As an AI Skill

Place the folder in your AI agent's skill directory. The agent reads `SKILL.md` to understand the workflow:

1. Extract structured event data from user input
2. Show confirmation card to user
3. Check for conflicts → suggest alternatives if needed
4. Write to Calendar or Reminders upon confirmation

## Requirements

- **macOS** 10.15 (Catalina) or later
- **Calendar.app** and **Reminders.app** (pre-installed)
- Grant automation permission on first use: *System Settings > Privacy & Security > Automation*

## License

[MIT](LICENSE)
