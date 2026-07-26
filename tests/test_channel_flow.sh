#!/usr/bin/env bash
# channel-flow.sh 核心逻辑单元测试
# 使用模拟 JSONL 日志验证: 消息计数、未回复检测、延迟计算、模型错误检测
set -euo pipefail

PASS=0; FAIL=0
pass() { PASS=$((PASS+1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ✗ $1 (expected: $2, got: $3)"; }

# ── 准备测试数据 ──
TEST_LOG=$(mktemp -t cf-test-XXXX.log)
trap 'rm -f "$TEST_LOG"' EXIT

cat > "$TEST_LOG" << 'JSONL'
{"0":"{}","1":"[default] Processing message from USER_A: Hello world","_meta":{},"time":"2026-07-26T18:00:01.000+08:00","message":"[default] Processing message from USER_A: Hello world","traceId":"TRACE_A"}
{"0":"{}","1":"[model-fetch] start provider=deepseek model=deepseek-v4-flash","_meta":{},"time":"2026-07-26T18:00:02.000+08:00","message":"[model-fetch] start provider=deepseek model=deepseek-v4-flash","traceId":"TRACE_A"}
{"0":"{}","1":"[model-fetch] response provider=deepseek status=200 elapsedMs=350","_meta":{},"time":"2026-07-26T18:00:05.000+08:00","message":"[model-fetch] response provider=deepseek status=200 elapsedMs=350","traceId":"TRACE_A"}
{"0":"{}","1":"[default] onMessageSent called: refIdx=REFIDX_X","_meta":{},"time":"2026-07-26T18:00:06.000+08:00","message":"[default] onMessageSent called: refIdx=REFIDX_X","traceId":"TRACE_A"}
{"0":"{}","1":"[default] Processing message from USER_B: Help me","_meta":{},"time":"2026-07-26T18:01:00.000+08:00","message":"[default] Processing message from USER_B: Help me","traceId":"TRACE_B"}
{"0":"{}","1":"[model-fetch] response provider=deepseek status=500 elapsedMs=12000","_meta":{},"time":"2026-07-26T18:01:05.000+08:00","message":"[model-fetch] response provider=deepseek status=500 elapsedMs=12000","traceId":"TRACE_B"}
{"0":"{}","1":"[default] Processing message from USER_C: Status check","_meta":{},"time":"2026-07-26T18:02:00.000+08:00","message":"[default] Processing message from USER_C: Status check","traceId":"TRACE_C"}
{"0":"{}","1":"[model-fetch] response provider=deepseek status=403 elapsedMs=800","_meta":{},"time":"2026-07-26T18:02:03.000+08:00","message":"[model-fetch] response provider=deepseek status=403 elapsedMs=800","traceId":"TRACE_C"}
JSONL

# ═══ Test 1: 消息收发计数 ═══
echo "=== Test 1: 消息收发计数 ==="
QQ_RECEIVED=$(grep -c 'Processing message from' "$TEST_LOG" 2>/dev/null || echo 0)
QQ_RECEIVED="${QQ_RECEIVED//[^0-9]/}"
[ -z "$QQ_RECEIVED" ] && QQ_RECEIVED=0
QQ_SENT=$(grep -c 'onMessageSent called' "$TEST_LOG" 2>/dev/null || echo 0)
QQ_SENT="${QQ_SENT//[^0-9]/}"
[ "$QQ_RECEIVED" = "3" ] && pass "收到 3 条消息" || fail "收到消息数" "3" "$QQ_RECEIVED"
[ "$QQ_SENT" = "1" ] && pass "回复 1 条消息" || fail "回复数" "1" "$QQ_SENT"

# ═══ Test 2: 未回复检测 ═══
echo "=== Test 2: 未回复检测 ==="
UNREPLIED=0
while IFS= read -r trace_id; do
  [ -z "$trace_id" ] && continue
  if ! grep -q "onMessageSent.*$trace_id" "$TEST_LOG" 2>/dev/null; then
    UNREPLIED=$((UNREPLIED + 1))
  fi
done < <(grep 'Processing message from' "$TEST_LOG" 2>/dev/null | grep -oP '"traceId":"\K[^"]+' | sort -u)
[ "$UNREPLIED" = "2" ] && pass "未回复 2 条 (TRACE_B + TRACE_C)" || fail "未回复数" "2" "$UNREPLIED"

# ═══ Test 3: 响应延迟计算 ═══
echo "=== Test 3: 响应延迟 ==="
LATENCY_SUM=0; LATENCY_COUNT=0
while IFS= read -r elapsed; do
  LATENCY_SUM=$((LATENCY_SUM + elapsed))
  LATENCY_COUNT=$((LATENCY_COUNT + 1))
done < <(grep -oP '"message":"[^"]*elapsedMs=\K\d+' "$TEST_LOG" 2>/dev/null || true)
AVG_LATENCY="N/A"
[ "$LATENCY_COUNT" -gt 0 ] && AVG_LATENCY=$((LATENCY_SUM / LATENCY_COUNT))
[ "$LATENCY_COUNT" = "3" ] && pass "3 次模型请求" || fail "延迟采样数" "3" "$LATENCY_COUNT"
[ "$AVG_LATENCY" = "4383" ] && pass "均延 4383ms (350+12000+800)/3" || fail "均延" "4383" "$AVG_LATENCY"

# ═══ Test 4: 模型请求统计 ═══
echo "=== Test 4: 模型请求统计 ==="
MODEL_STARTS=$(grep -c '"message":"[^"]*\[model-fetch\] start' "$TEST_LOG" 2>/dev/null || echo 0)
MODEL_STARTS="${MODEL_STARTS//[^0-9]/}"
MODEL_ERRORS=$(grep -c '"message":"[^"]*\[model-fetch\].*status=[^2]' "$TEST_LOG" 2>/dev/null || echo 0)
MODEL_ERRORS="${MODEL_ERRORS//[^0-9]/}"
[ "$MODEL_STARTS" = "1" ] && pass "1 次模型 start 事件" || fail "模型start" "1" "$MODEL_STARTS"
[ "$MODEL_ERRORS" = "2" ] && pass "2 次模型错误 (500+403)" || fail "模型错误" "2" "$MODEL_ERRORS"

# ═══ Test 5: safe_count 模拟 (from channel-health.sh) ═══
echo "=== Test 5: safe_count 数字净化 ==="
safe_count() { local n; n=$(grep -c "$1" "$2" 2>/dev/null) || n=0; echo "${n//[^0-9]/}"; }
SC=$(safe_count "Processing message" "$TEST_LOG")
[ "$SC" = "3" ] && pass "safe_count 返回 3" || fail "safe_count" "3" "$SC"
SC_GARBAGE=$(safe_count "NO_MATCH" "$TEST_LOG")
[ "$SC_GARBAGE" = "0" ] && pass "safe_count 无匹配返回 0" || fail "safe_count(无匹配)" "0" "$SC_GARBAGE"

# ═══ Results ═══
echo ""
echo "── 结果 ──"
echo "  通过: $PASS  失败: $FAIL"
[ "$FAIL" -eq 0 ] && echo "  ✅ ALL TESTS PASSED" || echo "  ❌ $FAIL TESTS FAILED"
exit $FAIL
