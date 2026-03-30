# Apple Schedule Manager Skill 📅

AI 日程管理 Skill，将自然语言日程指令解析并写入 macOS 原生日历或提醒事项。

> ⚠️ **仅支持 macOS** — 依赖 `osascript` 调用 Calendar.app 和 Reminders.app，不支持 Windows/Linux，不支持 Google Calendar、Outlook 等第三方日历。

## 功能概览

- **自然语言解析** — 支持中文自然语言时间表达（"明天下午3点开会一小时"、"下周一上午十点"）
- **日历事件管理** — 创建、查询、修改、删除日历事件
- **批量写入** — 多条日程一次性批量写入日历
- **提醒事项管理** — 创建、查看、完成、删除提醒事项
- **冲突检测** — 写入前自动检查时间冲突，提供替代时段建议
- **智能排程** — 分析空闲时段，根据事件类型推荐最优时间
- **重复事件** — 支持 daily / weekly / monthly / yearly 重复规则

## 安装

```bash
git clone https://github.com/Evenssi/apple-schedule-manager-skill.git
cd apple-schedule-manager-skill
chmod +x scripts/*.sh
```

安装后将此文件夹放入 AI agent 的 skill 目录，agent 会自动读取 `SKILL.md` 获取完整工作流程和脚本调用方式。

## 系统要求

- **macOS** 10.15 (Catalina) 或更高版本
- **Calendar.app** 和 **Reminders.app**（系统预装）
- 首次使用需授权自动化权限：*系统设置 > 隐私与安全性 > 自动化*

## License

[MIT](LICENSE)
