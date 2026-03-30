---
name: apple-schedule-manager-skill
description: >
  智能日程管理助手，从用户自然语言输入中提取日程信息并写入 macOS 系统日历或提醒事项。
  触发条件：当用户提到日程、会议、约会、提醒、截止日期、安排行程、查看日历、
  时间冲突、空闲时间等关键词时触发，或用户明确要求创建/查看/管理日程时触发。
  核心能力包括：(1) 从自然语言提取结构化日程信息 (2) 通过 AppleScript 读写苹果日历和提醒事项
  (3) 冲突检测与替代时段建议 (4) 智能排程——查询空闲时段为用户推荐最优时间
  (5) 支持相对时间解析（如"明天下午3点"、"下周一"）。
  仅适用于 macOS 系统。
---

# Apple Schedule Manager Skill - 日程管理助手

## 基础路径

本 Skill 的脚本位于此文件同级的 `scripts/` 目录下。使用时通过以下方式获取路径：

```
SKILL_DIR = <this SKILL.md's parent directory>
SCRIPTS_DIR = SKILL_DIR/scripts
```

## 工作流程

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
✅ 已写入 3 条日程
━━━━━━━━━━━━━━━━━━
📌 个人活动A
🕐 2026-03-31 周二 10:00 - 11:00
📍 家中
⏰ 提前 15 分钟提醒
━━━━━━━━━━━━━━━━━━
📌 观看线上直播
🕐 2026-03-31 周二 10:00 - 11:00
📍 线上
⏰ 提前 15 分钟提醒
━━━━━━━━━━━━━━━━━━
📌 领取杂志
🕐 2026-03-31 周二 15:00 - 15:30
⏰ 提前 15 分钟提醒
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
   - 会议类：工作时间 9:00-18:00 内的空闲段
   - 运动/个人：下班后 18:00-21:00
   - 全天事件：选择日程最少的一天
4. 提供 2-3 个推荐时段供用户选择
5. 用户选择后**直接写入**，写入完成后展示结果

### 5. 写入操作

根据事件类型选择目标应用：

- **有明确时间段的日程** → 写入苹果日历：运行 `scripts/calendar_write.sh`
- **待办/提醒类（无明确时段）** → 写入提醒事项：运行 `scripts/reminder_write.sh`

### 6. 回退策略

如果 AppleScript 执行失败（权限不足、应用不可用等）：

1. 向用户说明原因
2. 输出标准格式的日程文本，方便手动添加
3. 如果是权限问题，指导用户在"系统设置 > 隐私与安全 > 自动化"中授权

## 脚本清单

| 脚本 | 用途 | 参数 |
|------|------|------|
| `scripts/calendar_read.sh` | 读取指定时间范围内的日历事件 | start_date, end_date, calendar_name(可选) |
| `scripts/calendar_write.sh` | 写入新日历事件 | title, start_date, end_date, location, notes, all_day, reminder, recurrence, calendar_name |
| `scripts/calendar_find_free.sh` | 查找空闲时段 | date, duration_minutes, work_hours_only |
| `scripts/reminder_write.sh` | 写入提醒事项 | title, due_date, notes, priority, list_name |
| `scripts/calendar_list.sh` | 列出所有可用日历 | 无 |

所有脚本均通过 `osascript` 调用 AppleScript，适用于 macOS。
