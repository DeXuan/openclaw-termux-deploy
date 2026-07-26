#!/data/data/com.termux/files/usr/bin/bash
# 机队配置备份 — 从四台设备拉取关键配置，存到本地带时间戳目录
# cron: 0 2 * * 0  ~/backup-configs.sh  (周日 02:00)
set -euo pipefail

BACKUP_ROOT=~/fleet-backups
TS=$(date '+%Y%m%d-%H%M')
BACKUP_DIR="$BACKUP_ROOT/$TS"
KEEP_DAYS=30  # 保留最近 30 天

# ── 设备连接信息（IP 集中管理：~/.fleet-devices.conf，与 lib/common.sh 保持同步）──
if [ -f ~/.fleet-devices.conf ]; then
  . ~/.fleet-devices.conf
else
  # 兜底硬编码（修改 IP 请优先改 ~/.fleet-devices.conf 或 lib/common.sh）
  K60_SSH="u0_a129@100.118.60.29:8022"
  NOTE7_SSH="u0_a171@100.91.94.44:8022"
  MIX2S_SSH="u0_a129@100.104.72.125:8022"
  NOTE4X_SSH="u0_a129@192.168.1.19:8022"
fi
declare -A DEV_IPS
DEV_IPS=(
  [K60]="$K60_SSH"
  [Note7]="$NOTE7_SSH"
  [MIX2S]="$MIX2S_SSH"
  [Note4X]="$NOTE4X_SSH"
)

FILES_TO_BACKUP=(
  ".openclaw/openclaw.json"
  ".openclaw/agents/main/agent/models.json"
  ".openclaw/free_quota.json"
  "healthcheck.sh"
  "self-check.sh"
  "quota_watcher.sh"
  "quota_manager.sh"
)

mkdir -p "$BACKUP_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

# ── 逐台备份 ──
for dev in K60 Note7 MIX2S Note4X; do
  conn="${DEV_IPS[$dev]}"
  user_host="${conn%:*}"
  port="${conn##*:}"

  if ! ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user_host" 'echo OK' 2>/dev/null | grep -q OK; then
    log "SKIP $dev — SSH 不可达"
    continue
  fi

  dev_dir="$BACKUP_DIR/$dev"
  mkdir -p "$dev_dir"

  for f in "${FILES_TO_BACKUP[@]}"; do
    ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user_host" \
      "cat ~/$f 2>/dev/null" > "$dev_dir/$(basename "$f")" 2>/dev/null && \
      log "  $dev: $f ✓" || log "  $dev: $f (跳过，可能不存在)"
  done

  # crontab
  ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user_host" \
    'crontab -l 2>/dev/null' > "$dev_dir/crontab.txt" 2>/dev/null && \
    log "  $dev: crontab ✓" || log "  $dev: crontab (空)"

  # 设备信息摘要
  ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user_host" \
    'echo "hostname:$(hostname) | model:$(getprop ro.product.model 2>/dev/null || echo N/A) | android:$(getprop ro.build.version.release 2>/dev/null || echo N/A) | openclaw:$(openclaw --version 2>/dev/null | head -1 || echo N/A) | node:$(node --version 2>/dev/null || echo N/A)"' \
    > "$dev_dir/device-info.txt" 2>/dev/null
done

# ── 本机 (K60) 配置也备份 ──
if [ "$(hostname 2>/dev/null)" = "localhost" ] || [ -d ~/.openclaw ]; then
  local_dir="$BACKUP_DIR/K60-local"
  mkdir -p "$local_dir"
  for f in "${FILES_TO_BACKUP[@]}"; do
    cp ~/"$f" "$local_dir/$(basename "$f")" 2>/dev/null && \
      log "  K60-local: $f ✓" || true
  done
  crontab -l 2>/dev/null > "$local_dir/crontab.txt" || true
fi

# ── 打包 + 清理旧备份 ──
cd "$BACKUP_ROOT"
tar -czf "${TS}.tar.gz" "$TS" && rm -rf "$TS"
log "打包: ${TS}.tar.gz ($(du -h "${TS}.tar.gz" | cut -f1))"

# 清理 30 天前的备份
find "$BACKUP_ROOT" -name "*.tar.gz" -mtime +"$KEEP_DAYS" -delete 2>/dev/null || true

COUNT=$(find "$BACKUP_ROOT" -name "*.tar.gz" | wc -l)
log "完成 — 现存 ${COUNT} 个备份"
