import { spawn, execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { homedir } from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// OpenClaw Gateway 监听内部端口 18789
// Nginx 在 7860 端口反向代理到这里
const GATEWAY_PORT = process.env.OPENCLAW_PORT || '18789';
const PUBLIC_PORT = process.env.PORT || '7860';

console.log(`🚀 Starting OpenClaw Gateway on port ${GATEWAY_PORT} (proxied via nginx on ${PUBLIC_PORT})`);

// 恢复备份（如果配置了 Google Drive）
console.log('📥 Checking for backup to restore...');
try {
  execSync('bash restore.sh', { stdio: 'inherit', cwd: __dirname });
} catch (error) {
  console.warn('⚠️  Restore script failed, continuing with fresh data');
}

// 确保 OpenClaw 配置目录存在
const openclawDir = join(homedir(), '.openclaw');
const configFile = join(openclawDir, 'openclaw.json');

if (!existsSync(openclawDir)) {
  mkdirSync(openclawDir, { recursive: true });
}

// 创建或更新配置文件
let config = {};
let configExists = existsSync(configFile);

if (configExists) {
  // 读取现有配置
  try {
    const configContent = readFileSync(configFile, 'utf-8');
    config = JSON.parse(configContent);
    console.log('📖 Loading existing OpenClaw configuration...');
  } catch (error) {
    console.warn('⚠️  Failed to parse existing config, creating new one:', error.message);
    config = {};
    configExists = false;
  }
} else {
  console.log('📝 Creating initial OpenClaw configuration...');
}

// 确保 gateway 配置存在
if (!config.gateway) {
  config.gateway = {};
}

// 同步环境变量到配置（每次启动都更新）
config.gateway.mode = 'local';
config.gateway.port = parseInt(GATEWAY_PORT);
config.gateway.bind = 'lan';

// 注意：dmPolicy 是通道级别的配置，不是 gateway 级别的
// 如果需要配置 dmPolicy，应该在 config.channels.<provider> 中设置

// 更新 Gateway Token（如果环境变量中有设置）
if (process.env.OPENCLAW_GATEWAY_TOKEN) {
  if (!config.gateway.auth) {
    config.gateway.auth = {};
  }
  config.gateway.auth.mode = 'token';
  config.gateway.auth.token = process.env.OPENCLAW_GATEWAY_TOKEN;
  console.log('🔑 Gateway token updated from environment variable');
} else if (!config.gateway.auth || !config.gateway.auth.token) {
  // 如果环境变量和配置文件都没有 token，使用默认值
  if (!config.gateway.auth) {
    config.gateway.auth = {};
  }
  config.gateway.auth.mode = 'token';
  config.gateway.auth.token = 'changeme-insecure-token';
  console.log('⚠️  Using default gateway token (please set OPENCLAW_GATEWAY_TOKEN)');
}

// 如果环境变量中有 API key，添加或更新到配置中（仅首次创建时）
if (!configExists) {
  if (process.env.ANTHROPIC_API_KEY) {
    if (!config.providers) config.providers = {};
    config.providers.anthropic = {
      apiKey: process.env.ANTHROPIC_API_KEY
    };
    console.log('🤖 Added Anthropic API key from environment variable');
  }
  
  if (process.env.OPENAI_API_KEY) {
    if (!config.providers) config.providers = {};
    config.providers.openai = {
      apiKey: process.env.OPENAI_API_KEY
    };
    console.log('🤖 Added OpenAI API key from environment variable');
  }
}

// 写入配置文件
writeFileSync(configFile, JSON.stringify(config, null, 2));
if (configExists) {
  console.log('✅ Configuration updated at:', configFile);
} else {
  console.log('✅ Configuration created at:', configFile);
}

console.log('📁 Data directory:', openclawDir);

// Check if openclaw is installed
const openclawPath = join(__dirname, 'node_modules', '.bin', 'openclaw');

if (!existsSync(openclawPath)) {
  console.error('❌ OpenClaw not found. Please run: npm install');
  process.exit(1);
}

// 启动定时备份任务（如果配置了 Google Drive OAuth）
let backupInterval = null;
const BACKUP_INTERVAL = parseInt(process.env.BACKUP_INTERVAL_MINUTES || '60') * 60 * 1000;

if (process.env.RCLONE_OAUTH_TOKEN) {
  console.log(`⏰ Backup scheduled every ${BACKUP_INTERVAL / 60000} minutes`);
  backupInterval = setInterval(() => {
    console.log('🔄 Running scheduled backup...');
    try {
      execSync('bash backup.sh', { stdio: 'inherit', cwd: __dirname });
    } catch (error) {
      console.error('❌ Backup failed:', error.message);
    }
  }, BACKUP_INTERVAL);
} else {
  console.log('ℹ️  Backup disabled (RCLONE_OAUTH_TOKEN not set)');
}

// Start OpenClaw gateway with environment variables
const gateway = spawn('npx', ['openclaw', 'gateway'], {
  env: {
    ...process.env,
    PORT: GATEWAY_PORT,
    // OpenClaw listens on internal port 18789, proxied by nginx on port 7860
    OPENCLAW_PORT: GATEWAY_PORT,
  },
  stdio: 'inherit',
  shell: true
});

gateway.on('error', (error) => {
  console.error('❌ Failed to start OpenClaw:', error);
  process.exit(1);
});

gateway.on('exit', (code) => {
  console.log(`OpenClaw gateway exited with code ${code}`);
  
  // 退出前进行最后一次备份
  if (process.env.RCLONE_OAUTH_TOKEN) {
    console.log('💾 Performing final backup before exit...');
    try {
      execSync('bash backup.sh', { stdio: 'inherit', cwd: __dirname });
    } catch (error) {
      console.error('❌ Final backup failed:', error.message);
    }
  }
  
  if (backupInterval) clearInterval(backupInterval);
  process.exit(code);
});

// Handle shutdown gracefully
process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down gracefully...');
  gateway.kill('SIGTERM');
});

process.on('SIGINT', () => {
  console.log('Received SIGINT, shutting down gracefully...');
  gateway.kill('SIGINT');
});
