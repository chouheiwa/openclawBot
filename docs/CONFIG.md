# 环境变量配置指南

本文档详细说明所有可配置的环境变量。

> 💡 **提示**：所有环境变量在 HuggingFace Space Settings → Variables and secrets 中配置。

---

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
     "apiKeys": {
       "anthropic": "sk-ant-api03-...",
       "openai": "sk-proj-..."
     },
     "platforms": {
       "telegram": {
         "token": "123456:ABC-..."
       }
     }
   }
   ```
