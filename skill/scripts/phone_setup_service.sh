#!/data/data/com.termux/files/usr/bin/sh
# OpenClaw runit 服务 + Termux:Boot 启动脚本配置（手机 Termux 侧执行，幂等可重跑）
# 用法: cat phone_setup_service.sh | ssh -p 8022 user@<IP> 'sh -'
set -e

# 坑10：Termux:Boot 环境 PATH 无 npm 全局目录，必须解析绝对路径
OPENCLAW_BIN=$(command -v openclaw)
[ -n "$OPENCLAW_BIN" ] || { echo "ERROR: openclaw 未安装，先跑 phone_install_openclaw.sh"; exit 1; }
echo "==> openclaw 绝对路径: $OPENCLAW_BIN"

echo "==> [1/4] 创建 runit 服务"
mkdir -p "$PREFIX/var/service/openclaw/log"
cat > "$PREFIX/var/service/openclaw/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
# 坑14：QQ 等平台 IP 白名单只支持 IPv4，强制 Node 优先走 IPv4 出口
export NODE_OPTIONS="--dns-result-order=ipv4first"
exec $OPENCLAW_BIN gateway
EOF
chmod +x "$PREFIX/var/service/openclaw/run"
ln -sf "$PREFIX/share/termux-services/svlogger" "$PREFIX/var/service/openclaw/log/run"

echo "==> [2/4] 创建 Termux:Boot 开机脚本（wake-lock + sshd + 服务群）"
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-services.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
EOF
chmod +x ~/.termux/boot/start-services.sh

echo "==> [3/4] 启动服务"
. "$PREFIX/etc/profile.d/start-services.sh"
export SVDIR="$PREFIX/var/service"
sv-enable openclaw 2>/dev/null || true
sv up openclaw
termux-wake-lock

echo "==> [4/4] 等待 gateway 就绪并验证"
sleep 25
sv status openclaw
HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:18789/)
echo "dashboard HTTP $HTTP"
[ "$HTTP" = "200" ] && echo "==> SERVICE_SETUP_DONE" || { echo "ERROR: gateway 未就绪，查日志 $PREFIX/var/log/sv/openclaw/current"; exit 1; }
