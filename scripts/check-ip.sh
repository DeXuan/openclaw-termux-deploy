#!/data/data/com.termux/files/usr/bin/bash
# IP 漂移检测 — 蜂窝/宽带 IPv4 变更时飞书告警
# cron: */10 * * * * ~/check-ip.sh
# 凭证文件 ~/.fleet-dashboard.conf 格式同 fleet-dashboard.sh
set -euo pipefail

STAMP_FILE=~/check-ip.last
LOG=~/check-ip.log

log() { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }

# ── 取当前 IPv4 ──
CURRENT_IP=$(curl -4 -s --connect-timeout 10 https://api.ip.sb/ip 2>/dev/null || \
             curl -4 -s --connect-timeout 10 https://ifconfig.me/ip 2>/dev/null || \
             curl -4 -s --connect-timeout 10 https://ipinfo.io/ip 2>/dev/null)

if [ -z "$CURRENT_IP" ]; then
  log "WARN: 无法获取外网 IPv4"
  exit 0
fi

# ── 首次运行，记录基准 ──
if [ ! -f "$STAMP_FILE" ]; then
  echo "$CURRENT_IP" > "$STAMP_FILE"
  log "INIT: 基准 IP = $CURRENT_IP"
  exit 0
fi

LAST_IP=$(cat "$STAMP_FILE")

if [ "$CURRENT_IP" = "$LAST_IP" ]; then
  exit 0  # 无变化，静默
fi

# ── IP 变了 ──
echo "$CURRENT_IP" > "$STAMP_FILE"
CHANGE_MSG="⚠️ IP 漂移: ${LAST_IP} → ${CURRENT_IP} (时间: $(date '+%m-%d %H:%M'))"
log "$CHANGE_MSG"

# ── 飞书告警 ──
ALERT_TEXT="${CHANGE_MSG}

影响: QQ 机器人 IP 白名单可能失效
操作: 去 q.qq.com → 开发设置 → 更新白名单为 ${CURRENT_IP}
或者: 换飞书渠道（无白名单限制）"

if echo "$ALERT_TEXT" | python3 ~/feishu_push.py -t "⚠️ IP 漂移" >> "$LOG" 2>&1; then
  log "飞书推送成功"
else
  log "飞书推送失败（feishu_push.py 不存在或凭证未配置）"
fi
