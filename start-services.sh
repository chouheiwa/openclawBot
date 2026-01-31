#!/bin/bash
set -e

echo "================================================"
echo "🚀 Starting OpenClaw with Web Terminal"
echo "================================================"

# 诊断信息
echo "📊 System Info:"
echo "  - User: $(whoami)"
echo "  - Node: $(node --version)"
echo "  - npm: $(npm --version)"
echo "  - Working directory: $(pwd)"
echo ""

# Create nginx temp directories
echo "📁 Creating nginx temp directories..."
mkdir -p /tmp/nginx/body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi
chown -R user:user /tmp/nginx
echo "   ✅ Nginx temp directories created"

# Generate htpasswd file for Web Terminal authentication
TTYD_USERNAME=${TTYD_USERNAME:-admin}
TTYD_PASSWORD=${TTYD_PASSWORD:-changeme}

echo ""
echo "🔐 Setting up Web Terminal authentication..."
echo "   Username: $TTYD_USERNAME"
echo "   Password: [REDACTED]"
mkdir -p /etc/nginx
htpasswd -bc /etc/nginx/.htpasswd "$TTYD_USERNAME" "$TTYD_PASSWORD"
chmod 644 /etc/nginx/.htpasswd
echo "   ✅ Authentication configured"

# 验证 OpenClaw 安装
echo ""
echo "🔍 Checking OpenClaw installation..."
if [ ! -d "/home/user/app/node_modules/openclaw" ]; then
    echo "   ❌ ERROR: OpenClaw not installed!"
    echo "   Attempting to install..."
    cd /home/user/app
    su - user -c "cd /home/user/app && npm install"
fi
echo "   ✅ OpenClaw found"

# 验证配置文件
echo ""
echo "📋 Checking configuration files..."
echo "   - supervisord.conf: $([ -f /home/user/app/supervisord.conf ] && echo '✅' || echo '❌')"
echo "   - nginx.conf: $([ -f /etc/nginx/nginx.conf ] && echo '✅' || echo '❌')"
echo "   - start.js: $([ -f /home/user/app/start.js ] && echo '✅' || echo '❌')"

# 验证端口可用性
echo ""
echo "🔌 Checking ports..."
netstat -tuln 2>/dev/null | grep -E ':(7860|18789|7681)' && echo "   ⚠️  Some ports already in use!" || echo "   ✅ All ports available"

# Start all services via supervisor
echo ""
echo "🎬 Starting services (nginx, openclaw, ttyd)..."
echo "================================================"
exec /usr/bin/supervisord -c /home/user/app/supervisord.conf
