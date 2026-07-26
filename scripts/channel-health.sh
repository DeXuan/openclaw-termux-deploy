#!/data/data/com.termux/files/usr/bin/bash
# 渠道健康巡检 — grep gateway 日志检测 QQ/飞书/微信连通性（不额外启动 node 实例，坑23安全）
# cron: */15 * * * * ~/channel-health.sh
set -euo pipefail

# 临时文件清理
RECENT=""
cleanup() { rm -f "$RECENT" 2>/dev/null; }
trap cleanup INT TERM EXIT

LOG=~/channel-health.log
ALERT_LOG=~/channel-health.alert.log
MAX_1006=10     # 15分钟内 WebSocket 1006 超过此次数告警
MAX_401=3       # 15分钟内 401/IP白名单 超过此次数告警

log()  { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }
alert() {
  echo "[$(date '+%m-%d %H:%M')] $1" >> "$ALERT_LOG"
  echo "$1" | python3 ~/feishu_push.py -t "📡 渠道告警" 2>/dev/null || true
}

# ── 找最新 gateway 日志 ──
GLOG=$(ls -t "$PREFIX/tmp/openclaw-"*/openclaw-20*.log 2>/dev/null | head -1)
if [ -z "$GLOG" ] || [ ! -f "$GLOG" ]; then
  log "SKIP: 未找到 gateway 日志"
  exit 0
fi

# ── 只看最近日志（Termux 无 date -d，用 tail 近似 15 分钟量）──
RECENT="$HOME/channel-health-recent-$$"  # Termux 没有 /tmp（坑21）
tail -500 "$GLOG" > "$RECENT" 2>/dev/null || cp "$GLOG" "$RECENT" 2>/dev/null || true

# ── 辅助：安全取整数（grep -c 可能在异常时输出非数字）──
safe_count() { local n; n=$(grep -c "$1" "$RECENT" 2>/dev/null) || n=0; echo "${n//[^0-9]/}"; }

# ═══ QQ ═══
QQ_READY=$(safe_count "qqbot.*Gateway ready")
QQ_WS=$(safe_count "qqbot.*WebSocket connected")
QQ_1006=$(safe_count "qqbot.*WebSocket closed: 1006")
QQ_401=$(safe_count 'qqbot.*401|qqbot.*白名单|qqbot.*IP.*not')

# ═══ 飞书 ═══
FS_WS=$(safe_count "feishu.*WebSocket client started")
FS_1006=$(safe_count "feishu.*WebSocket closed: 1006")

# ═══ 微信 ═══
WX_WS=$(safe_count "openclaw-weixin.*WebSocket connected|weixin.*Gateway ready")
WX_1006=$(safe_count "openclaw-weixin.*WebSocket closed: 1006")

# ═══ 汇总 ═══
STATUS="QQ:"
[ "$QQ_READY" -gt 0 ] 2>/dev/null && STATUS+=" ready×${QQ_READY}" || STATUS+=" 无连接"
[ "$QQ_WS" -gt 0 ] 2>/dev/null && STATUS+=" ws×${QQ_WS}"
STATUS+=" | 飞书:"
[ "$FS_WS" -gt 0 ] 2>/dev/null && STATUS+=" ws×${FS_WS}" || STATUS+=" 无连接"
STATUS+=" | 微信:"
[ "$WX_WS" -gt 0 ] 2>/dev/null && STATUS+=" ws×${WX_WS}" || STATUS+=" 无连接"
TOTAL_1006=$(( QQ_1006 + FS_1006 + WX_1006 )) 2>/dev/null || TOTAL_1006="?"
STATUS+=" | 异常: 1006×${TOTAL_1006} 401×${QQ_401}"

log "$STATUS"

# ═══ 告警判断 ═══
ALERTS=""

# QQ 完全无连接（已配置但 15 分钟都没有 Gateway ready）
if [ "$QQ_READY" -eq 0 ] 2>/dev/null && grep -q "qqbot" "$GLOG" 2>/dev/null; then
  ALERTS+="⚠️ QQ 渠道 15 分钟内无 Gateway ready（已配置但无连接记录）
"
fi

# WebSocket 异常断开过多
if [ "$QQ_1006" -gt "$MAX_1006" ] 2>/dev/null; then
  ALERTS+="⚠️ QQ WebSocket 1006 断开 ×${QQ_1006}（15min，阈值 ${MAX_1006}）
"
fi
if [ "$FS_1006" -gt "$MAX_1006" ] 2>/dev/null; then
  ALERTS+="⚠️ 飞书 WebSocket 1006 断开 ×${FS_1006}（15min）
"
fi

# IP 白名单问题
if [ "$QQ_401" -gt "$MAX_401" ] 2>/dev/null; then
  CURRENT_IP=$(curl -4 -s --connect-timeout 5 https://api.ip.sb/ip 2>/dev/null || echo "未知")
  ALERTS+="🔴 QQ IP 白名单 401 ×${QQ_401}（15min）当前 IP: ${CURRENT_IP}
  操作: q.qq.com → 开发设置 → 更新白名单
"
fi

if [ -n "$ALERTS" ]; then
  alert "$ALERTS"
fi

rm -f "$RECENT"
