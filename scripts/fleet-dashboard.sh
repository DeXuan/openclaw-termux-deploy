#!/data/data/com.termux/files/usr/bin/bash
# 机队每日仪表盘 — 汇总四台设备状态，飞书 API 直推
# cron: 57 8 * * * ~/fleet-dashboard.sh
set -euo pipefail

# 凭证文件（不入库，单独部署到 ~/.fleet-dashboard.conf）
if [ -f ~/.fleet-dashboard.conf ]; then
  . ~/.fleet-dashboard.conf
else
  echo "ERROR: ~/.fleet-dashboard.conf not found"
  exit 1
fi

collect() {
  local ip="$1" port="${2:-8022}"
  ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$ip" \
    'GW=$(curl -s -o /dev/null -w "%{http_code}" -m 5 http://127.0.0.1:18789/ 2>/dev/null || echo "DOWN")
UP=$(uptime -p 2>/dev/null | sed "s/up //")
MEM=$(free -m 2>/dev/null | awk "/Mem:/{printf \"%.1fG/%.1fG\", \$7/1024, \$2/1024}")
DSK=$(df -h /data 2>/dev/null | awk "NR==2{print \$5}")
echo "GW:${GW} |UP:${UP} |MEM:${MEM} |DSK:${DSK}"' 2>/dev/null | tr -d '\n' || \
    echo "GW:N/A |UP:N/A |MEM:N/A |DSK:N/A"
}

collect_local() {
  GW=$(curl -s -o /dev/null -w "%{http_code}" -m 5 http://127.0.0.1:18789/ 2>/dev/null || echo "DOWN")
  UP=$(uptime -p 2>/dev/null | sed "s/up //")
  MEM=$(free -m 2>/dev/null | awk "/Mem:/{printf \"%.1fG/%.1fG\", \$7/1024, \$2/1024}")
  DSK=$(df -h /data 2>/dev/null | awk "NR==2{print \$5}")
  echo "GW:${GW} |UP:${UP} |MEM:${MEM} |DSK:${DSK}"
}

K60_INFO=$(collect_local)
MIX2S_INFO=$(collect "192.168.1.20")
NOTE4_INFO=$(collect "192.168.1.19")
NOTE7_INFO=$(collect "100.91.94.44")

TEXT="OPENCLAW FLEET $(date '+%m/%d %H:%M')
================
K60   | $K60_INFO
MIX2S | $MIX2S_INFO
Note4 | $NOTE4_INFO
Note7 | $NOTE7_INFO
================
Daily 08:57 | Backup Sun 02:00"

TOKEN=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
  -H "Content-Type: application/json" \
  -d "{\"app_id\":\"$FEISHU_APP_ID\",\"app_secret\":\"$FEISHU_APP_SECRET\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('tenant_access_token',''))" 2>/dev/null)

CONTENT=$(python3 -c "import json; print(json.dumps({'text': '''$TEXT'''}))" 2>/dev/null)

RESP=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"receive_id\":\"$FEISHU_RECEIVE_ID\",\"msg_type\":\"text\",\"content\":$CONTENT}")

CODE=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('code',''))" 2>/dev/null)
if [ "$CODE" = "0" ]; then
  echo "[$(date +%H:%M)] dashboard sent OK" >> ~/fleet-dashboard.log
else
  echo "[$(date +%H:%M)] dashboard FAILED: $RESP" >> ~/fleet-dashboard.log
fi
