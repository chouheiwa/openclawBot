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
---

# OpenClaw AI Agent Gateway

这是一个部署在 HuggingFace Spaces 上的 OpenClaw AI 代理网关。OpenClaw 是一个功能强大的 AI 助手，可以连接多种消息平台（WhatsApp、Telegram、Discord、Slack 等）并提供 24/7 的 AI 服务。

## 🚀 快速导航

- **遇到问题？** → [常见问题](#常见问题)
- **如何配置 AI API Key？** → [Q9: 如何更换或添加 API Key](#q9-如何更换或添加-ai-provider-的-api-key)
- **提示 "pairing required"？** → [Q8: pairing required 错误](#q8-访问-gateway-时提示-disconnected-1008-pairing-required)
- **如何配置 Web Terminal？** → [Web 终端配置](#web-终端配置强烈推荐)
- **如何设置数据备份？** → [Google Drive 备份配置](#-推荐方案-google-drive-自动备份免费-15gb)

## 功能特性

- 🤖 **多平台支持**：WhatsApp、Telegram、Discord、Slack、iMessage 等
- ⚡ **主动式 AI**：通过心跳和定时任务主动提醒用户
- 🔧 **工具调用**：访问日历、邮箱、文件系统等
- 🎯 **技能扩展**：可以自主学习和编写新技能
- 🌐 **HTTP API**：提供兼容 OpenAI 的 API 接口
- 💻 **Web 终端**：浏览器内访问系统 Shell，方便运行时配置

## 环境变量配置

在 HuggingFace Space 的 Settings 中配置以下环境变量：

### 必需配置

#### 1. Gateway 认证 Token（必需）

- `OPENCLAW_GATEWAY_TOKEN`：OpenClaw Gateway 的访问令牌

**配置步骤**：
1. 生成安全的随机 token：
   ```bash
   openssl rand -base64 32
   # 输出示例: GUz8uwCK9Zfvw4FXm3zn5cFtKdv54a5sOXzuZQdyRd8=
   ```

2. 在 HuggingFace Space Settings → Variables and secrets 中添加：
   - Name: `OPENCLAW_GATEWAY_TOKEN`
   - Value: 你生成的 token（例如上面的输出）
   - 设置为 **Secret**（保密）

3. 重启 Space 使配置生效

**动态更新**：
- ✅ 每次容器启动时，会自动将环境变量中的 `OPENCLAW_GATEWAY_TOKEN` 同步到配置文件
- ✅ 如果你在 HuggingFace Secrets 中更新了 token，只需重启 Space 即可生效
- ✅ 不会覆盖配置文件中手动添加的其他配置（如 API Keys、平台配置等）
- ℹ️ 如需配置通道访问控制，请参考 [Q8: pairing required 错误](#q8-访问-gateway-时提示-disconnected-1008-pairing-required)

**使用方式**：
- 访问 Gateway 时需要带上 token 参数：
  ```
  https://your-space.hf.space/?token=YOUR_TOKEN_HERE
  ```

- 或在 API 请求头中添加：
  ```
  Authorization: Bearer YOUR_TOKEN_HERE
  ```

#### 2. AI Provider API Key（可选，推荐应用内配置）

- `ANTHROPIC_API_KEY` 或 `OPENAI_API_KEY`：AI 模型的 API 密钥

OpenClaw 需要至少一个 AI Provider 才能工作。你有两种配置方式：

**方式 1：环境变量配置（HuggingFace Secrets）**
- 在 HuggingFace Secrets 中直接配置
- 优点：简单直接
- 缺点：API Key 存储在 HuggingFace 平台

**方式 2：应用内配置（推荐）** ⭐
- 通过 Web Terminal 编辑 `~/.openclaw/openclaw.json` 配置文件
- 优点：
  - ✅ API Key 随数据备份到你的 Google Drive（更私密）
  - ✅ 容器重启自动恢复
  - ✅ 支持 OpenClaw 的所有高级配置选项
- 详细步骤见下文 ["应用内配置 API Key"](#应用内配置-api-key推荐) 章节

支持的 AI Provider：
- **Claude (Anthropic)**：`ANTHROPIC_API_KEY`
- **GPT (OpenAI)**：`OPENAI_API_KEY`
- 可同时配置多个 Provider

### 数据持久化配置（推荐使用 Google Drive 备份）

为了保存 bot 的长期记忆、对话历史等数据，本项目提供了**完全免费**的 Google Drive 自动备份方案：

#### 🎯 推荐方案: Google Drive 自动备份（免费 15GB）

**优势**：
- ✅ 本地 SQLite 高性能读写（无延迟）
- ✅ 自动备份到你的个人 Google Drive（容器重启可恢复）
- ✅ 完全免费（Google Drive 15GB 免费空间）
- ✅ 可自定义备份频率
- ✅ 无需创建 Google Cloud Project（比 Service Account 简单）

**配置步骤**：

##### 步骤 1: 在本地机器生成 OAuth Token

**前提条件**：需要一台有浏览器的电脑（macOS、Linux、Windows 均可）

1. **安装 rclone**
   
   **macOS**：
   ```bash
   curl https://rclone.org/install.sh | sudo bash
   ```
   
   **Linux**：
   ```bash
   curl https://rclone.org/install.sh | sudo bash
   ```
   
   **Windows**：
   - 访问 [rclone 下载页面](https://rclone.org/downloads/)
   - 下载并解压到任意目录（如 `C:\rclone`）
   - 在该目录打开 PowerShell 或 CMD

2. **生成 Google Drive OAuth Token**
   
   在终端执行：
   ```bash
   rclone authorize "drive"
   ```
   
   这会：
   - 自动打开浏览器跳转到 Google 登录页面
   - 要求你登录并授权 rclone 访问你的 Google Drive
   - 授权后，终端会输出类似以下内容：
   
   ```
   Paste the following into your remote machine --->
   {"access_token":"ya29.xxx...","token_type":"Bearer","refresh_token":"1//xxx...","expiry":"2026-01-31T10:00:00Z"}
   <---End paste
   ```

3. **复制 Token JSON**
   
   - 复制整个 JSON 字符串（包括花括号）
   - **重要**：这个 token 包含 `refresh_token`，可以长期使用（无需每次重新授权）
   - 保存好这个 JSON，下一步要用

**⚠️ Token 安全说明**：
- `access_token`：短期令牌（1小时有效），用于 API 调用
- `refresh_token`：长期令牌，用于自动刷新 `access_token`
- rclone 会自动管理 token 刷新，无需手动干预
- Token 有效期：只要不撤销授权，`refresh_token` 永久有效

##### 步骤 2: 配置 HuggingFace Secrets

1. **添加 OAuth Token**
   - 访问 Space Settings → Variables and secrets
   - 点击 "New secret"
   - **Name**: `RCLONE_OAUTH_TOKEN`
   - **Value**: 粘贴步骤 1 中生成的完整 JSON 字符串，例如：
     ```json
     {"access_token":"ya29.a0AfB_byD...","token_type":"Bearer","refresh_token":"1//0gd-xxx...","expiry":"2026-01-31T12:34:56Z"}
     ```
   - 设置为 **Secret**（保密）

2. **设置备份间隔（可选）**
   - 点击 "New variable"
   - Name: `BACKUP_INTERVAL_MINUTES`
   - Value: `60`（每 60 分钟备份一次，可自定义）
   - 设置为 **Variable**（非保密）

3. **重启 Space**
   - 点击 "Factory reboot" 重启容器

##### 步骤 3: 验证备份是否工作

1. **查看启动日志**
   - 访问 Space 主页，查看 Logs 标签
   - 或访问 `/terminal` 路径（Web 终端）执行：
     ```bash
     sudo supervisorctl tail -50 openclaw
     ```
   - 应该看到类似输出：
     ```
     📥 Checking for backup to restore...
     ℹ️  No backup found in Google Drive.
        Starting with fresh data.
     ⏰ Backup scheduled every 60 minutes
     ```

2. **手动测试备份**
   
   在 Web Terminal 中执行：
   ```bash
   cd /home/user/app
   bash backup.sh
   ```
   
   成功输出示例：
   ```
   🔄 [2026-01-31 13:30:00] Starting OpenClaw backup...
   📦 Copying data from /root/.openclaw...
   🗜️  Creating archive: /tmp/openclaw_backup_20260131_133000.tar.gz
   ☁️  Uploading to Google Drive: gdrive:/openclaw_backup
   Transferred:        1.234 MiB / 1.234 MiB, 100%, 2.345 MiB/s, ETA 0s
   ✅ Backup completed successfully at 2026-01-31 13:30:05
      Saved to: gdrive:/openclaw_backup/openclaw_backup_20260131_133000.tar.gz
   ```

3. **检查 Google Drive 中的备份文件**
   - 访问你的 [Google Drive](https://drive.google.com/)
   - 应该在根目录看到新建的 `openclaw_backup` 文件夹
   - 文件夹内包含：
     - `openclaw_backup_YYYYMMDD_HHMMSS.tar.gz`（带时间戳的备份）
     - `openclaw_backup_latest.tar.gz`（最新备份的副本）

##### 步骤 4: 测试恢复功能

1. **触发容器重启**（模拟数据丢失场景）
   - 在 HuggingFace Space Settings 中点击 "Factory reboot"

2. **查看恢复日志**
   - 重启后访问 Logs 标签
   - 应该看到：
     ```
     📥 [2026-01-31 14:00:00] Starting OpenClaw restore...
     🔍 Checking for backups in gdrive:/openclaw_backup...
     ☁️  Downloading latest backup from Google Drive...
     📦 Extracting backup to /root/.openclaw...
     ✅ Restore completed successfully at 2026-01-31 14:00:15
        Data restored to: /root/.openclaw
     ```

---

**🎓 常见问题**

**Q1: Token 会过期吗？**
- `access_token` 每小时过期，但 rclone 会自动使用 `refresh_token` 刷新
- `refresh_token` 理论上永久有效，除非你在 Google 账户中手动撤销授权
- 无需定期重新生成 token

**Q2: 如何更新或更换 Google 账号？**
1. 在本地重新运行 `rclone authorize "drive"` 并登录新账号
2. 将新生成的 JSON 更新到 HuggingFace Secrets 中的 `RCLONE_OAUTH_TOKEN`
3. 重启 Space

**Q3: 备份失败了怎么办？**
- 访问 Web Terminal 执行 `bash backup.sh` 查看详细错误信息
- 常见原因：
  - Token 格式错误（确保复制了完整的 JSON）
  - Google Drive 空间不足（检查 [storage.google.com](https://storage.google.com/)）
  - Token 被撤销（在 [myaccount.google.com/permissions](https://myaccount.google.com/permissions) 查看）

**Q4: 我想备份到不同的文件夹怎么办？**
- 在 HuggingFace Secrets 中添加新变量：
  - Name: `BACKUP_REMOTE`
  - Value: `gdrive:/my_custom_folder`（文件夹会自动创建）

3. **检查 Google Drive**
   - 访问你创建的 `openclaw_backup` 文件夹
   - 应该能看到备份文件：`openclaw_data_YYYY-MM-DD_HH-MM-SS.tar.gz`

**常见问题排查**：
- ❌ **"Failed to create file system for 'gdrive:'"**: JSON 格式错误，确保是单行且引号完整
- ❌ **"403 Forbidden"**: 检查是否共享了文件夹给 Service Account，权限是否为 Editor
- ❌ **"API not enabled"**: 确认已启用 Google Drive API

**工作原理**：
- 容器启动时自动从 Google Drive 恢复最新备份
- 每小时（可配置）自动备份到 Google Drive
- 容器关闭前自动执行最后一次备份

#### 备选方案: PostgreSQL 远程数据库

如果需要多端同步或团队协作，可以使用远程数据库（会有 50-200ms 网络延迟）：

##### Supabase (免费 500MB)
1. 访问 [Supabase](https://supabase.com/) 创建免费账号
2. 创建新项目，获取数据库连接字符串
3. 在 HuggingFace Secrets 中添加：
   ```
   OPENPROSE_POSTGRES_URL=postgresql://postgres.xxxx:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
   ```

##### Neon (免费 10GB)
1. 访问 [Neon](https://neon.tech/) 创建免费账号
2. 获取连接字符串并添加到 Secrets

**性能对比**：
- Google Drive 备份：本地读写延迟 <1ms，推荐
- PostgreSQL 远程：读写延迟 50-200ms，适合多端同步

**不配置持久化的影响**：容器重启后所有对话历史和记忆将丢失。

### 可选配置（根据需要的平台）

- `TELEGRAM_BOT_TOKEN`：Telegram 机器人令牌
- `WHATSAPP_ACCESS_TOKEN`：WhatsApp API 访问令牌
- `DISCORD_BOT_TOKEN`：Discord 机器人令牌
- `SLACK_BOT_TOKEN`：Slack 机器人令牌

### Web 终端配置（强烈推荐）

为了方便在运行时配置 OpenClaw（例如直接编辑配置文件、查看日志、手动执行备份等），本项目集成了 **Web 终端**。

**访问地址**：`https://your-space.hf.space/terminal`

#### 配置步骤

**⚠️ 安全警告**：Web 终端提供完整的 Shell 访问权限，**必须设置强密码**！

1. **生成安全密码**
   ```bash
   # 生成随机强密码
   openssl rand -base64 16
   # 输出示例: X8k9L2mP4qR7sT1vW3yZ5aC=
   ```

2. **在 HuggingFace Space Settings → Variables and secrets 中添加**
   - Name: `TTYD_USERNAME`
   - Value: `admin`（或你喜欢的用户名）
   - 设置为 **Variable**
   
   - Name: `TTYD_PASSWORD`
   - Value: 步骤 1 生成的强密码
   - 设置为 **Secret**（保密）

3. **重启 Space**
   - 点击 "Factory reboot" 重启容器

4. **访问 Web 终端**
   - 访问 `https://your-space.hf.space/terminal`
   - 使用你设置的用户名和密码登录

#### 常见用途

**编辑 OpenClaw 配置**：
```bash
# 查看当前配置
cat ~/.openclaw/openclaw.json

# 编辑配置文件（添加 API Keys 等）
vim ~/.openclaw/openclaw.json

# 或使用 nano 编辑器
nano ~/.openclaw/openclaw.json
```

**管理备份**：
```bash
# 手动执行备份
bash /home/user/app/backup.sh

# 恢复备份
bash /home/user/app/restore.sh
```

**查看日志**：
```bash
# 查看服务状态
sudo supervisorctl status

# 实时查看 OpenClaw 日志
sudo supervisorctl tail -f openclaw

# 查看 nginx 日志
sudo supervisorctl tail -f nginx
```

**系统管理**：
```bash
# 安装额外工具
sudo apt-get update && sudo apt-get install -y htop

# 查看系统资源
htop

# 检查端口占用
netstat -tlnp
```

**安全提示**：
- Web 终端使用 HTTP Basic Auth 保护
- **必须设置强密码**，避免使用默认密码 `changeme`
- 不要在公共网络中使用弱密码
- 终端会话具有完整的系统访问权限（sudo）
- 终端会话超时时间为 1 小时（无操作自动断开）

---

## 应用内配置 API Key（推荐）

相比在 HuggingFace Secrets 中配置 API Key，**更推荐通过应用内配置文件管理**。

### 优势

- ✅ **更私密**：API Key 存储在你的 Google Drive，不在 HuggingFace 平台
- ✅ **自动备份**：配置随数据一起备份，容器重启自动恢复
- ✅ **更灵活**：支持 OpenClaw 的所有高级配置选项
- ✅ **易于管理**：通过 Web Terminal 随时修改

### 配置步骤

#### 1. 首次部署（最小化配置）

在 HuggingFace Secrets 中只需配置：

```bash
# 必需：Gateway 认证
OPENCLAW_GATEWAY_TOKEN=<openssl rand -base64 32 生成>

# 推荐：Web 终端访问
TTYD_USERNAME=admin
TTYD_PASSWORD=<openssl rand -base64 16 生成>

# 推荐：Google Drive 备份
RCLONE_CONFIG_GDRIVE_JSON=<Service Account JSON 单行>
BACKUP_INTERVAL_MINUTES=60
```

**不需要配置 `ANTHROPIC_API_KEY` 或 `OPENAI_API_KEY`！**

#### 2. 通过 Web Terminal 编辑配置

1. **访问 Web Terminal**
   ```
   https://your-space.hf.space/terminal
   ```

2. **编辑配置文件**
   ```bash
   vim ~/.openclaw/openclaw.json
   ```
   
   或使用 nano（更适合新手）：
   ```bash
   nano ~/.openclaw/openclaw.json
   ```

3. **添加 API Keys**
   
   完整配置示例：
   ```json
   {
     "gateway": {
       "mode": "local",
       "port": 18789,
       "bind": "loopback",
       "auth": {
         "mode": "token",
         "token": "your-gateway-token-here"
       }
     },
     "providers": {
       "anthropic": {
         "apiKey": "sk-ant-xxxxxxxxxxxxxxxxxxxxx"
       },
       "openai": {
         "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx"
       }
     }
   }
   ```

4. **保存并退出**
   - **vim**：按 `Esc`，输入 `:wq`，按 `Enter`
   - **nano**：按 `Ctrl+O` 保存，按 `Ctrl+X` 退出

5. **重启 OpenClaw 服务**
   ```bash
   sudo supervisorctl restart openclaw
   ```

6. **验证配置**
   ```bash
   # 查看服务状态
   sudo supervisorctl status openclaw
   
   # 查看日志确认 API Key 加载
   sudo supervisorctl tail -f openclaw
   ```

#### 3. 手动触发备份（保存配置）

```bash
cd /home/user/app
bash backup.sh
```

成功输出：
```
✅ Backup completed successfully
   Saved to: gdrive:/openclaw_backup/openclaw_backup_20260131_140000.tar.gz
```

#### 4. 验证自动恢复

重启容器后，通过 Web Terminal 检查配置是否恢复：

```bash
cat ~/.openclaw/openclaw.json
# 应该能看到你之前添加的 API Keys
```

### 配置文件完整示例

```json
{
  "gateway": {
    "mode": "local",
    "port": 18789,
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "your-gateway-token"
    },
    "trustedProxies": ["127.0.0.1"]
  },
  "providers": {
    "anthropic": {
      "apiKey": "sk-ant-api03-xxxxx",
      "defaultModel": "claude-3-5-sonnet-20241022"
    },
    "openai": {
      "apiKey": "sk-proj-xxxxx",
      "defaultModel": "gpt-4"
    }
  },
  "platforms": {
    "telegram": {
      "token": "123456:ABCdefGHI..."
    },
    "discord": {
      "token": "MTIzNDU2Nzg5..."
    }
  }
}
```

### 常见操作

**查看当前配置**：
```bash
cat ~/.openclaw/openclaw.json | jq
```

**备份配置文件**：
```bash
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup
```

**测试配置是否有效**：
```bash
# 检查 JSON 格式是否正确
cat ~/.openclaw/openclaw.json | jq . > /dev/null && echo "✅ JSON 格式正确" || echo "❌ JSON 格式错误"
```

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

## 常见问题

### Q1: 访问 Gateway 时提示 "unauthorized: gateway token missing"？
**A**: OpenClaw 需要 token 认证才能访问。请确保：
1. 已在 HuggingFace Secrets 中设置 `OPENCLAW_GATEWAY_TOKEN`
2. 访问时带上 token 参数：`https://your-space.hf.space/?token=YOUR_TOKEN`
3. 或在 API 请求头中添加：`Authorization: Bearer YOUR_TOKEN`

### Q2: 如何生成安全的 Gateway Token？
**A**: 使用命令生成随机 token：
```bash
openssl rand -base64 32
```
将输出的字符串设置为 `OPENCLAW_GATEWAY_TOKEN` 环境变量。

### Q3: 容器重启后数据丢失怎么办？
**A**: HuggingFace Spaces 使用临时存储，重启后数据会丢失。解决方案：
- **推荐**：配置 Google Drive 自动备份（见上文"数据持久化配置"）
- **备选**：使用 PostgreSQL 远程数据库（Supabase/Neon）

### Q4: 如何查看服务运行状态？
**A**: 通过 Web 终端（`/terminal`）执行：
```bash
sudo supervisorctl status
# 应该显示：
# nginx      RUNNING
# openclaw   RUNNING
# ttyd       RUNNING
```

### Q5: Web 终端密码忘记了怎么办？
**A**: 在 HuggingFace Space Settings 中修改 `TTYD_PASSWORD` 环境变量，然后重启 Space。

### Q6: 如何配置多个 AI Provider？
**A**: 可以同时设置多个 API Key：
```bash
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
```
OpenClaw 会自动识别并支持多个 Provider。

### Q7: Gateway Token 可以禁用吗？
**A**: 不可以。OpenClaw Gateway 强制要求认证，不支持完全禁用 token。这是出于安全考虑。

### Q8: 访问 Gateway 时提示 "disconnected (1008): pairing required"？
**A**: 这表示 OpenClaw 需要 pairing（配对）认证。有三种解决方案：

**方案 1：修改配置为 Open 模式（适合测试）**
1. 通过 Web Terminal 编辑配置：
   ```bash
   nano ~/.openclaw/openclaw.json
   ```

2. 添加或修改 `channels` 配置：
   ```json
   {
     "gateway": {
       "mode": "local",
       "port": 18789,
       "bind": "loopback",
       "auth": {
         "mode": "token",
         "token": "your-gateway-token"
       }
     },
     "channels": {
       "telegram": {
         "enabled": true,
         "dmPolicy": "open",
         "allowFrom": ["*"]
       }
     }
   }
   ```
   **⚠️ 注意**：`dmPolicy: "open"` 必须配合 `allowFrom: ["*"]` 使用。

3. 保存后重启服务：
   ```bash
   sudo supervisorctl restart openclaw
   ```

**方案 2：使用 Allowlist 模式（生产推荐）**
```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": [
        "123456789"  // 你的 Telegram 用户 ID
      ]
    }
  }
}
```

获取 Telegram 用户 ID：
```bash
# 给 bot 发一条消息后，查看日志
sudo supervisorctl tail -f openclaw
# 找到日志中的 from.id 字段
```

**方案 3：批准 Pairing 请求**
```bash
# 查看待审批的请求
npx openclaw pairing list

# 批准特定的 pairing
npx openclaw pairing approve <pairing_code>
```

**dmPolicy 选项对比**：
- `pairing`：需要手动批准每个新用户（最安全）
- `allowlist`：仅允许白名单用户（推荐生产环境）
- `open`：允许所有人（仅测试环境）

### Q9: 如何更换或添加 AI Provider 的 API Key？

**推荐方式：通过 Web Terminal 编辑配置文件**

1. **访问 Web Terminal**
   ```
   https://your-space.hf.space/terminal
   ```
   使用你配置的 `TTYD_USERNAME` 和 `TTYD_PASSWORD` 登录

2. **编辑配置文件**
   ```bash
   nano ~/.openclaw/openclaw.json
   ```

3. **添加或修改 API Keys**
   ```json
   {
     "gateway": {
       "mode": "local",
       "port": 18789,
       "bind": "loopback",
       "auth": {
         "mode": "token",
         "token": "your-gateway-token"
       }
     },
     "providers": {
       "anthropic": {
         "apiKey": "sk-ant-xxxxxxxxxxxxxxxxxxxxx",
         "defaultModel": "claude-3-5-sonnet-20241022"
       },
       "openai": {
         "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxx",
         "defaultModel": "gpt-4"
       }
     }
   }
   ```

4. **保存并退出**
   - 按 `Ctrl+O` 保存
   - 按 `Ctrl+X` 退出

5. **重启 OpenClaw 服务**
   ```bash
   sudo supervisorctl restart openclaw
   ```

6. **验证配置生效**
   ```bash
   # 查看服务状态
   sudo supervisorctl status openclaw
   
   # 查看日志确认 API Key 已加载
   sudo supervisorctl tail -f openclaw
   ```

7. **触发备份（保存到 Google Drive）**
   ```bash
   bash /home/user/app/backup.sh
   ```

**优势**：
- ✅ API Key 存储在你的 Google Drive，更安全
- ✅ 容器重启后自动恢复
- ✅ 随时可以修改，无需重新部署

**详细说明**：见上文 ["应用内配置 API Key"](#应用内配置-api-key推荐) 章节

## License

MIT
