---
name: apple-schedule-manager-skill
description: >
  【仅限 macOS】将用户的自然语言日程指令解析并写入 macOS 原生日历或提醒事项。
  触发条件：
  - 用户明确说出「写入日历」「添加日程」「创建提醒」等操作词时触发
  - 用户用自然语言描述时间+事件（如"明天上午十点开会一小时"），且意图是创建日程时触发
  - 用户要求查看/修改/删除日历事件、查找空闲时间时触发
  闲聊中单纯提及时间或会议（无操作意图）不触发。
  不支持 Windows、Linux；不支持 Google Calendar、Outlook 等第三方日历；未接入企业办公平台。
keywords:
  - 写入日历
  - 添加日程
  - 创建提醒
  - 查看日历
  - 删除日程
  - 修改日程
  - 安排行程
  - 查找空闲时间
  - 提醒事项
  - 苹果日历
examples:
  - "帮我把明天下午3点的团队周会写入日历"
  - "明天上午十点开会一小时，下午三点去40楼取杂志"
  - "查看我这周的日历安排"
  - "把周五的晚餐约会改到周六"
  - "删除明天上午的面试日程"
  - "帮我找一下这周三有没有空闲时间"
  - "添加一个提醒：周五前提交报告"
  - "帮我安排一个1小时的健身时间"
  - "后天下午两点牙科复诊"
  - "提醒我周五前交报告"
---

# Apple Schedule Manager Skill

## 系统要求

- **仅支持 macOS**，依赖 `osascript` 调用 AppleScript 操作系统日历和提醒事项应用
- 不支持 Windows、Linux 等其他操作系统
- 不支持 Google Calendar、Outlook、飞书、企业微信、钉钉等第三方日历/办公平台

## 不触发条件

以下场景 **不应** 激活本 skill：
- 用户只是闲聊中提到时间、会议、日程等词汇，没有操作日历的意图
- 用户要求操作非 macOS 日历（如 Google Calendar、Outlook）
- 用户在非 macOS 系统上运行

## 基础路径

本 Skill 的脚本位于此文件同级的 `scripts/` 目录下：

```
SKILL_DIR = <this SKILL.md's parent directory>
SCRIPTS_DIR = SKILL_DIR/scripts
```

## 工作流程

### 0. 前置检查

执行任何脚本前，先确认用户系统为 macOS（脚本内已有 `$OSTYPE` 检测，非 darwin 会返回 `ERR|此功能仅支持 macOS 系统，当前系统不支持`）。收到此错误时，直接告知用户本功能仅支持 macOS，不再执行后续步骤。

### 1. 日程提取

从用户输入中识别并提取以下字段：

| 字段 | 必填 | 说明 |
|------|------|------|
| title | ✅ | 事项标题 |
| start_date | ✅ | 开始日期时间（ISO 8601 格式） |
| end_date | ❌ | 结束日期时间，默认为开始时间 +1 小时 |
| location | ❌ | 地点 |
| notes | ❌ | 备注描述 |
| attendees | ❌ | 参与人列表 |
| all_day | ❌ | 是否全天事件，默认 false |
| reminder | ❌ | 提前提醒分钟数，默认 15 |
| recurrence | ❌ | 重复规则（daily/weekly/monthly/yearly + interval） |
| calendar_name | ❌ | 目标日历名称，默认系统默认日历 |

**时间解析规则：**
- "明天" → 当前日期 +1 天
- "下周一" → 下一个周一
- "后天下午3点" → 当前日期 +2 天 15:00
- "下个月15号" → 下月15日
- 仅有日期无时间时，默认为全天事件
- 时间模糊不可推断时，**主动询问用户确认**

### 2. 冲突检测

提取完成后，**立即**执行冲突检测：

1. 运行 `scripts/calendar_read.sh` 查询所有待写入日程时间段内的已有事件
2. 对比所有待写入日程之间是否存在相互冲突（同一时段的多个事件）

### 3. 根据冲突结果决定写入策略

#### 情况 A：无冲突

**直接写入**，不需要用户确认。写入完成后，以结构化卡片格式展示已写入的日程：

```
✅ 已写入 1 条日程
📌 朋友聚餐
🕐 2026-03-31 周二 18:30 - 20:30
📍 海底捞（朝阳店）
⏰ 提前 30 分钟提醒
━━━━━━━━━━━━━━━━━━
```

#### 情况 B：存在冲突

**暂停写入**，向用户展示冲突详情并等待确认：

- 明确说明哪些日程之间存在时间重叠
- 运行 `scripts/calendar_find_free.sh` 查找替代时段，提供 2-3 个建议
- 等待用户确认处理方式（保持冲突继续写入 / 调整时间 / 取消部分日程）

**关键规则：用户确认冲突处理方式后，立即执行写入，不再二次确认。** 写入完成后同样以结构化卡片展示已写入的日程。

### 4. 智能排程

当用户请求"帮我安排一个XX"而未指定具体时间时：

1. 运行 `scripts/calendar_read.sh` 获取近期日历安排
2. 运行 `scripts/calendar_find_free.sh` 分析空闲时段
3. 根据事件类型推荐合适时段：
   - 工作/会议：工作时间 9:00-18:00 内的空闲段
   - 社交/约会：晚上或周末空闲时段
   - 医疗/办事：工作日上午 9:00-17:00
   - 运动/个人：早晨 7:00-9:00 或晚上 18:00-21:00
   - 全天事件：选择日程最少的一天
4. 提供 2-3 个推荐时段供用户选择
5. 用户选择后**直接写入**，写入完成后展示结果

### 5. 写入操作

根据事件类型选择目标应用：

- **有明确时间段的日程** → 写入苹果日历：运行 `scripts/calendar_write.sh`
- **多条日程批量写入** → 运行 `scripts/calendar_write_batch.sh`，传入 JSON 文件路径
- **待办/提醒类（无明确时段）** → 写入提醒事项：运行 `scripts/reminder_write.sh`

### 6. 编辑与删除

#### 日历事件

当用户要求修改或取消已有日程时：

1. 运行 `scripts/calendar_read.sh` 查询匹配事件，获取精确的 title 和 start_date
2. **修改**：运行 `scripts/calendar_update.sh`，传入定位字段（title + start_date）和需更新的字段（空字段不修改）
3. **删除**：运行 `scripts/calendar_delete.sh`，传入 title + start_date

#### 提醒事项

- **查看**：运行 `scripts/reminder_read.sh` 读取提醒列表
- **完成**：运行 `scripts/reminder_complete.sh` 标记为已完成
- **删除**：运行 `scripts/reminder_delete.sh`

### 7. 回退策略

如果 AppleScript 执行失败（权限不足、应用不可用等）：

1. 向用户说明原因
2. 输出标准格式的日程文本，方便手动添加
3. 如果是权限问题，指导用户在"系统设置 > 隐私与安全 > 自动化"中授权

## 脚本清单

| 脚本 | 用途 | 参数 | 输出格式 |
|------|------|------|----------|
| `scripts/calendar_read.sh` | 读取指定时间范围内的日历事件 | start_date, end_date, calendar_name(可选) | `TITLE\|START\|END\|LOCATION\|NOTES\|CALENDAR\|ALL_DAY` |
| `scripts/calendar_write.sh` | 写入新日历事件 | title, start_date, end_date, location, notes, all_day, reminder, recurrence, calendar_name | 文本消息 |
| `scripts/calendar_write_batch.sh` | 批量写入日历事件 | json_file（JSON 数组文件路径） | 每行 `OK\|title` 或 `ERR\|title\|reason` |
| `scripts/calendar_update.sh` | 修改已有日历事件 | search_title, search_start_date, new_title, new_start_date, new_end_date, new_location, new_notes, calendar_name | `OK\|msg` 或 `ERR\|msg` |
| `scripts/calendar_delete.sh` | 删除日历事件 | title, start_date, calendar_name(可选) | `OK\|msg` 或 `ERR\|msg` |
| `scripts/calendar_find_free.sh` | 查找空闲时段 | date, duration_minutes, work_hours_only | `BUSY\|HH:MM\|HH:MM\|name` / `FREE\|HH:MM\|HH:MM\|minutes` / `NONE` |
| `scripts/calendar_list.sh` | 列出所有可用日历 | 无 | `NAME\|WRITABLE` |
| `scripts/reminder_write.sh` | 写入提醒事项 | title, due_date, notes, priority, list_name | 文本消息 |
| `scripts/reminder_read.sh` | 读取提醒事项列表 | list_name(可选), show_completed(可选) | `NAME\|DUE_DATE\|PRIORITY\|COMPLETED\|LIST_NAME\|NOTES` |
| `scripts/reminder_complete.sh` | 标记提醒为已完成 | title, list_name(可选) | `OK\|msg` 或 `ERR\|msg` |
| `scripts/reminder_delete.sh` | 删除提醒事项 | title, list_name(可选) | `OK\|msg` 或 `ERR\|msg` |

所有脚本均通过 `osascript` 调用 AppleScript，适用于 macOS。
