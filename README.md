# 安卓手机一键部署 OpenClaw，打通微信 / QQ / 飞书

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![ShellCheck](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml)

> 把退役安卓手机变成 24 小时在线的 AI 机器人服务器 · 无需 root · Termux 原生方案
>
> 4 台真机验证：K60 (A15) · MIX 2S (A10) · Note 7 (A10) · Note 4X (A7) | OpenClaw 2026.7.1-2

---

## 🧰 5 秒上手

```bash
git clone https://github.com/DeXuan/openclaw-termux-deploy.git
cd openclaw-termux-deploy
chmod +x openclaw-deploy
./openclaw-deploy
```

彩色 TUI 工具箱，选 `1` 新手向导，6 步完成部署。PC 和 Termux 都能跑。

| 功能 | 说明 |
|---|---|
| 🚀 新手向导 | 6 步引导式部署，零基础 |
| 📦 部署设备 | PC 远程 SSH 或本机安装 Node.js + OpenClaw + runit |
| 🔍 设备体检 | 一键诊断机型/版本/服务状态 |
| 📊 机队仪表盘 | 4 台设备 gateway/内存/磁盘/swap 实时一览 |
| ⚙️ 服务管理 | 启停/重启/实时日志（本机 + 远程） |
| 🩺 自愈系统 | 双向互检 + 自动重启 + 内存/磁盘阈值保护 |
| 🧩 技能工具箱 | 安装/搜索/同步技能到远程设备 |
| 🤖 模型与渠道 | 模型管理、渠道状态、免费额度查询 |

```bash
./openclaw-deploy dashboard    # 机队仪表盘（非交互）
./openclaw-deploy check        # 全队一键体检
./openclaw-deploy wizard       # 新手向导
```

> 📖 **完整使用指南：[GUIDE.md](GUIDE.md)** — 界面截图、功能详解、常见问题、进阶玩法

---

## 📖 文档导航

| 文档 | 内容 |
|---|---|
| **[GUIDE.md](GUIDE.md)** | 工具箱使用指南：界面截图 + 8 大功能详解 + FAQ + 进阶 |
| **[docs/device-comparison.md](docs/device-comparison.md)** | 机队全景：4 台设备详情、自愈架构、SSH 互信、技能清单 |
| **[skill/](skill/)** | 部署技能参考：渠道配置 (QQ/飞书/微信)、机型适配、踩坑速查 |

---

## 🖥️ 机队概览

| 设备 | SoC | RAM | 系统 | 角色 | 渠道 |
|---|---|---|---|---|---|
| **K60** 🔥 | 8+ Gen 1 | 16GB | A15 | 随身主力 | QQ + 飞书 + 微信 |
| **Note 7** 🍃 | 660 | 6GB | A10 | 家里轻量 | QQ + 飞书 |
| **MIX 2S** ⚡ | 845 | 6GB | A10 | 稳定副机 | QQ + 飞书 |
| **Note 4X** 🪨 | 625 | 3GB | A7 | 韧性备机 | QQ + 飞书 |

```
TS 组网: K60 · Note 7 · MIX 2S  |  Note 4X 仅 LAN (A7 不支持)
4 机 SSH 全互信 ✅  crond 自愈全覆盖 ✅  IP 漂移告警 ✅
```

---

## ✨ 核心特性

### 🩺 自愈系统

设备互检 gateway，异常时自动远程重启，修不好才 QQ 告警。本地内存/磁盘阈值自动清理。

```
K60 ⇄ Note 7  双向互检 + 自动重启 (Tailscale)
MIX 2S → K60  单向监控 (LAN)
Note 4X → K60  单向监控 (LAN)
```

### 📊 机队仪表盘

从 PC 一键查看 4 台设备：gateway 在线状态、可用内存、磁盘占用、Swap 使用率、在线时长。

### 🔧 技能生态

K60 已有 63 个就绪技能——金融投研、数据分析、商业查询、内容运营。三台设备已同步 59 个技能。

### 🛡️ 运维可靠

- **runit** 进程保活，gateway 挂了 15 秒自动拉起
- **crond** 全队定时体检，异常静默自愈
- **IP 漂移检测**，宽带重拨自动告警
- **Termux:Boot** 断电重启全部自恢复

---

## 📦 手动部署参考

工具箱已覆盖全流程。如需手动操作或排查：

```bash
# 1. 手机端 (Termux)
pkg update && pkg install -y openssh && passwd && sshd

# 2. PC 端配置免密
ssh-copy-id -p 8022 u0_a129@<手机IP>

# 3. 一键安装
cat scripts/phone_install_openclaw.sh | ssh -p 8022 u0_a129@<IP> 'sh -'

# 4. 环境体检
cat scripts/phone_check_env.sh | ssh -p 8022 u0_a129@<IP> 'sh -'
```

| 机型 | Android | 特殊处理 |
|---|---|---|
| K60 | 15 / HyperOS | 关 phantom killer + 锁 device_config |
| MIX 2S | 10 / MIUI 12.5 | 仅需 Doze 白名单（天然免疫 phantom killer） |
| Note 7 | 10 / MIUI 12.5 | 同上；禁止并发 CLI（SD660 瓶颈） |
| Note 4X | 7 / MIUI 11 | Tailscale 不可用；手动 deb 装 Node + hold 防升级；禁并发 CLI |

---

## 📡 渠道速查

### QQ 机器人

出口 IP 变化时需同时更新 4 个 AppID 的白名单：

| 设备 | AppID |
|---|---|
| K60 | 102825839 |
| MIX 2S | 1903080675 |
| Note 7 | 1905221791 |
| Note 4X | 1905222557 |

白名单管理：https://q.qq.com → 开发设置 → IP 白名单

### 飞书

WebSocket 长连接，无 IP 白名单。`openclaw plugins install @openclaw/feishu`

### 微信 iLink（腾讯官方）

仅 K60 保留绑定 (970ed7c8f462-im-bot)。其余三台已移除。

---

## 🔧 运维速查

| 操作 | 命令 |
|---|---|
| 工具箱 | `./openclaw-deploy` |
| 仪表盘 | `./openclaw-deploy dashboard` |
| 查出口 IP | `curl -4 -s https://api.ip.sb/ip` |
| 服务状态 | `sv status openclaw` |
| HTTP 探活 | `curl http://127.0.0.1:18789/health` |
| 实时日志 | `tail -f $PREFIX/var/log/sv/openclaw/current` |
| 重启服务 | `sv restart openclaw` |
| 版本号 | `openclaw --version` |
| 自愈日志 | `cat ~/healthcheck.log` |

---

## 📁 项目结构

```
openclaw-termux-deploy/
├── openclaw-deploy         ← 🚀 工具箱入口 (bash TUI)
├── lib/common.sh           ← UI 组件库 / 设备配置 / SSH
├── scripts/                ← 部署 & 自愈脚本
├── docs/                   ← 机队全景文档
├── skill/                  ← OpenClaw 技能定义 & 参考手册
├── GUIDE.md                ← 工具箱使用指南
└── README.md               ← 本文档
```

---

## 🔗 相关链接

- [OpenClaw 官方](https://openclaw.ai) · [SkillHub 技能市场](https://skillhub.cn)
- [Tailscale 跨网络组网](https://tailscale.com) · [Termux F-Droid](https://f-droid.org/packages/com.termux/)
