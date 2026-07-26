#!/usr/bin/env bash
# Pre-push 本地验证 (手动运行或作为 git hook)
# 用法: bash scripts/pre-push-check.sh        # 手动检查
#       bash scripts/pre-push-check.sh --install  # 安装为 git hook
set -euo pipefail

if [ "${1:-}" = "--install" ]; then
  HOOK=".git/hooks/pre-push"
  cp "$0" "$HOOK"
  chmod +x "$HOOK"
  echo "✓ pre-push hook 已安装: $HOOK"
  echo "  以后每次 git push 前自动运行检查"
  exit 0
fi

echo ""
echo -e "\033[1;36m═══ Pre-push 验证 ═══\033[0m"
FAIL=0

# ── 1. bash -n 语法检查 ──
echo -e "\033[1;33m[1/3] bash -n 语法检查\033[0m"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  bash -n "$f" 2>&1 || { echo -e "  \033[31mFAIL: $f\033[0m"; FAIL=1; }
done < <(find . -name "*.sh" -not -path "./.git/*" -not -path "./.claude/*" -not -path "./bailian-quota-switcher/*")
bash -n openclaw-deploy 2>&1 || { echo -e "  \033[31mFAIL: openclaw-deploy\033[0m"; FAIL=1; }
[ $FAIL -eq 0 ] && echo "  ✓ 全部通过" || { echo -e "\033[31m  ✗ 语法错误\033[0m"; exit 1; }

# ── 2. ShellCheck ──
# Windows winget 安装后 PATH 可能未刷新
SHELLCHECK=$(command -v shellcheck 2>/dev/null || echo "")
[ -z "$SHELLCHECK" ] && [ -x "/c/Users/gdx/AppData/Local/Microsoft/WinGet/Links/shellcheck.exe" ] && SHELLCHECK="/c/Users/gdx/AppData/Local/Microsoft/WinGet/Links/shellcheck.exe"

if [ -n "$SHELLCHECK" ] && [ -x "$SHELLCHECK" ]; then
  echo -e "\033[1;33m[2/3] ShellCheck\033[0m"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    # 从 git 读取 (LF 版本)，避免本地 CRLF 误报；新文件用 cat
    if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
      src=$(git show ":$f" 2>/dev/null)
    else
      src=$(cat "$f" 2>/dev/null)
    fi
    result=$(echo "$src" | "$SHELLCHECK" --severity=warning - 2>&1) || {
      echo "$result" | tail -3
      echo -e "\033[31m  ✗ $f\033[0m"
      FAIL=1
    }
  done < <(find scripts/ tests/ -name "*.sh" 2>/dev/null)
  [ $FAIL -eq 0 ] && echo "  ✓ 全部通过" || exit 1
else
  echo -e "\033[1;33m[2/3] ShellCheck\033[0m — 未安装 (winget install shellcheck / pkg install shellcheck)"
fi

# ── 3. skill/scripts/ 同步 ──
echo -e "\033[1;33m[3/3] skill/scripts/ 同步\033[0m"
for f in phone_check_env.sh phone_install_openclaw.sh phone_setup_service.sh; do
  if ! diff -q "scripts/$f" "skill/scripts/$f" >/dev/null 2>&1; then
    echo -e "  \033[31m✗ scripts/$f ≠ skill/scripts/$f — 请同步!\033[0m"
    FAIL=1
  fi
done
[ $FAIL -eq 0 ] && echo "  ✓ 全部同步" || { echo -e "\033[31m  ✗ 副本不同步\033[0m"; exit 1; }

echo ""
echo -e "\033[1;32m═══ 验证通过 ✅\033[0m"
echo ""
exit 0
