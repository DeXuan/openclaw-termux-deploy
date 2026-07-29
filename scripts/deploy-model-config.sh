#!/data/data/com.termux/files/usr/bin/bash
#==============================================================================
# 设备模型配置注入 — 通用版
# 用法: API_KEY="sk-xxx" DEVICE="K60" ./deploy-model-config.sh
# 从环境变量读取 API Key，从 config/devices/ 目录读取设备专属模型列表
#==============================================================================
set -euo pipefail

API_KEY="${API_KEY:-${BAILIAN_API_KEY:-}}"
DEVICE="${DEVICE:-$(hostname 2>/dev/null || echo 'unknown')}"
CONFIG_DIR="${CONFIG_DIR:-$(dirname "$0")/../config/devices}"

if [ -z "$API_KEY" ]; then
  echo "ERROR: API_KEY or BAILIAN_API_KEY environment variable required" >&2
  echo "Usage: API_KEY='sk-xxx' DEVICE='K60' $0" >&2
  exit 1
fi

# ── 设备模型查找表 ──
get_oc_models() {
  case "${1:-}" in
    K60) python3 -c 'import json; print(json.dumps([
      {"id":"qwen3-max","name":"qwen3-max"},{"id":"qwen3.7-max-2026-05-20","name":"qwen3.7-max-2026-05-20"},
      {"id":"qwen3.7-flash-2026-07-15","name":"qwen3.7-flash-2026-07-15"},{"id":"qwen3.7-flash","name":"qwen3.7-flash"},
      {"id":"qwen3.6-plus-2026-04-02","name":"qwen3.6-plus-2026-04-02"},{"id":"qwen3.6-flash-2026-04-16","name":"qwen3.6-flash-2026-04-16"},
      {"id":"qwen3.5-plus-2026-04-20","name":"qwen3.5-plus-2026-04-20"},{"id":"qwen3.5-plus","name":"qwen3.5-plus"},
      {"id":"qwen3.5-flash-2026-02-23","name":"qwen3.5-flash-2026-02-23"},{"id":"qwen3.5-flash","name":"qwen3.5-flash"}
    ]))' ;;
    MIX2S) python3 -c 'import json; print(json.dumps([
      {"id":"qwen-plus-character","name":"qwen-plus-character"},{"id":"qwen-plus","name":"qwen-plus"},
      {"id":"qwen-turbo","name":"qwen-turbo"},{"id":"qwen-flash","name":"qwen-flash"},
      {"id":"qwen-coder-turbo","name":"qwen-coder-turbo"},{"id":"qwen-coder-plus","name":"qwen-coder-plus"},
      {"id":"qwen-math-turbo","name":"qwen-math-turbo"},{"id":"qwen-math-plus","name":"qwen-math-plus"},
      {"id":"qwen-long-latest","name":"qwen-long-latest"},{"id":"qwen-long","name":"qwen-long"}
    ]))' ;;
    Note7) python3 -c 'import json; print(json.dumps([
      {"id":"qwen3-max","name":"qwen3-max"},{"id":"qwen3.7-max-2026-05-20","name":"qwen3.7-max-2026-05-20"},
      {"id":"qwen3.7-flash-2026-07-15","name":"qwen3.7-flash-2026-07-15"},{"id":"qwen3.6-plus-2026-04-02","name":"qwen3.6-plus-2026-04-02"},
      {"id":"qwen3.6-flash-2026-04-16","name":"qwen3.6-flash-2026-04-16"},{"id":"qwen3.5-plus-2026-04-20","name":"qwen3.5-plus-2026-04-20"},
      {"id":"qwen3.5-plus","name":"qwen3.5-plus"},{"id":"qwen3.5-flash-2026-02-23","name":"qwen3.5-flash-2026-02-23"}
    ]))' ;;
    Note4X) python3 -c 'import json; print(json.dumps([
      {"id":"qwen-portal/coder-model","name":"qwen-coder"},{"id":"deepseek/deepseek-v4-flash","name":"DeepSeek"},
      {"id":"qwen-portal/vision-model","name":"qwen-vision"}
    ]))' ;;
    *) echo "ERROR: Unknown device '$1'. Valid: K60, MIX2S, Note7, Note4X" >&2; exit 1 ;;
  esac
}

get_hermes_config() {
  case "${1:-}" in
    K60)    echo "primary=kimi-k2-thinking fallback=Moonshot-Kimi-K2-Instruct,MiniMax-M2.5,MiniMax-M2.1" ;;
    MIX2S)  echo "primary=gui-plus fallback=qwen3-coder-plus-2025-09-23,qwen3-coder-plus-2025-07-22,qwen3-coder-plus" ;;
    Note7)  echo "primary=qwq-plus fallback=qwen3-coder-plus-2025-09-23" ;;
    Note4X) echo "primary=NOT_APPLICABLE" ;;
    *) echo "ERROR: Unknown device '$1'" >&2; exit 1 ;;
  esac
}

OC_MODELS=$(get_oc_models "$DEVICE")
HM_INFO=$(get_hermes_config "$DEVICE")
HM_PRIMARY=$(echo "$HM_INFO" | grep -oP 'primary=\K\S+')
HM_FALLBACK=$(echo "$HM_INFO" | grep -oP 'fallback=\K.*')

# ── Write OpenClaw config ──
python3 -c "
import json, os
KEY='$API_KEY'
BASE='https://dashscope.aliyuncs.com/compatible-mode/v1'
MODELS=$OC_MODELS

with open(os.path.expanduser('~/.openclaw/openclaw.json')) as f:
    c = json.load(f)
c['models'] = {'mode': 'merge', 'providers': {'alibaba-model-studio': {'apiKey': KEY, 'baseUrl': BASE, 'models': MODELS}}}
with open(os.path.expanduser('~/.openclaw/openclaw.json'), 'w') as f:
    json.dump(c, f, indent=2)
print('OpenClaw config updated')
"

# ── Write Hermes config (skip if Note 4X) ──
if [ "$HM_PRIMARY" != "NOT_APPLICABLE" ]; then
  python3 -c "
import os
primary='$HM_PRIMARY'
fallback='$HM_FALLBACK'
lines = [f'model:\n  name: {primary}\n  provider: openai-api\n', 'fallback_model:\n']
for m in fallback.split(','):
    lines.append(f'  - model: {m}\n    provider: openai-api\n')
with open(os.path.expanduser('~/.hermes/config.yaml'), 'w') as f:
    f.writelines(lines)
print('Hermes config updated')
"
fi

echo "$DEVICE configured — restart services to apply"
