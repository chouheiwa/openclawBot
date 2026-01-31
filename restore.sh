#!/bin/bash
# OpenClaw 数据恢复脚本 - 从 Google Drive 恢复

set -e

echo "📥 [$(date '+%Y-%m-%d %H:%M:%S')] Starting OpenClaw restore..."

# 配置
DATA_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
BACKUP_REMOTE="${BACKUP_REMOTE:-gdrive:/openclaw_backup}"
OAUTH_TOKEN="${RCLONE_OAUTH_TOKEN}"

# 检查是否配置了 Google Drive OAuth
if [ -z "$OAUTH_TOKEN" ]; then
    echo "⚠️  RCLONE_OAUTH_TOKEN not set. Skipping restore."
    echo "   Starting with fresh data."
    mkdir -p "$DATA_DIR"
    exit 0
fi

# 配置 rclone (使用 OAuth Token)
export RCLONE_CONFIG_GDRIVE_TYPE=drive
export RCLONE_CONFIG_GDRIVE_SCOPE=drive
export RCLONE_CONFIG_GDRIVE_TOKEN="$OAUTH_TOKEN"

# 检查备份是否存在
echo "🔍 Checking for backups in $BACKUP_REMOTE..."
if ! rclone lsf "$BACKUP_REMOTE/openclaw_backup_latest.tar.gz" >/dev/null 2>&1; then
    echo "ℹ️  No backup found in Google Drive."
    echo "   Starting with fresh data."
    mkdir -p "$DATA_DIR"
    exit 0
fi

# 下载最新备份
BACKUP_FILE="/tmp/openclaw_backup_latest.tar.gz"
echo "☁️  Downloading latest backup from Google Drive..."
rclone copy "$BACKUP_REMOTE/openclaw_backup_latest.tar.gz" /tmp/ --progress 2>&1 || {
    echo "❌ Failed to download backup"
    mkdir -p "$DATA_DIR"
    exit 1
}

# 创建数据目录
mkdir -p "$DATA_DIR"

# 解压备份
echo "📦 Extracting backup to $DATA_DIR..."
tar -xzf "$BACKUP_FILE" -C "$DATA_DIR" 2>/dev/null || {
    echo "❌ Failed to extract backup"
    rm -f "$BACKUP_FILE"
    exit 1
}

# 清理临时文件
rm -f "$BACKUP_FILE"

echo "✅ Restore completed successfully at $(date '+%Y-%m-%d %H:%M:%S')"
echo "   Data restored to: $DATA_DIR"
