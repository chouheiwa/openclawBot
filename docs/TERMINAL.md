# Web Terminal 使用指南

Web Terminal 提供浏览器内 Shell 访问,方便运行时配置和调试。

**访问地址**：`https://your-space.hf.space/terminal`

---

## Web 终端配置（强烈推荐）

为了方便在运行时配置 OpenClaw（例如直接编辑配置文件、查看日志、手动执行备份等），本项目集成了 **Web 终端**。

**访问地址**：`https://your-space.hf.space/terminal`

### 配置步骤

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

### 常见用途

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
