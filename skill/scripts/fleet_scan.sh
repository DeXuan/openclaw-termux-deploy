#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# OpenClaw 机队全面体检 v2
# 覆盖：硬件/软件版本/资源/渠道/服务/模型/记忆
# 用法：cat fleet_scan.sh | ssh -p 8022 user@<IP> 'bash -'
# ============================================
HOSTNAME=$(hostname)
MODEL=$(getprop ro.product.marketname 2>/dev/null || echo "unknown")
ANDROID=$(getprop ro.build.version.release 2>/dev/null || echo "?")
export SVDIR=$PREFIX/var/service
OC_LOG="$PREFIX/var/log/sv/openclaw/current"
HM_LOG="$PREFIX/var/log/sv/hermes-gateway/current"
OC_JSON="$HOME/.openclaw/openclaw.json"

echo "╔══════════════════════════════════════════════════╗"
echo "║  机队全面体检  $HOSTNAME / $MODEL / Android $ANDROID"
echo "║  时间: $(date '+%Y-%m-%d %H:%M')"
echo "╚══════════════════════════════════════════════════╝"

# ── 1. 硬件健康 ──
echo ""
echo "── 1. 硬件 ──"
echo "CPU: $(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "?")"
echo "核心: $(grep -c processor /proc/cpuinfo) / 频率: $(grep -m1 "cpu MHz" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "?") MHz"
echo "电池: $(termux-battery-status 2>/dev/null | grep -oP '"percentage":\K\d+' || echo "?")% / 温度: $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print $1/1000"°C"}' || echo "?")"
echo "运行时间: $(uptime | sed 's/.*up //' | cut -d, -f1)"

# ── 2. 软件版本 ──
echo ""
echo "── 2. 版本 ──"
echo "Termux: $(termux-info 2>/dev/null | grep -oP 'TERMUX_VERSION=\K[^ ]+' || echo "?")"
echo "Node: $(node --version 2>/dev/null || echo "MISSING")"
echo "npm: $(npm --version 2>/dev/null || echo "MISSING")"
echo "Python: $(python3 --version 2>/dev/null || echo "MISSING")"
echo "libsqlite: $(node -e "const s=require('node:sqlite');console.log(new s.DatabaseSync(':memory:').prepare('select sqlite_version() v').get().v)" 2>/dev/null || echo "?")"
echo "OpenClaw: $(openclaw --version 2>/dev/null | head -1 || echo "MISSING")"
echo "Hermes: $(hermes version 2>/dev/null | head -1 || echo "MISSING")"
echo "记忆插件: $(node -e "try{const c=JSON.parse(require('fs').readFileSync('$OC_JSON','utf8'));console.log(c.plugins?.entries?.['memory-tencentdb']?.enabled?'enabled':'disabled')}catch(e){console.log('N/A')}" 2>/dev/null)"

# ── 3. 资源使用率 ──
echo ""
echo "── 3. 资源 ──"
MEM_TOTAL=$(free -b | grep Mem | awk '{print $2}')
MEM_USED=$(free -b | grep Mem | awk '{print $3}')
MEM_PCT=$(echo "scale=1; $MEM_USED*100/$MEM_TOTAL" | bc 2>/dev/null || echo "?")
echo "内存: $(free -m | grep Mem | awk "{print \$3\"MB / \"\$2\"MB ($MEM_PCT%)\"}")"
echo "Swap: $(free -m | grep Swap | awk "{print \$3\"MB / \"\$2\"MB\"}")"
echo "磁盘: $(df -h /data 2>/dev/null | tail -1 | awk '{print $3" / "$2" ("$5")"}')"
echo "TOP5进程:"
ps aux --sort=-rss 2>/dev/null | head -6 | tail -5 | awk '{printf "  %-30s RSS=%dMB CPU=%.1f%%\n", $11, $6/1024, $3}'

# ── 4. 服务状态 ──
echo ""
echo "── 4. 服务 ──"
for svc in openclaw hermes-gateway crond sshd; do
  STATUS=$(sv status $svc 2>/dev/null | head -1 || echo "N/A")
  [ "$STATUS" != "N/A" ] && echo "  $svc: $STATUS"
done

# ── 5. 渠道连通 ──
echo ""
echo "── 5. 渠道 (OpenClaw) ──"
# QQ
QQ_CONN=$(grep -c "WebSocket connected" "$OC_LOG" 2>/dev/null || echo 0)
QQ_RESUME=$(grep -c "Gateway resumed" "$OC_LOG" 2>/dev/null || echo 0)
QQ_401=$(grep -c "401.*Unauthorized\|IP不在白名单" "$OC_LOG" 2>/dev/null || echo 0)
QQ_ERR=$(grep -c "403.*quota\|failover.*qqbot" "$OC_LOG" 2>/dev/null || echo 0)
echo "  QQ: connected×$QQ_CONN resumed×$QQ_RESUME | 401×$QQ_401 403×$QQ_ERR"

# 飞书(OC)
FS_CONN=$(grep -c "feishu.*WebSocket client started" "$OC_LOG" 2>/dev/null || echo 0)
echo "  飞书(OC): started×$FS_CONN"

# 微信
WX_INSTALLED=$(ls ~/.openclaw/npm/projects/ 2>/dev/null | grep -c weixin || echo 0)
WX_LOG=$(grep -c "openclaw-weixin.*connected\|openclaw-weixin.*login" "$OC_LOG" 2>/dev/null || echo 0)
echo "  微信: $([ $WX_INSTALLED -gt 0 ] && echo "已安装, log×$WX_LOG" || echo "未安装")"

# ── 6. 渠道 (Hermes) ──
echo ""
echo "── 6. 渠道 (Hermes) ──"
if [ -f "$HM_LOG" ]; then
  HM_FS=$(grep -c "lark.*connect\|Lark.*connected" "$HM_LOG" 2>/dev/null || echo 0)
  echo "  飞书(HM): $([ $HM_FS -gt 0 ] && echo "connected ✓" || echo "未连接 ✗")"
  HM_ERR=$(grep -c "error\|Error\|ERROR" "$HM_LOG" 2>/dev/null || echo 0)
  echo "  Hermes 错误: ${HM_ERR}行"
else
  echo "  Hermes: 无日志（未安装或未运行）"
fi

# ── 7. 模型配置 ──
echo ""
echo "── 7. 模型链 ──"
echo "  agent override: $(node -e "try{const c=JSON.parse(require('fs').readFileSync('$OC_JSON','utf8'));console.log(JSON.stringify(c.agents?.main?.model||c.agents?.defaults?.model||'CLEAN').substring(0,60))}catch(e){console.log('ERROR')}" 2>/dev/null)"
echo "  OC模型数: $(node -e "try{const c=JSON.parse(require('fs').readFileSync('$OC_JSON','utf8'));console.log(c.models.providers['alibaba-model-studio'].models.length)}catch(e){console.log('?')}" 2>/dev/null)"
echo "  HM模型: $(grep -m1 "name:" ~/.hermes/config.yaml 2>/dev/null | awk '{print $2}' || echo "?")"
echo "  Watchdog: $(tail -1 ~/.hermes/logs/oc-model-watchdog.log 2>/dev/null || echo "NO LOG")"

# ── 8. 记忆插件 ──
echo ""
echo "── 8. 记忆(TencentDB) ──"
if [ -d "$HOME/.openclaw/memory-tdai" ]; then
  echo "  vectors.db: $(ls -lh $HOME/.openclaw/memory-tdai/vectors.db 2>/dev/null | awk '{print $5}')"
  echo "  对话: $(wc -l $HOME/.openclaw/memory-tdai/conversations/*.jsonl 2>/dev/null | tail -1 | awk '{print $1}')条"
  echo "  记忆: $(wc -l $HOME/.openclaw/memory-tdai/records/*.jsonl 2>/dev/null | tail -1 | awk '{print $1}')条"
  echo "  degraded: $(grep -c "degraded mode" $OC_LOG 2>/dev/null || echo 0)次"
else
  echo "  未安装"
fi

# ── 9. 近30分钟异常 ──
echo ""
echo "── 9. 近30分钟异常 ──"
ERRORS=$(tail -1000 "$OC_LOG" 2>/dev/null | grep -ciE "error|fail|401|403|quota|crash" || echo 0)
echo "  错误关键词: ${ERRORS}行"

echo ""
echo "═══════════════════════════════════════════"
echo "  体检完成  $HOSTNAME"
echo "═══════════════════════════════════════════"
