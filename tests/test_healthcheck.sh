#!/usr/bin/env bash
# healthcheck.sh 测试 — 自愈引擎核心逻辑
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test_runner.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

export LOG="$TMPDIR/hc.log"
export STAMP="$TMPDIR/last_restart"
export TARGET="test@127.0.0.1" PORT="8022" LABEL="TestDevice"
export SLEEP=0 MAX_RETRY=2 COOLDOWN=600 SSH_FAIL_ALERT=1

MOCK_HTTP="200"; MOCK_SSH_FAIL=0; MOCK_RESTART_OK=1; RESTART_WAS_CALLED=0

mock_ssh() {
  [ "$MOCK_SSH_FAIL" = "1" ] && return 255
  local last="${*: -1}"
  if echo "$last" | grep -q "sv restart"; then
    RESTART_WAS_CALLED=1; MOCK_HTTP="200"
    [ "$MOCK_RESTART_OK" = "1" ] && return 0 || return 1
  fi
  if echo "$last" | grep -q "curl.*18789"; then echo "$MOCK_HTTP"; return 0; fi
  return 0
}
ssh()      { mock_ssh "$@"; }
curl()     { echo "$MOCK_HTTP"; }
openclaw() { echo "alert" >> "$TMPDIR/alert.log"; }
timeout()  { shift 2>/dev/null; "$@" 2>/dev/null || return 124; }
date()     { command date "$@"; }

reset_mock() {
  MOCK_HTTP="200"; MOCK_SSH_FAIL=0; MOCK_RESTART_OK=1; RESTART_WAS_CALLED=0
  rm -f "$LOG" "$STAMP" "$TMPDIR/alert.log"
}

# 内联被测逻辑
hc() {
  local HTTP
  HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
    "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"
  [ "$HTTP" = "200" ] && return 0
  if [ "$HTTP" = "ssh_fail" ]; then
    [ "$SSH_FAIL_ALERT" = "1" ] && return 1 || return 0
  fi
  local NOW; NOW=$(date +%s)
  if [ -f "$STAMP" ]; then
    local LAST; LAST=$(cat "$STAMP")
    [ $((NOW - LAST)) -lt "$COOLDOWN" ] && return 0
  fi
  local i
  for ((i=1; i<=MAX_RETRY; i++)); do
    ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" "sv restart openclaw" 2>/dev/null || break
    echo "$NOW" > "$STAMP"
    sleep "$SLEEP"
    HTTP=$(ssh -p "$PORT" -o ConnectTimeout=5 -o BatchMode=yes "$TARGET" \
      "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 3 http://127.0.0.1:18789/" 2>/dev/null) || HTTP="ssh_fail"
    [ "$HTTP" = "200" ] && return 0
  done
  return 1
}

echo "=== healthcheck.sh 测试 ==="
echo ""
set +e  # 测试期间关闭 errexit，测试断言自行处理

# 1
reset_mock; MOCK_HTTP="200"; hc; RC=$?; test "200健康→退出0" "0" "$RC"

# 2
reset_mock; MOCK_HTTP="503"; hc; RC=$?; test "503→自愈恢复→退出0" "0" "$RC"
test "  重启被调用" "1" "$RESTART_WAS_CALLED"

# 3
reset_mock; MOCK_SSH_FAIL=1; SSH_FAIL_ALERT=1; hc; RC=$?; test "SSH不通+告警→退出1" "1" "$RC"

# 4
reset_mock; MOCK_SSH_FAIL=1; SSH_FAIL_ALERT=0; hc; RC=$?; test "SSH不通+静默→退出0" "0" "$RC"

# 5
reset_mock; MOCK_HTTP="503"; date +%s > "$STAMP"; hc; RC=$?; test "冷却期→跳过→退出0" "0" "$RC"

# 6
reset_mock; MOCK_HTTP="503"; MOCK_RESTART_OK=0; hc; RC=$?; test "重启2次均失败→退出1" "1" "$RC"

# 7
reset_mock; MOCK_HTTP="200"; hc; RC=$?; test "恢复后正常→退出0" "0" "$RC"

set +e; summary
