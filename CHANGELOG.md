# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.6.0] — 2026-07-26

### Added (P3–P4 工具箱扩展)
- 🗑️ `scripts/uninstall.sh` — 6-step uninstall: stop→crontab→scripts→boot→npm→config, `--dry-run` / `--keep-config`
- 📡 `scripts/channel-health.sh` — grep-based channel monitor (QQ/Feishu/WeChat), `safe_count()` sanitizer, per-channel alert thresholds
- 🚀 `scripts/rolling-upgrade.sh` — canary deployment: preflight→canary(Note7)→sequential→summary, `--dry-run`
- 💾 `scripts/backup-configs.sh` — fleet-wide config backup to K60 (tar.gz, 30-day retention)
- 🛡️ `scripts/self-check.sh` — memory/disk/swap threshold protection + auto-cleanup + gateway restart
- 🔍 `scripts/check-ip.sh` — IPv4 egress drift detection → Feishu alert
- 📦 `scripts/check-version.sh` — weekly npm scan for new OpenClaw versions
- 🧪 `tests/test_feishu_push.py` — 8 unit tests for unified push module
- 🔄 `.github/workflows/smoke-test.yml` — CI: bash -n + py_compile + 6-part consistency check

### Changed (P3–P4)
- `lib/menus.sh`: 4-device dashboard with parallel SSH probes, full-fleet check/update/self-heal menus
- `openclaw-deploy`: `--all` flag for service/logs/check commands, fixed `local` variable bugs
- `scripts/phone_check_env.sh`: hardcoded `/data/data/…/tmp` → `$PREFIX/tmp`, date pattern year-agnostic
- 4 healthcheck scripts: `--connect-timeout 3` on all curl calls, IP source-of-truth comments
- `scripts/phone_setup_service.sh`: idempotency for all 5 steps, OPENCLAW_MJS resolved before check
- `scripts/backup-configs.sh`: fixed `cp ~/ $f` → `cp ~/"$f"` space bug
- `scripts/rolling-upgrade.sh`: TARGET_VERSION moved after arg parsing, `/tmp` → `$HOME`
- `scripts/channel-health.sh`: `date -d` → `tail -500` for Termux compatibility
- Pitfall count: 24 → 25 (`skill/SKILL.md`, `skill/references/device-matrix.md`, `skill/references/pitfalls.md`)

### Added (P0–P2 本轮优化)
- `finance/` directory: fund-monitor, fund-weekly, trade-signal-scanner separated from deploy toolbox
- `finance/README.md`: standalone documentation for financial scripts
- `config/` and `finance/` added to project structure docs

### Changed (P0–P2)
- **Error handling upgraded**: `phone_install_openclaw.sh`, `phone_setup_service.sh`, `uninstall.sh` → `set -euo pipefail` + trap
- **bailian-quota-switcher hardened**: `quota_watcher.sh`, `quota_manager.sh`, `deploy.sh` → `set -euo pipefail` + PREFIX guards
- **bailian phone_check_env.sh**: path/date pattern synced with canonical version
- `quota_watcher.sh`: removed duplicate startup echo line
- `channel-health.sh`: trap INT TERM EXIT for temp file cleanup
- `install.sh`: version banner `v1.0.0` → `v2.6.0`
- `scripts/README.md`: added `uninstall.sh`, `channel-health.sh`, `rolling-upgrade.sh`
- `fund-*.py` / `trade-signal-scanner.py`: HTTP → HTTPS for all API calls
- skill/scripts/ copies: synced with canonical scripts/ (set -euo pipefail consistency)

### Fixed
- Deprecated `deepseek-chat`/`deepseek-reasoner` model references → `deepseek-v4-flash`/`v4-pro`

### Added
- ⚡ One-line installer: `curl -fsSL ... | bash` with 6-step auto-deploy
- 📖 Bilingual README (English + 中文) with quick language toggle
- 🏷️ GitHub Topics: ai, android, termux, self-hosted, homelab, low-power, etc.
- 📋 Issue templates (bug report + feature request) with structured forms
- 🔀 Pull request template with device testing checklist
- 🤝 Contributor Covenant Code of Conduct
- 🔒 Security policy with vulnerability reporting process
- 📦 Dependabot configuration for GitHub Actions and npm
- 🚀 GitHub Release v1.0.0
- 📊 Fund NAV monitor: daily report (15:30) + weekly report (Fri 22:00)
- 📉 Fund signal alerts: daily move >3%, 3-day trend, break-even approaching
- 📡 Fleet dashboard: daily Feishu push at 08:57 (K60 primary + MIX2S backup)
- 🚨 IP change alert: instant Feishu notification when broadband IP drifts
- 🩺 Healthcheck alert: Feishu API direct push instead of openclaw agent
- 🔍 Version update checker: weekly npm scan → Feishu alert
- 💾 Config backup: weekly pull from all 4 devices to K60
- 🩺 Self-healing coverage: all 4 devices (MIX 2S → K60 Tailscale, Note 4X → K60 LAN)
- 📊 Dashboard now shows real-time data for all 4 devices (was K60 + Note7 only)
- 🔍 Check menu supports individual and full-fleet health checks for all 4 devices

### Fixed
- 🐛 Pitfall #25: shebang `/usr/bin/env` trap on Android/Termux
- 🔴 ShellCheck CI badge — changed from red (failing) to green (passing)
- 🟡 Fund report format — compact mobile-friendly layout with QDII separation
- 🔵 Note 4X model — primary switched from GLM-5.2 to qwen-portal/coder-model
- 🔢 Version number unified: install.sh, openclaw-deploy, CHANGELOG all v1.0.0

### Changed
- README totally rewritten: badges, comparison table, fleet dashboard preview
- GUIDE.md updated with troubleshooting FAQ for pitfall #25
- phone_check_env.sh: added channel probe (QQ/Feishu) + pitfall #25 detection
- MIX 2S crontab intervals tightened: 15/30 → 5/10 minutes
- Dashboard menu: parallel probe all 4 devices (was sequential K60+Note7 only)
- Self-healing menu: supports all 4 devices for install/status/logs
- bailian-quota-switcher phone_check_env.sh synced to canonical version

### Added (P2 — 2026-07-26)
- 🚀 `scripts/feishu_push.py` — unified Feishu push module (stdin / `-m` / `-t`), replaces 4 duplicate implementations
- 📖 `scripts/README.md` — script index grouped by scenario (deploy/heal/monitor/finance)
- 🎯 CLI `--all` flag for `service` and `logs` commands — batch operate all 4 devices
- 📋 `config/fleet-devices.conf.example` — centralized IP config template
- 📁 `scripts/phone_setup_service.sh` — canonical copy in scripts/ directory

### Changed (P2)
- `fleet-dashboard.sh`: Feishu push uses unified module; IPs from config file
- `check-ip.sh`: Feishu push uses unified module (was inline curl+python3)
- `check-version.sh`: Feishu push uses unified module (was inline curl+python3)
- `trade-signal-scanner.py`: Feishu push uses unified module (was inline subprocess with os.environ hacks)
- `backup-configs.sh`: IPs from `~/.fleet-devices.conf` with fallback
- All healthcheck scripts: IP source-of-truth comments added
- Install scripts: cross-reference comments for sync discipline

---

## [0.9.0] — 2026-07-23

### Added
- 🧰 Color TUI toolbox (`openclaw-deploy`) with 10 interactive functions
- 🚀 6-step deployment wizard for new devices
- 📊 Fleet dashboard with real-time status cards
- 🔍 Device health check: one-command diagnostic (PASS/FAIL/SKIP)
- 🩺 Self-healing system: cross-device monitoring + auto-restart
- 📡 Channel deployment wizard for QQ/Feishu/WeChat
- 🤖 Model & channel management menu
- 📖 Comprehensive GUIDE.md with screenshots and FAQ

### Added (Documentation)
- Device comparison matrix: K60, MIX 2S, Note 7, Note 4X
- 24 battle-tested pitfalls with symptom → root cause → fix
- Channel setup guides: QQ bot, Feishu, WeChat iLink
- SSH mesh configuration with Tailscale + fallback
- Full device hardening guide (Android 7–15)
- Fleet operations quick-reference

---

## [0.5.0] — 2026-07-16

### Added
- Initial release: OpenClaw deployment scripts for Android/Termux
- Node.js + OpenClaw auto-install with native module compilation
- runit service setup with Termux:Boot auto-start
- Tailscale integration for cross-network SSH
- QQ bot channel configuration
- Basic health check and service management

---

[2.6.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v2.6.0
[1.0.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v1.0.0
[0.9.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v0.9.0
[0.5.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v0.5.0
