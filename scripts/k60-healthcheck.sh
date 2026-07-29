#!/data/data/com.termux/files/usr/bin/bash
# K60 → 监控 Note 7 (Tailscale) · cron: */5 * * * * ~/healthcheck.sh
export TARGET="u0_a171@100.91.94.44" LABEL="Note7" SLEEP=20 SSH_FAIL_ALERT=1
exec "$(dirname "$0")/healthcheck.sh"
