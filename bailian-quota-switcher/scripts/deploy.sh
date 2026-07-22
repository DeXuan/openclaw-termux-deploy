#!/bin/bash
# 一键部署百炼免费模型 + watcher 到多台 Termux 设备 v2.2
# 用法: export BAILIAN_KEY="sk-ws-H.XXX"; bash deploy.sh
set -e

API_KEY="${BAILIAN_KEY:-sk-ws-H.XXX}"

DEVICES=(
  "192.168.1.23 u0_a197 8022 K60 qwen3.7-max"
)

# 核心模型列表（仅大语言模型）
MODELS_JSON='[
  {"id":"qwen3.7-max","name":"Qwen3.7 Max","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192},
  {"id":"qwen3.7-plus","name":"Qwen3.7 Plus","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192},
  {"id":"qwen3-max","name":"Qwen3 Max","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192},
  {"id":"qwen-max","name":"Qwen Max","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":32768,"maxTokens":8192},
  {"id":"qwen-plus","name":"Qwen Plus","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":131072,"maxTokens":8192},
  {"id":"deepseek-v4-pro","name":"DeepSeek V4 Pro","reasoning":true,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192},
  {"id":"deepseek-v4-flash","name":"DeepSeek V4 Flash","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192},
  {"id":"kimi-k2.6","name":"Kimi K2.6","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192},
  {"id":"glm-5.2","name":"GLM 5.2","reasoning":false,"input":["text"],"cost":{"input":0,"output":0,"cacheRead":0,"cacheWrite":0},"contextWindow":128000,"maxTokens":8192}
]'

FALLBACK_ORDER="qwen3.7-max qwen3.7-plus qwen3-max qwen-max qwen-plus deepseek-v4-pro deepseek-v4-flash kimi-k2.6 glm-5.2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# === 飞行前检查 ===
if [ "$API_KEY" = "sk-ws-H.XXX" ]; then
  echo "ERROR: 请设置 API_KEY"
  echo "  export BAILIAN_KEY=sk-ws-H..."
  exit 1
fi

echo "=== 飞行前 Key 验证 ==="
HTTP=$(curl -4 -s --max-time 10 -w "%{http_code}" -o /dev/null \
  "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions" \
  -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"qwen-plus","messages":[{"role":"user","content":"hi"}],"max_tokens":5}')
if [ "$HTTP" = "200" ]; then echo "  Key OK"; else echo "  Key HTTP $HTTP — 请检查"; fi
echo ""

deploy_device() {
  local HOST=$1 USER=$2 PORT=$3 NAME=$4 PRIMARY=$5
  echo "=== $NAME ($USER@$HOST:$PORT) → $PRIMARY ==="

  if ! ssh -o ConnectTimeout=5 -p "$PORT" -o BatchMode=yes "$USER@$HOST" 'echo OK' 2>/dev/null | grep -q OK; then
    echo "  SSH 不通，跳过"; return 1
  fi

  # Step 1: 写 Key + 创建必要文件
  echo "$API_KEY" | ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "cat > \$HOME/bailian_key.txt && chmod 600 \$HOME/bailian_key.txt" 2>/dev/null
  ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "mkdir -p \$HOME/.openclaw; [ -f \$HOME/.openclaw/free_quota.json ] || echo '{\"models\":{}}' > \$HOME/.openclaw/free_quota.json" 2>/dev/null
  echo "  key + quota file: done"

  # Step 2: 清理 crash-loop breaker + 旧 provider 残骸
  ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "rm -f \$HOME/.openclaw/logs/stability/*.json 2>/dev/null; echo '  breaker: cleared'" 2>/dev/null

  # Step 3: Auth + Models + Config
  ssh -o ConnectTimeout=15 -p "$PORT" "$USER@$HOST" bash -s << ENDSSH
set -e
KEY=\$(cat \$HOME/bailian_key.txt)

echo "\$KEY" | openclaw models auth paste-api-key --provider alibaba-model-studio 2>&1 | tail -1

# models.json — 统一 provider name: alibaba-model-studio
node -e '
var fs=require("fs"),k=fs.readFileSync(process.env.HOME+"/bailian_key.txt","utf8").trim();
var p=process.env.HOME+"/.openclaw/agents/main/agent/models.json";
var c={providers:{}};
try{c=JSON.parse(fs.readFileSync(p,"utf8"))}catch(e){}
// 清理旧 provider 名（dashscope/qwen-portal 等）
["dashscope","qwen-portal","qwen","deepseek"].forEach(function(id){delete c.providers[id]});
c.providers["alibaba-model-studio"]={
  baseUrl:"https://dashscope.aliyuncs.com/compatible-mode/v1",
  api:"openai-completions",apiKey:k,
  models: $MODELS_JSON
};
fs.writeFileSync(p,JSON.stringify(c,null,2));
console.log("models.json: "+c.providers["alibaba-model-studio"].models.length+" models");
'

# openclaw.json
node -e '
var fs=require("fs"),p=process.env.HOME+"/.openclaw/openclaw.json";
var c=JSON.parse(fs.readFileSync(p,"utf8"));
c.agents = c.agents || {};
c.agents.defaults = c.agents.defaults || {};
c.agents.defaults.model = c.agents.defaults.model || {};
c.agents.defaults.model.primary = "alibaba-model-studio/$PRIMARY";
var all = "$FALLBACK_ORDER".split(" ")
  .filter(function(m){ return m !== "$PRIMARY"; })
  .map(function(m){ return "alibaba-model-studio/"+m; });
c.agents.defaults.model.fallbacks = all;
// 清理旧 provider 残骸 + 错误路径
["dashscope","qwen-portal","qwen","deepseek"].forEach(function(id){
  if(c.models&&c.models.providers) delete c.models.providers[id];
});
delete c.models.default; delete c.models.fallbacks;
fs.writeFileSync(p,JSON.stringify(c,null,2));
console.log("config: primary=$PRIMARY, fallbacks="+all.length);
'

export SVDIR=\$PREFIX/var/service
sv restart openclaw 2>&1
echo "gateway: restarted"
ENDSSH

  # Step 4: 部署 watcher v2.2
  cat "$SCRIPT_DIR/quota_watcher.sh" | ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "cat > \$HOME/quota_watcher.sh && chmod +x \$HOME/quota_watcher.sh" 2>/dev/null
  ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "pkill -f quota_watcher 2>/dev/null; nohup bash \$HOME/quota_watcher.sh > \$HOME/watcher.log 2>&1 &" 2>/dev/null
  echo "  watcher: deployed"

  # Step 5: Boot 自启
  ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "if [ -f ~/.termux/boot/start-services.sh ]; then
       grep -q quota_watcher ~/.termux/boot/start-services.sh 2>/dev/null || {
         echo '' >> ~/.termux/boot/start-services.sh
         echo '# 百炼免费额度自动切换守护' >> ~/.termux/boot/start-services.sh
         echo 'nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &' >> ~/.termux/boot/start-services.sh
         echo '  boot: configured'
       }
     else echo '  boot: not installed'; fi" 2>/dev/null

  # Step 6: 验证
  sleep 10
  HTTP=$(ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "curl -4 -s --max-time 5 http://127.0.0.1:18789/ -o /dev/null -w '%{http_code}'" 2>/dev/null)
  W=$(ssh -o ConnectTimeout=10 -p "$PORT" "$USER@$HOST" \
    "ps aux 2>/dev/null | grep -c '[q]uota_watcher'" 2>/dev/null)
  if [ "$HTTP" = "200" ] && [ "$W" -gt 0 ]; then
    echo "  ✅ $NAME OK (HTTP:$HTTP watcher:$W)"
  else
    echo "  ⚠️  $NAME HTTP:$HTTP watcher:$W"
  fi
  echo ""
}

for dev in "${DEVICES[@]}"; do
  read -r HOST USER PORT NAME PRIMARY <<< "$dev"
  deploy_device "$HOST" "$USER" "$PORT" "$NAME" "$PRIMARY"
done
echo "=== 全队部署完成 ==="
