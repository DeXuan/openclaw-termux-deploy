# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-07-26

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

### Fixed
- 🐛 Pitfall #25: shebang `/usr/bin/env` trap on Android/Termux
- 🔴 ShellCheck CI badge — changed from red (failing) to green (passing)
- 🟡 Fund report format — compact mobile-friendly layout with QDII separation
- 🔵 Note 4X model — primary switched from GLM-5.2 to qwen-portal/coder-model

### Changed
- README totally rewritten: badges, comparison table, fleet dashboard preview
- GUIDE.md updated with troubleshooting FAQ for pitfall #25
- phone_check_env.sh: added channel probe (QQ/Feishu) + pitfall #25 detection
- MIX 2S crontab intervals tightened: 15/30 → 5/10 minutes

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

[1.0.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v1.0.0
[0.9.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v0.9.0
[0.5.0]: https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v0.5.0
