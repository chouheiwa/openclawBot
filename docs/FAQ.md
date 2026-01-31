# 常见问题（FAQ）

---

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
