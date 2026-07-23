#!/data/data/com.termux/files/usr/bin/bash
# Note 7 自愈互检 — 监控 K60 gateway，异常时自动重启，重启无效才告警
# cron: */5 * * * * ~/healthcheck.sh
set -euo pipefail

TARGET="u0_a129@100.118.60.29"
PORT="8022"
LOG=~/healthcheck.log
STAMP=~/healthcheck.last_restart
MAX_RETRY=2
COOLDOWN=600  # 10 分钟内不重复重启

log() { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }
alert() {
  log "🚨 ALERT: $1"
  timeout 15 openclaw agent --agent main --message "🚨 机队告警: $1" 2>/dev/null || true
}

# ── 1. 快速探活 ──
HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
  "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"

if [ "$HTTP" = "200" ]; then
  exit 0
fi

# ── 2. SSH 不通 → 无法自愈，直接告警 ──
if [ "$HTTP" = "ssh_fail" ]; then
  alert "K60 SSH 不可达，无法自愈，请检查设备是否在线。"
  exit 1
fi

# ── 3. 冷却检查 ──
NOW=$(date +%s)
if [ -f "$STAMP" ]; then
  LAST=$(cat "$STAMP")
  ELAPSED=$((NOW - LAST))
  if [ "$ELAPSED" -lt "$COOLDOWN" ]; then
    log "K60 gateway ${HTTP}, 距上次重启 ${ELAPSED}s, 冷却中 (cooldown=${COOLDOWN}s)"
    exit 0
  fi
fi

# ── 4. 自愈循环 ──
for ((i=1; i<=MAX_RETRY; i++)); do
  log "K60 gateway ${HTTP}, 第 ${i}/${MAX_RETRY} 次尝试远程重启…"
  ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "export SVDIR=\$PREFIX/var/service && sv restart openclaw" 2>/dev/null || {
    log "重启命令执行失败"
    break
  }

  echo "$NOW" > "$STAMP"
  sleep 20

  HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"

  if [ "$HTTP" = "200" ]; then
    log "✅ 第 ${i} 次重启后恢复 (HTTP 200)"
    exit 0
  fi
done

# ── 5. 自愈失败 → 告警 ──
alert "K60 gateway 自愈失败：${MAX_RETRY} 次重启后仍 ${HTTP}，需人工介入。"
