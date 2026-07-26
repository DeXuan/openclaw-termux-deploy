#!/data/data/com.termux/files/usr/bin/bash
# OpenClaw 版本更新检测 — npm 扫描，有新版本时飞书告警
# cron: 37 10 * * 1  ~/check-version.sh  (周一 10:37)
set -euo pipefail

LOG=~/check-version.log
STAMP=~/check-version.last

log() { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }

# ── 获取本地版本 ──
if ! command -v openclaw &>/dev/null; then
  log "SKIP: openclaw 未安装"
  exit 0
fi

LOCAL_VER=$(openclaw --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9.]+)?' | head -1)
if [ -z "$LOCAL_VER" ]; then
  log "SKIP: 无法解析本地版本"
  exit 0
fi

# ── 获取 npm 最新版本 ──
# 优先用 npm view（最快），失败则用 registry API
LATEST_VER=$(npm view openclaw version 2>/dev/null) || \
  LATEST_VER=$(curl -4 -s --connect-timeout 10 \
    "https://registry.npmjs.org/openclaw/latest" 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin).get('version',''))" 2>/dev/null)

if [ -z "$LATEST_VER" ]; then
  log "SKIP: 无法获取 npm 最新版本"
  exit 0
fi

# ── 已经检查过的版本不重复告警 ──
LAST_CHECKED=""
[ -f "$STAMP" ] && LAST_CHECKED=$(cat "$STAMP")

# ── 版本比较 ──
if [ "$LOCAL_VER" = "$LATEST_VER" ]; then
  # 版本一致，记录
  log "OK: openclaw ${LOCAL_VER} 已是最新"
  exit 0
fi

# 同一个新版已经告警过就不再重复
if [ "$LATEST_VER" = "$LAST_CHECKED" ]; then
  exit 0
fi

echo "$LATEST_VER" > "$STAMP"

# ── 有新版本 ──
UPDATE_MSG="📦 OpenClaw 新版本可用: ${LOCAL_VER} → ${LATEST_VER}
升级命令: GYP_DEFINES=\"android_ndk_path=\" npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@${LATEST_VER}"

log "UPDATE: $UPDATE_MSG"

# ── 飞书告警 ──
if echo "$UPDATE_MSG" | python3 ~/feishu_push.py -t "📦 OpenClaw 更新" >> "$LOG" 2>&1; then
  log "飞书推送成功"
else
  log "飞书推送失败（feishu_push.py 不存在或凭证未配置）"
fi
