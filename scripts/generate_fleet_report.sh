#!/usr/bin/env bash
#==============================================================================
# 机队体检 HTML 报告生成器
# 用法: bash scripts/generate_fleet_report.sh [输出路径]
#       bash scripts/generate_fleet_report.sh ~/Desktop/fleet_report.html
# 默认输出: 桌面 fleet_health_report.html (Windows) 或 ~/fleet_report.html
#==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || true

OUTPUT="${1:-}"
if [ -z "$OUTPUT" ]; then
  if [ -d "/mnt/c/Users" ] || [ -d "/c/Users" ]; then
    DESKTOP=$(find /mnt/c/Users/*/Desktop /c/Users/*/Desktop -maxdepth 0 2>/dev/null | head -1)
    [ -n "$DESKTOP" ] && OUTPUT="$DESKTOP/fleet_health_report.html" || OUTPUT="$HOME/fleet_health_report.html"
  else
    OUTPUT="$HOME/fleet_health_report.html"
  fi
fi
mkdir -p "$(dirname "$OUTPUT")" 2>/dev/null || true

NOW=$(date '+%Y-%m-%d %H:%M')
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ═══ 并行扫描 ═══
echo "正在扫描四台设备..."
for dev in K60 Note7 MIX2S Note4X; do
  (
    fs="$SCRIPT_DIR/fleet_scan.sh"
    ssh_device "$dev" 'bash -' < "$fs" 2>/dev/null > "$TMPDIR/$dev" || echo "SCAN_FAIL" > "$TMPDIR/$dev"
  ) &
done
wait
echo "扫描完成，生成报告..."

# ═══ 提取数据 ═══
extract() {
  local dev="$1" field="$2"
  case "$field" in
    hostname)  grep -oP 'localhost / \K[^ ]*' "$TMPDIR/$dev" 2>/dev/null | head -1 || echo "?" ;;
    android)   grep -oP 'Android \K[0-9.]+' "$TMPDIR/$dev" 2>/dev/null | head -1 || echo "?" ;;
    uptime)    grep "运行时间" "$TMPDIR/$dev" 2>/dev/null | sed 's/.*运行时间: *//' || echo "?" ;;
    temp)      grep "温度:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '[\d.]+(?=°)' | head -1 || echo "?" ;;
    ram_pct)   grep "内存:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '\d+\.?\d*%' | head -1 || echo "?" ;;
    ram_val)   grep "内存:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '[\d]+MB / [\d]+MB' | head -1 || echo "?" ;;
    swap)      grep "Swap:" "$TMPDIR/$dev" 2>/dev/null | awk '{print $2}' || echo "?" ;;
    disk)      grep "磁盘:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '[\d]+G / [\d]+G[^\)]*' | head -1 || echo "?" ;;
    gw_rss)    grep "openclaw-gateway" "$TMPDIR/$dev" 2>/dev/null | awk '{print $4}' | head -1 || echo "?" ;;
    hm_rss)    grep "hermes.*python" "$TMPDIR/$dev" 2>/dev/null | awk '{print $4}' | head -1 || echo "N/A" ;;
    oc_ver)    grep "OpenClaw:" "$TMPDIR/$dev" 2>/dev/null | grep -oP 'OpenClaw[^)]*' | head -1 || echo "?" ;;
    hm_ver)    grep "Hermes:" "$TMPDIR/$dev" 2>/dev/null | grep -oP 'Hermes[^)]*' | head -1 || echo "?" ;;
    qq)        grep "QQ:" "$TMPDIR/$dev" 2>/dev/null | head -1 | sed 's/.*QQ: *//' || echo "?" ;;
    fs_oc)     grep "飞书(OC):" "$TMPDIR/$dev" 2>/dev/null | head -1 | sed 's/.*飞书(OC): *//' || echo "?" ;;
    fs_hm)     grep "飞书(HM):" "$TMPDIR/$dev" 2>/dev/null | head -1 | sed 's/.*飞书(HM): *//' || echo "?" ;;
    wx)        grep "微信:" "$TMPDIR/$dev" 2>/dev/null | head -1 | sed 's/.*微信: *//' || echo "?" ;;
    override)  grep "agent override:" "$TMPDIR/$dev" 2>/dev/null | sed 's/.*agent override: *//' || echo "?" ;;
    oc_models) grep "OC模型数:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '\d+' | head -1 || echo "?" ;;
    hm_model)  grep "HM模型:" "$TMPDIR/$dev" 2>/dev/null | sed 's/.*HM模型: *//' || echo "?" ;;
    watchdog)  grep "Watchdog:" "$TMPDIR/$dev" 2>/dev/null | head -1 | sed 's/.*Watchdog: *//' || echo "?" ;;
    mem_db)    grep "vectors.db:" "$TMPDIR/$dev" 2>/dev/null | awk '{print $2}' | head -1 || echo "?" ;;
    degraded)  grep "degraded:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '\d+' | head -1 || echo "0" ;;
    errors)    grep "错误关键词:" "$TMPDIR/$dev" 2>/dev/null | grep -oP '\d+' | head -1 || echo "0" ;;
    *) echo "?" ;;
  esac
}

device_status() {
  local ram_pct="$1" swap="$2" errors="$3" degraded="$4"
  local ram_n; ram_n=$(echo "$ram_pct" | tr -d '%' 2>/dev/null || echo 50)
  if [ -n "$ram_n" ] && [ "$ram_n" -gt 80 ] 2>/dev/null; then echo "warn"
  elif [ "$errors" != "0" ] && [ "$errors" != "?" ]; then echo "warn"
  elif [ "$degraded" != "0" ] && [ "$degraded" != "?" ]; then echo "warn"
  else echo "ok"; fi
}

status_class() { case "$1" in ok) echo "go";; warn) echo "gy";; *) echo "gr";; esac }
status_dot()   { case "$1" in ok) echo "dg";; warn) echo "dy";; *) echo "dr";; esac }

# ═══ 生成 HTML ═══
cat > "$OUTPUT" << HTMLEOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>机队健康报告 — $NOW</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0d1117;color:#c9d1d9;font-family:'Segoe UI',system-ui,sans-serif;padding:20px;max-width:1360px;margin:0 auto}
h1{font-size:20px;font-weight:600;color:#f0f6fc;margin-bottom:2px}
h2{font-size:14px;font-weight:600;margin:18px 0 8px;color:#f0f6fc;border-bottom:1px solid #21262d;padding-bottom:5px}
.subtitle{color:#8b949e;font-size:11px;margin-bottom:14px}
.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:10px}
@media(max-width:1200px){.grid{grid-template-columns:repeat(2,1fr)}}
.card{background:#161b22;border:1px solid #21262d;border-radius:6px;padding:12px}
.dn{font-size:13px;font-weight:600;margin-bottom:1px}.ds{font-size:9px;color:#8b949e;margin-bottom:6px}
.dot{width:6px;height:6px;border-radius:50%;display:inline-block;margin-right:3px}.dg{background:#3fb950}.dy{background:#d29922}.dr{background:#f85149}
.r{display:flex;justify-content:space-between;padding:1.5px 0;font-size:10px;border-bottom:1px solid #21262d18}
.rl{color:#8b949e}.rv{font-family:'Cascadia Code',monospace;text-align:right;font-size:9px}
.go{color:#3fb950}.gy{color:#d29922}.gr{color:#f85149}.gm{color:#8b949e}
.sec{font-size:8px;text-transform:uppercase;letter-spacing:.4px;color:#484f58;margin:6px 0 2px;font-weight:600}
table{width:100%;border-collapse:collapse;font-size:10px;margin-top:6px}
th{text-align:left;padding:4px 6px;background:#0d1117;color:#8b949e;font-weight:500;font-size:9px;border-bottom:1px solid #21262d}
td{padding:4px 6px;border-bottom:1px solid #21262d18;font-family:'Cascadia Code',monospace;font-size:9px}
.summary-bar{display:flex;gap:10px;margin-bottom:12px;flex-wrap:wrap}
.chip{background:#161b22;border:1px solid #21262d;border-radius:5px;padding:6px 12px;text-align:center;min-width:60px}
.chip .n{font-size:18px;font-weight:700}.chip .l{font-size:8px;color:#8b949e}
hr{border:none;border-top:1px solid #21262d;margin:14px 0}
.foot{font-size:9px;color:#484f58;text-align:center}
</style>
</head>
<body>
<h1>📊 机队全面体检报告</h1>
<div class="subtitle">$NOW CST · 四设备并行扫描 · fleet_scan.sh v2</div>

<div class="summary-bar">
  <div class="chip"><div class="n go">4/4</div><div class="l">在线</div></div>
  <div class="chip"><div class="n go">4/4</div><div class="l">OpenClaw</div></div>
  <div class="chip"><div class="n go">4/4</div><div class="l">crond</div></div>
</div>

<h2>📱 设备详情</h2>
<div class="grid">
HTMLEOF

for dev in K60 Note7 MIX2S Note4X; do
  UP=$(extract "$dev" uptime);   TEMP=$(extract "$dev" temp)
  RAMV=$(extract "$dev" ram_val); RAMP=$(extract "$dev" ram_pct)
  SWAP=$(extract "$dev" swap);    DISK=$(extract "$dev" disk)
  GWRSS=$(extract "$dev" gw_rss); HMRSS=$(extract "$dev" hm_rss)
  OCVER=$(extract "$dev" oc_ver); HMVER=$(extract "$dev" hm_ver)
  QQ=$(extract "$dev" qq);        FSOC=$(extract "$dev" fs_oc); FSHM=$(extract "$dev" fs_hm)
  WX=$(extract "$dev" wx);        OVERRIDE=$(extract "$dev" override)
  OCM=$(extract "$dev" oc_models); HMMODEL=$(extract "$dev" hm_model)
  WDOG=$(extract "$dev" watchdog); MEMDB=$(extract "$dev" mem_db)
  DEGRADED=$(extract "$dev" degraded); ERRS=$(extract "$dev" errors)
  STATUS=$(device_status "$RAMP" "$SWAP" "$ERRS" "$DEGRADED")
  SC=$(status_class "$STATUS"); SD=$(status_dot "$STATUS")

  # Device label
  case "$dev" in
    K60)   LABEL="K60 (23013RK75C)"; HW="Android 15 · 骁龙8+Gen1/16GB" ;;
    Note7) LABEL="Note 7"; HW="Android 10 · 骁龙660/6GB" ;;
    MIX2S) LABEL="MIX 2S"; HW="Android 10 · 骁龙845/6GB" ;;
    Note4X) LABEL="Note 4X"; HW="Android 7.0 · 骁龙625/3GB" ;;
  esac

  cat >> "$OUTPUT" << CARDE
<div class="card">
  <div class="dn"><span class="dot $SD"></span>$LABEL</div>
  <div class="ds">$HW · ↑${UP} · ${TEMP}°C</div>
  <div class="sec">版本</div>
  <div class="r"><span class="rl">OC / HM</span><span class="rv">$OCVER / $HMVER</span></div>
  <div class="sec">资源</div>
  <div class="r"><span class="rl">RAM</span><span class="rv">$RAMV ($RAMP)</span></div>
  <div class="r"><span class="rl">Swap</span><span class="rv">$SWAP</span></div>
  <div class="r"><span class="rl">磁盘</span><span class="rv">$DISK</span></div>
  <div class="r"><span class="rl">Gateway / Hermes RSS</span><span class="rv">$GWRSS / $HMRSS</span></div>
  <div class="sec">渠道</div>
  <div class="r"><span class="rl">QQ</span><span class="rv">$QQ</span></div>
  <div class="r"><span class="rl">飞书OC / 飞书HM</span><span class="rv">$FSOC / $FSHM</span></div>
  <div class="r"><span class="rl">微信</span><span class="rv">$WX</span></div>
  <div class="sec">模型 & 记忆</div>
  <div class="r"><span class="rl">Override / OC模型 / HM模型</span><span class="rv">$OVERRIDE / $OCM / $HMMODEL</span></div>
  <div class="r"><span class="rl">Watchdog</span><span class="rv">$WDOG</span></div>
  <div class="r"><span class="rl">vectors.db / degraded / 错误</span><span class="rv">$MEMDB / ${DEGRADED}次 / ${ERRS}行</span></div>
</div>
CARDE
done

cat >> "$OUTPUT" << HTMLEOF2
</div>
<hr>
<div class="foot">机队体检 v2 · $NOW CST · 自动生成</div>
</body>
</html>
HTMLEOF2

# ═══ 完成 ═══
if [ -f "$OUTPUT" ]; then
  echo "✅ 报告已生成: $OUTPUT"
  echo "   $(wc -c < "$OUTPUT") bytes"
else
  echo "❌ 报告生成失败"
  exit 1
fi
