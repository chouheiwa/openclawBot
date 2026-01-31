#!/bin/bash
# OpenClaw 数据备份脚本 - 备份到 Google Drive

set -e

echo "🔄 [$(date '+%Y-%m-%d %H:%M:%S')] Starting OpenClaw backup..."

# 配置
DATA_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
BACKUP_REMOTE="${BACKUP_REMOTE:-gdrive:/openclaw_backup}"
OAUTH_TOKEN="${RCLONE_OAUTH_TOKEN}"

# 检查数据目录是否存在
if [ ! -d "$DATA_DIR" ]; then
    echo "⚠️  Data directory not found: $DATA_DIR"
    echo "   Nothing to backup."
    exit 0
fi

# 检查是否配置了 Google Drive OAuth
if [ -z "$OAUTH_TOKEN" ]; then
    echo "⚠️  RCLONE_OAUTH_TOKEN not set. Skipping backup."
    echo "   Please configure Google Drive OAuth token in HuggingFace Secrets."
    echo "   Run: rclone authorize \"drive\" on your local machine to generate token."
    exit 0
fi

# 配置 rclone (使用 OAuth Token)
export RCLONE_CONFIG_GDRIVE_TYPE=drive
export RCLONE_CONFIG_GDRIVE_SCOPE=drive
export RCLONE_CONFIG_GDRIVE_TOKEN="$OAUTH_TOKEN"

# 创建临时备份目录
BACKUP_DIR="/tmp/openclaw_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"

# 复制数据到临时目录
echo "📦 Copying data from $DATA_DIR..."
cp -r "$DATA_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true

# 创建压缩包
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/tmp/openclaw_backup_${TIMESTAMP}.tar.gz"
echo "🗜️  Creating archive: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" . 2>/dev/null || true

# 上传到 Google Drive
echo "☁️  Uploading to Google Drive: $BACKUP_REMOTE"
rclone copy "$BACKUP_FILE" "$BACKUP_REMOTE" --progress 2>&1 || {
    echo "❌ Backup failed"
    rm -f "$BACKUP_FILE"
    rm -rf "$BACKUP_DIR"
    exit 1
}

# 保留最近的备份文件（也上传最新版本）
LATEST_FILE="/tmp/openclaw_backup_latest.tar.gz"
cp "$BACKUP_FILE" "$LATEST_FILE"
rclone copy "$LATEST_FILE" "$BACKUP_REMOTE" --progress 2>&1

# 清理临时文件
rm -f "$BACKUP_FILE" "$LATEST_FILE"
rm -rf "$BACKUP_DIR"

echo "✅ Backup completed successfully at $(date '+%Y-%m-%d %H:%M:%S')"
echo "   Saved to: $BACKUP_REMOTE/openclaw_backup_${TIMESTAMP}.tar.gz"
