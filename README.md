# OpenClaw + Hermes Termux Deploy — Turn Old Android Phones into AI Servers 🚀

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

## 🖥️ Fleet at a Glance

| Device | SoC | RAM | OS | OpenClaw | Hermes | Memory Plugin | Channels |
|------|-----|-----|------|:--:|:--:|:--:|------|
| **K60** 🔥 | 8+ Gen 1 | 16GB | A15 | 2026.7.1-2 | v0.19.0 | ✅ v1.0.1 | QQ + Feishu + WeChat + ClawChat Mini |
| **Note 7** 🍃 | 660 | 6GB | A10 | 2026.7.1-2 | v0.19.0 | ✅ v1.0.1 | QQ + Feishu |
| **MIX 2S** ⚡ | 845 | 6GB | A10 | 2026.7.1-2 | v0.19.0 | ✅ v1.0.1 | QQ + Feishu |
| **Note 4X** 🪨 | 625 | 3GB | A7 | 2026.7.1-2 | — | — | QQ + Feishu |

> 🔥 Flagship · ⚡ Stable secondary · 🍃 Lightweight · 🪨 Resilient (A7, 3GB RAM — extreme efficiency)

---

## 🆚 Why This Over Other Solutions?

| | **This Project** | AidanPark/openclaw-android | Proot-based |
|---|---|---|---|
| **Stars** | ⭐ New | 1.7k | Various |
| **Approach** | Native Termux | Native Termux | Linux container |
| **Storage** | ~50 MB | ~50 MB | 1–2 GB |
| **Android** | 7–15 | 7–14 | 8+ |
| **Dual Engine** | ✅ OpenClaw + Hermes co-deploy | ❌ | ❌ |
| **TUI Toolbox** | ✅ Color menu | ❌ | ❌ |
| **Self-Healing** | ✅ Mutual monitoring + auto-restart | ❌ | ❌ |
| **Fleet Mgmt** | ✅ Dashboard + HTML health reports | ❌ | ❌ |
| **Memory System** | ✅ TencentDB 4-layer progressive memory | ❌ | ❌ |
| **Pitfall DB** | ✅ 26 real-world fixes | Basic FAQ | ❌ |
| **QQ + Feishu + WeChat** | ✅ All 3 channels | ❌ | ❌ |
| **Device Matrix** | ✅ 4 phones, A7–A15 | 1–2 phones | Generic |
| **Finance Plugins** | ✅ Fund NAV + trade signals | ❌ | ❌ |
| **Docs Language** | 中文 + English | English | Mixed |

---

## ✨ What You Get

### 🧠 Dual Engine: OpenClaw + Hermes Agent

Run both Node.js (OpenClaw) and Python (Hermes Agent v0.19.0) on the same phone as independent runit services. Zero conflict. 3 devices deployed (K60 / MIX 2S / Note 7). Canary build + venv tar-pipe distribution — deploy Hermes to a new device in ~2 minutes.

```
K60    → Hermes Feishu + Alibaba Bailian (qwen3.7-plus / kimi-k2-thinking)
MIX 2S → Hermes Feishu + Alibaba Bailian (gui-plus + qwen3-coder-plus fallback)
Note 7 → Hermes Feishu + Alibaba Bailian (qwq-plus)
```

### 🧬 4-Layer Memory System (TencentDB Agent Memory)

TencentDB open-source AI agent memory plugin v1.0.1: L0 conversation capture → L1 fact extraction → L2 vector search → L3 scene memory. Deployed on K60 / MIX 2S / Note 7. On Android/Termux, sqlite-vec runs in degraded mode (glibc ABI) — L0-L1 functional, vector search requires cloud TencentDB.

### 🖥️ Fleet Dashboard + HTML Health Reports

Parallel 9-dimension health scan across all 4 devices (hardware / versions / resources / services / channels / model chain / memory / anomalies). Auto-generates dark-themed compact HTML report with change detection and self-healing event tracking.

```bash
# Scan all 4 devices in parallel, generate HTML report
cat scripts/fleet_scan.sh | ssh <device> 'bash -'
```

### 🩺 Self-Healing Mesh

```
K60 ⇄ Note 7   Mutual monitoring + auto-restart (Tailscale)
MIX 2S → K60   Backup monitor (Tailscale)
Note 4X → K60  Backup monitor (LAN)
```

All 4 devices covered. Gateway down → auto restart via SSH → still down? → Feishu alert.

### 📡 Multi-Channel Bots

| Channel | Protocol | IP Whitelist | Setup | Devices |
|---------|----------|-------------|-------|---------|
| **QQ** | WebSocket | ✅ Required | AppID + secret | 4 |
| **Feishu (OC)** | WebSocket | ❌ None | Plugin install | 4 |
| **Feishu (HM)** | WebSocket | ❌ None | .env + pairing | 3 |
| **WeChat iLink** | WebSocket | ❌ None | QR scan | 4 (installed) |
| **ClawChat Mini** | HTTP polling | ❌ None | Mini-program scan | K60 |

### 📊 Smart Alerts

- **Daily fleet dashboard** → Feishu @ 8:57 AM (K60) + 9:23 AM (MIX 2S backup)
- **IP change alert** → instant Feishu push (QQ whitelist risk — all 4 bots share same public IP)
- **Healthcheck alert** → when self-healing fails
- **Model quota alert** → Bailian free quota auto-switching
- **Fund NAV report** → trading days @ 3:30 PM + weekly on Fridays
- **Version update check** → weekly npm scan + canary upgrade SOP

### 🔧 26 Battle-Tested Pitfalls

Real issues encountered on real phones, with symptoms → root cause → fix. Covers 10 categories: install / model / process guard / auto-boot / network / channels / upgrade / API key / memory plugin / Termux adaptation. [Full list →](skill/references/pitfalls.md)

---

## 📖 Documentation

| Document | Language | Content |
|----------|----------|---------|
| **[GUIDE.md](GUIDE.md)** | 中文 | Full usage guide: TUI screenshots, 8 features, FAQ, advanced tips |
| **[docs/device-comparison.md](docs/device-comparison.md)** | 中文 | Fleet atlas: 4 device details, SSH mesh, dual-engine architecture |
| **[skill/references/pitfalls.md](skill/references/pitfalls.md)** | 中文 | 26 pitfall quick-reference with fixes |
| **[skill/references/device-matrix.md](skill/references/device-matrix.md)** | 中文 | Device adaptation matrix: Android 7/10/15 + upgrade SOP |
| **[skill/references/channel-qqbot.md](skill/references/channel-qqbot.md)** | 中文 | QQ bot setup + IP whitelist guide |
| **[skill/references/channel-weixin.md](skill/references/channel-weixin.md)** | 中文 | WeChat iLink setup + QR scan SOP |
| **[skill/references/channel-feishu-hermes.md](skill/references/channel-feishu-hermes.md)** | 中文 | Hermes Feishu channel: credentials → gateway → pairing → runit |
| **[finance/README.md](finance/README.md)** | 中文 | Finance plugins: fund NAV, weekly, trade signal scanner |

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
| **Fleet health scan** | `fleet_scan.sh` (parallel 4 devices → HTML report) | Every ops session |
| Device health check | `cat scripts/phone_check_env.sh \| ssh …` | On demand |
| Dashboard | `./openclaw-deploy dashboard` | On demand |
| IP change alert | `check-ip.sh` | Every 10 min |
| Mutual healthcheck | `healthcheck.sh` (per-device) | Every 5 min |
| Model watchdog | `oc-model-watchdog.sh` (quota/failure auto-failover) | Every 5 min |
| Model sync | `sync-oc-models.py` (cross-device model config sync) | On demand |
| Hermes config sync | `hermes-mesh-sync.sh` (cross-device Hermes sync) | On demand |
| Channel health | `channel-health.sh` (QQ/Feishu/WeChat connectivity) | On demand |
| Canary upgrade | `rolling-upgrade.sh` (single→verify→fleet) | On release |
| Daily fleet report | `fleet-dashboard.sh` | 8:57 + 9:23 AM |
| Fund NAV report | `fund-monitor.py` | Trading days 3:30 PM |
| Fund weekly report | `fund-weekly.py` | Fri 10:00 PM |
| Trade signals | `trade-signal-scanner.py` | On demand |
| Config backup | `backup-configs.sh` (pull from all 4 devices) | Sun 2:00 AM |
| Config restore | `restore-configs.sh` | On demand |
| Version check | `check-version.sh` | Mon 10:37 AM |
| Uninstall | `uninstall.sh` (supports --dry-run / --keep-config) | On demand |

---

## 📁 Project Structure

```
openclaw-termux-deploy/
├── openclaw-deploy              ← 🚀 TUI toolbox entry
├── install.sh                   ← ⚡ One-line installer
├── config/                      ← Configuration templates (.env / fleet-devices)
├── lib/                         ← Shared library (UI / SSH / config)
├── scripts/                     ← Operational scripts (34 total)
│   ├── phone_install_openclaw.sh   ← Auto-install (piped via SSH)
│   ├── phone_check_env.sh          ← Device environment diagnostic
│   ├── fleet_scan.sh               ← Parallel fleet scan + HTML report
│   ├── fleet-dashboard.sh          ← Daily Feishu dashboard report
│   ├── oc-model-watchdog.sh        ← Model quota/failure auto-failover
│   ├── sync-oc-models.py           ← Cross-device model config sync
│   ├── hermes-mesh-sync.sh         ← Cross-device Hermes config sync
│   ├── rolling-upgrade.sh          ← Canary upgrade (single→verify→fleet)
│   ├── channel-health.sh           ← Channel connectivity check
│   ├── channel-flow.sh             ← Channel message flow monitor
│   ├── check-ip.sh                 ← IP drift detection + alert
│   ├── healthcheck.sh              ← Mutual monitoring (per-device scripts)
│   ├── backup-configs.sh           ← Config backup
│   ├── restore-configs.sh          ← Config restore
│   ├── alert-dedup.sh              ← Alert deduplication
│   ├── feishu_push.py              ← Feishu API push library
│   └── ...                         ← See scripts/README.md
├── skill/                        ← OpenClaw skill definitions
│   ├── references/               ← Reference manuals (7 docs)
│   │   ├── pitfalls.md              ← 26 pitfalls quick-ref
│   │   ├── device-matrix.md         ← Device adaptation matrix
│   │   ├── channel-qqbot.md         ← QQ bot setup
│   │   ├── channel-weixin.md        ← WeChat iLink setup
│   │   ├── channel-feishu-hermes.md ← Hermes Feishu setup
│   │   └── hardening.md             ← System hardening guide
│   └── scripts/                  ← Deploy scripts (synced with scripts/)
├── finance/                      ← Finance plugins
│   ├── fund-monitor.py              ← Fund NAV daily report
│   ├── fund-weekly.py               ← Fund weekly report
│   └── trade-signal-scanner.py      ← Trade signal scanner
├── bailian-quota-switcher/       ← Bailian free quota manager
├── docs/device-comparison.md     ← Fleet atlas
├── GUIDE.md                      ← Full usage guide (中文)
├── README.md                     ← This file
└── README_CN.md                  ← Chinese README
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines on:
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
- [Hermes Agent](https://hermesagent.org.cn) · [TencentDB Agent Memory](https://github.com/TencentCloud/tagent-memory)
- [Tailscale](https://tailscale.com) · [Termux (F-Droid)](https://f-droid.org/packages/com.termux/)
- [QQ Open Platform](https://q.qq.com) · [Feishu Developer](https://open.feishu.cn) · [Alibaba Bailian](https://bailian.console.aliyun.com)

---

**Made with ❤️ for the Android fleet | MIT License**
