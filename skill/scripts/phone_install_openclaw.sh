#!/data/data/com.termux/files/usr/bin/sh
# Canonical: scripts/phone_install_openclaw.sh — sync from there
# OpenClaw 安装脚本（手机 Termux 侧执行，幂等可重跑）
# 用法: cat phone_install_openclaw.sh | ssh -p 8022 user@<IP> 'sh -'
set -e

echo "==> [1/5] 安装基础依赖与编译工具链"
pkg update -y >/dev/null 2>&1 || pkg update -y
pkg install -y nodejs git python make clang binutils termux-services

echo "==> [2/5] 环境合规预检（坑 17/18：OpenClaw 2026.7.1-x 双重启动检查）"
# libsqlite ≥3.51.3（坑 17）——node 动态链接系统包，直接升到位
apt install --only-upgrade -y libsqlite >/dev/null 2>&1 || true
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]; }
SQV=$(node -e 'const s=require("node:sqlite");console.log(new s.DatabaseSync(":memory:").prepare("select sqlite_version() v").get().v)' 2>/dev/null || echo 0)
ver_ge "$SQV" "3.51.3" && echo "    libsqlite $SQV OK" || { echo "!! libsqlite $SQV <3.51.3 且升级失败（坑 17），检查 apt 源后重跑"; exit 1; }
# node 版本号（坑 18）：>=22.22.3<23 / >=24.15.0<25 / >=25.9.0
NV=$(node --version | tr -d v); NMAJ=$(echo "$NV" | cut -d. -f1); NODE_OK=no
case "$NMAJ" in
  22) ver_ge "$NV" "22.22.3" && NODE_OK=yes ;;
  24) ver_ge "$NV" "24.15.0" && NODE_OK=yes ;;
  25) ver_ge "$NV" "25.9.0" && NODE_OK=yes ;;
  2[6-9]|[3-9][0-9]) NODE_OK=yes ;;
esac
if [ "$NODE_OK" = yes ]; then echo "    node $NV OK"; else
  echo "!! node $NV 不合规（坑 18）。仓库无合规版时手动装 26.4.0（Termux 无 /tmp，写 \$HOME！坑 21）："
  echo "   curl -4 -L -o \$HOME/nodejs.deb https://mirrors.ustc.edu.cn/termux/apt/termux-main/pool/main/n/nodejs/nodejs_26.4.0_aarch64.deb"
  echo "   （或从仓库 Release v2.3-packages 下载）然后: dpkg -i \$HOME/nodejs.deb && apt-mark hold nodejs，再重跑本脚本"
  exit 1
fi

echo "==> [3/5] 安装 OpenClaw（含坑2 NDK 变量 / 坑3 allow-scripts 修复）"
export GYP_DEFINES="android_ndk_path="
npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest

echo "==> [4/5] 验证版本"
openclaw --version

echo "==> [5/5] 验证网络接口检测（原生 Termux 应正常，无需 Bionic 补丁）"
node -e "console.log('netif:', Object.keys(require('os').networkInterfaces()).join(','))"

echo "==> INSTALL_DONE"
