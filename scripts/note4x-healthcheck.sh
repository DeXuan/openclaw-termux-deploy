#!/data/data/com.termux/files/usr/bin/bash
# Note 4X → 监控 K60 (LAN only) · cron: */5 * * * * ~/healthcheck.sh
# Note 4X 无 Tailscale，SSH 不通不告警（K60 可能出门了）
export TARGET="u0_a129@192.168.1.23" LABEL="K60" SLEEP=30 SSH_FAIL_ALERT=0
exec "$(dirname "$0")/healthcheck.sh"
