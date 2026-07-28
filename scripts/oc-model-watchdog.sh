#!/data/data/com.termux/files/usr/bin/bash
# OpenClaw 模型看门狗 v2 — 从 openclaw.json 读取设备专属模型池，检测401/403自动轮换
# cron: */5 * * * * ~/oc-model-watchdog.sh

LOG="$HOME/.hermes/logs/oc-model-watchdog.log"
OC_LOG="$PREFIX/var/log/sv/openclaw/current"
OC_JSON="$HOME/.openclaw/openclaw.json"

# 检测最近日志中是否有401/403
has_error() {
  tail -100 "$OC_LOG" 2>/dev/null | grep -qE "401 Unauthorized|403.*quota|Free quota exhausted"
}

if ! has_error; then
  echo "$(date -Iseconds) OK" >> "$LOG"
  tail -100 "$LOG" > "${LOG}.tmp" 2>/dev/null && mv "${LOG}.tmp" "$LOG"
  exit 0
fi

# 从 openclaw.json 读取当前模型池
MODELS=$(python3 -c "
import json
with open('$OC_JSON') as f: c = json.load(f)
models = c.get('models',{}).get('providers',{}).get('alibaba-model-studio',{}).get('models',[])
print(' '.join([m['id'] for m in models]))
")
CURRENT=$(echo "$MODELS" | cut -d' ' -f1)
REST=$(echo "$MODELS" | cut -d' ' -f2-)

if [ -z "$REST" ]; then
  echo "$(date -Iseconds) FAIL on $CURRENT — no fallback!" >> "$LOG"
  exit 1
fi

NEXT=$(echo "$REST" | cut -d' ' -f1)
echo "$(date -Iseconds) FAIL on $CURRENT → switching to $NEXT" >> "$LOG"

# 轮换：当前模型移到末尾
NEW_LIST="["
for m in $REST; do
  NEW_LIST+="{\"id\":\"$m\",\"name\":\"$m\"}, "
done
NEW_LIST+="{\"id\":\"$CURRENT\",\"name\":\"$CURRENT\"}]"

python3 -c "
import json
with open('$OC_JSON') as f: c = json.load(f)
c['models']['providers']['alibaba-model-studio']['models'] = $NEW_LIST
with open('$OC_JSON', 'w') as f: json.dump(c, f, indent=2)
print(f'Switched to $NEXT')
" && export SVDIR="$PREFIX/var/service" && sv restart openclaw >> "$LOG" 2>&1

echo "$(date -Iseconds) now: $NEXT" >> "$LOG"
tail -100 "$LOG" > "${LOG}.tmp" 2>/dev/null && mv "${LOG}.tmp" "$LOG"
