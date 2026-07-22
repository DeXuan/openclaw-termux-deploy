#!/data/data/com.termux/files/usr/bin/sh
# 机型环境体检（手机 Termux 侧执行，只读不改，幂等）
# 用法: cat phone_check_env.sh | ssh -p 8022 user@<IP> 'sh -'
# 输出各项 [PASS]/[FAIL]/[SKIP]，FAIL 项附坑号与修复命令

echo "==== OpenClaw 机型环境体检 ===="

# ── 1. 机型识别 ──
MODEL=$(getprop ro.product.model 2>/dev/null)
MARKET=$(getprop ro.product.marketname 2>/dev/null)
AV=$(getprop ro.build.version.release 2>/dev/null)
MIUI=$(getprop ro.miui.ui.version.name 2>/dev/null)
echo "机型: ${MODEL} (${MARKET:-无marketname}) | Android ${AV} | MIUI/HyperOS: ${MIUI:-非小米}"

# ── 2. Android 版本决策树 ──
AMAJ=$(echo "$AV" | cut -d. -f1)
if [ "$AMAJ" -ge 12 ] 2>/dev/null; then
  echo "[加固] Android 12+：phantom killer 必关 + 权限自动撤销必禁 + Doze 白名单（hardening.md 全套）"
elif [ "$AMAJ" -ge 8 ] 2>/dev/null; then
  echo "[加固] Android 8-11：只需 Doze 白名单（phantom killer A12 才有）"
else
  echo "[加固] Android <=7：只需 Doze 白名单；Tailscale App 装不上 → 局域网 IP + 路由器 MAC 绑定"
fi

ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }

# ── 3. Node 版本合规（OpenClaw 2026.7.1-x CLI 硬检查，坑 18）──
if command -v node >/dev/null 2>&1; then
  NV=$(node --version | tr -d v)
  NMAJ=$(echo "$NV" | cut -d. -f1)
  NODE_OK=no
  case "$NMAJ" in
    22) ver_ge "$NV" "22.22.3" && NODE_OK=yes ;;
    24) ver_ge "$NV" "24.15.0" && NODE_OK=yes ;;
    25) ver_ge "$NV" "25.9.0" && NODE_OK=yes ;;
    2[6-9]|[3-9][0-9]) NODE_OK=yes ;;
  esac
  if [ "$NODE_OK" = yes ]; then
    echo "[PASS] node $NV 合规"
  else
    echo "[FAIL] node $NV 不合规（需 >=22.22.3<23 / >=24.15.0<25 / >=25.9.0，坑 18）"
    echo "       修复: 仓库无合规版时手动装 26.4.0 —— curl -4 -L -o \$HOME/nodejs.deb <镜像pool的nodejs_26.4.0_aarch64.deb> && dpkg -i \$HOME/nodejs.deb && apt-mark hold nodejs（装后必须重装 openclaw）"
  fi
else
  echo "[SKIP] node 未安装（阶段 2 会装）"
fi

# ── 4. SQLite 版本（OpenClaw WAL 安全检查，坑 17）──
if command -v node >/dev/null 2>&1; then
  SQV=$(node -e 'const s=require("node:sqlite");console.log(new s.DatabaseSync(":memory:").prepare("select sqlite_version() v").get().v)' 2>/dev/null)
  if [ -n "$SQV" ] && ver_ge "$SQV" "3.51.3"; then
    echo "[PASS] libsqlite $SQV 合规"
  else
    echo "[FAIL] libsqlite ${SQV:-读取失败} 不合规（需 >=3.51.3，坑 17）"
    echo "       修复: apt update && apt install --only-upgrade -y libsqlite"
  fi
fi

# ── 5. OpenClaw ──
if command -v openclaw >/dev/null 2>&1; then
  OV=$(openclaw --version 2>&1 | head -1)
  case "$OV" in
    OpenClaw*) echo "[PASS] $OV" ;;
    *) echo "[FAIL] openclaw CLI 异常: $OV" ;;
  esac
else
  echo "[SKIP] openclaw 未安装"
fi

# ── 6. 开机自启链 ──
[ -x ~/.termux/boot/start-services.sh ] && echo "[PASS] boot 脚本存在" || echo "[FAIL] boot 脚本缺失（阶段 4 的 phone_setup_service.sh 会建）"
BOOTPKG=$(pm list packages 2>/dev/null | grep -c com.termux.boot)
if [ "$BOOTPKG" = "1" ]; then
  echo "[PASS] Termux:Boot 已安装"
elif [ "$AMAJ" -ge 12 ] 2>/dev/null; then
  echo "[WARN] pm 未查到 Termux:Boot —— Android 12+ 包可见性会漏报（HyperOS 实测），以重启实测为准"
else
  echo "[FAIL] Termux:Boot 未安装（重启即失联！阶段 5 安装）"
fi

# ── 7. 服务状态 ──
export SVDIR=$PREFIX/var/service
if [ -d "$SVDIR/openclaw" ]; then
  echo "[INFO] $(sv status openclaw 2>&1 | head -1)"
  echo "[INFO] dashboard HTTP $(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://127.0.0.1:18789/ 2>/dev/null)"
else
  echo "[SKIP] runit 服务未创建（阶段 4）"
fi

echo "==== 体检完成 ===="
