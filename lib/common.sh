#!/usr/bin/env bash
#==============================================================================
# OpenClaw Deploy — Modern CLI UI Toolkit
#==============================================================================
set -euo pipefail

# ═══ Color Palette (Catppuccin-inspired) ═══
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_ITALIC='\033[3m'
C_UNDERLINE='\033[4m'

# Base
C_RED='\033[38;5;203m';    C_GREEN='\033[38;5;114m'
C_YELLOW='\033[38;5;221m'; C_BLUE='\033[38;5;111m'
C_MAGENTA='\033[38;5;176m'; C_CYAN='\033[38;5;80m'
C_WHITE='\033[38;5;255m';  C_GRAY='\033[38;5;243m'
C_ORANGE='\033[38;5;215m'; C_PINK='\033[38;5;211m'
C_TEAL='\033[38;5;73m';    C_PURPLE='\033[38;5;140m'

# Backgrounds
C_BG_DARK='\033[48;5;236m'
C_BG_CYAN='\033[48;5;37m'
C_BG_GREEN='\033[48;5;28m'
C_BG_RED='\033[48;5;124m'
C_BG_YELLOW='\033[48;5;136m'

# ═══ Box Drawing Characters ═══
BOX_H='─'; BOX_V='│'; BOX_TL='╭'; BOX_TR='╮'; BOX_BL='╰'; BOX_BR='╯'
BOX_H2='═'; BOX_V2='║'; BOX_TL2='╔'; BOX_TR2='╗'; BOX_BL2='╚'; BOX_BR2='╝'
BOX_DOT='·'; BOX_ARROW='→'; BOX_BULLET='●'; BOX_HOLLOW='○'
BOX_CHECK='✔'; BOX_CROSS='✘'

# ═══ Icons ═══
ICO_OK="${C_GREEN}${BOX_CHECK}${C_RESET}"
ICO_FAIL="${C_RED}${BOX_CROSS}${C_RESET}"
ICO_DOT="${C_CYAN}${BOX_BULLET}${C_RESET}"
ICO_HOLLOW="${C_DIM}${BOX_HOLLOW}${C_RESET}"
ICO_ARROW="${C_CYAN}${BOX_ARROW}${C_RESET}"
ICO_WARN="${C_YELLOW}⚠${C_RESET}"
ICO_INFO="${C_BLUE}ℹ${C_RESET}"
ICO_GEAR="${C_DIM}⚙${C_RESET}"
ICO_ROCKET="${C_CYAN}🚀${C_RESET}"
ICO_PHONE="${C_GREEN}📱${C_RESET}"
ICO_CHART="${C_MAGENTA}📊${C_RESET}"
ICO_LOCK="${C_YELLOW}🔒${C_RESET}"
ICO_STAR="${C_YELLOW}★${C_RESET}"

# ═══ Spinner ═══
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPINNER_PID=""

spinner_start() {
  local msg="${1:-}"
  printf "\r\033[K"
  (
    local i=0
    while true; do
      local c="${SPINNER_CHARS:$i:1}"
      printf "\r  ${C_CYAN}%s${C_RESET} %s" "$c" "$msg"
      i=$(((i + 1) % ${#SPINNER_CHARS}))
      sleep 0.1
    done
  ) &
  SPINNER_PID=$!
}

spinner_stop() {
  [ -n "$SPINNER_PID" ] && kill "$SPINNER_PID" 2>/dev/null || true
  SPINNER_PID=""
  printf "\r\033[K"
}

# ═══ Drawing Helpers ═══

# Horizontal rule
hr()      { printf "${C_DIM}%s${C_RESET}\n" "$(printf '─%.0s' $(seq 1 ${1:-40}))"; }

# Section header with icon
section()  { echo -e "\n  ${C_BOLD}${1}${C_RESET}  ${C_DIM}${2:-}${C_RESET}\n"; }

# Info panel (bordered box)
panel_start() {
  local title="${1:-}"
  local width=${2:-60}
  echo -e "${C_DIM}${BOX_TL}$(printf "${BOX_H}%.0s" $(seq 1 $((width-2))))${BOX_TR}${C_RESET}"
  if [ -n "$title" ]; then
    echo -e "${C_DIM}${BOX_V}${C_RESET} ${C_BOLD}${title}${C_RESET}"
    echo -e "${C_DIM}${BOX_V}${C_RESET}"
  fi
}
panel_line()  { echo -e "${C_DIM}${BOX_V}${C_RESET} ${1:-}"; }
panel_end()   {
  local width=${1:-60}
  echo -e "${C_DIM}${BOX_BL}$(printf "${BOX_H}%.0s" $(seq 1 $((width-2))))${BOX_BR}${C_RESET}"
}

# Card (rounded box with padding)
card() {
  local title="$1" body="$2" width=${3:-50}
  local inner=$((width - 4))
  echo -e "  ${C_DIM}${BOX_TL}$(printf "${BOX_H}%.0s" $(seq 1 $((width-2))))${BOX_TR}${C_RESET}"
  echo -e "  ${C_DIM}${BOX_V}${C_RESET} ${C_BOLD}${C_CYAN}$title${C_RESET}"
  echo -e "  ${C_DIM}${BOX_V}$(printf ' %.0s' $(seq 1 $((width-2))))${BOX_V}${C_RESET}"
  while IFS= read -r line; do
    printf "  ${C_DIM}${BOX_V}${C_RESET}  %-${inner}s${C_DIM}${BOX_V}${C_RESET}\n" "$line"
  done <<< "$body"
  echo -e "  ${C_DIM}${BOX_BL}$(printf "${BOX_H}%.0s" $(seq 1 $((width-2))))${BOX_BR}${C_RESET}"
}

# ═══ Status Pills ═══
pill_ok()     { echo -e "${C_BG_GREEN}${C_WHITE} 在线 ${C_RESET}"; }
pill_off()    { echo -e "${C_BG_RED}${C_WHITE} 离线 ${C_RESET}"; }
pill_warn()   { echo -e "${C_BG_YELLOW}${C_WHITE} ${1:-警告} ${C_RESET}"; }
pill_info()   { echo -e "${C_BG_CYAN}${C_WHITE} ${1:-信息} ${C_RESET}"; }
pill_tag()    { echo -e "${C_DIM}[${1}]${C_RESET}"; }

# ═══ Logging (quiet by default) ═══
log_ok()    { echo -e "  ${ICO_OK} ${C_GREEN}$1${C_RESET}"; }
log_fail()  { echo -e "  ${ICO_FAIL} ${C_RED}$1${C_RESET}"; }
log_warn()  { echo -e "  ${ICO_WARN} ${C_YELLOW}$1${C_RESET}"; }
log_info()  { echo -e "  ${ICO_INFO} ${C_BLUE}$1${C_RESET}"; }
log_step()  { echo -e "  ${ICO_ARROW} $1"; }
log_done()  { echo -e "  ${ICO_OK} ${C_GREEN}$1${C_RESET}"; }

# Step indicator (1/5 style)
show_step() {
  local step=$1 total=$2 desc="$3"
  local dots=""
  for ((i=1; i<=total; i++)); do
    if [ "$i" -lt "$step" ]; then dots+="${C_GREEN}${BOX_CHECK}${C_RESET} "
    elif [ "$i" -eq "$step" ]; then dots+="${C_CYAN}${BOX_BULLET}${C_RESET} "
    else dots+="${C_DIM}${BOX_HOLLOW}${C_RESET} "
    fi
  done
  echo -e "  ${dots}${C_BOLD}${desc}${C_RESET}"
}

# ═══ Progress Bar ═══
show_progress() {
  local current=$1 total=$2 desc=${3:-""} width=30
  local pct=$((current * 100 / total))
  local filled=$((pct * width / 100))
  local bar=""
  for ((i=0; i<width; i++)); do
    if [ "$i" -lt "$filled" ]; then bar+="${C_CYAN}█${C_RESET}"
    else bar+="${C_DIM}░${C_RESET}"
    fi
  done
  printf "\r  %s %3d%%  ${C_DIM}%s${C_RESET}" "$bar" "$pct" "$desc"
  [ "$current" -eq "$total" ] && echo
}

# ═══ System Detection ═══
is_termux()  { [ -d /data/data/com.termux/files/usr ] 2>/dev/null; }
is_android() { [ "$(uname -o 2>/dev/null)" = "Android" ]; }
get_arch()   { uname -m; }

if [ -z "${PREFIX:-}" ] && is_termux; then
  PREFIX="/data/data/com.termux/files/usr"
elif [ -z "${PREFIX:-}" ]; then
  PREFIX=""
fi

get_data_dir() {
  if is_termux; then echo "${PREFIX}/.."; else echo "$HOME"; fi
}

# ═══ Device Identity ═══
get_device_name() {
  local model
  model=$(getprop ro.product.model 2>/dev/null) || model=$(uname -n 2>/dev/null) || model="unknown"
  case "$model" in
    *23013*)           echo "K60"    ;;
    *MIX*2S*)          echo "MIX 2S" ;;
    *Redmi*Note*7*)    echo "Note 7" ;;
    *Redmi*Note*4X*)   echo "Note 4X" ;;
    *)                 echo "$model" ;;
  esac
}

get_device_emoji() {
  case "$(get_device_name)" in
    K60)    echo "🔥" ;;  Note7) echo "🍃" ;;
    MIX2S)  echo "⚡" ;;  Note4X) echo "🪨" ;;
    *)      echo "📱" ;;
  esac
}

# ═══ Fleet Configuration ═══
declare -A DEVICES
DEVICES=(
  [K60]="u0_a129@100.118.60.29:8022"
  [Note7]="u0_a171@100.91.94.44:8022"
  [MIX2S]="u0_a129@100.104.72.125:8022"
  [Note4X]="u0_a129@192.168.1.19:8022"
)

DEVICE_NAMES=("K60" "Note7" "MIX2S" "Note4X")
DEVICE_EMOJI=("🔥" "🍃" "⚡" "🪨")
DEVICE_LABELS=("随身主力机" "家里轻量机" "待重新定位" "长期备机")
DEVICE_ROLES=("QQ+飞书+微信" "QQ+飞书" "QQ+飞书" "QQ+飞书+微信")

# ═══ SSH ═══
ssh_device() {
  local name="$1"; shift
  local conn="${DEVICES[$name]}"
  local user_host="${conn%:*}"
  local port="${conn##*:}"
  ssh -p "$port" -o ConnectTimeout=5 -o BatchMode=yes "$user_host" "$@" 2>/dev/null
}

# ═══ Gateway Probe ═══
check_gateway() {
  local target=${1:-http://127.0.0.1:18789/}
  curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 "$target" 2>/dev/null || echo "fail"
}

# ═══ Confirmation ═══
confirm() {
  local prompt="${1:-确认?}"
  read -r -p "$(echo -e "  ${C_YELLOW}${prompt}${C_RESET} ${C_DIM}[y/N]${C_RESET} ")" reply
  case "$reply" in [Yy]|[Yy][Ee][Ss]) return 0 ;; *) return 1 ;; esac
}

# ═══ Pause ═══
press_enter() {
  echo
  read -r -p "$(echo -e "  ${C_DIM}按 Enter 继续…${C_RESET}")" _
}

# ═══ Header (ASCII Art) ═══
header() {
  clear
  echo -e "${C_CYAN}${C_BOLD}"
  echo "         ██████╗ ██████╗ ███████╗███╗   ██╗"
  echo "        ██╔═══██╗██╔══██╗██╔════╝████╗  ██║"
  echo "        ██║   ██║██████╔╝█████╗  ██╔██╗ ██║"
  echo "        ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║"
  echo "        ╚██████╔╝██║     ███████╗██║ ╚████║"
  echo "         ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝"
  echo -e "${C_RESET}"
  echo -e "  ${C_BOLD}${C_WHITE}OpenClaw${C_RESET}${C_DIM} · Termux 机队管理工具箱${C_RESET}"
  echo -e "  ${C_DIM}${BOX_H}$(printf "${BOX_H}%.0s" $(seq 1 38))${C_RESET}"
  echo
}

# ═══ Fleet Status Bar ═══
fleet_status_bar() {
  local k60_status="$(ssh_device K60 'curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://127.0.0.1:18789/' 2>/dev/null || echo 'fail')"
  local n7_status="$(ssh_device Note7 'curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://127.0.0.1:18789/' 2>/dev/null || echo 'fail')"

  local k60_dot n7_dot
  [ "$k60_status" = "200" ] && k60_dot="${C_GREEN}●${C_RESET}" || k60_dot="${C_RED}●${C_RESET}"
  [ "$n7_status" = "200" ] && n7_dot="${C_GREEN}●${C_RESET}" || n7_dot="${C_RED}●${C_RESET}"

  echo -e "  ${C_DIM}$(date '+%Y-%m-%d %H:%M')${C_RESET}    ${k60_dot} K60  ${n7_dot} N7  ${C_DIM}|${C_RESET}  $(get_device_name 2>/dev/null || echo 'PC')"
}

# ═══ Menu Item ═══
menu_item() {
  local key="$1" icon="$2" title="$3" desc="$4"
  printf "  ${C_BOLD}${C_CYAN}%s${C_RESET}   %s ${C_BOLD}%-22s${C_RESET}${C_DIM}%s${C_RESET}\n" \
    "$key" "$icon" "$title" "$desc"
}
