#!/data/data/com.termux/files/usr/bin/bash
# OpenClaw 模型看门狗 — 检测 401/403 自动切换有额度的模型
# cron: */5 * * * * ~/oc-model-watchdog.sh

LOG="$HOME/.hermes/logs/oc-model-watchdog.log"
OC_LOG="$PREFIX/var/log/sv/openclaw/current"
OC_JSON="$HOME/.openclaw/openclaw.json"
NOW=$(date +%s)
WINDOW=$((5 * 60))  # 检查最近5分钟的日志

# 所有可用模型（按优先级排列，定期更新）
MODELS=(
  "qwen-plus-2025-07-28"
  "deepseek-v3.2"
  "glm-5"
  "qwen3-coder-plus"
  "qwen3.7-max-2026-06-08"
  "kimi-k2.7-code"
  "deepseek-r1-distill-qwen-32b"
  "qwen-plus"
  "qwen3.6-plus"
  "qwen-max"
)

# 检查最近5分钟是否有401/403
RECENT=$(grep -E "401|403|Free quota exhausted" "$OC_LOG" 2>/dev/null | tail -20)
if [ -z "$RECENT" ]; then
  echo "$(date -Iseconds) OK" >> "$LOG"
  exit 0
fi

# 有错误—调当前模型到列表末尾，换下一个
CURRENT=$(python3 -c "import json; c=json.load(open('$OC_JSON')); print(c['models']['providers']['alibaba-model-studio']['models'][0]['id'])" 2>/dev/null)
echo "$(date -Iseconds) FAIL on $CURRENT — rotating" >> "$LOG"

# 找到当前模型在列表中的位置，选下一个
NEXT=""
for i in "${!MODELS[@]}"; do
  if [ "${MODELS[$i]}" = "$CURRENT" ]; then
    n=$(( (i + 1) % ${#MODELS[@]} ))
    NEXT="${MODELS[$n]}"
    break
  fi
done
[ -z "$NEXT" ] && NEXT="${MODELS[0]}"

# 构建新模型列表（NEXT放首位）
NEW_LIST="["
first=true
for m in "$NEXT"; do
  $first && first=false || NEW_LIST+=", "
  NEW_LIST+="{\"id\":\"$m\",\"name\":\"$m\"}"
done
for m in "${MODELS[@]}"; do
  [ "$m" = "$NEXT" ] && continue
  NEW_LIST+=", {\"id\":\"$m\",\"name\":\"$m\"}"
done
NEW_LIST+="]"

python3 -c "
import json
with open('$OC_JSON') as f: c = json.load(f)
c['models']['providers']['alibaba-model-studio']['models'] = $NEW_LIST
with open('$OC_JSON', 'w') as f: json.dump(c, f, indent=2)
print(f'Switched to $NEXT')
" && export SVDIR="$PREFIX/var/service" && sv restart openclaw 2>&1 >> "$LOG"

echo "$(date -Iseconds) switched to $NEXT" >> "$LOG"
tail -100 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
