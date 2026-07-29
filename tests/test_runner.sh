#!/usr/bin/env bash
#==============================================================================
# 轻量级 Shell 测试框架
# 用法: source tests/test_runner.sh
#       test "描述" "期望" "实际"       # 断言
#       summary                          # 打印结果
#==============================================================================
set -euo pipefail

PASS=0; FAIL=0; TESTS=0
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; RESET='\033[0m'

test() {
  local desc="$1" expected="$2" actual="$3"
  TESTS=$((TESTS + 1))
  if [ "$expected" = "$actual" ]; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}✓${RESET} $desc"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}✗${RESET} $desc"
    echo -e "    ${YELLOW}expected:${RESET} '$expected'"
    echo -e "    ${YELLOW}  actual:${RESET} '$actual'"
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  TESTS=$((TESTS + 1))
  if echo "$haystack" | grep -qF "$needle"; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}✓${RESET} $desc"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}✗${RESET} $desc"
    echo -e "    ${YELLOW}expected to contain:${RESET} '$needle'"
  fi
}

assert_exit() {
  local desc="$1" expected_code="$2"
  shift 2
  local actual_code=0
  "$@" 2>/dev/null || actual_code=$?
  TESTS=$((TESTS + 1))
  if [ "$actual_code" = "$expected_code" ]; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}✓${RESET} $desc (exit $actual_code)"
  else
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}✗${RESET} $desc"
    echo -e "    ${YELLOW}expected exit:${RESET} $expected_code  ${YELLOW}actual:${RESET} $actual_code"
  fi
}

summary() {
  echo ""
  echo "──────────────────────────────────────"
  if [ "$FAIL" -eq 0 ]; then
    echo -e "  ${GREEN}全部通过: $PASS/$TESTS${RESET}"
  else
    echo -e "  ${RED}失败: $FAIL, 通过: $PASS, 总计: $TESTS${RESET}"
  fi
  echo "──────────────────────────────────────"
  return "$FAIL"
}
