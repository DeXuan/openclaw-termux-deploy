#!/data/data/com.termux/files/usr/bin/bash
# MIX 2S → 监控 K60 (Tailscale) · cron: */5 * * * * ~/healthcheck.sh
export TARGET="u0_a129@100.118.60.29" LABEL="K60" SLEEP=25 SSH_FAIL_ALERT=1
exec "$(dirname "$0")/healthcheck.sh"
