# OpenClaw Termux Deploy — 把旧安卓手机变成 AI 服务器 🚀

[![GitHub Stars](https://img.shields.io/github/stars/DeXuan/openclaw-termux-deploy?style=flat&color=yellow)](https://github.com/DeXuan/openclaw-termux-deploy/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.7.1--2-blue)](https://openclaw.ai)
[![Android](https://img.shields.io/badge/Android-7%2B-brightgreen)](https://www.android.com/)
[![Termux](https://img.shields.io/badge/Termux-F--Droid-orange)](https://f-droid.org/packages/com.termux/)
[![ShellCheck](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml)

> 📖 [English README](README.md) | **中文**

> **一行命令，把退役安卓手机变成 24 小时在线的 AI 机器人服务器。**
>
> 无需 root · 无需 Proot · 无需 Linux · 纯 Termux 原生方案
>
> 4 台真机实战验证：K60 (A15) · MIX 2S (A10) · Note 7 (A10) · Note 4X (A7)

---

## ⚡ 一行安装

```bash
curl -fsSL https://raw.githubusercontent.com/DeXuan/openclaw-termux-deploy/main/install.sh | bash
```

Termux 里粘贴执行，~10 分钟自动完成：Node.js + OpenClaw + runit 保活 + 开机自启。

> **想要更多控制？** 克隆仓库使用 TUI 工具箱：
> ```bash
> git clone https://github.com/DeXuan/openclaw-termux-deploy.git
> cd openclaw-termux-deploy && chmod +x openclaw-deploy && ./openclaw-deploy
> ```

---

## 🆚 为什么选这个方案？

| | **本项目** | AidanPark/openclaw-android | Proot 方案 |
|---|---|---|---|
| **Stars** | ⭐ 新项目 | 1.7k | 若干 |
| **方案** | 原生 Termux | 原生 Termux | Linux 容器 |
| **存储** | ~50 MB | ~50 MB | 1–2 GB |
| **Android** | 7–15 | 7–14 | 8+ |
| **TUI 工具箱** | ✅ 彩色菜单 | ❌ | ❌ |
| **自愈系统** | ✅ 双向互检 + 自动重启 | ❌ | ❌ |
| **机队管理** | ✅ 仪表盘 + 体检 | ❌ | ❌ |
| **踩坑库** | ✅ 25 个实战修复 | 基础 FAQ | ❌ |
| **QQ+飞书+微信** | ✅ 三渠道打通 | ❌ | ❌ |
| **机型适配** | ✅ 4台 A7–A15 | 1–2台 | 通用 |
| **文档语言** | 中文 + English | English | 多种 |

---

## ✨ 能做什么

### 🖥️ 机队仪表盘
一键看四台设备：gateway 状态、内存、磁盘、运行时长。
```
🔥K60  : GW:200 | UP:1w | MEM:6.4G/14.8G | DSK:29%
⚡MIX2S: GW:200 | UP:2d | MEM:3.0G/5.5G  | DSK:17%
🪨Note4: GW:200 | UP:2h | MEM:0.9G/2.8G  | DSK:52%
🍃Note7: GW:200 | UP:6d | MEM:2.9G/5.6G  | DSK:26%
```

### 🩺 自愈网格
```
K60 ⇄ Note 7   双向互检 + 自动重启 (Tailscale)
MIX 2S → K60   备份监控 (Tailscale)
Note 4X → K60  备份监控 (LAN)
```
4 台全覆盖。Gateway 挂了 → SSH 远程重启 → 还不行 → 飞书告警。

### 📡 多渠道机器人
| 渠道 | 协议 | IP 白名单 | 接入方式 |
|------|------|----------|----------|
| **QQ** | WebSocket | ✅ 需要 | AppID + Secret |
| **飞书** | WebSocket | ❌ 不需要 | 插件安装 |
| **微信 iLink** | WebSocket | ❌ 不需要 | 扫码绑定 |

### 📊 智能告警
- **每日机队日报** → 飞书推送 8:57
- **IP 变更告警** → 秒级飞书提醒（QQ 白名单风险）
- **健康检查告警** → 自愈失败时推送
- **基金净值日报** → 交易日 15:30 + 周报周五 22:00
- **版本更新检测** → 每周一扫 npm

### 🔧 25 个实战踩坑速查
真机上碰到的问题 → 现象 → 根因 → 修复。从 SQLite WAL bug 到 shebang 陷阱，一查就有。[完整列表 →](skill/references/pitfalls.md)

---

## 📖 文档导航

| 文档 | 内容 |
|------|------|
| **[GUIDE.md](GUIDE.md)** | 工具箱使用指南：截图 + 8 大功能详解 + FAQ + 进阶 |
| **[docs/device-comparison.md](docs/device-comparison.md)** | 机队全景：4 台设备详情、自愈架构、SSH 互信 |
| **[skill/references/pitfalls.md](skill/references/pitfalls.md)** | 25 坑速查表 |
| **[skill/references/device-matrix.md](skill/references/device-matrix.md)** | 机型适配矩阵：Android 7/10/15 |
| **[skill/references/channel-qqbot.md](skill/references/channel-qqbot.md)** | QQ 机器人配置 + IP 白名单 |
| **[skill/references/channel-weixin.md](skill/references/channel-weixin.md)** | 微信 iLink 配置 + 远程扫码 |

---

## 🚀 快速上手

### 方式 A：一行安装（推荐）
```bash
# 在安卓手机的 Termux 里执行：
curl -fsSL https://raw.githubusercontent.com/DeXuan/openclaw-termux-deploy/main/install.sh | bash
```

### 方式 B：PC 远程部署
```bash
git clone https://github.com/DeXuan/openclaw-termux-deploy.git
cd openclaw-termux-deploy
./openclaw-deploy wizard    # 6 步引导式部署
```

### 方式 C：手动
```bash
# 手机端 (Termux):
pkg update && pkg install -y openssh && passwd && sshd

# PC 端:
ssh-copy-id -p 8022 u0_a129@<手机IP>
cat scripts/phone_install_openclaw.sh | ssh -p 8022 u0_a129@<IP> 'sh -'
cat scripts/phone_check_env.sh | ssh -p 8022 u0_a129@<IP> 'sh -'
```

---

## 🧬 安装脚本做了什么

1. **检测** Android 版本、CPU、内存
2. **安装** Node.js（自动选合规版本）、git、python、编译工具
3. **修复** libsqlite（坑17）+ shebang/env 陷阱（坑25）
4. **安装** OpenClaw 并编译原生模块
5. **配置** runit 保活服务 + Termux:Boot 开机自启
6. **验证** gateway HTTP 200 + 模型 E2E 测试
7. **输出** 下一步指引（模型配置、渠道配置）

---

## 🛡️ 机队运维

| 任务 | 命令 | 频率 |
|------|------|------|
| 仪表盘 | `./openclaw-deploy dashboard` | 按需 |
| 环境体检 | `cat scripts/phone_check_env.sh \| ssh …` | 按需 |
| IP 变更告警 | `check-ip.sh` | 每 10 分钟 |
| 双向互检 | `healthcheck.sh`（每台设备） | 每 5 分钟 |
| 每日机队日报 | `fleet-dashboard.sh` | 每天 8:57 |
| 基金净值日报 | `fund-monitor.py` | 交易日 15:30 | 见 `finance/` |
| 基金周报 | `fund-weekly.py` | 周五 22:00 | 见 `finance/` |
| 配置备份 | `backup-configs.sh` | 周日 02:00 |
| 版本检测 | `check-version.sh` | 周一 10:37 |

---

## 🖥️ 机队概览

| 设备 | SoC | RAM | 系统 | 角色 | 渠道 |
|------|-----|-----|------|------|------|
| **K60** 🔥 | 8+ Gen 1 | 16GB | A15 | 随身主力 | QQ + 飞书 + 微信 |
| **Note 7** 🍃 | 660 | 6GB | A10 | 家里轻量 | QQ + 飞书 |
| **MIX 2S** ⚡ | 845 | 6GB | A10 | 稳定副机 | QQ + 飞书 |
| **Note 4X** 🪨 | 625 | 3GB | A7 | 韧性备机 | QQ + 飞书 |

---

## 📁 项目结构

```
openclaw-termux-deploy/
├── openclaw-deploy         ← 🚀 TUI 工具箱入口
├── install.sh              ← ⚡ 一行安装脚本
├── lib/common.sh           ← UI 组件库 / 设备配置 / SSH
├── scripts/                ← 部署 & 自愈 & 监控脚本
├── docs/                   ← 机队全景文档
├── skill/                  ← OpenClaw 技能定义 & 参考手册
├── GUIDE.md                ← 工具箱使用指南
├── README.md               ← English README
└── README_CN.md            ← 本文档
```

---

## 🤝 参与贡献

详见 [CONTRIBUTING.md](.github/CONTRIBUTING.md)。快速参与方式：
- 在你的手机上测试 → 报告结果加入机型矩阵
- 翻译文档到其他语言
- 分享踩坑经验

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=DeXuan/openclaw-termux-deploy&type=Date)](https://star-history.com/#DeXuan/openclaw-termux-deploy&Date)

## 🔗 相关链接

- [OpenClaw 官方](https://openclaw.ai) · [SkillHub 技能市场](https://skillhub.cn)
- [Tailscale](https://tailscale.com) · [Termux (F-Droid)](https://f-droid.org/packages/com.termux/)
- [QQ 开放平台](https://q.qq.com) · [飞书开发者](https://open.feishu.cn)

---

**Made with ❤️ for the Android fleet | MIT License**
