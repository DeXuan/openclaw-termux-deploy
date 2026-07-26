#!/data/data/com.termux/files/usr/bin/bash
# 告警去重 — 防止同一告警短时间内重复推送
# 用法: source 本文件，然后调用 dedup_check <key> <cooldown_seconds>
#       dedup_check 返回 0 = 应该发告警，1 = 冷却中跳过
set -euo pipefail

DEDUP_FILE="${HOME}/.alert-dedup.state"
DEDUP_DEFAULT_COOLDOWN=1800  # 默认 30 分钟

# 确保状态文件存在
[ -f "$DEDUP_FILE" ] || touch "$DEDUP_FILE"

# dedup_check <alert_key> [cooldown_seconds]
# 返回 0: 应该发告警 (首次或冷却已过)
# 返回 1: 冷却中，跳过
dedup_check() {
  local key="$1"
  local cooldown="${2:-$DEDUP_DEFAULT_COOLDOWN}"
  local now
  now=$(date +%s)

  # 查找上次告警时间
  local last
  last=$(grep "^${key}|" "$DEDUP_FILE" 2>/dev/null | tail -1 | cut -d'|' -f2)
  [ -z "$last" ] && last=0

  # 冷却中？
  if [ "$((now - last))" -lt "$cooldown" ]; then
    return 1
  fi

  # 更新状态文件 (保留最近 200 条)
  echo "${key}|${now}" >> "$DEDUP_FILE"
  # 清理旧记录
  local lines
  lines=$(wc -l < "$DEDUP_FILE" 2>/dev/null || echo 0)
  if [ "$lines" -gt 200 ]; then
    tail -100 "$DEDUP_FILE" > "${DEDUP_FILE}.tmp" && mv "${DEDUP_FILE}.tmp" "$DEDUP_FILE"
  fi

  return 0
}

# dedup_status <key> — 查看距上次告警多久
dedup_status() {
  local key="$1"
  local now last elapsed
  now=$(date +%s)
  last=$(grep "^${key}|" "$DEDUP_FILE" 2>/dev/null | tail -1 | cut -d'|' -f2)
  if [ -z "$last" ] || [ "$last" = "0" ]; then
    echo "无记录"
  else
    elapsed=$((now - last))
    echo "${elapsed}秒前"
  fi
}
