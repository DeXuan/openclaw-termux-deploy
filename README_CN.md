# OpenClaw + Hermes Termux Deploy — 把旧安卓手机变成 AI 服务器 🚀

[![GitHub Stars](https://img.shields.io/github/stars/DeXuan/openclaw-termux-deploy?style=flat&color=yellow)](https://github.com/DeXuan/openclaw-termux-deploy/stargazers)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-v2.7.0-blue)](https://github.com/DeXuan/openclaw-termux-deploy/releases)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-2026.7.1--2-6366f1)](https://openclaw.ai)
[![Hermes](https://img.shields.io/badge/Hermes-v0.19.0-8b5cf6)](https://hermesagent.org.cn)
[![Android](https://img.shields.io/badge/Android-7%2B-brightgreen)](https://www.android.com/)
[![Termux](https://img.shields.io/badge/Termux-F--Droid-orange)](https://f-droid.org/packages/com.termux/)
[![ShellCheck](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/shellcheck.yml)
[![Smoke Test](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/smoke-test.yml/badge.svg)](https://github.com/DeXuan/openclaw-termux-deploy/actions/workflows/smoke-test.yml)
[![Tests](https://img.shields.io/badge/tests-54%20passed-success)](https://github.com/DeXuan/openclaw-termux-deploy/tree/main/tests)
[![TencentDB](https://img.shields.io/badge/TencentDB-Memory%20v1.0.1-teal)](https://github.com/TencentCloud/tagent-memory)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen)](.github/CONTRIBUTING.md)

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

## 🖥️ 机队全景

| 设备 | SoC | RAM | 系统 | OpenClaw | Hermes | 记忆插件 | 渠道 |
|------|-----|-----|------|:--:|:--:|:--:|------|
| **K60** 🔥 | 8+ Gen 1 | 16GB | A15 | 2026.7.1-2 | v0.19.0 | ✅ v1.0.1 | QQ + 飞书 + 微信 + ClawChat 小程序 |
| **Note 7** 🍃 | 660 | 6GB | A10 | 2026.7.1-2 | v0.19.0 | ✅ v1.0.1 | QQ + 飞书 |
| **MIX 2S** ⚡ | 845 | 6GB | A10 | 2026.7.1-2 | v0.19.0 | ✅ v1.0.1 | QQ + 飞书 |
| **Note 4X** 🪨 | 625 | 3GB | A7 | 2026.7.1-2 | — | — | QQ + 飞书 |

> 🔥 主力机 · ⚡ 稳定副机 · 🍃 轻量备机 · 🪨 韧性备机（Android 7、3GB RAM 极限运行）

---

## 🆚 为什么选这个方案？

| | **本项目** | AidanPark/openclaw-android | Proot 方案 |
|---|---|---|---|
| **Stars** | ⭐ 新项目 | 1.7k | 若干 |
| **方案** | 原生 Termux | 原生 Termux | Linux 容器 |
| **存储** | ~50 MB | ~50 MB | 1–2 GB |
| **Android** | 7–15 | 7–14 | 8+ |
| **双引擎** | ✅ OpenClaw + Hermes 共存 | ❌ | ❌ |
| **TUI 工具箱** | ✅ 彩色菜单 | ❌ | ❌ |
| **自愈系统** | ✅ 双向互检 + 自动重启 | ❌ | ❌ |
| **机队管理** | ✅ 仪表盘 + HTML 体检报告 | ❌ | ❌ |
| **记忆系统** | ✅ TencentDB 四层渐进记忆 | ❌ | ❌ |
| **踩坑库** | ✅ 26 个实战修复 | 基础 FAQ | ❌ |
| **QQ+飞书+微信** | ✅ 三渠道打通 | ❌ | ❌ |
| **机型适配** | ✅ 4台 A7–A15 | 1–2台 | 通用 |
| **文档语言** | 中文 + English | English | 多种 |
| **金融插件** | ✅ 基金分析 + 交易信号 | ❌ | ❌ |

---

## ✨ 核心能力

### 🧠 双引擎共存（OpenClaw + Hermes）

同一台手机上 Node.js（OpenClaw）和 Python（Hermes Agent v0.19.0）双 runit 服务独立运行，互不冲突。3 台设备已部署（K60 / MIX 2S / Note 7），金丝雀编译 + venv tar 管道分发，新设备 ~2 分钟即可完成 Hermes 叠加部署。

```
K60    → Hermes 飞书 (cli_aaec0cd55438dbda) + 阿里云百炼 qwen3.7-plus / kimi-k2-thinking
MIX 2S → Hermes 飞书 (cli_aaedb902eb795be9) + gui-plus + qwen3-coder-plus 后备
Note 7 → Hermes 飞书 (cli_aaec7d7077b85bde) + 阿里云百炼 qwq-plus
```

### 🧬 四层渐进记忆系统（TencentDB Agent Memory）

腾讯云开源的 AI Agent 记忆插件 v1.0.1，L0 对话采集 → L1 事实提取 → L2 向量搜索 → L3 场景记忆。K60 / MIX 2S / Note 7 三台已部署（Note 4X 因 3GB RAM 待评估）。Android/Termux 上 sqlite-vec 以降级模式运行（glibc ABI），L0-L1 正常，向量搜索需云端 TencentDB。

### 🖥️ 机队仪表盘 + HTML 体检报告

一键并行扫描四台设备，9 维度体检（硬件/版本/资源/服务/渠道/模型链/记忆/异常），自动生成深色紧凑风格 HTML 报告到桌面。支持对比上一轮变化、标注自愈事件。

```bash
# 四台并行扫描，输出 HTML 报告
cat scripts/fleet_scan.sh | ssh <device> 'bash -'
```

### 🩺 自愈网格

```
K60 ⇄ Note 7   双向互检 + 自动重启 (Tailscale)
MIX 2S → K60   备份监控 (Tailscale)
Note 4X → K60  备份监控 (LAN)
```

4 台全覆盖。Gateway 挂了 → SSH 远程重启 → 还不行 → 飞书告警。

### 📡 多渠道机器人

| 渠道 | 协议 | IP 白名单 | 接入方式 | 部署设备 |
|------|------|----------|----------|----------|
| **QQ** | WebSocket | ✅ 需要 | AppID + Secret | 4台 |
| **飞书 (OpenClaw)** | WebSocket | ❌ 不需要 | 插件安装 | 4台 |
| **飞书 (Hermes)** | WebSocket | ❌ 不需要 | 配置 .env + pairing | 3台 |
| **微信 iLink** | WebSocket | ❌ 不需要 | 扫码绑定 | 4台已装 |
| **ClawChat 小程序** | HTTP 轮询 | ❌ 不需要 | 小程序扫码 | K60 |

### 📊 智能告警

- **每日机队日报** → 飞书推送 8:57 (K60) + 9:23 (MIX 2S 备份)
- **IP 变更告警** → 秒级飞书提醒（QQ 白名单风险，4 台 QQ 同出口 IP 联动）
- **健康检查告警** → 自愈失败时推送
- **模型额度告警** → 百炼免费额度自动切换（bailian-quota-switcher）
- **基金净值日报** → 交易日 15:30 + 周报周五 22:00
- **版本更新检测** → 每周一扫 npm，金丝雀升级流程

### 🔧 26 个实战踩坑速查

真机上碰到的问题 → 现象 → 根因 → 修复。涵盖装机/模型/保活/自启/网络/渠道/升级/换Key/记忆插件/Termux适配 10 大类。[完整列表 →](skill/references/pitfalls.md)

---

## 📖 文档导航

| 文档 | 内容 |
|------|------|
| **[GUIDE.md](GUIDE.md)** | 工具箱使用指南：截图 + 8 大功能详解 + FAQ + 进阶 |
| **[docs/device-comparison.md](docs/device-comparison.md)** | 机队全景：4 台设备详情、自愈架构、SSH 互信、双引擎共存 |
| **[skill/references/pitfalls.md](skill/references/pitfalls.md)** | 26 坑速查表（装机→模型→保活→自启→网络→渠道→升级→记忆→Termux） |
| **[skill/references/device-matrix.md](skill/references/device-matrix.md)** | 机型适配矩阵：Android 7/10/15 差异 + 升级 SOP |
| **[skill/references/channel-qqbot.md](skill/references/channel-qqbot.md)** | QQ 机器人配置 + IP 白名单双坑 |
| **[skill/references/channel-weixin.md](skill/references/channel-weixin.md)** | 微信 iLink 配置 + 远程扫码 SOP |
| **[skill/references/channel-feishu-hermes.md](skill/references/channel-feishu-hermes.md)** | Hermes 飞书渠道：凭证→gateway→配对→runit |
| **[finance/README.md](finance/README.md)** | 金融插件：基金净值/周报/交易信号扫描 |

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
| **全队体检** | `fleet_scan.sh`（并行4台→HTML报告） | 每次运维会话 |
| 环境体检 | `cat scripts/phone_check_env.sh \| ssh …` | 按需 |
| 仪表盘 | `./openclaw-deploy dashboard` | 按需 |
| IP 变更告警 | `check-ip.sh` | 每 10 分钟 |
| 双向互检 | `healthcheck.sh`（每台设备独立） | 每 5 分钟 |
| 模型看门狗 | `oc-model-watchdog.sh`（额度/故障自动切换） | 每 5 分钟 |
| 模型同步 | `sync-oc-models.py`（设备间模型配置同步） | 按需 |
| Hermes 配置同步 | `hermes-mesh-sync.sh`（Hermes 配置跨设备同步） | 按需 |
| 渠道健康 | `channel-health.sh`（QQ/飞书/微信连通性） | 按需 |
| 金丝雀升级 | `rolling-upgrade.sh`（单台先升→验证→全队推广） | 版本发布时 |
| 每日机队日报 | `fleet-dashboard.sh` | 每天 8:57 + 9:23 |
| 基金净值日报 | `fund-monitor.py` | 交易日 15:30 |
| 基金周报 | `fund-weekly.py` | 周五 22:00 |
| 交易信号 | `trade-signal-scanner.py` | 按需 |
| 配置备份 | `backup-configs.sh`（拉取四台 openclaw.json + crontab） | 周日 02:00 |
| 配置恢复 | `restore-configs.sh` | 按需 |
| 版本检测 | `check-version.sh` | 周一 10:37 |
| 卸载 | `uninstall.sh`（支持 --dry-run / --keep-config） | 按需 |

---

## 📁 项目结构

```
openclaw-termux-deploy/
├── openclaw-deploy              ← 🚀 TUI 工具箱入口
├── install.sh                   ← ⚡ 一行安装脚本
├── config/                      ← 配置模板 (.env / fleet-devices)
├── lib/                         ← 共享库 (UI / SSH / 配置)
├── scripts/                     ← 运维脚本 (34个)
│   ├── phone_install_openclaw.sh   ← 安装（SSH管道）
│   ├── phone_check_env.sh          ← 单机环境体检
│   ├── fleet_scan.sh               ← 全队并行体检 + HTML报告
│   ├── fleet-dashboard.sh          ← 每日机队日报（飞书推送）
│   ├── oc-model-watchdog.sh        ← 模型额度/故障自动切换
│   ├── sync-oc-models.py           ← 模型配置跨设备同步
│   ├── hermes-mesh-sync.sh         ← Hermes 配置跨设备同步
│   ├── rolling-upgrade.sh          ← 金丝雀升级（单台→全队）
│   ├── channel-health.sh           ← 渠道连通性检查
│   ├── channel-flow.sh             ← 渠道消息流监控
│   ├── check-ip.sh                 ← IP 漂移检测 + 告警
│   ├── healthcheck.sh              ← 双向互检（每台设备独立脚本）
│   ├── backup-configs.sh           ← 配置备份
│   ├── restore-configs.sh          ← 配置恢复
│   ├── alert-dedup.sh              ← 告警去重
│   ├── feishu_push.py              ← 飞书 API 推送基础库
│   └── ...                         ← 更多见 scripts/README.md
├── skill/                        ← OpenClaw 技能定义
│   ├── references/               ← 参考手册 (7份)
│   │   ├── pitfalls.md              ← 26坑速查
│   │   ├── device-matrix.md         ← 机型适配矩阵
│   │   ├── channel-qqbot.md         ← QQ 配置
│   │   ├── channel-weixin.md        ← 微信配置
│   │   ├── channel-feishu-hermes.md ← Hermes 飞书配置
│   │   └── hardening.md             ← 系统加固指南
│   └── scripts/                  ← 同步自 scripts/ 的部署脚本
├── finance/                      ← 金融插件
│   ├── fund-monitor.py              ← 基金净值日报
│   ├── fund-weekly.py               ← 基金周报
│   └── trade-signal-scanner.py      ← 交易信号扫描
├── bailian-quota-switcher/       ← 百炼免费额度管理器
├── docs/device-comparison.md     ← 机队全景文档
├── GUIDE.md                      ← 工具箱使用指南
├── README.md                     ← English README
└── README_CN.md                  ← 本文档
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
- [Hermes Agent](https://hermesagent.org.cn) · [TencentDB Agent Memory](https://github.com/TencentCloud/tagent-memory)
- [Tailscale](https://tailscale.com) · [Termux (F-Droid)](https://f-droid.org/packages/com.termux/)
- [QQ 开放平台](https://q.qq.com) · [飞书开发者](https://open.feishu.cn) · [阿里云百炼](https://bailian.console.aliyun.com)

---

**Made with ❤️ for the Android fleet | MIT License**
