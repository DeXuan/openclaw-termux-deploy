#!/data/data/com.termux/files/usr/bin/sh
# OpenClaw 安装脚本（手机 Termux 侧执行，幂等可重跑）
# 用法: cat phone_install_openclaw.sh | ssh -p 8022 user@<IP> 'sh -'
set -e

echo "==> [1/4] 安装基础依赖与编译工具链"
pkg update -y >/dev/null 2>&1 || pkg update -y
pkg install -y nodejs git python make clang binutils termux-services

echo "==> [2/4] 安装 OpenClaw（含坑2 NDK 变量 / 坑3 allow-scripts 修复）"
export GYP_DEFINES="android_ndk_path="
npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest

echo "==> [3/4] 验证版本"
openclaw --version

echo "==> [4/4] 验证网络接口检测（原生 Termux 应正常，无需 Bionic 补丁）"
node -e "console.log('netif:', Object.keys(require('os').networkInterfaces()).join(','))"

echo "==> INSTALL_DONE"
