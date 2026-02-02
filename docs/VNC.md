# VNC 远程桌面访问指南

本文档介绍如何通过 VNC 访问容器内的图形界面，用于查看和操作浏览器（Puppeteer/Playwright）。

## 📋 目录

- [功能概述](#功能概述)
- [访问方式](#访问方式)
- [使用场景](#使用场景)
- [Puppeteer 配置](#puppeteer-配置)
- [常见问题](#常见问题)

---

## 🎯 功能概述

容器内已配置完整的 VNC 服务，包括：

- **Xvfb**: 虚拟显示服务器（`:99`）
- **x11vnc**: VNC 服务器（端口 `5900`）
- **Fluxbox**: 轻量级窗口管理器
- **noVNC**: Web 端 VNC 客户端（端口 `6080`）
- **Chromium**: 完整的浏览器环境

**适用场景**:
- ✅ 扫码登录（微信、QQ、钉钉等）
- ✅ 图形验证码识别和输入
- ✅ 需要人工点击确认的操作
- ✅ 调试和检查浏览器自动化流程

---

## 🌐 访问方式

### 方式 1: Web 浏览器访问（推荐）

无需安装任何客户端，直接通过浏览器访问：

```
http://localhost:7860/vnc
```

或使用完整 URL 参数：

```
http://localhost:7860/vnc/vnc.html?autoconnect=1
```

**登录凭证**:
- 用户名: 使用你设置的 nginx 认证用户名（见 [TERMINAL.md](./TERMINAL.md)）
- VNC 密码: `openclaw` (可通过环境变量 `VNC_PASSWORD` 修改)

### 方式 2: VNC 客户端访问

如果你有专业的 VNC 客户端（如 TigerVNC、RealVNC），可以直接连接：

```
vnc://localhost:5900
```

**注意**: 直接连接 VNC 端口需要确保防火墙允许 `5900` 端口。

---

## 💡 使用场景

### 场景 1: 扫码登录

```javascript
// 示例：微信扫码登录
import puppeteer from 'puppeteer';

const browser = await puppeteer.launch({
  headless: false,  // 必须设置为 false
  executablePath: '/usr/bin/chromium',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--display=:99',
    '--window-size=1920,1080',
  ]
});

const page = await browser.newPage();
await page.goto('https://wx.qq.com/');

console.log('请通过 VNC 扫码登录: http://localhost:7860/vnc');

// 等待登录完成（检测 URL 变化）
await page.waitForNavigation({
  waitUntil: 'networkidle2',
  timeout: 120000  // 等待 2 分钟
});

console.log('登录成功！');
// 继续后续操作...
```

**操作步骤**:
1. 运行脚本，浏览器会在虚拟显示上打开
2. 访问 `http://localhost:7860/vnc` 查看二维码
3. 用手机扫码登录
4. 脚本自动继续后续流程

---

### 场景 2: 图形验证码

```javascript
// 示例：处理需要人工输入的验证码
const browser = await puppeteer.launch({
  headless: false,
  executablePath: '/usr/bin/chromium',
  args: ['--no-sandbox', '--display=:99']
});

const page = await browser.newPage();
await page.goto('https://example.com/login');

// 输入用户名密码
await page.type('#username', 'user');
await page.type('#password', 'pass');

// 检测是否有验证码
const hasCaptcha = await page.$('#captcha-image') !== null;

if (hasCaptcha) {
  console.log('检测到验证码，请通过 VNC 手动输入');
  console.log('VNC 地址: http://localhost:7860/vnc');
  
  // 等待用户手动输入并提交
  await page.waitForNavigation({
    waitUntil: 'networkidle2',
    timeout: 60000
  });
} else {
  await page.click('#login-button');
}
```

---

### 场景 3: 调试自动化脚本

```javascript
// 示例：暂停执行，允许人工检查
async function pauseForInspection(page, message, seconds = 30) {
  console.log(`\n⏸️  暂停: ${message}`);
  console.log(`   VNC 地址: http://localhost:7860/vnc`);
  console.log(`   将在 ${seconds} 秒后继续...\n`);
  
  await new Promise(resolve => setTimeout(resolve, seconds * 1000));
}

// 在关键步骤插入暂停
await page.click('#important-button');
await pauseForInspection(page, '点击按钮后，请检查页面状态', 30);

// 继续执行
await page.type('#input', 'some value');
```

---

## ⚙️ Puppeteer 配置

### 基础配置

```javascript
const launchOptions = {
  headless: false,  // ⚠️ 必须设置为 false
  
  executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium',
  
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--display=:99',  // 使用虚拟显示
    '--window-size=1920,1080',
  ],
  
  defaultViewport: {
    width: 1920,
    height: 1080,
  },
  
  slowMo: 100,  // 减慢操作速度便于观察
};

const browser = await puppeteer.launch(launchOptions);
```

### 环境变量

在 `.env` 文件中配置：

```bash
# 显示服务器
DISPLAY=:99

# VNC 配置
VNC_PORT=5900
NOVNC_PORT=6080
VNC_PASSWORD=openclaw

# Puppeteer 配置
PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
```

### 完整示例

参考项目根目录的 `puppeteer-example.js` 文件，包含：
- 基础使用
- 扫码登录示例
- 混合自动化 + 人工介入
- 调试模式

运行示例：

```bash
node puppeteer-example.js
```

---

## 🔍 常见问题

### Q1: 访问 VNC 时提示 "Connection failed"

**原因**: VNC 服务未启动或端口配置错误

**解决方法**:
```bash
# 检查服务状态
supervisorctl status

# 应该看到以下服务运行中:
# xvfb      RUNNING
# fluxbox   RUNNING
# x11vnc    RUNNING
# novnc     RUNNING

# 重启服务
supervisorctl restart xvfb fluxbox x11vnc novnc
```

---

### Q2: VNC 连接成功但看不到浏览器窗口

**原因**: Puppeteer 使用了 headless 模式

**解决方法**:
```javascript
// ❌ 错误
const browser = await puppeteer.launch({ headless: true });

// ✅ 正确
const browser = await puppeteer.launch({ 
  headless: false,
  args: ['--display=:99']
});
```

---

### Q3: 浏览器崩溃或无法启动

**原因**: 共享内存不足

**解决方法**:

添加 Docker 启动参数：
```bash
docker run --shm-size=2g ...
```

或在 `docker-compose.yml` 中：
```yaml
services:
  app:
    shm_size: '2gb'
```

或在 Puppeteer 中禁用共享内存：
```javascript
args: ['--disable-dev-shm-usage']
```

---

### Q4: VNC 画面卡顿

**原因**: 网络带宽或资源不足

**优化方法**:
1. **降低颜色深度**: 在 noVNC 设置中选择 "Low color"
2. **调整压缩级别**: noVNC 设置 -> Compression level
3. **增加资源**: 为容器分配更多 CPU 和内存

---

### Q5: 如何修改 VNC 密码？

**方法 1: 环境变量**（推荐）

在 `.env` 文件中：
```bash
VNC_PASSWORD=your-new-password
```

**方法 2: 修改 supervisor 配置**

编辑 `supervisord.conf`:
```ini
[program:x11vnc]
command=/usr/bin/x11vnc -display :99 -forever -shared -rfbport 5900 -passwd your-new-password
```

重启服务：
```bash
supervisorctl restart x11vnc
```

---

### Q6: 多个浏览器窗口如何管理？

**建议**: 使用 Puppeteer 的多页面管理

```javascript
const browser = await puppeteer.launch({ headless: false });

// 打开多个页面
const page1 = await browser.newPage();
const page2 = await browser.newPage();

await page1.goto('https://example1.com');
await page2.goto('https://example2.com');

// 在 VNC 中可以看到两个浏览器标签
// 可以手动切换标签页进行操作
```

---

## 🔒 安全建议

1. **修改默认密码**: 生产环境务必修改 `VNC_PASSWORD`
2. **启用 HTTPS**: 通过反向代理（如 Caddy）启用 SSL
3. **限制访问**: 使用防火墙或 VPN 限制 VNC 端口访问
4. **审计日志**: 定期检查 VNC 访问日志

---

## 📚 相关文档

- [TERMINAL.md](./TERMINAL.md) - Web 终端访问指南
- [CONFIG.md](./CONFIG.md) - 环境变量配置说明
- [FAQ.md](./FAQ.md) - 常见问题解答

---

## 📞 技术支持

如有问题，请查看：
- [项目 Issues](https://github.com/chouheiwa/openclawBot/issues)
- [Puppeteer 官方文档](https://pptr.dev)
- [noVNC 项目主页](https://novnc.com)
