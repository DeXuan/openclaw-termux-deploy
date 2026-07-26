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

# ── 设备 IP（优先 ~/.fleet-devices.conf，兜底硬编码；与 lib/common.sh 保持同步）──
if [ -f ~/.fleet-devices.conf ]; then
  . ~/.fleet-devices.conf
else
  MIX2S_SSH="u0_a129@100.104.72.125:8022"
  NOTE4X_SSH="u0_a129@192.168.1.19:8022"
  NOTE7_SSH="u0_a171@100.91.94.44:8022"
fi

# 从 SSH 连接串中提取 user@host 和 port
parse_conn() { echo "${1%:*}"; }
parse_port() { echo "${1##*:}"; }

K60_INFO=$(collect_local)
MIX2S_INFO=$(collect "$(parse_conn "$MIX2S_SSH")" "$(parse_port "$MIX2S_SSH")")
NOTE4_INFO=$(collect "$(parse_conn "$NOTE4X_SSH")" "$(parse_port "$NOTE4X_SSH")")
NOTE7_INFO=$(collect "$(parse_conn "$NOTE7_SSH")" "$(parse_port "$NOTE7_SSH")")

TEXT="OPENCLAW FLEET $(date '+%m/%d %H:%M')
================
K60   | $K60_INFO
MIX2S | $MIX2S_INFO
Note4 | $NOTE4_INFO
Note7 | $NOTE7_INFO
================
Daily 08:57 | Backup Sun 02:00"

# 统一飞书推送
if echo "$TEXT" | python3 ~/feishu_push.py >> ~/fleet-dashboard.log 2>&1; then
  echo "[$(date +%H:%M)] dashboard sent OK" >> ~/fleet-dashboard.log
else
  echo "[$(date +%H:%M)] dashboard FAILED" >> ~/fleet-dashboard.log
fi
