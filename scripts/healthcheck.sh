#!/data/data/com.termux/files/usr/bin/bash
#==============================================================================
# 机队自愈互检 — 通用版
# 用法: TARGET="user@ip:port" LABEL="K60" SLEEP=20 SSH_FAIL_ALERT=1 ./healthcheck.sh
# 或 source ~/.fleet-devices.conf 后直接运行（自动从配置文件读取目标）
# cron: */5 * * * * ~/healthcheck.sh
#==============================================================================
set -euo pipefail

# ═══ 配置（可通过环境变量覆盖）═══
TARGET="${TARGET:-}"                  # 监控目标 (user@host)
PORT="${PORT:-8022}"                  # SSH 端口
LABEL="${LABEL:-remote}"              # 设备标签（用于日志）
SLEEP="${SLEEP:-20}"                  # 重启后等待秒数
SSH_FAIL_ALERT="${SSH_FAIL_ALERT:-1}" # SSH 不通时是否告警 (1=告警, 0=静默)
LOG="${LOG:-$HOME/healthcheck.log}"
STAMP="${STAMP:-$HOME/healthcheck.last_restart}"
MAX_RETRY="${MAX_RETRY:-2}"
COOLDOWN="${COOLDOWN:-600}"

# ── 如果未设置 TARGET，尝试从标签推断 ──
if [ -z "$TARGET" ]; then
  case "${LABEL:-}" in
    Note7|note7|N7) TARGET="u0_a171@100.91.94.44" ;;
    MIX2S|mix2s)    TARGET="u0_a129@100.104.72.125" ;;
    K60|k60)        TARGET="u0_a129@192.168.1.23" ;;
    *) echo "ERROR: TARGET not set and LABEL='$LABEL' not recognized"; exit 1 ;;
  esac
fi

log()   { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }
alert() {
  log "🚨 ALERT: $1"
  timeout 15 openclaw agent --agent main --message "🚨 机队告警 (${LABEL}): $1" 2>/dev/null || true
}

# ═══ 1. 快速探活 ═══
HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
  "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"

if [ "$HTTP" = "200" ]; then
  exit 0
fi

# ═══ 2. SSH 不通 → 按策略处理 ═══
if [ "$HTTP" = "ssh_fail" ]; then
  if [ "$SSH_FAIL_ALERT" = "1" ]; then
    alert "$LABEL SSH 不可达，无法自愈，请检查设备是否在线。"
    exit 1
  else
    log "$LABEL SSH 不可达 (${TARGET#*@})，LAN-only 场景，静默跳过"
    exit 0
  fi
fi

# ═══ 3. 冷却检查 ═══
NOW=$(date +%s)
if [ -f "$STAMP" ]; then
  LAST=$(cat "$STAMP")
  ELAPSED=$((NOW - LAST))
  if [ "$ELAPSED" -lt "$COOLDOWN" ]; then
    log "$LABEL gateway ${HTTP}, 距上次重启 ${ELAPSED}s, 冷却中 (cooldown=${COOLDOWN}s)"
    exit 0
  fi
fi

# ═══ 4. 自愈循环 ═══
for ((i=1; i<=MAX_RETRY; i++)); do
  log "$LABEL gateway ${HTTP}, 第 ${i}/${MAX_RETRY} 次远程重启…"
  ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "export SVDIR=\$PREFIX/var/service && sv restart openclaw" 2>/dev/null || {
    log "重启命令执行失败"
    break
  }

  echo "$NOW" > "$STAMP"
  sleep "$SLEEP"

  HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"

  if [ "$HTTP" = "200" ]; then
    log "✅ 第 ${i} 次重启后恢复 (HTTP 200)"
    exit 0
  fi
done

# ═══ 5. 自愈失败 → 告警 ═══
alert "$LABEL gateway 自愈失败：${MAX_RETRY} 次重启后仍 ${HTTP}，需人工介入。"
