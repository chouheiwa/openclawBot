# Google Drive 自动备份配置

本文档介绍如何配置 Google Drive OAuth 2.0 备份方案。

## 优势

- ✅ 本地 SQLite 高性能读写（<1ms 延迟）
- ✅ 自动备份到你的个人 Google Drive
- ✅ 完全免费（15GB 免费空间）
- ✅ 容器重启自动恢复数据

---

## 🎯 推荐方案: Google Drive 自动备份（免费 15GB）

**优势**：
- ✅ 本地 SQLite 高性能读写（无延迟）
- ✅ 自动备份到你的个人 Google Drive（容器重启可恢复）
- ✅ 完全免费（Google Drive 15GB 免费空间）
- ✅ 可自定义备份频率
- ✅ 无需创建 Google Cloud Project（比 Service Account 简单）

**配置步骤**：

### 步骤 1: 在本地机器生成 OAuth Token

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

### 步骤 2: 配置 HuggingFace Secrets

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

### 步骤 3: 验证备份是否工作

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

### 步骤 4: 测试恢复功能

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

## 🎓 常见问题

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

---

## 常见问题排查

- ❌ **"Failed to create file system for 'gdrive:'"**: JSON 格式错误，确保是单行且引号完整
- ❌ **"403 Forbidden"**: 检查是否共享了文件夹给 Service Account，权限是否为 Editor
- ❌ **"API not enabled"**: 确认已启用 Google Drive API

## 工作原理

- 容器启动时自动从 Google Drive 恢复最新备份
- 每小时（可配置）自动备份到 Google Drive
- 容器关闭前自动执行最后一次备份
