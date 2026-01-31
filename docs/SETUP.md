# 完整部署指南

本文档提供详细的部署步骤和架构说明。

---

## 部署步骤

1. Fork 或上传此仓库到你的 HuggingFace Space
2. 在 Space Settings → Variables and secrets 中配置环境变量：
   - **必需**：`OPENCLAW_GATEWAY_TOKEN`（Gateway 访问令牌，使用 `openssl rand -base64 32` 生成）
   - **推荐**：`TTYD_USERNAME` 和 `TTYD_PASSWORD`（Web 终端登录凭证，使用 `openssl rand -base64 16` 生成密码）
   - **推荐**：`RCLONE_CONFIG_GDRIVE_JSON`（Google Drive 备份配置）
   - **可选**：AI Provider API Key（可以通过 Web Terminal 在应用内配置，见上文）
   - **可选**：`RCLONE_CONFIG_GDRIVE_JSON`（Google Drive 备份配置）
3. 等待构建完成（首次构建可能需要 5-10 分钟）
4. Space 启动后：
   - OpenClaw Gateway 在根路径 `/` 运行
   - Web 终端在 `/terminal` 路径可访问
5. 访问 OpenClaw：
   ```
   https://your-space.hf.space/?token=YOUR_GATEWAY_TOKEN
   ```

## 快速开始示例

### 方案 A：最小化部署 + 应用内配置（推荐）⭐

**HuggingFace Secrets 配置**：
```bash
# 1. Gateway 认证（必需）
OPENCLAW_GATEWAY_TOKEN=GUz8uwCK9Zfvw4FXm3zn5cFtKdv54a5sOXzuZQdyRd8=

# 2. Web 终端（强烈推荐）
TTYD_USERNAME=admin
TTYD_PASSWORD=X8k9L2mP4qR7sT1vW3yZ5aC=

# 3. 数据备份（推荐）
RCLONE_CONFIG_GDRIVE_JSON={"type":"service_account","project_id":"..."}
BACKUP_INTERVAL_MINUTES=60
```

**AI Provider API Key**：通过 Web Terminal 在应用内配置（见上文 ["应用内配置 API Key"](#应用内配置-api-key推荐) 章节）

**优势**：
- ✅ API Key 存储在你的 Google Drive，更安全
- ✅ 支持所有高级配置选项
- ✅ 容器重启自动恢复

---

### 方案 B：完整环境变量配置

**HuggingFace Secrets 配置**：
```bash
# 1. Gateway 认证（必需）
OPENCLAW_GATEWAY_TOKEN=GUz8uwCK9Zfvw4FXm3zn5cFtKdv54a5sOXzuZQdyRd8=

# 2. AI Provider（至少需要一个）
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxxxxxxx

# 3. Web 终端（推荐）
TTYD_USERNAME=admin
TTYD_PASSWORD=X8k9L2mP4qR7sT1vW3yZ5aC=

# 4. 数据备份（推荐）
RCLONE_CONFIG_GDRIVE_JSON={"type":"service_account","project_id":"..."}
BACKUP_INTERVAL_MINUTES=60

# 5. 消息平台（按需配置）
TELEGRAM_BOT_TOKEN=123456:ABCdefGHIjklMNOpqrsTUVwxyz
WHATSAPP_ACCESS_TOKEN=EAAxxxxxxxxxxxxx
```

---

### 配置完成后

访问：
- **OpenClaw Gateway**: `https://your-space.hf.space/?token=YOUR_GATEWAY_TOKEN`
- **Web 终端**: `https://your-space.hf.space/terminal` (需要 TTYD 用户名密码)

## 本地开发

```bash
# 安装依赖
npm install

# 启动服务
npm start
```

## 配置文件

配置文件保存在 `~/.openclaw/` 目录下。在 HuggingFace Spaces 环境中，这些配置会在容器重启后重置，建议通过环境变量管理所有配置。

## 了解更多

- [OpenClaw 官方网站](https://openclaw.ai/)
- [OpenClaw 文档](https://docs.openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)

## 注意事项

- 此部署版本适配了 HuggingFace Spaces 的 7860 端口要求
- 默认情况下会启动 gateway 模式（网关服务）
- 建议在 HuggingFace Secrets 中安全地存储 API 密钥
- **用户具有 sudo 权限**：可以通过 `sudo` 命令安装反向代理工具或其他软件包
- **数据持久化方案**：
  - 推荐：Google Drive 自动备份（本地高性能 + 云端安全）
  - 备选：PostgreSQL 远程数据库（多端同步，但有网络延迟）
  - 不配置：容器重启数据丢失

## 备份管理

### 手动触发备份
```bash
# 进入容器（通过 HuggingFace Space 的 Terminal 或 SSH）
bash /app/backup.sh
```

### 手动恢复备份
```bash
# 从 Google Drive 恢复数据
bash /app/restore.sh
```

### 查看备份日志
容器启动和定时备份时会在日志中显示备份状态。
  
## 系统管理

容器内的 `user` 用户具有完整的 sudo 权限，你可以：

```bash
# 安装反向代理工具（如需要）
sudo apt-get update
sudo apt-get install nginx socat proxychains-ng

# 安装其他工具
sudo apt-get install htop net-tools

# 编辑系统配置
sudo vim /etc/hosts
```

已预装工具：`curl`、`wget`、`vim`、`git`、`sudo`、`rclone`

## 项目文件说明

```
ClaudBot/
├── Dockerfile              # Docker 镜像配置
├── package.json            # Node.js 依赖
├── start.js                # 启动脚本（包含自动恢复和定时备份）
├── backup.sh               # 备份脚本（上传到 Google Drive）
├── restore.sh              # 恢复脚本（从 Google Drive 下载）
├── nginx.conf              # Nginx 反向代理配置
├── supervisord.conf        # Supervisor 多进程管理配置
├── start-services.sh       # 服务启动脚本
├── .env.example            # 环境变量配置示例
└── README.md               # 项目说明
```

## 架构说明

本项目使用 **nginx** 作为反向代理，将多个服务统一暴露在 7860 端口：

- `/` → OpenClaw Gateway（端口 18789）
- `/terminal` → ttyd Web 终端（端口 7681，Basic Auth 保护）

所有进程通过 **supervisor** 统一管理，确保服务自动重启和日志收集。
