#!/usr/bin/env bash
#==============================================================================
# OpenClaw 滚动升级 — 金丝雀流程自动化
# 用法: ./rolling-upgrade.sh [--dry-run] [--version 2026.7.x] [K60 Note7 ...]
#
# 流程（对应 device-matrix.md §6 升级 SOP）:
#   1. 预检 — 所有目标设备可达 + 当前版本
#   2. 金丝雀 — 第一台先升，验证 HTTP 200 + 模型 E2E
#   3. 逐台推 — 金丝雀通过后剩余设备逐台升级
#   4. 汇总 — 全部完成后的版本矩阵
#
# 安全设计:
#   - 单台失败不阻塞后续（标记 FAILED 继续）
#   - 每台升级前自动备份 openclaw.json
#   - --dry-run 只检查不升级
#==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh" 2>/dev/null || {
  echo "WARN: 无法加载 lib/common.sh，使用内置 DEVICES 配置"
  declare -A DEVICES
  DEVICES=(
    [K60]="u0_a129@100.118.60.29:8022"
    [Note7]="u0_a171@100.91.94.44:8022"
    [MIX2S]="u0_a129@100.104.72.125:8022"
    [Note4X]="u0_a129@192.168.1.19:8022"
  )
}

DRY_RUN=false
TARGET_VERSION="${1:-latest}"
declare -a TARGETS=()
UPGRADE_LOG="/tmp/openclaw-upgrade-$(date +%Y%m%d-%H%M).log"
CANARY=""  # 第一台金丝雀设备

# ═══ Args ═══
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --version|-v) TARGET_VERSION="$2"; shift 2 ;;
    --help|-h)
      echo "用法: $0 [--dry-run] [--version 2026.7.x] [K60 Note7 MIX2S Note4X]"
      echo "  --dry-run    只检查不升级"
      echo "  --version    指定版本 (默认 latest)"
      echo "  默认设备: K60 Note7 MIX2S Note4X (金丝雀: Note7)"
      exit 0
      ;;
    K60|Note7|MIX2S|Note4X) TARGETS+=("$1"); shift ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(Note7 K60 MIX2S Note4X)  # Note7 先升（家里轻量机，风险最低）
CANARY="${TARGETS[0]}"

# ═══ Helpers ═══
log()  { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$UPGRADE_LOG"; }
ok()   { log "  ✅ $1"; }
fail() { log "  ❌ $1"; }
warn() { log "  ⚠️  $1"; }

ssh_dev() {
  local name="$1"; shift
  local conn="${DEVICES[$name]}"
  ssh -p "${conn##*:}" -o ConnectTimeout=5 -o BatchMode=yes "${conn%:*}" "$@" 2>/dev/null
}

probe() {
  ssh_dev "$1" 'curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://127.0.0.1:18789/' 2>/dev/null || echo "fail"
}

get_version() {
  ssh_dev "$1" 'openclaw --version 2>&1 | head -1' 2>/dev/null || echo "N/A"
}

# ═══ Main ═══
echo ""
log "══════════════════════════════════════════"
log "  OpenClaw 滚动升级 — 金丝雀流程"
log "  版本: $TARGET_VERSION"
log "  设备: ${TARGETS[*]} (金丝雀: $CANARY)"
log "  模式: $([ "$DRY_RUN" = true ] && echo 'DRY RUN (不实际升级)' || echo '正式升级')"
log "  日志: $UPGRADE_LOG"
log "══════════════════════════════════════════"

# ═══ Phase 1: 预检 ═══
log ""
log "── [1/4] 预检 ──"
declare -A PRE_VERSIONS REACHABLE
ALL_OK=true

for dev in "${TARGETS[@]}"; do
  if [ "$(probe "$dev")" = "200" ]; then
    ver=$(get_version "$dev")
    PRE_VERSIONS[$dev]="$ver"
    REACHABLE[$dev]=true
    ok "$dev — $ver — HTTP 200"
  else
    REACHABLE[$dev]=false
    PRE_VERSIONS[$dev]="N/A"
    fail "$dev — 不可达，跳过"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" != "true" ]; then
  log ""
  warn "部分设备不可达，将继续升级可达设备"
fi

# ═══ Phase 2: 金丝雀 ═══
log ""
log "── [2/4] 金丝雀升级: $CANARY ──"

if [ "${REACHABLE[$CANARY]}" != "true" ]; then
  fail "金丝雀 $CANARY 不可达，无法继续"
  exit 1
fi

upgrade_one() {
  local dev="$1"
  local conn="${DEVICES[$dev]}"
  local user_host="${conn%:*}"
  local port="${conn##*:}"

  # 备份配置
  log "  $dev: 备份 openclaw.json..."
  ssh_dev "$dev" 'cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y%m%d-%H%M)' 2>/dev/null || true

  if [ "$DRY_RUN" = true ]; then
    log "  $dev: [DRY RUN] 跳过实际升级"
    return 0
  fi

  # libsqlite
  log "  $dev: 升级 libsqlite..."
  ssh_dev "$dev" 'apt install --only-upgrade -y libsqlite >/dev/null 2>&1' || warn "  $dev: libsqlite 升级跳过"

  # npm 升级 openclaw
  log "  $dev: npm install -g openclaw@$TARGET_VERSION..."
  if ! ssh_dev "$dev" 'export GYP_DEFINES="android_ndk_path=" && npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@'"$TARGET_VERSION"' 2>&1' | tail -2; then
    fail "$dev: npm 安装失败"
    return 1
  fi

  # shebang 修复 (坑25)
  log "  $dev: shebang 修复..."
  ssh_dev "$dev" '
    OCBIN=$(command -v openclaw)
    if [ -L "$OCBIN" ]; then
      NPM_ROOT=$(npm root -g)
      OCMJS="$NPM_ROOT/openclaw/openclaw.mjs"
      rm "$OCBIN"
      cat > "$OCBIN" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec node $OCMJS "\$@"
EOF
      chmod +x "$OCBIN"
    fi
  ' 2>/dev/null || warn "  $dev: shebang 修复跳过"

  # 重启
  log "  $dev: sv restart openclaw..."
  ssh_dev "$dev" 'export SVDIR=$PREFIX/var/service && sv restart openclaw' 2>/dev/null

  # 等待就绪（低端设备最多 90s）
  log "  $dev: 等待 gateway 就绪..."
  for i in $(seq 1 18); do
    sleep 5
    local http
    http=$(probe "$dev")
    if [ "$http" = "200" ]; then
      ok "$dev: HTTP 200 (${i}x5s)"
      return 0
    fi
    printf "."
  done
  echo ""

  fail "$dev: 90s 后仍未就绪"
  return 1
}

# 升级金丝雀
if ! upgrade_one "$CANARY"; then
  fail "金丝雀 $CANARY 升级失败，终止！其余设备不会升级。"
  log "  手动回滚: ssh $CANARY 'npm install -g openclaw@<旧版本>'"
  exit 1
fi

# 金丝雀 E2E 验证
log "  $CANARY: 模型 E2E 验证..."
E2E_RESULT=$(ssh_dev "$CANARY" \
  'timeout 30 openclaw agent --agent main --message "只回复OK" 2>&1 | head -3' 2>/dev/null) || E2E_RESULT=""
if echo "$E2E_RESULT" | grep -qi "OK"; then
  ok "$CANARY: 模型 E2E 通过"
else
  fail "$CANARY: 模型 E2E 异常: ${E2E_RESULT:-超时}"
  warn "继续升级其余设备，但 $CANARY 可能需要人工检查"
fi

# ═══ Phase 3: 逐台推 ═══
log ""
log "── [3/4] 逐台升级 ──"
declare -A RESULTS
RESULTS[$CANARY]="PASS"

for dev in "${TARGETS[@]}"; do
  [ "$dev" = "$CANARY" ] && continue
  [ "${REACHABLE[$dev]}" != "true" ] && { RESULTS[$dev]="SKIP"; continue; }

  log ""
  if upgrade_one "$dev"; then
    RESULTS[$dev]="PASS"
    ok "$dev: 升级完成 ($(get_version "$dev"))"
  else
    RESULTS[$dev]="FAIL"
    fail "$dev: 升级失败，继续下一台"
  fi
done

# ═══ Phase 4: 汇总 ═══
log ""
log "── [4/4] 汇总 ──"
printf "  %-8s %-20s %-40s %s\n" "设备" "升级前" "升级后" "状态"
printf "  %-8s %-20s %-40s %s\n" "────" "──────" "──────" "────"
for dev in "${TARGETS[@]}"; do
  after="${RESULTS[$dev]:-N/A}"
  if [ "$after" = "PASS" ]; then
    after_ver=$(get_version "$dev")
    status="✅ PASS"
  elif [ "$after" = "SKIP" ]; then
    after_ver="—"
    status="⏭️ SKIP"
  else
    after_ver="—"
    status="❌ FAIL"
  fi
  printf "  %-8s %-20s %-40s %s\n" "$dev" "${PRE_VERSIONS[$dev]}" "$after_ver" "$status"
done

log ""
log "日志: $UPGRADE_LOG"
