#!/data/data/com.termux/files/usr/bin/sh
# OpenClaw 卸载脚本（手机 Termux 侧执行，幂等）
# 用法: cat uninstall.sh | ssh -p 8022 user@<IP> 'sh -'
#       bash uninstall.sh --dry-run        # 预览不执行
#       bash uninstall.sh --keep-config     # 保留配置文件
set -e

DRY_RUN=false
KEEP_CONFIG=false

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=true ;;
    --keep-config|-k) KEEP_CONFIG=true ;;
    --help|-h)
      echo "用法: $0 [--dry-run] [--keep-config]"
      echo "  --dry-run, -n    只预览不执行"
      echo "  --keep-config, -k 保留 ~/.openclaw/ 配置文件"
      exit 0
      ;;
  esac
done

run() {
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] $1"
  else
    echo "  $1"
    eval "$1" || echo "  (警告: 忽略错误继续)"
  fi
}

echo ""
echo "  OpenClaw 卸载"
echo "  $( [ "$DRY_RUN" = true ] && echo '模式: DRY RUN (预览)' || echo '模式: 正式卸载' )"
echo "  $( [ "$KEEP_CONFIG" = true ] && echo '配置: 保留 ~/.openclaw/' || echo '配置: 删除 ~/.openclaw/' )"
echo ""

# ═══ 1. 停服务 ═══
echo "── [1/6] 停止服务 ──"
if [ -d "$PREFIX/var/service/openclaw" ]; then
  run "export SVDIR=\$PREFIX/var/service && sv down openclaw 2>/dev/null || true"
  sleep 2
  run "rm -rf \$PREFIX/var/service/openclaw"
  echo "  ✓ runit 服务已移除"
else
  echo "  (runit 服务不存在，跳过)"
fi

# ═══ 2. 清理 crontab ═══
echo "── [2/6] 清理 crontab ──"
if crontab -l 2>/dev/null | grep -qE "healthcheck|self-check|openclaw|fleet-dashboard|check-ip|check-version|backup-configs|fund-monitor|fund-weekly|trade-signal|quota_watcher|rolling-upgrade"; then
  echo "  当前 crontab:"
  crontab -l 2>/dev/null | grep -E "healthcheck|self-check|openclaw|fleet-dashboard|check-ip|check-version|backup-configs|fund-monitor|fund-weekly|trade-signal|quota_watcher|rolling-upgrade" | while read -r line; do
    echo "    $line"
  done
  run "crontab -l 2>/dev/null | grep -vE 'healthcheck|self-check|openclaw|fleet-dashboard|check-ip|check-version|backup-configs|fund-monitor|fund-weekly|trade-signal|quota_watcher|rolling-upgrade' | crontab - 2>/dev/null || crontab -r 2>/dev/null || true"
  echo "  ✓ crontab 已清理"
else
  echo "  (无相关 crontab，跳过)"
fi

# ═══ 3. 清理脚本文件 ═══
echo "── [3/6] 清理部署的脚本 ──"
SCRIPTS="healthcheck.sh self-check.sh check-ip.sh check-version.sh backup-configs.sh fleet-dashboard.sh fund-monitor.py fund-weekly.py trade-signal-scanner.py feishu_push.py quota_watcher.sh quota_manager.sh rolling-upgrade.sh"
for f in $SCRIPTS; do
  [ -f "$HOME/$f" ] && run "rm -f \$HOME/$f" && echo "  ✓ $f" || true
done
# 清理日志
for f in healthcheck.log self-check.log check-ip.log check-version.log fleet-dashboard.log watcher.log; do
  [ -f "$HOME/$f" ] && run "rm -f \$HOME/$f" && echo "  ✓ $f" || true
done
echo "  ✓ 脚本文件已清理"

# ═══ 4. 清理 Termux:Boot ═══
echo "── [4/6] 清理开机自启 ──"
if [ -f "$HOME/.termux/boot/start-services.sh" ]; then
  if grep -q "openclaw\|runsv\|start-services" "$HOME/.termux/boot/start-services.sh" 2>/dev/null; then
    run "rm -f \$HOME/.termux/boot/start-services.sh"
    echo "  ✓ boot 脚本已移除"
  else
    echo "  (boot 脚本不含 openclaw 引用，保留)"
  fi
else
  echo "  (无 boot 脚本)"
fi

# ═══ 5. 卸载 npm 包 ═══
echo "── [5/6] 卸载 OpenClaw ──"
if command -v openclaw >/dev/null 2>&1; then
  OC_VER=$(openclaw --version 2>&1 | head -1)
  echo "  当前版本: $OC_VER"
  run "npm uninstall -g openclaw 2>/dev/null || true"
  echo "  ✓ npm 包已卸载"
else
  echo "  (openclaw 未安装)"
fi

# ═══ 6. 配置文件 ═══
echo "── [6/6] 配置文件 ──"
if [ "$KEEP_CONFIG" = true ]; then
  echo "  ✓ ~/.openclaw/ 已保留 (--keep-config)"
else
  if [ -d "$HOME/.openclaw" ]; then
    run "rm -rf \$HOME/.openclaw"
    echo "  ✓ ~/.openclaw/ 已删除"
  else
    echo "  (无配置文件)"
  fi
fi
# fleet 凭证不管 --keep-config 都保留（含 API Key，误删代价大）
if [ -f "$HOME/.fleet-dashboard.conf" ]; then
  echo "  ✓ ~/.fleet-dashboard.conf 保留（含 API 凭证，手动删除: rm ~/.fleet-dashboard.conf）"
fi

echo ""
echo "  ══════════════════════════════"
echo "  卸载完成"
echo ""
if [ "$KEEP_CONFIG" = true ]; then
  echo "  配置文件已保留在 ~/.openclaw/"
  echo "  重新安装: curl -fsSL https://... | bash"
fi
echo "  ══════════════════════════════"
