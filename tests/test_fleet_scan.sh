#!/usr/bin/env bash
#==============================================================================
# fleet_scan.sh 测试套件
# 覆盖: 9维度输出完整性、关键指标存在、退出码
# 运行: bash tests/test_fleet_scan.sh
#==============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Mock Termux 环境
export PREFIX="$TMPDIR/termux"
export HOME="$TMPDIR/home"
export SVDIR="$PREFIX/var/service"
mkdir -p "$PREFIX/var/service" "$PREFIX/var/log/sv/openclaw" "$PREFIX/var/log/sv/hermes-gateway"
mkdir -p "$HOME/.openclaw/npm/projects/openclaw-qqbot-d3553f72f8"
mkdir -p "$HOME/.openclaw/npm/projects/tencent-weixin-openclaw-weixin-7783ac86ba"

# Mock 二进制
mkdir -p "$PREFIX/bin"
cat > "$PREFIX/bin/node" << 'NODEEOF'
#!/bin/bash
case "$*" in
  *sqlite_version*) echo '{"v":"3.53.4"}' ;;
  *openclaw.json*files*enabled*) echo "enabled" ;;
  *openclaw.json*plugins.allow*) echo '["feishu","qqbot"]' ;;
  *memory-tdai*enabled*) echo "enabled" ;;
  *alibaba*) echo "15" ;;
  *openclaw.json*agents*main*model*|*openclaw.json*agents*defaults*model*) echo '"CLEAN"' ;;
  *) echo '{"v":"mock"}' ;;
esac
NODEEOF
chmod +x "$PREFIX/bin/node"

cat > "$PREFIX/bin/openclaw" << 'OCEOF'
#!/bin/bash
[[ "$*" == *"--version"* ]] && echo "OpenClaw 2026.7.1-2 (0790d9f)" || echo "mock"
OCEOF
chmod +x "$PREFIX/bin/openclaw"

cat > "$PREFIX/bin/hermes" << 'HMEOF'
#!/bin/bash
echo "Hermes Agent v0.19.0 (2026.7.20)"
HMEOF
chmod +x "$PREFIX/bin/hermes"

cat > "$PREFIX/bin/python3" << 'PYEOF'
#!/bin/bash
echo "Python 3.14.6"
PYEOF
chmod +x "$PREFIX/bin/python3"

# Mock 系统工具
cat > "$PREFIX/bin/termux-info" << 'TIEOF'
#!/bin/bash
echo "TERMUX_VERSION=0.118.0"
TIEOF
chmod +x "$PREFIX/bin/termux-info"

cat > "$PREFIX/bin/termux-battery-status" << 'TBEOF'
#!/bin/bash
echo '{"percentage":85}'
TBEOF
chmod +x "$PREFIX/bin/termux-battery-status"

cat > "$PREFIX/bin/getprop" << 'GPEOF'
#!/bin/bash
case "$*" in
  *marketname*) echo "Redmi K60" ;;
  *version.release*) echo "15" ;;
  *cpu*) echo "8" ;;
  *) echo "mock" ;;
esac
GPEOF
chmod +x "$PREFIX/bin/getprop"

# Mock 日志
OC_LOG="$PREFIX/var/log/sv/openclaw/current"
cat > "$OC_LOG" << 'LOGEOF'
2026-07-29T21:37:00 [qqbot] WebSocket connected
2026-07-29T21:37:01 [feishu] WebSocket client started
2026-07-29T21:38:00 [qqbot] 401 Unauthorized
2026-07-29T21:38:05 [qqbot] WebSocket connected (resumed)
2026-07-29T21:50:00 403 quota exhausted
LOGEOF

HM_LOG="$PREFIX/var/log/sv/hermes-gateway/current"
cat > "$HM_LOG" << 'HMLOG'
2026-07-29T21:37:00 Lark connected to wss://msg-frontier.feishu.cn
2026-07-29T21:37:05 error: timeout
HMLOG

# Mock Hermes config
mkdir -p "$HOME/.hermes/logs"
cat > "$HOME/.hermes/config.yaml" << 'CFGEOF'
model:
  name: kimi-k2-thinking
  provider: openai-api
CFGEOF
echo "2026-07-29T21:45:00 Watchdog OK" > "$HOME/.hermes/logs/oc-model-watchdog.log"

# Mock openclaw.json
cat > "$HOME/.openclaw/openclaw.json" << 'JSONEOF'
{"plugins":{"entries":{"memory-tencentdb":{"enabled":true},"feishu":{},"qqbot":{}},"allow":["feishu","qqbot","memory-tencentdb"]},"agents":{"main":{}}}
JSONEOF

# Mock memory data
mkdir -p "$HOME/.openclaw/memory-tdai/conversations" "$HOME/.openclaw/memory-tdai/records"
echo '{"test":"data"}' > "$HOME/.openclaw/memory-tdai/conversations/conv1.jsonl"
echo '{"fact":"test"}' > "$HOME/.openclaw/memory-tdai/records/rec1.jsonl"
dd if=/dev/zero of="$HOME/.openclaw/memory-tdai/vectors.db" bs=1024 count=2000 2>/dev/null

export PATH="$PREFIX/bin:$PATH"

# ═══ 运行扫描 ═══
SCAN_OUTPUT=$(bash "$SCRIPT_DIR/../scripts/fleet_scan.sh" 2>/dev/null) || true

# ═══ 测试用例 ═══

echo "=== fleet_scan.sh 测试 ==="
echo ""

# ── 维度 1: 硬件 ──
assert_contains "1.硬件-标题"     "$SCAN_OUTPUT" "1. 硬件"
assert_contains "1.硬件-温度"     "$SCAN_OUTPUT" "C"
assert_contains "1.硬件-运行时间" "$SCAN_OUTPUT" "运行时间"

# ── 维度 2: 版本 ──
assert_contains "2.版本-标题"     "$SCAN_OUTPUT" "2. 版本"
assert_contains "2.版本-Termux"   "$SCAN_OUTPUT" "0.118.0"
assert_contains "2.版本-OpenClaw" "$SCAN_OUTPUT" "2026.7.1-2"
assert_contains "2.版本-Hermes"   "$SCAN_OUTPUT" "v0.19.0"
assert_contains "2.版本-libsqlite" "$SCAN_OUTPUT" "3.53.4"
assert_contains "2.版本-记忆插件"  "$SCAN_OUTPUT" "记忆插件"

# ── 维度 3: 资源 ──
assert_contains "3.资源-标题"  "$SCAN_OUTPUT" "3. 资源"
assert_contains "3.资源-内存"  "$SCAN_OUTPUT" "内存"
assert_contains "3.资源-Swap"  "$SCAN_OUTPUT" "Swap"
assert_contains "3.资源-磁盘"  "$SCAN_OUTPUT" "磁盘"

# ── 维度 4: 服务 ──
assert_contains "4.服务-openclaw" "$SCAN_OUTPUT" "openclaw"

# ── 维度 5: 渠道(OC) ──
assert_contains "5.渠道-QQ"     "$SCAN_OUTPUT" "QQ:"
assert_contains "5.渠道-401异常" "$SCAN_OUTPUT" "401×"

# ── 维度 6: 渠道(Hermes) ──
assert_contains "6.渠道-Hermes"  "$SCAN_OUTPUT" "6. 渠道 (Hermes)"

# ── 维度 7: 模型链 ──
assert_contains "7.模型-标题"   "$SCAN_OUTPUT" "7. 模型链"
assert_contains "7.模型-override" "$SCAN_OUTPUT" "agent override"

# ── 维度 8: 记忆 ──
assert_contains "8.记忆-标题"   "$SCAN_OUTPUT" "8. 记忆"

# ── 维度 9: 异常 ──
assert_contains "9.异常-标题"   "$SCAN_OUTPUT" "9. 近30分钟异常"

# ── 完整结构 ──
assert_contains "开始标记" "$SCAN_OUTPUT" "机队全面体检"
assert_contains "结束标记" "$SCAN_OUTPUT" "体检完成"

# ── 退出码 ──
bash "$SCRIPT_DIR/../scripts/fleet_scan.sh" > /dev/null 2>&1
test "退出码0" "0" "$?"

summary
