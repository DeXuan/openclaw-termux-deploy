#!/data/data/com.termux/files/usr/bin/sh
set -e
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
