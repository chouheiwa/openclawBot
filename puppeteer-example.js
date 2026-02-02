/**
 * Puppeteer 配置示例 - OpenClaw Bot
 * 
 * 支持人工介入的浏览器自动化配置
 * 通过 VNC 可实时查看和操作浏览器
 */

import puppeteer from 'puppeteer';

// 基础配置 - 适用于需要人工介入的场景
const launchOptions = {
  headless: false,  // 必须设置为 false，才能在 VNC 中看到浏览器
  
  executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium',
  
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',  // 使用 /tmp 而不是 /dev/shm
    '--disable-gpu',
    '--disable-software-rasterizer',
    '--disable-extensions',
    `--display=${process.env.DISPLAY || ':99'}`,  // 使用 Xvfb 虚拟显示
    '--window-size=1920,1080',
    '--start-maximized',
  ],
  
  // 默认超时设置
  defaultViewport: {
    width: 1920,
    height: 1080,
  },
  
  // 慢速操作便于人工观察和介入
  slowMo: 100,  // 每个操作延迟 100ms
};

// 示例 1: 基础使用
async function basicExample() {
  const browser = await puppeteer.launch(launchOptions);
  const page = await browser.newPage();
  
  await page.goto('https://example.com');
  
  // 等待用户手动操作（通过 VNC）
  console.log('浏览器已打开，可通过 VNC 手动操作');
  console.log('访问: http://localhost:7860/vnc');
  
  // 保持浏览器打开，等待手动操作
  await new Promise(resolve => setTimeout(resolve, 300000)); // 5分钟
  
  await browser.close();
}

// 示例 2: 扫码登录场景
async function qrCodeLoginExample() {
  const browser = await puppeteer.launch(launchOptions);
  const page = await browser.newPage();
  
  // 访问需要扫码的页面
  await page.goto('https://example.com/login');
  
  console.log('=================================');
  console.log('请通过 VNC 扫码登录');
  console.log('VNC 地址: http://localhost:7860/vnc');
  console.log('VNC 密码: openclaw');
  console.log('=================================');
  
  // 等待登录完成（检测特定元素或 URL 变化）
  try {
    await page.waitForNavigation({
      waitUntil: 'networkidle2',
      timeout: 120000  // 等待 2 分钟
    });
    console.log('登录成功！');
  } catch (error) {
    console.log('登录超时或失败');
  }
  
  // 继续后续自动化操作
  // ...
  
  await browser.close();
}

// 示例 3: 混合模式 - 自动化 + 人工介入
async function hybridExample() {
  const browser = await puppeteer.launch(launchOptions);
  const page = await browser.newPage();
  
  // 自动化部分
  await page.goto('https://example.com');
  await page.type('#username', 'your-username');
  await page.type('#password', 'your-password');
  
  // 检测是否有验证码
  const hasCaptcha = await page.$('#captcha') !== null;
  
  if (hasCaptcha) {
    console.log('检测到验证码，请通过 VNC 手动输入');
    console.log('VNC 地址: http://localhost:7860/vnc');
    
    // 等待用户完成验证码
    await page.waitForNavigation({
      waitUntil: 'networkidle2',
      timeout: 60000
    });
  } else {
    // 没有验证码，直接提交
    await page.click('#submit');
  }
  
  console.log('继续执行自动化任务...');
  
  await browser.close();
}

// 示例 4: 调试模式 - 暂停等待人工检查
async function debugExample() {
  const browser = await puppeteer.launch(launchOptions);
  const page = await browser.newPage();
  
  await page.goto('https://example.com');
  
  // 在关键步骤暂停，允许人工检查
  async function pauseForInspection(message, durationMs = 30000) {
    console.log(`\n⏸️  暂停: ${message}`);
    console.log(`   通过 VNC 查看: http://localhost:7860/vnc`);
    console.log(`   将在 ${durationMs/1000} 秒后继续...\n`);
    await new Promise(resolve => setTimeout(resolve, durationMs));
  }
  
  // 执行步骤 1
  await page.click('#step1');
  await pauseForInspection('步骤 1 完成，请检查页面状态');
  
  // 执行步骤 2
  await page.click('#step2');
  await pauseForInspection('步骤 2 完成，请检查页面状态');
  
  await browser.close();
}

// 环境变量配置说明
console.log(`
Puppeteer 环境变量:
- DISPLAY: ${process.env.DISPLAY || ':99'}
- PUPPETEER_EXECUTABLE_PATH: ${process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium'}

VNC 访问信息:
- noVNC Web: http://localhost:7860/vnc
- VNC 密码: ${process.env.VNC_PASSWORD || 'openclaw'}
- VNC 端口: ${process.env.VNC_PORT || '5900'}

注意事项:
1. headless 必须设置为 false
2. 需要启动 Xvfb 和 x11vnc 服务
3. 确保 supervisord 已正确启动所有服务
`);

// 导出配置供其他模块使用
export { launchOptions };

// 取消注释以运行示例
// basicExample();
// qrCodeLoginExample();
// hybridExample();
// debugExample();
