---
title: OpenClaw AI Gateway
emoji: 🦞
colorFrom: blue
colorTo: purple
sdk: docker
pinned: false
license: mit
app_port: 7860
startup_duration_timeout: 1h
short_description: AI Gateway for WhatsApp, Telegram, Discord & more
suggested_hardware: cpu-basic
tags:
  - AI
  - agent
  - gateway
  - chatbot
  - telegram
  - whatsapp
  - discord
  - openclaw
---

# OpenClaw AI Agent Gateway

部署在 HuggingFace Spaces 上的 OpenClaw AI 代理网关。

## ✨ 功能特性

- 🤖 多平台支持：WhatsApp、Telegram、Discord、Slack 等
- ⚡ 主动式 AI：定时任务和心跳提醒
- 🔧 工具调用：日历、邮箱、文件系统访问
- 🌐 HTTP API：OpenAI 兼容接口
- 💻 Web Terminal：浏览器内 Shell 访问

## 🚀 快速开始

### 1. 必需配置

在 HuggingFace Space Settings → Variables and secrets 中添加：

**Gateway Token**（必需）
```bash
# 生成 token
openssl rand -base64 32

# 设置环境变量
OPENCLAW_GATEWAY_TOKEN=<生成的token>
```

**AI Provider**（至少一个）
- `ANTHROPIC_API_KEY` 或 `OPENAI_API_KEY`

### 2. 推荐配置

**Web Terminal**
```bash
TTYD_USERNAME=admin
TTYD_PASSWORD=<openssl rand -base64 16>
```

**Google Drive 备份**
```bash
RCLONE_OAUTH_TOKEN=<OAuth token JSON>
BACKUP_INTERVAL_MINUTES=60
```

### 3. 访问

- **Gateway**: `https://your-space.hf.space/?token=YOUR_TOKEN`
- **Web Terminal**: `https://your-space.hf.space/terminal`

## 📚 详细文档

- [🛠️ 完整部署指南](docs/SETUP.md)
- [⚙️ 环境变量配置](docs/CONFIG.md)
- [💾 Google Drive 备份](docs/BACKUP.md)
- [💻 Web Terminal 使用](docs/TERMINAL.md)
- [❓ 常见问题](docs/FAQ.md)

## 🏗️ 架构

```
HuggingFace Spaces (Port 7860)
    ↓
  Nginx
    ├── /          → OpenClaw Gateway (18789)
    └── /terminal  → ttyd Web Terminal (7681)
```

## 📄 许可证

MIT

## 🔗 相关链接

- [OpenClaw 官网](https://openclaw.ai/)
- [OpenClaw 文档](https://docs.openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
