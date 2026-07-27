#!/data/data/com.termux/files/usr/bin/bash
# Hermes Mesh Sync v3 — 四设备记忆+技能双向同步
# cron: */10 * * * * ~/.hermes/mesh-sync.sh

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
LOCK_FILE="$HERMES_HOME/.mesh-sync.lock"
LOG_FILE="$HERMES_HOME/logs/mesh-sync.log"
HEARTBEAT="$HERMES_HOME/.mesh-heartbeat"

exec 200>"$LOCK_FILE"
flock -n 200 || exit 0
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date -Iseconds) $*" >> "$LOG_FILE"; }

# 对等设备: Tailscale_IP:LAN_IP:name  (TS优先，LAN回退，0=无)
PEERS=(
  "100.118.60.29:192.168.1.23:k60"
  "100.91.94.44:192.168.1.77:note7"
  "0:192.168.1.19:note4x"
  "100.104.72.125:192.168.1.20:mix2s"
)

SYNC_DIRS=("memories" "skills")
SSH_OPTS="-p 8022 -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no"

# 检测自己（通过 hostname 或本机所有 IP）
MY_IPS=$(ip addr show 2>/dev/null | grep 'inet ' | awk '{print $2}' | sed 's|/.*||' | tr '\n' ' ')
MY_HOST=$(hostname 2>/dev/null || getprop ro.product.model 2>/dev/null || echo "unknown")

is_me() {
  local ts="$1" lan="$2"
  for myip in $MY_IPS; do
    [ "$myip" = "$ts" ] && return 0
    [ "$myip" = "$lan" ] && return 0
  done
  return 1
}

log "=== mesh ==="
date -Iseconds > "$HEARTBEAT"
ok=0 skip=0

for entry in "${PEERS[@]}"; do
  IFS=':' read -r ts_ip lan_ip name <<< "$entry"

  if is_me "$ts_ip" "$lan_ip"; then
    log "ME $name ($MY_HOST)"; continue
  fi

  # 选可达 IP
  peer_ip=""
  for try in "$ts_ip" "$lan_ip"; do
    [ "$try" = "0" ] && continue
    if ssh $SSH_OPTS "user@$try" 'echo OK' 2>/dev/null; then
      peer_ip="$try"; break
    fi
  done

  if [ -z "$peer_ip" ]; then
    log "OFF $name"; ((skip++)); continue
  fi

  for dir in "${SYNC_DIRS[@]}"; do
    mkdir -p "$HERMES_HOME/$dir"
    rsync -az --update --times --exclude='.git' \
      -e "ssh $SSH_OPTS" \
      "$HERMES_HOME/$dir/" "user@$peer_ip:$HERMES_HOME/$dir/" 2>/dev/null \
      && log "↑$name $dir" || log "↑$name $dir FAIL"
    rsync -az --update --times --exclude='.git' \
      -e "ssh $SSH_OPTS" \
      "user@$peer_ip:$HERMES_HOME/$dir/" "$HERMES_HOME/$dir/" 2>/dev/null \
      && log "↓$name $dir" || log "↓$name $dir FAIL"
  done
  ((ok++))
done

log "mesh done: $ok synced, $skip offline"
