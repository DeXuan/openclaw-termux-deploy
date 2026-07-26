#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot 启动脚本 — 手工参考模板
# ⚠️ 实际部署由 phone_setup_service.sh [3/5] 动态生成（内容相同，含 set -e）
set -e
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
