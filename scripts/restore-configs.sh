#!/data/data/com.termux/files/usr/bin/bash
# 配置还原 — 从 backup-configs.sh 的备份恢复配置到指定设备
# 用法: bash restore-configs.sh <backup_dir> [target_device]
#       bash restore-configs.sh ~/fleet-backups/20260726-0200 K60
#       bash restore-configs.sh ~/fleet-backups/20260726-0200 --all
set -euo pipefail

BACKUP_DIR="${1:?用法: $0 <backup_dir> [K60|Note7|MIX2S|Note4X|--all]}"
TARGET="${2:---all}"

[ -d "$BACKUP_DIR" ] || { echo "错误: 备份目录不存在 — $BACKUP_DIR"; exit 1; }
echo "备份来源: $BACKUP_DIR"
echo ""

# ── 设备连接 (与 backup-configs.sh 同源) ──
if [ -f ~/.fleet-devices.conf ]; then
  . ~/.fleet-devices.conf
else
  K60_SSH="u0_a129@100.118.60.29:8022"
  NOTE7_SSH="u0_a171@100.91.94.44:8022"
  MIX2S_SSH="u0_a129@100.104.72.125:8022"
  NOTE4X_SSH="u0_a129@192.168.1.19:8022"
fi
declare -A DEV_SSH
DEV_SSH=(
  [K60]="$K60_SSH"
  [Note7]="$NOTE7_SSH"
  [MIX2S]="$MIX2S_SSH"
  [Note4X]="$NOTE4X_SSH"
)

FILES_TO_RESTORE=(
  ".openclaw/openclaw.json"
  ".openclaw/agents/main/agent/models.json"
  ".openclaw/agents/main/agent/openclaw-agent.sqlite"
)

restore_device() {
  local name="$1" conn="$2"
  local host="${conn%:*}"; host="${host#*@}"; local user="${conn%@*}"; local port="${conn##*:}"
  local dev_dir="$BACKUP_DIR/$name"

  echo "── $name ($user@$host:$port) ──"

  # SSH 探活
  if ! ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user@$host" 'echo OK' 2>/dev/null | grep -q OK; then
    echo "  ✗ SSH 不可达，跳过"
    return 1
  fi
  echo "  ✓ SSH 可达"

  # 检查备份子目录
  [ -d "$dev_dir" ] || { echo "  ✗ 备份中无 $name 数据 ($dev_dir)"; return 1; }

  # 还原前备份当前配置
  local ts; ts=$(date +%Y%m%d-%H%M)
  ssh -p "$port" -o ConnectTimeout=5 "$user@$host" "
    mkdir -p ~/.openclaw/restore-backups/${ts}
    for f in ~/.openclaw/openclaw.json ~/.openclaw/agents/main/agent/models.json; do
      [ -f \"\$f\" ] && cp \"\$f\" ~/.openclaw/restore-backups/${ts}/ 2>/dev/null || true
    done
    echo '  ✓ 当前配置已备份到 ~/.openclaw/restore-backups/${ts}/'
  " 2>/dev/null

  # 还原文件
  local restored=0 failed=0
  for f in "${FILES_TO_RESTORE[@]}"; do
    local src; src="$dev_dir/$(basename "$f")"
    if [ -f "$src" ]; then
      local remote_dir; remote_dir=$(dirname "$f")
      ssh -p "$port" -o ConnectTimeout=5 "$user@$host" "mkdir -p ~/${remote_dir}" 2>/dev/null
      scp -P "$port" -o ConnectTimeout=5 -q "$src" "$user@$host:~/${f}" 2>/dev/null && {
        echo "  ✓ $(basename "$f")"
        restored=$((restored + 1))
      } || {
        echo "  ✗ $(basename "$f") (scp 失败)"
        failed=$((failed + 1))
      }
    else
      echo "  - $(basename "$f") (备份中无此文件，跳过)"
    fi
  done

  # 重启 gateway
  if [ "$restored" -gt 0 ]; then
    echo -n "  重启 gateway..."
    ssh -p "$port" -o ConnectTimeout=5 "$user@$host" \
      'export SVDIR=$PREFIX/var/service && sv restart openclaw 2>/dev/null' 2>/dev/null && echo " ✓" || echo " ✗"
  fi

  echo "  结果: ${restored} 已还原, ${failed} 失败"
}

# ── 执行 ──
if [ "$TARGET" = "--all" ]; then
  for dev in K60 Note7 MIX2S Note4X; do
    restore_device "$dev" "${DEV_SSH[$dev]}"
    echo ""
  done
else
  restore_device "$TARGET" "${DEV_SSH[$TARGET]}"
fi

echo "═══ 还原完成 ═══"
echo "配置备份: ~/.openclaw/restore-backups/ (还原前自动创建)"
echo "如还原后异常，可从 restore-backups 目录恢复旧配置"
