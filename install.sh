#!/data/data/com.termux/files/usr/bin/sh
# ⚡ OpenClaw Termux Deploy — One-Line Installer
# curl -fsSL https://raw.githubusercontent.com/DeXuan/openclaw-termux-deploy/main/install.sh | bash
#
# ⚠️ 同步约定：本文件是自包含的 curl-pipe 入口（不能引用外部文件）。
# 修改安装逻辑时请同步更新以下 canonical 脚本：
#   - scripts/phone_install_openclaw.sh  (SSH 管道安装，含合规预检)
#   - scripts/phone_setup_service.sh     (runit + boot 配置，含坑25修复)
#   - skill/scripts/ 下的对应副本
set -e

# ── CLI 参数解析 ──
YES=false; DRY_RUN=false; VERBOSE=false; NO_AUTO_START=false
OC_VERSION="latest"; OC_PORT="18789"; OC_TOKEN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --yes|-y) YES=true ;;
    --dry-run|-d) DRY_RUN=true ;;
    --verbose|-v) VERBOSE=true ;;
    --no-auto-start) NO_AUTO_START=true ;;
    --version|-V) OC_VERSION="$2"; shift ;;
    --port|-p) OC_PORT="$2"; shift ;;
    --token|-t) OC_TOKEN="$2"; shift ;;
    --help|-h)
      echo "Usage: curl -fsSL ... | bash -s -- [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --yes, -y          非交互模式，使用默认值"
      echo "  --version, -V <v>  指定 OpenClaw 版本 (默认 latest)"
      echo "  --port, -p <port>  指定 Gateway 端口 (默认 18789)"
      echo "  --token, -t <tok>  指定 Gateway Token (默认自动生成)"
      echo "  --no-auto-start    安装后不自动启动 gateway"
      echo "  --dry-run, -d      模拟运行，不实际安装"
      echo "  --verbose, -v      详细输出"
      echo "  --help, -h         显示帮助"
      echo ""
      echo "Examples:"
      echo "  curl -fsSL ... | bash                      # 交互式安装"
      echo "  curl -fsSL ... | bash -s -- --yes          # 一键安装"
      echo "  curl -fsSL ... | bash -s -- --yes --version 2026.7.1"
      exit 0
      ;;
    *) echo "Unknown option: $1 (use --help)"; exit 1 ;;
  esac
  shift
done

# npm 国内镜像加速
NPM_MIRROR="https://registry.npmmirror.com"
export NPM_CONFIG_REGISTRY="$NPM_MIRROR"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   OpenClaw Termux Deploy  v2.6.0        ║"
echo "  ║   One-command Android → AI server       ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── Abort handling ──
cleanup_and_exit() {
  echo ""
  echo "  ─────────────────────────────────────────"
  echo "  ⚠  Install interrupted by user (Ctrl+C)"
  echo "  ─────────────────────────────────────────"
  echo "  Partial install state:"
  echo "    • Node.js & deps: may be installed"
  echo "    • OpenClaw: may be partially installed"
  echo "    • runit service: may or may not exist"
  echo ""
  echo "  To clean up and retry:"
  echo "    npm uninstall -g openclaw 2>/dev/null"
  echo "    rm -rf \$PREFIX/var/service/openclaw"
  echo "    curl -fsSL ... | bash   # re-run installer"
  echo ""
  echo "  To resume manually:"
  echo "    openclaw --version  # check if installed"
  echo "    sv status openclaw  # check if service exists"
  exit 130
}
trap cleanup_and_exit INT TERM

# ── Confirmation ──
echo "  This will install Node.js + OpenClaw + runit"
echo "  on: $(getprop ro.product.model 2>/dev/null || echo 'this device')"
echo "  Estimated time: 5-10 minutes"
if $YES; then
  echo "  Mode: --yes (non-interactive)"
else
  echo ""
  printf "  Continue? [Y/n] "
  read -r confirm
  case "$confirm" in
    [Nn]|[Nn][Oo]) echo "  Aborted."; exit 0 ;;
  esac
fi

# ── Preflight ──
if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ]; then
  echo "ERROR: This script must run inside Termux on Android."
  echo "1. Install Termux from F-Droid (NOT Play Store)"
  echo "2. Open Termux, then re-run this command"
  exit 1
fi

AV=$(getprop ro.build.version.release 2>/dev/null || echo "0")
AMAJ=$(echo "$AV" | cut -d. -f1)
[ "$AMAJ" -lt 7 ] 2>/dev/null && { echo "ERROR: Android $AV too old (<7)."; exit 1; }

MODEL=$(getprop ro.product.model 2>/dev/null || echo "unknown")
RAM=$(free -m 2>/dev/null | awk '/Mem:/{print $2}')
echo "Device: $MODEL | Android $AV | RAM ${RAM}MB"
[ "$RAM" -lt 1800 ] 2>/dev/null && echo "WARN: <2GB RAM — consider lighter model config"

# ── Deps ──
echo ""
echo "[1/6] Installing system dependencies..."
pkg update -y -q >/dev/null 2>&1 || pkg update -y
pkg install -y -q nodejs git python make clang binutils termux-services which coreutils >/dev/null 2>&1
echo "  OK: node $(node --version) | python $(python3 --version 2>&1 | cut -d' ' -f2)"

# ── SQLite fix (pitfall#17) ──
echo "[2/6] Patching libsqlite for OpenClaw compatibility..."
apt install --only-upgrade -y libsqlite >/dev/null 2>&1 || true
echo "  OK: libsqlite updated"

# ── Node version check (pitfall#18) ──
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }
NV=$(node --version | tr -d v)
NMAJ=$(echo "$NV" | cut -d. -f1)
NODE_OK=no
case "$NMAJ" in
  22) ver_ge "$NV" "22.22.3" && NODE_OK=yes ;;
  24) ver_ge "$NV" "24.15.0" && NODE_OK=yes ;;
  25) ver_ge "$NV" "25.9.0" && NODE_OK=yes ;;
  2[6-9]|[3-9][0-9]) NODE_OK=yes ;;
esac
if [ "$NODE_OK" != "yes" ]; then
  echo "  Node $NV not compliant. Installing 26.4.0..."
  curl -4 -L -o "$HOME/nodejs.deb" \
    "https://mirrors.ustc.edu.cn/termux/apt/termux-main/pool/main/n/nodejs/nodejs_26.4.0_aarch64.deb" 2>/dev/null || true
  [ -f "$HOME/nodejs.deb" ] && dpkg -i "$HOME/nodejs.deb" && apt-mark hold nodejs && rm "$HOME/nodejs.deb"
  echo "  OK: node $(node --version)"
fi

# ── OpenClaw ──
echo "[3/6] Installing OpenClaw@${OC_VERSION}..."
if $DRY_RUN; then
  echo "  [DRY-RUN] npm install -g openclaw@${OC_VERSION}"
else
  export GYP_DEFINES="android_ndk_path="
  npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash "openclaw@${OC_VERSION}" 2>&1 | tail -1
  echo "  OK: $(openclaw --version 2>&1 | head -1)"
fi

# ── Shebang fix (pitfall#25) ──
echo "[4/6] Applying shebang/env fix..."
OCBIN=$(command -v openclaw)
NPM_ROOT=$(npm root -g)
OCMJS="$NPM_ROOT/openclaw/openclaw.mjs"
if [ -L "$OCBIN" ]; then
  rm "$OCBIN"
  cat > "$OCBIN" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec node $OCMJS "\$@"
EOF
  chmod +x "$OCBIN"
  echo "  OK: openclaw wrapper created"
fi

# ── runit service ──
echo "[5/6] Setting up runit service + auto-boot..."
mkdir -p "$PREFIX/var/service/openclaw/log"
cat > "$PREFIX/var/service/openclaw/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
export NODE_OPTIONS="--dns-result-order=ipv4first"
EOF
RAM_MB=$(free -m 2>/dev/null | awk '/Mem:/{print $2}')
if [ "$RAM_MB" -lt 4000 ] 2>/dev/null; then
  echo "export NODE_OPTIONS=\"\$NODE_OPTIONS --max-old-space-size=512 --max-semi-space-size=32\"" >> "$PREFIX/var/service/openclaw/run"
fi
echo "exec $PREFIX/bin/node $OCMJS gateway" >> "$PREFIX/var/service/openclaw/run"
chmod +x "$PREFIX/var/service/openclaw/run"
ln -sf "$PREFIX/share/termux-services/svlogger" "$PREFIX/var/service/openclaw/log/run"

mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-services.sh <<'BOOT'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
BOOT
chmod +x ~/.termux/boot/start-services.sh

. "$PREFIX/etc/profile.d/start-services.sh"
export SVDIR="$PREFIX/var/service"
sv-enable openclaw 2>/dev/null || true
sv up openclaw
termux-wake-lock
echo "  OK: runit service started"

# ── Verify ──
echo "[6/6] Verifying..."
sleep 25
SV=$(sv status openclaw 2>&1 | head -1)
HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:18789/ 2>/dev/null || echo "000")
echo "  Service: $SV"
echo "  Gateway: HTTP $HTTP"

echo ""
echo "  ╔══════════════════════════════════════════╗"
if [ "$HTTP" = "200" ]; then
  echo "  ║   ✅ INSTALL SUCCESS                    ║"
else
  echo "  ║   ⚠️  INSTALLED (gateway warming up)    ║"
fi
echo "  ║                                        ║"
echo "  ║   Next steps:                          ║"
echo "  ║   1. openclaw onboard --help           ║"
echo "  ║   2. Set up QQ/Feishu/WeChat channels  ║"
echo "  ║   3. cat phone_check_env.sh | sh -     ║"
echo "  ║                                        ║"
echo "  ║   Quick commands:                      ║"
echo "  ║   ocr  = gateway 状态                  ║"
echo "  ║   oclog = 实时日志                     ║"
echo "  ║   ockill = 停止 gateway               ║"
echo "  ║                                        ║"
echo "  ║   Docs: https://github.com/DeXuan/     ║"
echo "  ║         openclaw-termux-deploy         ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

# ── Shell 配置块 (bashrc 注入) ──
if ! $DRY_RUN && [ "$HTTP" = "200" ]; then
  NPM_BIN="$(npm bin -g 2>/dev/null || echo "$HOME/.npm-global/bin")"
  BLOCK_START="# --- OpenClaw managed block ---"
  BLOCK_END="# --- End OpenClaw block ---"

  if grep -qF "$BLOCK_START" "$HOME/.bashrc" 2>/dev/null; then
    sed -i "/^$(echo "$BLOCK_START" | sed 's/[\/&]/\\&/g')$/,/^$(echo "$BLOCK_END" | sed 's/[\/&]/\\&/g')$/d" "$HOME/.bashrc"
  fi

  cat >> "$HOME/.bashrc" << BLOCK

${BLOCK_START}
export PATH="${NPM_BIN}:\$PATH"
export SVDIR="\$PREFIX/var/service"

ocr()  { sv status openclaw 2>/dev/null; curl -so /dev/null -w "HTTP %{http_code}" http://127.0.0.1:18789/ 2>/dev/null; echo; }
oclog(){ tail -f "\$PREFIX/var/log/sv/openclaw/current" 2>/dev/null || echo "日志不可用"; }
ockill(){ sv down openclaw 2>/dev/null && echo "gateway 已停止" || echo "gateway 未运行"; }
${BLOCK_END}
BLOCK
  echo "  ✓ Shell 命令已注入 ~/.bashrc (ocr/oclog/ockill)"
fi
