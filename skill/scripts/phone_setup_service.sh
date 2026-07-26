#!/data/data/com.termux/files/usr/bin/sh
# OpenClaw runit 服务 + Termux:Boot 启动脚本配置（手机 Termux 侧执行，幂等可重跑）
# 用法: cat phone_setup_service.sh | ssh -p 8022 user@<IP> 'sh -'
#
# ⚠️ 同步约定：本文件是 runit+boot 配置的 canonical 版本（scripts/ 目录）。
# 修改服务配置时请同步更新：
#   - install.sh                       (自包含 curl-pipe 入口，内联了 runit 逻辑)
#   - skill/scripts/phone_setup_service.sh (技能引用副本)
set -e

# 坑10：Termux:Boot 环境 PATH 无 npm 全局目录，必须解析绝对路径
OPENCLAW_BIN=$(command -v openclaw)
[ -n "$OPENCLAW_BIN" ] || { echo "ERROR: openclaw 未安装，先跑 phone_install_openclaw.sh"; exit 1; }
echo "==> openclaw 绝对路径: $OPENCLAW_BIN"

echo "==> [1/5] 解析 openclaw.mjs 路径 + 修复 shebang/env 陷阱（坑25）"
# 坑25：Android/Termux 没有 /usr/bin/env，npm 全局 bin symlink → .mjs 的
# shebang "#!/usr/bin/env node" 在内核 exec() 时找不到解释器 → "not found"
# （交互 shell 的 bash 会自行处理 shebang 所以 which/直接调都正常，极具迷惑性）
# 解法：① 用 npm root -g 定位 .mjs 真实路径，run 脚本直接调 node
#       ② 把 npm 的 symlink 替换为 bash wrapper，全局修复 openclaw 命令
NPM_ROOT=$(npm root -g)
OPENCLAW_MJS="$NPM_ROOT/openclaw/openclaw.mjs"
if [ ! -f "$OPENCLAW_MJS" ]; then
  # fallback：从 symlink 解析（兼容 npm 不同目录布局）
  OPENCLAW_LINK=$(ls -l "$OPENCLAW_BIN" | awk -F' -> ' '{print $2}')
  OPENCLAW_DIR=$(dirname "$OPENCLAW_BIN")
  OPENCLAW_MJS="$OPENCLAW_DIR/$OPENCLAW_LINK"
fi
[ -f "$OPENCLAW_MJS" ] || { echo "ERROR: 无法定位 openclaw.mjs（$OPENCLAW_MJS）"; exit 1; }
echo "    openclaw.mjs = $OPENCLAW_MJS"

# 替换 npm symlink → bash wrapper（根治 shebang 问题，MIX 2S 2026-07-20 已验证）
if [ -L "$OPENCLAW_BIN" ]; then
  rm "$OPENCLAW_BIN"
  cat > "$OPENCLAW_BIN" <<WRAPPEREOF
#!/data/data/com.termux/files/usr/bin/bash
exec node $OPENCLAW_MJS "\$@"
WRAPPEREOF
  chmod +x "$OPENCLAW_BIN"
  echo "    openclaw symlink → bash wrapper（shebang 修复）"
fi

echo "==> [2/5] 创建 runit 服务"
mkdir -p "$PREFIX/var/service/openclaw/log"
cat > "$PREFIX/var/service/openclaw/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
# 坑14：QQ 等平台 IP 白名单只支持 IPv4，强制 Node 优先走 IPv4 出口
export NODE_OPTIONS="--dns-result-order=ipv4first"
exec $PREFIX/bin/node $OPENCLAW_MJS gateway
EOF
chmod +x "$PREFIX/var/service/openclaw/run"
ln -sf "$PREFIX/share/termux-services/svlogger" "$PREFIX/var/service/openclaw/log/run"

echo "==> [3/5] 创建 Termux:Boot 开机脚本（wake-lock + sshd + 服务群）"
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-services.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
EOF
chmod +x ~/.termux/boot/start-services.sh

echo "==> [4/5] 启动服务"
. "$PREFIX/etc/profile.d/start-services.sh"
export SVDIR="$PREFIX/var/service"
sv-enable openclaw 2>/dev/null || true
sv up openclaw
termux-wake-lock

echo "==> [5/5] 等待 gateway 就绪并验证"
sleep 25
sv status openclaw
HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:18789/)
echo "dashboard HTTP $HTTP"
[ "$HTTP" = "200" ] && echo "==> SERVICE_SETUP_DONE" || { echo "ERROR: gateway 未就绪，查日志 $PREFIX/var/log/sv/openclaw/current"; exit 1; }
