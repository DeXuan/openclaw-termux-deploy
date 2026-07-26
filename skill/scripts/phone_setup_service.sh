#!/data/data/com.termux/files/usr/bin/sh
# OpenClaw runit 服务 + Termux:Boot 启动脚本配置（手机 Termux 侧执行，幂等可重跑）
# 用法: cat phone_setup_service.sh | ssh -p 8022 user@<IP> 'sh -'
#
# ⚠️ 同步约定：本文件是 runit+boot 配置的 canonical 版本（scripts/ 目录）。
# 修改服务配置时请同步更新：
#   - install.sh                       (自包含 curl-pipe 入口，内联了 runit 逻辑)
#   - skill/scripts/phone_setup_service.sh (技能引用副本)
set -euo pipefail

# 坑10：Termux:Boot 环境 PATH 无 npm 全局目录，必须解析绝对路径
OPENCLAW_BIN=$(command -v openclaw)
[ -n "$OPENCLAW_BIN" ] || { echo "错误: openclaw 未安装，请先运行 phone_install_openclaw.sh"; exit 1; }
echo "==> openclaw 绝对路径: $OPENCLAW_BIN"

echo "==> [1/5] 解析 openclaw.mjs 路径 + 修复 shebang/env 陷阱（坑25）"
# 坑25：Android/Termux 没有 /usr/bin/env，npm 全局 bin symlink → .mjs 的
# shebang "#!/usr/bin/env node" 在内核 exec() 时找不到解释器 → "not found"

# 始终解析 OPENCLAW_MJS（后续步骤需要）
NPM_ROOT=$(npm root -g)
OPENCLAW_MJS="$NPM_ROOT/openclaw/openclaw.mjs"
if [ ! -f "$OPENCLAW_MJS" ]; then
  OPENCLAW_LINK=$(ls -l "$OPENCLAW_BIN" | awk -F' -> ' '{print $2}')
  OPENCLAW_DIR=$(dirname "$OPENCLAW_BIN")
  OPENCLAW_MJS="$OPENCLAW_DIR/$OPENCLAW_LINK"
fi
[ -f "$OPENCLAW_MJS" ] || { echo "错误: 无法定位 openclaw.mjs（$OPENCLAW_MJS）"; exit 1; }
echo "    openclaw.mjs = $OPENCLAW_MJS"

# 幂等：已修复为 bash wrapper 则跳过 shebang 修复
if [ ! -L "$OPENCLAW_BIN" ] && head -1 "$OPENCLAW_BIN" 2>/dev/null | grep -q "bash"; then
  echo "    openclaw 已是 bash wrapper，跳过 shebang 修复"
elif [ -L "$OPENCLAW_BIN" ]; then
  rm "$OPENCLAW_BIN"
  cat > "$OPENCLAW_BIN" <<WRAPPEREOF
#!/data/data/com.termux/files/usr/bin/bash
exec node $OPENCLAW_MJS "\$@"
WRAPPEREOF
  chmod +x "$OPENCLAW_BIN"
  echo "    openclaw symlink → bash wrapper（shebang 修复）"
fi

echo "==> [2/5] 创建 runit 服务"
# 幂等：服务目录已存在则跳过创建，但确保 run 脚本内容最新
if [ -d "$PREFIX/var/service/openclaw" ]; then
  echo "    runit 服务已存在，更新 run 脚本..."
else
  mkdir -p "$PREFIX/var/service/openclaw/log"
  ln -sf "$PREFIX/share/termux-services/svlogger" "$PREFIX/var/service/openclaw/log/run"
  echo "    runit 服务目录已创建"
fi
cat > "$PREFIX/var/service/openclaw/run" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
# 坑14：QQ 等平台 IP 白名单只支持 IPv4，强制 Node 优先走 IPv4 出口
export NODE_OPTIONS="--dns-result-order=ipv4first"
exec $PREFIX/bin/node $OPENCLAW_MJS gateway
EOF
chmod +x "$PREFIX/var/service/openclaw/run"

echo "==> [3/5] 创建 Termux:Boot 开机脚本（wake-lock + sshd + 服务群）"
# 幂等：boot 脚本已存在且内容正确则跳过
BOOT_EXPECTED='#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh'
if [ -f ~/.termux/boot/start-services.sh ] && \
   [ "$(cat ~/.termux/boot/start-services.sh 2>/dev/null)" = "$BOOT_EXPECTED" ]; then
  echo "    boot 脚本已存在且内容正确，跳过"
else
  mkdir -p ~/.termux/boot
  cat > ~/.termux/boot/start-services.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
EOF
  chmod +x ~/.termux/boot/start-services.sh
  echo "    boot 脚本已创建"
fi

echo "==> [4/5] 启动服务"
# 幂等：已运行则只确认状态，未运行才拉起
. "$PREFIX/etc/profile.d/start-services.sh"
export SVDIR="$PREFIX/var/service"
sv-enable openclaw 2>/dev/null || true
SV_STATUS=$(sv status openclaw 2>&1 | head -1)
if echo "$SV_STATUS" | grep -q "run:"; then
  echo "    服务已在运行: $SV_STATUS"
else
  sv up openclaw
  termux-wake-lock
  echo "    服务已启动"
fi

echo "==> [5/5] 等待 gateway 就绪并验证"
# 幂等：已就绪则不再等待 25s
HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://127.0.0.1:18789/ 2>/dev/null)
if [ "$HTTP" = "200" ]; then
  echo "    gateway 已就绪 (HTTP 200)"
else
  echo "    gateway 未就绪，等待启动..."
  sleep 25
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 http://127.0.0.1:18789/)
fi
sv status openclaw
echo "dashboard HTTP $HTTP"
[ "$HTTP" = "200" ] && echo "==> SERVICE_SETUP_DONE" || { echo "错误: gateway 未就绪，查看日志: $PREFIX/var/log/sv/openclaw/current"; exit 1; }
