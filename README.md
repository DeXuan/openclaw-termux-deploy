# OpenClaw Termux Deploy — Turn Old Android Phones into AI Servers 🚀

> 📖 **English** | [中文](README_CN.md)

[![GitHub Stars](https://img.shields.io/github/stars/DeXuan/openclaw-termux-deploy?style=flat&color=yellow)](https://github.com/DeXuan/openclaw-termux-deploy/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.7.1--2-blue)](https://openclaw.ai)
[![Android](https://img.shields.io/badge/Android-7%2B-brightgreen)](https://www.android.com/)
[![Termux](https://img.shields.io/badge/Termux-F--Droid-orange)](https://f-droid.org/packages/com.termux/)
[![ShellCheck](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml)

> **One command to turn any old Android phone into a 24/7 AI assistant server.**
>
> No root. No Proot. No Linux. Just Termux + OpenClaw.
>
> Battle-tested on 4 real phones: K60 (A15) · MIX 2S (A10) · Note 7 (A10) · Note 4X (A7)
>
> 把退役安卓手机变成 24 小时在线的 AI 机器人服务器。无需 root，Termux 原生方案。4 台真机实战验证。

---

## ⚡ One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/DeXuan/openclaw-termux-deploy/main/install.sh | bash
```

This single command installs **Node.js + OpenClaw + runit + auto-boot** on any Android 7+ phone with Termux. Takes ~10 minutes. [See what it does →](#-what-the-installer-does)

> **Want more control?** Clone and use the TUI toolbox:
> ```bash
> git clone https://github.com/DeXuan/openclaw-termux-deploy.git
> cd openclaw-termux-deploy && chmod +x openclaw-deploy && ./openclaw-deploy
> ```

---

## 🆚 Why This Over Other Solutions?

| | **This Project** | AidanPark/openclaw-android | Proot-based |
|---|---|---|---|
| **Stars** | ⭐ New | 1.7k | Various |
| **Approach** | Native Termux | Native Termux | Linux container |
| **Storage** | ~50 MB | ~50 MB | 1–2 GB |
| **Android** | 7–15 | 7–14 | 8+ |
| **TUI Toolbox** | ✅ Color menu | ❌ | ❌ |
| **Self-Healing** | ✅ Mutual monitoring + auto-restart | ❌ | ❌ |
| **Fleet Mgmt** | ✅ Dashboard + health checks | ❌ | ❌ |
| **Pitfall DB** | ✅ 25 real-world fixes | Basic FAQ | ❌ |
| **QQ + Feishu + WeChat** | ✅ All 3 channels | ❌ | ❌ |
| **Device Matrix** | ✅ 4 phones, A7–A15 | 1–2 phones | Generic |
| **Docs Language** | 中文 + English | English | Mixed |

---

## ✨ What You Get

### 🖥️ Fleet Dashboard
One-click view of all devices: gateway status, RAM, disk, swap, uptime.
```
🔥K60  : GW:200 | UP:1w | MEM:6.4G/14.8G | DSK:29%
⚡MIX2S: GW:200 | UP:2d | MEM:3.0G/5.5G  | DSK:17%
🪨Note4: GW:200 | UP:2h | MEM:0.9G/2.8G  | DSK:52%
🍃Note7: GW:200 | UP:6d | MEM:2.9G/5.6G  | DSK:26%
```

### 🩺 Self-Healing Mesh
```
K60 ⇄ Note 7   Mutual monitoring + auto-restart (Tailscale)
MIX 2S → K60   Backup monitor (Tailscale)
Note 4X → K60  Backup monitor (LAN)
```
All 4 devices covered. Gateway down → auto restart via SSH → still down? → Feishu alert.

### 📡 Multi-Channel Bots
| Channel | Protocol | IP Whitelist | Setup |
|---------|----------|-------------|-------|
| **QQ** | WebSocket | ✅ Required | AppID + secret |
| **Feishu** | WebSocket | ❌ None | Plugin install |
| **WeChat iLink** | WebSocket | ❌ None | QR scan |

### 📊 Smart Alerts
- **Daily fleet dashboard** → Feishu @ 8:57 AM
- **IP change alert** → instant Feishu push (QQ whitelist risk)
- **Healthcheck alert** → when self-healing fails
- **Fund NAV report** → daily @ 3:30 PM + weekly
- **Version update check** → weekly npm scan

### 🔧 25 Battle-Tested Pitfalls
Real issues encountered on real phones, with symptoms → root cause → fix. [Full list →](skill/references/pitfalls.md)

---

## 📖 Documentation

| Document | Language | Content |
|----------|----------|---------|
| **[GUIDE.md](GUIDE.md)** | 中文 | Full usage guide: TUI screenshots, 8 features, FAQ, advanced tips |
| **[docs/device-comparison.md](docs/device-comparison.md)** | 中文 | Fleet atlas: 4 device details, SSH mesh, skill inventory |
| **[skill/references/pitfalls.md](skill/references/pitfalls.md)** | 中文 | 25 pitfall quick-reference with fixes |
| **[skill/references/device-matrix.md](skill/references/device-matrix.md)** | 中文 | Device adaptation matrix: Android 7/10/15 |
| **[skill/references/channel-qqbot.md](skill/references/channel-qqbot.md)** | 中文 | QQ bot setup + IP whitelist guide |
| **[skill/references/channel-weixin.md](skill/references/channel-weixin.md)** | 中文 | WeChat iLink setup + QR scan SOP |

---

## 🚀 Quick Start

### Option A: One-Line Install (recommended)
```bash
# On your Android phone, in Termux:
curl -fsSL https://raw.githubusercontent.com/DeXuan/openclaw-termux-deploy/main/install.sh | bash
```

### Option B: PC Remote Deploy
```bash
# From your PC, deploy to phone via SSH:
git clone https://github.com/DeXuan/openclaw-termux-deploy.git
cd openclaw-termux-deploy
./openclaw-deploy wizard    # Interactive 6-step wizard
```

### Option C: Manual
```bash
# Phone side (Termux):
pkg update && pkg install -y openssh && passwd && sshd

# PC side:
ssh-copy-id -p 8022 u0_a129@<PHONE_IP>
cat scripts/phone_install_openclaw.sh | ssh -p 8022 u0_a129@<IP> 'sh -'
cat scripts/phone_check_env.sh | ssh -p 8022 u0_a129@<IP> 'sh -'
```

---

## 🧬 What the Installer Does

1. **Detects** Android version, CPU architecture, available RAM
2. **Installs** Node.js (auto-selects compliant version), git, python, build tools
3. **Patches** libsqlite (pitfall #17) and shebang/env trap (pitfall #25)
4. **Installs** OpenClaw globally with native module compilation
5. **Configures** runit service + Termux:Boot auto-start
6. **Verifies** gateway HTTP 200 + model E2E test
7. **Outputs** a summary card with next steps (model setup, channel setup)

---

## 🛡️ Fleet Operations

| Task | Command | Schedule |
|------|---------|----------|
| Dashboard | `./openclaw-deploy dashboard` | On demand |
| Health check | `cat scripts/phone_check_env.sh \| ssh …` | On demand |
| IP change alert | `check-ip.sh` | Every 10 min |
| Mutual healthcheck | `healthcheck.sh` (per-device) | Every 5 min |
| Daily report | `fleet-dashboard.sh` | 8:57 AM daily |
| Fund NAV report | `fund-monitor.py` | 3:30 PM weekdays |
| Fund weekly report | `fund-weekly.py` | Fri 10:00 PM |
| Config backup | `backup-configs.sh` | Sun 2:00 AM |
| Version check | `check-version.sh` | Mon 10:37 AM |

---

## 📁 Project Structure

```
openclaw-termux-deploy/
├── openclaw-deploy         ← 🚀 TUI toolbox entry
├── install.sh              ← ⚡ One-line installer
├── lib/common.sh           ← Shared library (UI, SSH, config)
├── scripts/
│   ├── phone_install_openclaw.sh   ← Auto-install (piped via SSH)
│   ├── phone_check_env.sh          ← Environment diagnostic
│   ├── phone_setup_service.sh      ← runit + boot setup
│   ├── fleet-dashboard.sh          ← Daily Feishu report
│   ├── fund-monitor.py             ← Fund NAV daily report
│   ├── fund-weekly.py              ← Fund weekly report
│   ├── trade-signal-scanner.py     ← Stock signal scanner
│   ├── runit-service_openclaw_run  ← runit template
│   └── sshphone.template           ← SSH config template
├── docs/device-comparison.md       ← Fleet reference
├── skill/                          ← OpenClaw skill definitions
│   ├── SKILL.md                    ← Skill metadata
│   ├── references/                 ← Reference manuals
│   └── scripts/                    ← Deploy scripts (synced)
├── GUIDE.md                        ← Full usage guide (中文)
└── README.md                       ← This file
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Adding support for new Android devices
- Reporting bugs with diagnostic data
- Submitting PRs with new features or fixes

**Quick ways to contribute:**
- Test on your phone model → report results to device matrix
- Translate docs to your language
- Share your pitfall experiences

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=DeXuan/openclaw-termux-deploy&type=Date)](https://star-history.com/#DeXuan/openclaw-termux-deploy&Date)

## 🔗 Links

- [OpenClaw Official](https://openclaw.ai) · [SkillHub Market](https://skillhub.cn)
- [Tailscale](https://tailscale.com) · [Termux (F-Droid)](https://f-droid.org/packages/com.termux/)
- [QQ Open Platform](https://q.qq.com) · [Feishu Developer](https://open.feishu.cn)

---

**Made with ❤️ for the Android fleet | MIT License**
