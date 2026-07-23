#!/usr/bin/env bash
# openclaw-deploy 共享库 — 颜色、日志、系统检测、设备配置
# 用法: source "$(dirname "$0")/lib/common.sh"

set -euo pipefail

# ── 颜色 ──
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_RED='\033[31m'   ; C_GREEN='\033[32m'; C_YELLOW='\033[33m'
C_BLUE='\033[34m'  ; C_MAGENTA='\033[35m'; C_CYAN='\033[36m'
C_WHITE='\033[37m'
C_BG_BLUE='\033[44m'; C_BG_GREEN='\033[42m'; C_BG_RED='\033[41m'

# ── 图标 ──
ICON_OK="✅"; ICON_FAIL="❌"; ICON_WARN="⚠️"; ICON_INFO="ℹ️"
ICON_STAR="⭐"; ICON_GEAR="⚙️"; ICON_ROCKET="🚀"; ICON_CHART="📊"
ICON_PHONE="📱"; ICON_LOCK="🔒"; ICON_KEY="🔑"; ICON_NET="🌐"

# ── 日志 ──
log_info()  { echo -e "${C_BLUE}${ICON_INFO}${C_RESET} $1"; }
log_ok()    { echo -e "${C_GREEN}${ICON_OK}${C_RESET} $1"; }
log_warn()  { echo -e "${C_YELLOW}${ICON_WARN}${C_RESET} $1"; }
log_fail()  { echo -e "${C_RED}${ICON_FAIL}${C_RESET} $1"; }
log_step()  { echo -e "${C_CYAN}${C_BOLD}→${C_RESET} $1"; }
log_title() { echo -e "\n${C_BOLD}${C_BG_BLUE}  $1  ${C_RESET}\n"; }

# ── 进度条 (兼容无 seq) ──
show_progress() {
  local current=$1 total=$2 desc=${3:-""} width=30
  local pct=$((current * 100 / total))
  local filled=$((pct * width / 100))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="#"; done
  printf "\r${C_CYAN}[%-${width}s]${C_RESET} %3d%% %s" "$bar" "$pct" "$desc"
  [ "$current" -eq "$total" ] && echo
}

# ── 系统检测 ──
is_termux() { [ -d /data/data/com.termux/files/usr ] 2>/dev/null; }
is_android() { [ "$(uname -o 2>/dev/null)" = "Android" ]; }
get_arch() { uname -m; }

# Termux PREFIX 容错 (PC 上无此变量)
if [ -z "${PREFIX:-}" ] && is_termux; then
  PREFIX="/data/data/com.termux/files/usr"
elif [ -z "${PREFIX:-}" ]; then
  PREFIX=""  # PC 环境，PREFIX 为空
fi

# Termux 数据目录 (跨设备兼容)
get_data_dir() {
  if is_termux; then
    echo "${PREFIX}/.."  # /data/data/com.termux/files
  else
    echo "$HOME"
  fi
}

# ── 设备别名 ──
get_device_name() {
  local model
  model=$(getprop ro.product.model 2>/dev/null) || model=$(uname -n 2>/dev/null) || model="unknown"
  case "$model" in
    *23013*)  echo "K60"   ;;
    *MIX*2S*) echo "MIX 2S" ;;
    *Redmi*Note*7*) echo "Note 7" ;;
    *Redmi*Note*4X*) echo "Note 4X" ;;
    *)        echo "$model" ;;
  esac
}

# ── 机队设备配置 ──
declare -A DEVICES
DEVICES=(
  [K60]="u0_a129@100.118.60.29:8022"
  [Note7]="u0_a171@100.91.94.44:8022"
  [MIX2S]="u0_a129@100.104.72.125:8022"
  [Note4X]="u0_a129@192.168.1.19:8022"
)

DEVICE_NAMES=("K60" "Note7" "MIX2S" "Note4X")
DEVICE_LABELS=("K60 — 主力机" "Note 7 — 轻量机" "MIX 2S — 副机" "Note 4X — 备机")

# ── SSH 快捷方法 ──
ssh_device() {
  local name="$1"; shift
  local conn="${DEVICES[$name]}"
  local user_host="${conn%:*}"     # u0_a129@100.118.60.29
  local port="${conn##*:}"         # 8022
  ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user_host" "$@" 2>/dev/null
}

# ── 网关探活 ──
check_gateway() {
  local target=${1:-http://127.0.0.1:18789/}
  curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "$target" 2>/dev/null || echo "fail"
}

# ── 格式化输出 ──
status_badge() {
  case "$1" in
    200)  echo -e "${C_GREEN}● 在线${C_RESET}" ;;
    fail) echo -e "${C_RED}● 离线${C_RESET}" ;;
    *)    echo -e "${C_YELLOW}● ${1}${C_RESET}" ;;
  esac
}

# ── 确认对话框 ──
confirm() {
  local prompt="${1:-确认?} [y/N] "
  read -r -p "$(echo -e "${C_YELLOW}${prompt}${C_RESET}")" reply
  case "$reply" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

# ── 标题横幅 ──
banner() {
  echo -e "${C_CYAN}${C_BOLD}"
  echo "  ╔══════════════════════════════════════╗"
  echo "  ║   OpenClaw Termux Deploy Toolbox    ║"
  echo "  ╚══════════════════════════════════════╝"
  echo -e "${C_RESET}"
}

# ── 按键继续 ──
press_enter() {
  echo
  read -r -p "$(echo -e "${C_DIM}按 Enter 返回菜单...${C_RESET}")" _
}
