# OpenClaw Deploy — 使用指南

> **OpenClaw Termux 机队管理工具箱** · 让安卓手机变成 24/7 AI 机器人服务器
>
> 支持机型：Redmi K60 / MIX 2S / Note 7 / Note 4X | 全队定版：OpenClaw 2026.7.1-2

---

## 目录

- [5 秒上手](#5-秒上手)
- [界面导览](#界面导览)
  - [主菜单](#主菜单)
  - [机队仪表盘](#机队仪表盘)
  - [新手部署向导](#新手部署向导)
  - [帮助与速查](#帮助与速查)
- [功能详解](#功能详解)
  - [1. 新手向导 — 零基础部署](#1-新手向导--零基础部署)
  - [2. 部署设备 — 高级安装](#2-部署设备--高级安装)
  - [3. 设备体检 — 一键诊断](#3-设备体检--一键诊断)
  - [4. 机队仪表盘 — 实时监控](#4-机队仪表盘--实时监控)
  - [5. 服务管理 — 启停控制](#5-服务管理--启停控制)
  - [6. 自愈系统 — 自动修复](#6-自愈系统--自动修复)
  - [7. 技能工具箱 — 能力扩展](#7-技能工具箱--能力扩展)
  - [8. 模型与渠道](#8-模型与渠道)
- [非交互模式](#非交互模式)
- [常见问题](#常见问题)
- [进阶玩法](#进阶玩法)

---

## 5 秒上手

```bash
# 1. 克隆仓库
git clone https://github.com/DeXuan/openclaw-termux-deploy.git
cd openclaw-termux-deploy

# 2. 赋予执行权限
chmod +x openclaw-deploy

# 3. 启动工具箱
./openclaw-deploy
```

> **第一次用？** 启动后选 **`1` 新手向导**，6 步完成全部部署。不需要懂 Linux。

**非交互模式（适合定时任务 / 脚本调用）：**

```bash
./openclaw-deploy dashboard    # 查看机队仪表盘
./openclaw-deploy check        # 全队一键体检
./openclaw-deploy install K60  # 远程部署到 K60
./openclaw-deploy wizard       # 直接启动向导
```

---

## 界面导览

### 主菜单

启动后进入彩色 TUI 主界面。顶部 ASCII 艺术字 OPEN 标识，中间实时显示机队探活状态（● 在线 ● 离线），下方 10 个功能入口按数字选择。

```
         ██████╗ ██████╗ ███████╗███╗   ██╗
        ██╔═══██╗██╔══██╗██╔════╝████╗  ██║
        ██║   ██║██████╔╝█████╗  ██╔██╗ ██║
        ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║
        ╚██████╔╝██║     ███████╗██║ ╚████║
         ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝

  OpenClaw · Termux 机队管理工具箱
  ───────────────────────────────────────

  2026-07-23 18:33    ● K60  ● N7  |  DESKTOP-OOEFHTF

  主 菜 单

  1   🚀 新手向导          一步步引导完成首次部署
  2   📦 部署设备          安装 Node.js / OpenClaw / runit
  3   🔍 设备体检          一键诊断机型/版本/服务状态
  4   📊 机队仪表盘        四台设备状态实时一览

  5   ⚙️  服务管理          启停/重启/日志查看
  6   🩺 自愈系统          安装/配置/状态/日志
  7   🧩 技能工具箱        安装/搜索/同步技能
  8   🤖 模型与渠道        模型管理/渠道状态/额度

  u   🔄 系统更新          升级 OpenClaw / Node.js
  h   📖 帮助与速查        运维命令/文档链接

  0   👋 退出
```

> 📸 **截图位置：** 终端全屏截图，展示彩色 TUI 主菜单

### 机队仪表盘

选 `4` 或直接 `./openclaw-deploy dashboard`，实时拉取四台设备状态：

```
  📊 机队仪表盘     2026-07-23 18:33

  ╭────────────────────────────────────────────────────────╮
  │ 🔥 K60 — 随身主力机
  │   Gateway:  在线   内存: 6.8Gi  磁盘: 132G/462G 29%  Swap: 28%
  │   在线: 5 days, 7 hours, 46 minutes
  │
  │ 🍃 Note 7 — 家里轻量机
  │   Gateway:  在线   内存: 3.0Gi  磁盘: 13G/50G 26%  Swap: 26%
  │   在线: 5 days, 2 hours, 14 minutes
  │
  │ ⚡ MIX 2S · 🪨 Note 4X — 离线中
  ╰────────────────────────────────────────────────────────╯

  [r] 刷新  [R] 强制刷新  [0] 返回
```

每行显示：Gateway 状态（绿色 `在线` / 红色 `离线` pill）· 可用内存 · 磁盘占用 · Swap 使用率 · 在线时长。

按 `r` 刷新，按 `0` 返回主菜单。

> 📸 **截图位置：** 仪表盘全屏截图，展示 K60 和 Note 7 在线数据

### 新手部署向导

选 `1` 或 `./openclaw-deploy wizard`，进入 6 步引导式部署：

```
  ╭──────────────────────────────────────────────╮
  │        🚀  新 手 部 署 向 导                 │
  ╰──────────────────────────────────────────────╯

  这个向导将一步步帮你完成 OpenClaw 部署。
  全程大约 5-10 分钟，大部分步骤自动完成。

  ✔ ✔ ✔ ● ○ ○ 检查环境 (Termux/Node.js/Git)
  ✔ ✔ ✔ ✔ ● ○ 配置 SSH 免密登录
  ✔ ✔ ✔ ✔ ✔ ● 安装 OpenClaw + 依赖
  ○ ○ ○ ○ ○ ○ 配置模型供应商 (API Key)
  ○ ○ ○ ○ ○ ○ 设置 runit 进程保活
  ○ ○ ○ ○ ○ ○ 开机自启 + 验证
```

支持两种模式：
- **本机安装**：在 Termux App 内直接运行，全程自动化
- **远程部署**：从 PC 通过 SSH 部署到目标手机

> 📸 **截图位置：** 向导页面，展示 6 个步骤指示器

### 帮助与速查

选 `h` 进入帮助页面，三张卡片式速查表：

```
  📖 帮助与速查

  ╭──────────────────────────────────────────────────╮
  │ 🖥️ 非交互模式                                      │
  │                                                    │
  │   openclaw-deploy dashboard  机队仪表盘            │
  │   openclaw-deploy check      全队一键体检          │
  │   openclaw-deploy install K60 远程部署             │
  │   openclaw-deploy wizard     新手部署向导          │
  ╰──────────────────────────────────────────────────╯

  ╭──────────────────────────────────────────────────╮
  │ 🔧 常用运维命令                                    │
  │                                                    │
  │   sv status openclaw           服务状态            │
  │   curl 127.0.0.1:18789/health  HTTP 探活          │
  │   tail -f $PREFIX/var/log/...  实时日志            │
  ╰──────────────────────────────────────────────────╯
```

---

## 功能详解

### 1. 新手向导 — 零基础部署

**适用场景：** 第一次使用、新手机加入机队、完全不懂 Linux。

向导自动完成 6 个步骤：

| 步骤 | 内容 | 自动化 |
|---|---|---|
| ① 环境检查 | 检测 Termux / Node.js / Git / 架构 | ✅ 全自动 |
| ② SSH 配置 | 生成 ed25519 密钥对 | ✅ 全自动 |
| ③ 安装 OpenClaw | npm 全局安装 + 编译 native 模块 | ✅ 全自动 |
| ④ 配置模型 | 支持 DeepSeek / 百炼 / 自定义 API | 🖐️ 需输入 Key |
| ⑤ runit 保活 | 创建服务目录 + 日志 + 自启脚本 | ✅ 全自动 |
| ⑥ 最终验证 | HTTP 探活 + 版本检查 | ✅ 全自动 |

**远程部署模式**（从 PC SSH 到手机）简化为 3 步：SSH 连接测试 → 管道安装 → 验证。

### 2. 部署设备 — 高级安装

**适用场景：** 熟悉流程后快速部署、批量部署多台设备。

提供 PC 远程部署和本机安装两种方式，复用 `scripts/phone_install_openclaw.sh` 脚本。

```bash
# 命令行等效操作
./openclaw-deploy install K60    # 远程部署到 K60
./openclaw-deploy install 192.168.1.100 u0_a129  # 自定义 IP
```

### 3. 设备体检 — 一键诊断

**适用场景：** 部署后验证、故障排查、升级前检查。

支持 4 种体检范围：

| 选项 | 目标 | 说明 |
|---|---|---|
| 本机体检 | 当前设备 | 直接在 Termux 内运行 |
| K60 远程 | K60 | 通过 SSH 远程诊断 |
| Note 7 远程 | Note 7 | 通过 SSH 远程诊断 |
| 全队体检 | K60 + Note 7 | 两台在线设备并行检查 |

体检内容：机型识别 · Node/libsqlite 版本合规 · OpenClaw 版本 · Boot 自启链 · 服务状态 · 渠道连接。

### 4. 机队仪表盘 — 实时监控

**适用场景：** 日常巡检、异常排查、资源规划。

card 风格面板，每个设备一行，5 秒刷新一次数据。指标说明：

| 指标 | 含义 | 健康范围 |
|---|---|---|
| Gateway | OpenClaw gateway HTTP 探活 | 200 = 在线（绿色 pill） |
| 内存 | `MemAvailable`，可立即分配的内存 | > 1GB（绿色） |
| 磁盘 | Termux 数据分区已用/总量 | < 80% |
| Swap | 交换分区使用率 | < 50% 正常，> 80% 告警 |
| 在线 | `uptime -p` 系统运行时长 | — |

> 💡 如果 Swap > 80%，自愈系统会通过 QQ 推送告警。

### 5. 服务管理 — 启停控制

支持本机和远程设备的 gateway 管理：

```
⚙️ 服务管理

  1   📊 本机状态        gateway HTTP + 进程信息
  2   🔄 本机重启        重启 gateway 服务
  3   📋 本机日志        实时跟踪 gateway 日志
  4   🔥 远程重启 K60    SSH 到 K60 重启 gateway
  5   🍃 远程重启 N7     SSH 到 Note 7 重启 gateway
```

重启前会弹出确认对话框，防止误操作。

### 6. 自愈系统 — 自动修复

**这是工具箱的核心亮点。** 部署后，两台设备互检，gateway 异常时自动远程重启，修不好才 QQ 通知你。

```
🩺 自愈系统

  1   📦 安装到本机      部署 healthcheck + self-check + crontab
  2   📡 安装到远程      SSH 部署到 K60 / Note 7
  3   📊 自愈状态        检查 crond / 脚本 / 重启记录
  4   📋 查看日志        互检日志 / 自检日志 / 告警记录
```

**工作原理：**

```
K60 (每5分钟) ──SSH──→ Note 7 ──curl──→ gateway HTTP 200?
                         ├── 是 → 静默
                         └── 否 → sv restart → 等20s → 重试2次
                               ├── 恢复 → 记录日志
                               └── 失败 → QQ 告警

同时每10分钟本地自检：磁盘>90%清理 · 内存<500M重启 · swap>80%告警
```

**安装后的 crontab：**

```
*/5  * * * * ~/healthcheck.sh    # 互检 + 自愈
*/10 * * * * ~/self-check.sh     # 本地自检
```

### 7. 技能工具箱 — 能力扩展

OpenClaw 的技能系统相当于"App Store"。K60 已安装 63 个就绪技能，覆盖金融投研、数据分析、企业查询、内容运营等领域。

```
🧩 技能工具箱

  1   📋 技能列表        查看已安装技能
  2   🔍 搜索安装        ClawHub / SkillHub 搜索安装
  3   📡 同步到远程      rsync 同步到 Note 7 / 全部
  4   🔥 K60 技能统计    K60 技能清单摘要
```

**常用技能速查：**

| 类别 | 推荐技能 | 能力 |
|---|---|---|
| 股票研究 | `stock-research-engine` | 个股基本面深度研究（A股/港股/美股） |
| 财务分析 | `financial-roe-analysis` | 杜邦分析体系，拆解 ROE 驱动因素 |
| 基金分析 | `fund-analyzer` | 净值/收益/风险 + 持仓回测 |
| 量化回测 | `onequant-backtest` | OneQuant 4.0，102 API + 策略回测 |
| 风险预警 | `a-share-risk-alert` | A股 ST/退市风险排查 |
| 天气 | `weather` | 全球天气查询 |
| 解梦 | `周公解梦` | 传统 + 心理学双语解梦 |

> 完整技能清单见 [docs/device-comparison.md](docs/device-comparison.md) 附录 B。

### 8. 模型与渠道

```
🤖 模型与渠道

  1   🧠 模型列表        查看当前可用模型
  2   📡 渠道状态        QQ/飞书/微信连接状态
  3   💰 免费额度        百炼模型免费额度查询
```

K60 当前模型策略：`deepseek-v4-flash` 主用（免费额度优先消耗），`deepseek-v4-pro` 自动兜底。

---

## 非交互模式

所有功能都可以不进入 TUI 菜单，直接在命令行调用：

| 命令 | 功能 | 典型场景 |
|---|---|---|
| `./openclaw-deploy dashboard` | 机队仪表盘 | SSH 登录后快速看一眼 |
| `./openclaw-deploy check` | 全队一键体检 | 定时任务 / CI 流水线 |
| `./openclaw-deploy wizard` | 新手向导 | 新手机开箱即用 |
| `./openclaw-deploy install K60` | 远程部署 | 批量部署多台设备 |
| `./openclaw-deploy version` | 版本号 | 脚本中检查兼容性 |
| `./openclaw-deploy help` | 帮助信息 | 忘记命令时查看 |

```bash
# 典型组合：每天早上的机队巡检
./openclaw-deploy dashboard && ./openclaw-deploy check
```

---

## 常见问题

### Q: 工具箱需要什么环境？

**PC 端（远程管理）：** Git Bash / WSL / macOS / Linux，能 SSH 到手机即可。
**手机端（本地操作）：** Termux (F-Droid 版)，Android 7+。

### Q: 为什么我的菜单没有颜色？

部分终端默认不支持 256 色。确认终端类型：`echo $TERM`。推荐：
- Windows: Windows Terminal 或 Git Bash
- macOS: iTerm2 或自带 Terminal
- Android: Termux 自带终端

### Q: 仪表盘显示"离线"但手机开着？

可能原因：
1. SSH 互信未配置 → 菜单 [6] 自愈系统 → 安装到远程
2. Tailscale 未连接 → 检查手机 VPN 状态
3. 手机 IP 变更 → 更新 `lib/common.sh` 中的 `DEVICES` 配置

### Q: 如何添加新设备到机队？

编辑 `lib/common.sh`，在 `DEVICES` 数组中添加：

```bash
DEVICES=(
  [K60]="u0_a129@100.118.60.29:8022"
  ...已有设备...
  [新设备]="用户名@IP:端口"      # ← 添加这一行
)
```

### Q: 自愈系统安装后不生效？

检查步骤：
1. `crontab -l` 确认定时任务已添加
2. `ps aux | grep crond` 确认 crond 在运行
3. `cat ~/healthcheck.log` 查看互检日志

Note 7 的 crond 有时会在 OOM 后挂掉。工具箱菜单 [6] → [3] 可查看自愈状态，如有异常会显示红色离线 pill。

### Q: 工具箱更新了怎么升级？

```bash
./openclaw-deploy  # 进入 TUI
# 选 u → 4  更新本工具箱 (git pull)
```

或手动：
```bash
cd openclaw-termux-deploy && git pull
```

---

## 进阶玩法

### 多设备并行体检

```bash
# 并行检查两台设备
for dev in K60 Note7; do
  (ssh_device "$dev" "sh -" < scripts/phone_check_env.sh > "${dev}_report.txt" 2>&1) &
done
wait
echo "报告已生成: K60_report.txt Note7_report.txt"
```

### 定时仪表盘快照

```bash
# 每天 9 点记录机队状态
# crontab: 0 9 * * * ~/snapshot.sh
#!/bin/bash
cd ~/openclaw-termux-deploy
./openclaw-deploy dashboard > "/tmp/fleet-$(date +%Y%m%d-%H%M).txt" 2>&1
```

### 自愈系统 + QQ 告警

部署自愈系统后，gateway 异常时：
1. 对端设备自动 SSH 重启 gateway（最多 2 次，间隔 10 分钟冷却）
2. 重启失败 → 通过 QQ 机器人推送告警消息
3. 本地资源保护同步工作：磁盘 >90% 自动清理、内存不足自动重启

**建议：** 给机队开一个单独 QQ 群，拉入所有机器人的 QQ 号，告警消息实时推送。

---

## 项目结构

```
openclaw-termux-deploy/
├── openclaw-deploy         ← 🚀 工具箱入口（bash TUI）
├── lib/
│   └── common.sh           ← 共享库（UI 组件/设备配置/SSH）
├── scripts/
│   ├── phone_install_openclaw.sh   ← 自动安装脚本
│   ├── phone_check_env.sh          ← 环境体检脚本
│   ├── phone_setup_service.sh      ← runit 服务配置
│   ├── k60-healthcheck.sh          ← K60 自愈互检
│   ├── note7-healthcheck.sh        ← Note 7 自愈互检
│   └── self-check.sh               ← 本地资源自检
├── docs/
│   └── device-comparison.md ← 机队全景文档（572 行）
├── skill/                   ← OpenClaw 技能定义
│   ├── SKILL.md
│   ├── references/           ← 参考手册（部署/渠道/加固）
│   └── scripts/
└── GUIDE.md                 ← 📖 本文档
```

---

## 相关链接

- [GitHub 仓库](https://github.com/DeXuan/openclaw-termux-deploy)
- [OpenClaw 官方](https://openclaw.ai)
- [SkillHub 技能市场](https://skillhub.cn)
- [机队全景文档](docs/device-comparison.md)

---

> **OpenClaw Deploy v1.0** · Made with ❤️ for the Android fleet
