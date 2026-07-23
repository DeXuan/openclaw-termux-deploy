#!/data/data/com.termux/files/usr/bin/bash
# 本地自愈体检 — 内存/磁盘/swap 阈值保护 + gateway 自检
# cron: */10 * * * * ~/self-check.sh
set -euo pipefail

LOG=~/self-check.log
ALERT_LOG=~/self-check.alert.log
HOSTNAME=$(hostname 2>/dev/null || echo "unknown")

# ── 阈值配置 ──
MEM_MIN_MB=500        # 可用内存低于此值触发清理
SWAP_MAX_PCT=80       # swap 使用率超过此值告警
DISK_MAX_PCT=90       # 磁盘使用率超过此值清理
LOG_MAX_KB=5120       # 单个日志超过此值截断 (5MB)

log()  { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }
alert() {
  echo "[$(date '+%m-%d %H:%M')] $1" >> "$ALERT_LOG"
  timeout 15 openclaw agent --agent main --message "⚙️ ${HOSTNAME}: $1" 2>/dev/null || true
}

CLEANED=0

# ── 1. 磁盘保护 ──
DISK_PCT=$(df /data 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}' || echo "0")
if [ "$DISK_PCT" -gt "$DISK_MAX_PCT" ] 2>/dev/null; then
  log "磁盘 ${DISK_PCT}% > ${DISK_MAX_PCT}%, 清理中…"
  # 清理 openclaw 日志
  find "$PREFIX/var/log/sv/openclaw/" -name "current" -size +"${LOG_MAX_KB}"k -exec truncate -s 0 {} \; 2>/dev/null || true
  # 清理旧日志
  find "$PREFIX/var/log/sv/openclaw/" -name "@*" -mtime +3 -delete 2>/dev/null || true
  find "$PREFIX/var/log/sv/openclaw/" -name "lock" -mtime +3 -delete 2>/dev/null || true
  # 清理 npm 缓存
  npm cache clean --force 2>/dev/null || true
  CLEANED=1
  log "磁盘清理完成"
fi

# ── 2. 内存保护 ──
AVAIL_KB=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo "999999")
AVAIL_MB=$((AVAIL_KB / 1024))

if [ "$AVAIL_MB" -lt "$MEM_MIN_MB" ]; then
  log "可用内存 ${AVAIL_MB}MB < ${MEM_MIN_MB}MB, 清理中…"
  # 截断日志释放内存
  find "$PREFIX/var/log/sv/openclaw/" -name "current" -size +"${LOG_MAX_KB}"k -exec truncate -s 0 {} \; 2>/dev/null || true
  # 清理文件系统缓存（需要 root，大概率无权限，忽略）
  sync 2>/dev/null || true
  echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true
  CLEANED=1
  log "内存清理完成, 可用 ${AVAIL_MB}MB"

  # 清理后仍然不够 → 重启 gateway 释放 Node.js heap
  sleep 5
  AVAIL_KB2=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
  AVAIL_MB2=$((AVAIL_KB2 / 1024))
  if [ "$AVAIL_MB2" -lt "$MEM_MIN_MB" ]; then
    log "清理后仍不足 (${AVAIL_MB2}MB), 重启 gateway…"
    export SVDIR="$PREFIX/var/service"
    sv restart openclaw 2>/dev/null || true
    log "gateway 已重启"
  fi
fi

# ── 3. Swap 保护 ──
SWAP_TOTAL=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
if [ "$SWAP_TOTAL" -gt 0 ]; then
  SWAP_FREE=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
  SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
  SWAP_PCT=$((SWAP_USED * 100 / SWAP_TOTAL))
  if [ "$SWAP_PCT" -gt "$SWAP_MAX_PCT" ]; then
    alert "Swap ${SWAP_PCT}% (${SWAP_USED}KB/${SWAP_TOTAL}KB), 需关注。Android 无法主动释放 swap，建议稍后观察或重启 gateway。"
  fi
fi

# ── 4. Gateway 自检 ──
HTTP=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 http://127.0.0.1:18789/ 2>/dev/null) || HTTP="fail"
if [ "$HTTP" != "200" ]; then
  log "⚠️ 本地 gateway 自检 ${HTTP}, 等待 runit 自愈 (最多 15s)…"
  # runit 会在 15s 内自动拉起，这里只记录不重启
  # 如果持续异常，由对端设备的 healthcheck.sh 处理
fi

# ── 5. 汇总 ──
if [ "$CLEANED" -eq 1 ]; then
  ALERT_MSG="${HOSTNAME} 自愈清理完成 (磁盘 ${DISK_PCT}%, 内存 ${AVAIL_MB}MB)"
  log "$ALERT_MSG"
  # 清理类操作不发 QQ 告警，只记日志；swap 超标才发告警
fi
