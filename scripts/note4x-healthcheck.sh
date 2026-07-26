#!/data/data/com.termux/files/usr/bin/bash
# Note 4X 自愈互检 — 监控 K60 gateway，异常时自动重启，重启无效才告警
# 运行位置: Note 4X (Android 7, 骁龙625, 3GB — 仅 LAN，无 Tailscale)
# cron: */5 * * * * ~/healthcheck.sh
set -euo pipefail

# K60 LAN 地址（Note 4X 无 Tailscale，只能走局域网）
# IP 来源: K60 WiFi IP (device-comparison.md)，修改 IP 请同步更新
TARGET="u0_a129@192.168.1.23"
PORT="8022"
LOG=~/healthcheck.log
STAMP=~/healthcheck.last_restart
MAX_RETRY=2
COOLDOWN=600  # 10 分钟内不重复重启

log() { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }
alert() {
  log "🚨 ALERT: $1"
  timeout 15 openclaw agent --agent main --message "🚨 机队告警 (Note 4X): $1" 2>/dev/null || true
}

# ── 1. 快速探活 ──
HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
  "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"

if [ "$HTTP" = "200" ]; then
  exit 0  # 一切正常，静默退出
fi

# ── 2. SSH 不通 → Note 4X 是 LAN-only，K60 可能不在同一局域网 ──
if [ "$HTTP" = "ssh_fail" ]; then
  # 不频繁告警——Note 4X LAN-only 场景下 SSH 不通很常见（K60 出门了）
  log "K60 SSH 不可达 (LAN ${TARGET#*@})，可能 K60 不在局域网内"
  exit 0  # 静默，不骚扰
fi

# ── 3. 冷却检查 → 避免短时间内反复重启 ──
NOW=$(date +%s)
if [ -f "$STAMP" ]; then
  LAST=$(cat "$STAMP")
  ELAPSED=$((NOW - LAST))
  if [ "$ELAPSED" -lt "$COOLDOWN" ]; then
    log "K60 gateway ${HTTP}, 距上次重启 ${ELAPSED}s, 冷却中 (cooldown=${COOLDOWN}s)"
    exit 0
  fi
fi

# ── 4. 自愈循环：最多尝试 MAX_RETRY 次 ──
for ((i=1; i<=MAX_RETRY; i++)); do
  log "K60 gateway ${HTTP}, 第 ${i}/${MAX_RETRY} 次尝试远程重启…"
  ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "export SVDIR=\$PREFIX/var/service && sv restart openclaw" 2>/dev/null || {
    log "重启命令执行失败 (ssh ok but sv restart failed)"
    break
  }

  echo "$NOW" > "$STAMP"

  # 等待服务启动（Note 4X 是低端机，远程 SSH 启动较慢，多等）
  sleep 30

  # 重新探活
  HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"

  if [ "$HTTP" = "200" ]; then
    log "✅ 第 ${i} 次重启后恢复 (HTTP 200)"
    exit 0
  fi
done

# ── 5. 自愈失败 → 告警 ──
alert "K60 gateway 自愈失败 (Note 4X LAN 监控)：${MAX_RETRY} 次重启后仍 ${HTTP}，需人工介入。"
