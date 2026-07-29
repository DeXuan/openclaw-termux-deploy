#!/usr/bin/env bash
#==============================================================================
# deploy-model-config.sh 测试套件
# 运行: bash tests/test_deploy_config.sh
#==============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

export HOME="$TMPDIR/home"
mkdir -p "$HOME/.openclaw" "$HOME/.hermes"
echo '{"plugins":{"entries":{},"allow":[]}}' > "$HOME/.openclaw/openclaw.json"

# Mock python3 — 用 PATH 优先而非 export -f（跨平台兼容）
cat > "$TMPDIR/python3" << 'PYEOF'
#!/bin/bash
echo "$*" >> "$HOME/py-log"
echo "OK"
PYEOF
chmod +x "$TMPDIR/python3"
export PATH="$TMPDIR:$PATH"

DEPLOY="$SCRIPT_DIR/../scripts/deploy-model-config.sh"

echo "=== deploy-model-config.sh 测试 ==="
echo ""

# 1. 无 API_KEY
OUT=$(unset API_KEY BAILIAN_API_KEY; bash "$DEPLOY" 2>&1) && RC=$? || RC=$?
assert_contains "无Key→ERROR" "$OUT" "ERROR"
test "无Key→exit 1" "1" "$RC"

# 2. 未知设备
OUT=$(API_KEY="sk-test" DEVICE="iPhone" bash "$DEPLOY" 2>&1) && RC=$? || RC=$?
assert_contains "未知设备→报错" "$OUT" "Unknown device"

# 3-6. 四台有效设备
for d in K60 MIX2S Note7 Note4X; do
  OUT=$(API_KEY="sk-test-123" DEVICE="$d" bash "$DEPLOY" 2>&1) && RC=$? || RC=$?
  test "$d→exit 0" "0" "$RC"
done

# 7. BAILIAN_API_KEY 后备
OUT=$(unset API_KEY; BAILIAN_API_KEY="sk-v2" DEVICE="K60" bash "$DEPLOY" 2>&1) && RC=$? || RC=$?
test "BAILIAN_API_KEY后备→exit 0" "0" "$RC"

# 8. Key 不泄露在输出
OUT=$(API_KEY="sk-SECRET-KEY-12345" DEVICE="K60" bash "$DEPLOY" 2>&1) && RC=$? || RC=$?
assert_contains "Key不泄露" "" "$(echo "$OUT" | grep "SECRET-KEY" || echo "")"

set +e; summary
