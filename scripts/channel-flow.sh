#!/data/data/com.termux/files/usr/bin/bash
# 渠道消息流监控 — 追踪消息从收→处理→回复的完整生命周期
# cron: */5 * * * * ~/channel-flow.sh
# 与 channel-health.sh 互补：前者看连通性，本脚本看消息处理质量
set -euo pipefail

LOG=~/channel-flow.log
MAX_UNREPLIED_ALERT=3   # 未回复消息超过此数告警
MAX_LATENCY_MS=30000    # 平均响应超过 30s 告警
TAIL_LINES=500          # 每次扫描最近 N 行（约 10-15 分钟量）

log()  { echo "[$(date '+%m-%d %H:%M')] $1" >> "$LOG"; }
alert() {
  echo "$1" | python3 ~/feishu_push.py -t "📡 消息流告警" 2>/dev/null || true
}

# ── 找最新 gateway 日志 ──
GLOG=$(ls -t "$PREFIX/tmp/openclaw-"*/openclaw-20*.log 2>/dev/null | head -1)
if [ -z "$GLOG" ] || [ ! -f "$GLOG" ]; then
  log "SKIP: 未找到 gateway 日志"
  exit 0
fi

# ── 取最近 N 行 ──
RECENT="$HOME/channel-flow-recent-$$"
cleanup() { rm -f "$RECENT"; }
trap cleanup INT TERM EXIT
tail -"$TAIL_LINES" "$GLOG" > "$RECENT" 2>/dev/null || cp "$GLOG" "$RECENT" 2>/dev/null || true

# ═══ 1. 消息收发统计 ═══
# 收到消息: "Processing message from <sender>: <content>"
QQ_RECEIVED=$(grep -c 'Processing message from' "$RECENT" 2>/dev/null || echo 0)
QQ_RECEIVED="${QQ_RECEIVED//[^0-9]/}"
[ -z "$QQ_RECEIVED" ] && QQ_RECEIVED=0

# 飞书收到: 飞书渠道的 Processing message（grep feishu subsystem）
FS_RECEIVED=$(grep -E 'channels/feishu.*Processing message' "$RECENT" 2>/dev/null | grep -c "Processing" || echo 0)
FS_RECEIVED="${FS_RECEIVED//[^0-9]/}"
[ -z "$FS_RECEIVED" ] && FS_RECEIVED=0

# 已回复: "onMessageSent called"
QQ_SENT=$(grep -c 'onMessageSent called' "$RECENT" 2>/dev/null || echo 0)
QQ_SENT="${QQ_SENT//[^0-9]/}"
[ -z "$QQ_SENT" ] && QQ_SENT=0

TOTAL_RECEIVED=$((QQ_RECEIVED + FS_RECEIVED))

# ═══ 2. 未回复检测 ═══
# 拿到"Processing message"的 traceId，检查是否有对应的 onMessageSent
UNREPLIED=0
UNREPLIED_MSGS=""

if [ "$QQ_RECEIVED" -gt 0 ] 2>/dev/null; then
  # 提取每条 Processing message 的 traceId
  while IFS= read -r trace_id; do
    [ -z "$trace_id" ] && continue
    # 检查这个 traceId 是否有 onMessageSent
    if ! grep -q "onMessageSent.*$trace_id" "$RECENT" 2>/dev/null; then
      UNREPLIED=$((UNREPLIED + 1))
      # 提取消息内容摘要（截取前 50 字）
      MSG_PREVIEW=$(grep "Processing message.*$trace_id" "$RECENT" 2>/dev/null | head -1 | grep -oP 'Processing message from [^:]+: \K[^"]+' | head -c 50)
      UNREPLIED_MSGS+="  • ${MSG_PREVIEW:-无内容}"$'\n'
    fi
  done < <(grep 'Processing message from' "$RECENT" 2>/dev/null | grep -oP '"traceId":"\K[^"]+' | sort -u)
fi

# ═══ 3. 响应延迟 ═══
# 从 model-fetch response 事件提取 elapsedMs
LATENCY_SUM=0
LATENCY_COUNT=0
while IFS= read -r elapsed; do
  LATENCY_SUM=$((LATENCY_SUM + elapsed))
  LATENCY_COUNT=$((LATENCY_COUNT + 1))
done < <(grep -oP 'elapsedMs=\K\d+' "$RECENT" 2>/dev/null || true)

AVG_LATENCY="N/A"
if [ "$LATENCY_COUNT" -gt 0 ] 2>/dev/null; then
  AVG_LATENCY=$((LATENCY_SUM / LATENCY_COUNT))
fi

# ═══ 4. 模型请求统计 ═══
MODEL_STARTS=$(grep -c '\[model-fetch\] start' "$RECENT" 2>/dev/null || echo 0)
MODEL_STARTS="${MODEL_STARTS//[^0-9]/}"
[ -z "$MODEL_STARTS" ] && MODEL_STARTS=0

MODEL_ERRORS=$(grep -c '\[model-fetch\].*status=[^2]' "$RECENT" 2>/dev/null || echo 0)
MODEL_ERRORS="${MODEL_ERRORS//[^0-9]/}"
[ -z "$MODEL_ERRORS" ] && MODEL_ERRORS=0

# ═══ 5. 汇总 ───
STATUS="📬 收: QQ×${QQ_RECEIVED} FS×${FS_RECEIVED} | 📤 回: ×${QQ_SENT}"
STATUS+=" | ⏱ 均延: ${AVG_LATENCY}ms (${LATENCY_COUNT}次)"
STATUS+=" | 🤖 模型: ${MODEL_STARTS}次请求"

if [ "$MODEL_ERRORS" -gt 0 ] 2>/dev/null; then
  STATUS+=" ${MODEL_ERRORS}错误"
fi

if [ "$UNREPLIED" -gt 0 ] 2>/dev/null; then
  STATUS+=" | ⚠️ 未回复: ${UNREPLIED}"
fi

log "$STATUS"

# ═══ 6. 告警判断 ═══
ALERTS=""

# 有消息收但全都没回复
if [ "$QQ_RECEIVED" -gt 0 ] 2>/dev/null && [ "$QQ_SENT" -eq 0 ] 2>/dev/null; then
  ALERTS+="🔴 QQ 收到 ${QQ_RECEIVED} 条消息但全部未回复！Agent 可能卡死或模型不可用
"
fi

# 未回复超过阈值
if [ "$UNREPLIED" -gt "$MAX_UNREPLIED_ALERT" ] 2>/dev/null; then
  ALERTS+="⚠️ 未回复消息 ×${UNREPLIED}（阈值 ${MAX_UNREPLIED_ALERT}）
${UNREPLIED_MSGS}"
fi

# 响应延迟过高
if [ "$AVG_LATENCY" != "N/A" ] && [ "$AVG_LATENCY" -gt "$MAX_LATENCY_MS" ] 2>/dev/null; then
  ALERTS+="⚠️ 平均响应延迟 ${AVG_LATENCY}ms（阈值 ${MAX_LATENCY_MS}ms），模型或网络慢
"
fi

# 模型请求错误
if [ "$MODEL_ERRORS" -gt 0 ] 2>/dev/null; then
  # 提取具体错误信息
  ERROR_DETAIL=$(grep -oP '\[model-fetch\].*status=[2-9][0-9][0-9][^"]*' "$RECENT" 2>/dev/null | tail -3 | tr '\n' ' ')
  ALERTS+="⚠️ 模型请求错误 ×${MODEL_ERRORS}: ${ERROR_DETAIL:-无详情}
"
fi

if [ -n "$ALERTS" ]; then
  alert "$ALERTS"
fi
