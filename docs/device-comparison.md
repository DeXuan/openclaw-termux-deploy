# OpenClaw 四台手机机队全方位对比

> 最后更新：2026-07-23 | 全队定版：OpenClaw 2026.7.1-2
>
> **本次更新：** K60 + Note 7 深度分析（含技能清单）、渠道/角色数据刷新、技能同步方案

---

## 一、硬件规格

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **代号** | mondrian | polaris | lavender | mido |
| **SoC** | 骁龙 8+ Gen 1 (4nm) | 骁龙 845 (10nm) | 骁龙 660 (14nm) | 骁龙 625 (14nm) |
| **CPU** | 1×3.0GHz X2 + 3×2.5GHz A710 + 4×1.8GHz A510 | 4×2.8GHz Kryo 385 Gold + 4×1.8GHz Silver | 4×2.2GHz Kryo 260 Gold + 4×1.8GHz Silver | 8×2.0GHz Cortex-A53 |
| **GPU** | Adreno 730 | Adreno 630 | Adreno 512 | Adreno 506 |
| **RAM** | 16GB LPDDR5 | 6GB LPDDR4x | 6GB LPDDR4X | 3GB LPDDR3 |
| **存储** | UFS 3.1 (无 microSD) | UFS 2.1 (无 microSD) | eMMC 5.1 (支持 microSD) | eMMC 5.1 (支持 microSD) |
| **屏幕** | 6.67" AMOLED 3200×1440 120Hz | 5.99" IPS LCD 2160×1080 | 6.3" IPS LCD 2340×1080 | 5.5" IPS LCD 1920×1080 |
| **电池** | 5500mAh | 3400mAh | 4000mAh | 4100mAh |
| **充电** | 67W 有线 + 30W 无线 | 18W 有线 + 7.5W 无线 | 18W 有线 (QC4) | 10W 有线 |
| **发布年份** | 2022 | 2018 | 2019 | 2017 |
| **重量** | 199g | 189g | 186g | 165g |
| **耳机孔** | 无 | 无 | 有 | 有 |
| **指纹** | 屏下 | 后置 | 后置 | 后置 |
| **性能档位** | 🟢 旗舰 | 🟡 次旗舰 | 🟠 中端 | 🔴 低端 |

---

## 二、操作系统与加固

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **Android 版本** | 15 (HyperOS V816) | 10 (MIUI 12.5.1) | 10 (MIUI 12.5.7) | 7.0 (MIUI 11) |
| **官方支持状态** | 活跃更新中 | EOL (2020/12 终版) | EOL (2021/10 终版) | EOL (MIUI 10 终版) |
| **phantom process killer** | ⚠️ 已关 + 锁 persistent | ✅ 天然免疫 (A12 引入) | ✅ 天然免疫 | ✅ 天然免疫 |
| **权限自动撤销** | ⚠️ 已禁 | ✅ 无此机制 (A11+ 才有) | ✅ 无此机制 | ✅ 无此机制 |
| **Doze 白名单** | ✅ 已加 | ✅ 已加 | ✅ 已加 | ✅ 已加 |
| **root 状态** | 无 | 无 | 无 | 无 (su 是空壳) |
| **加固难度** | 🔴 高（全套 adb） | 🟢 低（仅 Doze） | 🟢 低（仅 Doze） | 🟢 低（仅 Doze） |
| **特殊注意** | HyperOS 需锁 device_config 防云端回滚；Termux 内 `pm list` 漏报 | MIUI 12.5 普通 USB 调试无 WRITE_SECURE_SETTINGS | 无需特殊加固 | 电源键不灵敏，已装 Power Button Tile (F-Droid) 通过磁贴重启 |

---

## 三、网络与连接

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **局域网 IP** | 192.168.1.23 | 192.168.1.20 | 192.168.1.24 | 192.168.1.19 |
| **Tailscale IP** | 100.118.60.29 | 100.104.72.125 | 100.91.94.44 | ❌ 不支持 (Android 7) |
| **MAC 地址** | 真实 MAC (已绑定) | ⚠️ 随机 MAC AE:1A:3A:F6:F9:0C | 真实 MAC 70:3A:51:8C:5E:09 | 真实 MAC 50:8F:4C:63:5D:3B |
| **SSH 端口** | 8022 | 8022 | 8022 | 8022 |
| **SSH 用户** | u0_a129 | u0_a129 | u0_a171 | u0_a129 |
| **PC 连接脚本** | `sshk60` (TS 优先→热点回退) | `sshmix2s` (TS 优先→LAN 回退) | `sshnote7` (TS 优先→LAN 回退) | `ssh4x` (仅 LAN 直连) |
| **可达性冗余** | 双路径 (TS + 蜂窝热点) | 双路径 (TS + LAN) | 双路径 (TS + LAN) | 单路径 (仅 LAN) |
| **路由器 MAC 绑定** | ✅ | ⚠️ 随机 MAC 绑定 (若「忘记网络」重连需重绑) | ✅ | ✅ |

### 网络拓扑

```
家庭宽带 (出口 117.186.4.220)
├── K60 ........ 192.168.1.23 ── Tailscale 100.118.60.29
├── MIX 2S ..... 192.168.1.20 ── Tailscale 100.104.72.125
├── Note 7 ..... 192.168.1.24 ── Tailscale 100.91.94.44
├── Note 4X .... 192.168.1.19 ── (无 Tailscale，仅局域网)
└── PC ......... 100.70.110.100 (desktop-ooefhtf)
```

---

## 四、软件栈

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **OpenClaw** | 2026.7.1-2 | 2026.7.1-2 | 2026.7.1-2 | 2026.7.1-2 |
| **Node.js** | 24.17.0 | 26.4.0 | 26.4.0 | 26.4.0 |
| **libsqlite** | 3.53.3 | 3.53.3 | 3.53.3 | 3.53.0 |
| **Node 来源** | 仓库 nodejs-lts | 仓库（撤版前安装） | 仓库（撤版前安装） | **手动 deb + apt-mark hold** |
| **Termux 版本** | 0.118+ | 0.118+ | 0.118+ | 0.118 |
| **进程管理** | runit | runit | runit | runit |
| **自启** | Termux:Boot | Termux:Boot | Termux:Boot | Termux:Boot |
| **gateway 端口** | 18789 (token 认证) | 18789 (token 认证) | 18789 (token 认证) | 18789 (token 认证) |
| **升级风险** | 🟢 低 (Node 合规源) | 🟡 中 (Node 需手动维护) | 🟡 中 (Node 需手动维护) | 🔴 高 (Node 手动 deb + hold) |
| **gateway 冷启动** | ~10s | ~20s | 40-60s | 2.5-3min (含迁移) |

---

## 五、渠道矩阵

| 渠道 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **QQ 机器人** | ✅ AppID 102825839 | ✅ AppID 1903080675 | ✅ AppID 1905221791 | ✅ AppID 1905222557 |
| **飞书** | ✅ | ✅ (流式卡片已修) | ✅ (长连接，无白名单) | ✅ cli_aad19b0b53b89d24 |
| **微信官方 (iLink)** | ✅ **已绑定** (970ed7c8f462-im-bot) | 已装未绑 | 🗑️ 已移除 (2026-07-23) | ✅ 已绑定（占主号，待移除） |
| **渠道总数** | 3 (全活) | 2 (全活) + 1 未绑 | 2 (全活) | 3 (全活，微信待下架) |

> ⚠️ **ClawChat 微信小程序已于 2026-07-23 全队废弃**——K60 已删除，其余设备从未配置。

### QQ 白名单联动

四台 QQ bot 同在家庭宽带下，出口同为 **117.186.4.220**。宽带重拨后 IP 变化，需在 [qq.qq.com](https://qq.qq.com) 同时更新四个 AppID 的白名单：

```bash
# 查当前出口 IPv4
curl -4 -s https://api.ip.sb/ip

# 四个 AppID
K60:     102825839
MIX 2S:  1903080675
Note 7:  1905221791
Note 4X: 1905222557
```

白名单加好后无需重启，插件每分钟自动重试，约 1 分钟自愈。

---

## 六、AI 模型供应商

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **供应商** | deepseek | deepseek | deepseek | qwen-portal |
| **模型** | deepseek-v4-flash | deepseek-v4-flash | deepseek-v4-flash | coder-model (OAuth) |
| **响应质量** | ⭐⭐⭐ 最新最快 | ⭐⭐⭐ 标准 | ⭐⭐⭐ 标准 | ⭐⭐ 指令跟随偏差 |
| **认证方式** | API Key | API Key | API Key | Qwen OAuth 登录 |

---

## 七、角色定位与可靠性

| 设备 | 角色 | 定位说明 |
|---|---|---|
| **K60** | 🥇 **随身主力机** | 旗舰性能 + 蜂窝移动性，随身携带；QQ + 飞书 + 微信 iLink 三渠道全活；Termux:API 支持拍照/传感器；唯一有蜂窝冗余的设备 |
| **MIX 2S** | 🔍 **待重新定位** | 骁龙 845 次旗舰，加固最简单；当前 QQ + 飞书双活；后续需全面分析再确定方向 |
| **Note 7** | 🥈 **家里轻量任务机** | QQ + 飞书双活（微信已移除）；骁龙 660 冷启动 40-60s；轻量任务专用，禁止并发 CLI |
| **Note 4X** | 🏅 **家里长期备机** | QQ + 飞书双活（微信待移除）；3GB RAM 极限运行但韧性极强；放在家里作为稳定后备 |

### 重启后自愈能力

| 设备 | sshd | gateway | Tailscale | QQ | 飞书 | 微信 iLink | 全部通过 |
|---|---|---|---|---|---|---|---|
| K60 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| MIX 2S | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ |
| Note 7 | ✅ | ✅ | ✅ | ✅ | ✅ | — (已移除) | ✅ |
| Note 4X | ✅ | ✅ | N/A | ✅ | ✅ | ✅ (待移除) | ✅ |

---

## 八、风险矩阵

| 风险项 | K60 | MIX 2S | Note 7 | Note 4X | 应对措施 |
|---|---|---|---|---|---|
| **IP 漂移断连** | 🔴 高 (蜂窝+WiFi 切换) | 🟢 低 | 🟢 低 | 🟢 低 | 固定 LAN + Tailscale 冗余 |
| **OOM 风险** | 🟢 极低 (16GB) | 🟢 低 (6GB) | 🟡 中 (6GB+弱 SoC) | 🔴 高 (3GB) | Note 4X 禁并发 CLI；runit 15s 自愈 |
| **断电后自启** | ✅ | ✅ | ✅ | ✅ (已补装 Boot) | Termux:Boot 全队安装 |
| **SSH 不可达** | 🟢 双路径 | 🟢 双路径 | 🟢 双路径 | 🟡 单路径 | Note 4X 依赖路由器 MAC 绑定 |
| **QQ 白名单过期** | 🔗 四台联动 | 🔗 四台联动 | 🔗 四台联动 | 🔗 四台联动 | `curl ip.sb` → q.qq.com 四台同更 |
| **Node 版本退化** | 🟢 仓库版锁定 | 🟡 仓库撤版 | 🟡 仓库撤版 | 🔴 手动 hold | Note 4X 禁止 `apt upgrade nodejs` |
| **libsqlite 不兼容** | 🟢 3.53.3 | 🟢 3.53.3 | 🟢 3.53.3 | 🟡 3.53.0 | 升级 OpenClaw 前先 `apt install --only-upgrade libsqlite` |

---

## 九、运维速查

### 一键验证四台设备

```bash
# 服务状态
ssh -p 8022 u0_a129@192.168.1.23 'sv status openclaw'   # K60
ssh -p 8022 u0_a129@192.168.1.20 'sv status openclaw'   # MIX 2S
ssh -p 8022 u0_a171@192.168.1.24 'sv status openclaw'   # Note 7
ssh -p 8022 u0_a129@192.168.1.19 'sv status openclaw'   # Note 4X

# HTTP 探活
curl -s http://127.0.0.1:18789/health  # 各机本地执行

# Agent E2E
openclaw agent --agent main --message "只回复OK"  # 各机本地执行
```

### 升级金丝雀流程

```
① K60 (旗舰，先趟) → 验证四连
② MIX 2S           → 验证四连
③ Note 7           → 验证四连
④ Note 4X (最后，有坑先暴露)
```

### 关键命令速查

| 操作 | 命令 |
|---|---|
| 查出口 IP | `curl -4 -s https://api.ip.sb/ip` |
| 查 QQ AppID | `node -e "console.log(require(process.env.HOME+'/.openclaw/openclaw.json').channels.qqbot.appId)"` |
| 查 OpenClaw 版本 | `openclaw --version` |
| 查 Node 版本 | `node --version` |
| 查 SQLite 版本 | `node -e "const s=require('node:sqlite');console.log(new s.DatabaseSync(':memory:').prepare('select sqlite_version() v').get().v)"` |
| 查渠道连接状态 | `openclaw channels status --probe` (⚠️ Note 4X 会卡死，改 grep 日志) |
| 日志路径 | `$PREFIX/var/log/sv/openclaw/current` |
| 重启服务 | `sv restart openclaw` (需先 `export SVDIR=$PREFIX/var/service`) |

---

## 十、总评

| 维度 | 🥇 最强 | 🥈 次之 | 🥉 第三 | 🏅 最弱 |
|---|---|---|---|---|
| **算力** | K60 (8+ Gen1) | MIX 2S (845) | Note 7 (660) | Note 4X (625) |
| **内存** | K60 (16GB) | MIX 2S / Note 7 (6GB) | — | Note 4X (3GB) |
| **系统版本** | K60 (A15) | MIX 2S / Note 7 (A10) | — | Note 4X (A7) |
| **渠道完整度** | Note 4X (3 全活) | K60 (4 含 1 未绑) | MIX 2S / Note 7 (3 含 1 未绑) | — |
| **网络冗余** | K60 (TS+热点) | MIX 2S / Note 7 (TS+LAN) | — | Note 4X (仅 LAN) |
| **运维简易度** | MIX 2S / Note 7 (加固最少) | K60 (HyperOS 复杂) | Note 4X (无 root+无 TS) | — |
| **稳定性** | Note 7 (四链路全验证) | K60 / MIX 2S | Note 4X (3GB 受限) | — |

**一句话总结：** K60 是随身旗舰主力（三渠道全活+蜂窝冗余+58 技能），MIX 2S 待重新定位，Note 7 是家里轻量任务机（双活，SD660 禁并发 CLI），Note 4X 是家里长期备机（双活，微信待下架）。机队最大运维痛点不是单机稳定性，而是 **QQ 白名单四台联动**——宽带重拨一次需同时更新四个 AppID。

---

# 各设备独立篇章

## K60 — 随身主力机 `mondrian`

> 定位：**随身携带的核心旗舰设备**，唯一有蜂窝网络冗余的移动节点。
> 渠道：QQ (102825839) + 飞书 + 微信 iLink (970ed7c8f462-im-bot)

### 硬件档案

| 项目 | 参数 | 说明 |
|---|---|---|
| **SoC** | 骁龙 8+ Gen 1 (SM8475, 4nm) | 1×3.0GHz X2 + 3×2.5GHz A710 + 4×1.8GHz A510 |
| **GPU** | Adreno 730 | 旗舰图形性能 |
| **RAM** | 16GB LPDDR5 | 全队最大，实测可用 ~7.7GB |
| **存储** | 462GB (125GB 已用，337GB 空闲) | UFS 3.1，无 microSD |
| **屏幕** | 6.67" AMOLED 3200×1440 120Hz | 2K 高刷屏 |
| **电池** | 5500mAh，67W 有线 + 30W 无线 | 健康度 GOOD，循环 540 次 |
| **系统** | Android 15 / HyperOS V816 | 全队唯一仍在官方支持的设备 |
| **尺寸/重量** | 162.8×75.4×8.6mm / 199g | — |
| **特殊硬件** | 屏下指纹、红外、NFC、立体声扬声器、VC 均热板 | 旗舰级散热 |

### 实时运行状态（2026-07-23 实测）

```
运行时间:   4 天 22 小时
CPU 负载:   0.75 (1min) / 0.94 (5min) / 1.52 (15min)
内存:       15.5GB 总量，7.7GB 可用（~50% 空闲）
Swap:       16.8GB 总量，4.3GB 已用（~25%）
存储:       462GB 总量，125GB 已用（28%）
电池:       已插电充电中，100%，35.6°C
gateway:    RSS 362MB，VmSwap 0KB，12 线程
日志大小:   3.7MB
```

### 软件栈

```
OpenClaw:   2026.7.1-2 (0790d9f)
Node.js:    v24.17.0 (LTS, 仓库原生合规版)
V8:         13.6.233.17
libsqlite:  3.53.3 (远超 3.51.3 安全阈值)
Termux:     F-Droid 0.118.0
Python:     3.14.6 + numpy 2.4.4
git:        2.55.0
SSH:        OpenSSH 10.4p1
```

### 网络

| 路径 | 地址 | 状态 |
|---|---|---|
| **Tailscale** | 100.118.60.29 | ✅ |
| **家庭 WiFi** | 192.168.1.23 (LAN) | 🔀 当前不在家庭网络 |
| **蜂窝网络** | 出口 IP 117.136.120.99 | ✅ 当前使用中 |
| **热点网关** | PC 默认网关（自动发现） | 备用回退 |

### 配置分析

| 项目 | 当前值 | 评价 |
|---|---|---|
| **默认模型** | `alibaba-model-studio/qwen3.7-max-preview` | ⚠️ 应改为 `deepseek/deepseek-v4-flash` |
| **已配置模型** | 35 个 | ❌ 严重膨胀，建议精简到 5 个 |
| **废弃模型** | `deepseek-chat`（已于 2026-07-24 退役） | ❌ 需立即删除 |
| **plugins.allow** | deepseek, feishu, qianfan, qqbot, qwen, memory-core, openclaw-weixin | ✅ 已清理 ClawChat |
| **活跃渠道** | qqbot + feishu + openclaw-weixin | ✅ 三通道全活 |

### 📦 已安装技能（58 个，33MB）

**来源：** `~/.openclaw/workspace/skills/`，通过 SkillHub 社区和技能包安装。

#### 金融投研类

| 技能 | 来源 | 版本 |
|---|---|---|
| stocks | community | — |
| finance-radar | community | — |
| fund-realtime-scraper | community | — |
| joinquant | pack:finance-quant-backtesting | — |
| quant-strategy | pack:finance-quant-backtesting | — |
| quant | pack:finance-quant-backtesting | — |
| quant-backtest-strategy | pack:finance-quant-backtesting | — |
| stock-strategy-backtester | pack:finance-quant-backtesting | — |
| openclaw-backtester | pack:finance-quant-backtesting | — |

#### 风控合规类

| 技能 | 来源 | 版本 |
|---|---|---|
| sec | community | — |
| fintech-risk-control | pack:finance-risk-assessment | — |
| riskofficer | pack:finance-risk-assessment | — |
| a-share-risk-alert | pack:finance-risk-assessment | — |
| pe-compliance-expert-pro | pack:finance-risk-assessment | — |
| position-risk-manager | pack:finance-risk-assessment | — |
| quant-risk-dashboard | pack:finance-risk-assessment | — |
| finance-risk-assessment | pack:finance-risk-assessment | — |

#### 工具类

| 技能 | 来源 | 版本 |
|---|---|---|
| find-skill-skillhub | community | v1.0.2 |
| tianji-business-search | community | v1.0.9 |

#### 插件内置技能

此外，以下插件自带技能（位于 `node_modules/@openclaw/` 下）：

- **飞书插件：** feishu-doc、feishu-wiki、feishu-perm、feishu-drive
- **QQ 插件：** qqbot-channel、qqbot-remind、qqbot-media

**技能存储：** 58 个 SKILL.md，总大小 33MB。部分技能含 Python `.venv` 虚拟环境（如 stocks），跨设备同步时需重建 venv。

### 🟢 优势 / 🟡 待优化 / 🚀 潜力

| 优势 | 待优化 | 潜力 |
|---|---|---|
| 全队最强性能，唯一可并发 CLI | 默认模型应切 deepseek-v4-flash | 本地小模型（Python+numpy+16GB） |
| 蜂窝+WiFi 双网络，移动不掉线 | 35 模型→精简到 5 个 | 边缘计算节点 |
| Termux:API 拍照/GPS/通知 | 电池 100% 常充需智能插座 | 手机眼（唯一有摄像头） |
| Python 3.14+numpy，技能生态最丰富 | 无监控告警 | 配置 Git 管理中枢 |
| Node LTS 仓库版，升级路径最顺 | IP 漂移导致 QQ 白名单失效 | 飞书告警中枢 |

---

## Note 7 — 家里轻量任务机 `lavender`

> 定位：**放在家里跑简单任务**。QQ (1905221791) + 飞书双活，微信已移除。
> 特点：骁龙 660 冷启动慢但长期稳定，**全队最重要的纪律——禁止并发 CLI**。

### 硬件档案

| 项目 | 参数 | 说明 |
|---|---|---|
| **SoC** | 骁龙 660 (SDM660, 14nm) | 4×2.2GHz Kryo 260 Gold + 4×1.8GHz Silver |
| **GPU** | Adreno 512 | 中端图形性能 |
| **RAM** | 6GB LPDDR4X | 实测可用 ~3.0GB |
| **存储** | 50GB (13GB 已用，37GB 空闲) | eMMC 5.1，支持 microSD |
| **屏幕** | 6.3" IPS LCD 2340×1080 | 19.5:9，Gorilla Glass 5 双面 |
| **电池** | 4000mAh，18W QC4 快充 | ⚠️ 无 termux-api，无法远程监测 |
| **系统** | Android 10 / MIUI 12.5.7 (V125) | EOL 自 2021/10，不再有安全更新 |

### 实时运行状态（2026-07-23 实测）

```
运行时间:   4 天 17 小时
CPU 负载:   8.12/8.17/7.65 → 孤儿进程清理后预期恢复 < 1.0
内存:       5.6GB 总量，3.0GB 可用（~54% 空闲）
Swap:       2.5GB 总量，666MB 已用（~25%）
存储:       50GB 总量，13GB 已用（26%）
电池:       ⚠️ 无 termux-api，盲区
gateway:    RSS 319MB，VmSwap 0KB，12 线程
日志大小:   7.3MB（K60 的 2 倍）
USB 调试:   ✅ adb 已启用
```

### 软件栈

```
OpenClaw:   2026.7.1-2 (0790d9f)
Node.js:    v26.4.0 (仓库撤版前安装)
libsqlite:  3.53.3
Termux:     F-Droid 0.118.0
Python:     3.14.6 (无 numpy)
git:        2.55.0
缺失:       termux-api, vim/nano
```

### 网络

| 路径 | 地址 | 状态 |
|---|---|---|
| **Tailscale** | 100.91.94.44 | ✅ |
| **家庭 WiFi** | 192.168.122.238 (LAN) | ✅ |
| **出口 IP** | 117.136.120.99 | 与 K60 同出口 |
| **网关延迟** | 27-49ms | 正常 |

> ⚠️ LAN IP 是 `192.168.122.238`（非直觉的 192.168.1.x），`sshnote7` 脚本中已正确配置。

### 配置分析

| 项目 | 当前值 | 评价 |
|---|---|---|
| **已配置模型** | 11 个 | 🟢 合理 |
| **plugins.allow** | feishu, qqbot, deepseek | ✅ 极简 |
| **活跃渠道** | qqbot + feishu | ✅ 双活 |
| **残留条目** | 无 | ✅ 全队最干净 |

### 📦 已安装技能（1 个 + 插件内置）

| 技能 | 位置 | 说明 |
|---|---|---|
| **bailian-cli** | `~/.openclaw/skills/bailian-cli` → symlink 到 `~/.agents/skills/` | 阿里百炼 CLI 管理工具 |

**插件内置技能（7 个）：**

| 技能 | 来源插件 |
|---|---|
| qqbot-channel、qqbot-remind、qqbot-media | @openclaw/qqbot |
| feishu-doc、feishu-wiki、feishu-perm、feishu-drive | @openclaw/feishu |

### 🔴 核心约束：禁止并发 CLI

一次 `openclaw models list` 诊断产生了 **33.8% CPU + 267MB RAM** 孤儿进程，CPU load 冲到 8+。

```
正常:   gateway 1 进程，~319MB，~7% CPU
并发:   +1 CLI → ~50-270MB，~3-34% CPU
3GB 机: 双 CLI → gateway OOM 连坐（runit 15s 自愈）
6GB 机: 双 CLI → CPU 满载但幸存
```

**规则：** ✅ `sv status`/`curl`/`tail`/`ps` · ❌ `models list`/`channels probe`/`agent`

### 🟢 优势 / 🟡 待优化

| 优势 | 待优化 |
|---|---|
| 配置极简（3 plugins / 11 models） | 安装 termux-api（电池盲区） |
| A10 天然免疫 phantom killer | 安装 vim/nano（紧急排障用） |
| 全链路自动恢复全验证通过 | 日志轮转（7.3MB，2 倍于 K60） |
| 6GB RAM 日常 swap 仅 666MB | Node 26.4.0 升级风险 |
| USB 调试已启用且验证 | Doze 白名单待 adb 确认 |

---

## MIX 2S — 待重新定位 `polaris`

> 定位：**待全面分析后重新规划**。当前 QQ (1903080675) + 飞书双活。
> 状态：设备离线（2026-07-23），需上线后进行深度审计。

| 项目 | 参数 |
|---|---|
| SoC | 骁龙 845 (10nm) |
| RAM | 6GB LPDDR4x |
| 系统 | Android 10 / MIUI 12.5.1 |
| Tailscale | 100.104.72.125 |
| 微信 iLink | 已装未绑（待移除） |
| 待办 | 上线后按 K60/Note 7 模板全面分析 + 技能盘点 |

---

## Note 4X — 家里长期备机 `mido`

> 定位：**放在家里作为长期稳定后备**。QQ (1905222557) + 飞书双活，微信待移除。

| 项目 | 参数 |
|---|---|
| SoC | 骁龙 625 (14nm) |
| RAM | 3GB LPDDR3（禁止并发 CLI） |
| 系统 | Android 7.0 / MIUI 11 |
| Tailscale | ❌ 不支持 |
| Node | 26.4.0 手动 deb + apt-mark hold |
| libsqlite | 3.53.0（全队最低，升级前必须先升） |
| 微信 iLink | ✅ 已绑定主号（待移除） |
| 待办 | 上线后移除微信 + 全面分析 + 技能盘点 |

---

# 跨设备技能同步

## 技能存储对比

| 维度 | K60 | Note 7 |
|---|---|---|
| **workspace skills** | 58 个（33MB） | 0 |
| **用户 skills** | 无 | 1 个（bailian-cli, symlink） |
| **插件内置** | 飞书 4 + QQ 3 = 7 个 | 飞书 4 + QQ 3 = 7 个 |
| **安装源** | SkillHub 社区 + 技能包 | 手动（symlink） |

## 快速同步方案

### 方案一：tar + scp（最直接，一次性的）

```bash
# Step 1: K60 打包
ssh -p 8022 u0_a129@100.118.60.29 \
  'tar czf ~/skills-backup.tar.gz -C ~/.openclaw/workspace skills/'

# Step 2: PC 中继拉取
scp -P 8022 u0_a129@100.118.60.29:~/skills-backup.tar.gz /tmp/

# Step 3: 推到目标设备
scp -P 8022 /tmp/skills-backup.tar.gz u0_a171@100.91.94.44:~/

# Step 4: 目标设备解压
ssh -p 8022 u0_a171@100.91.94.44 \
  'mkdir -p ~/.openclaw/workspace && tar xzf ~/skills-backup.tar.gz -C ~/.openclaw/workspace/'

# Step 5: 清理
ssh -p 8022 u0_a129@100.118.60.29 'rm ~/skills-backup.tar.gz'
ssh -p 8022 u0_a171@100.91.94.44 'rm ~/skills-backup.tar.gz'
```

**注意：** 部分技能含 Python `.venv` 虚拟环境，跨设备后路径可能不对。同步后运行以下命令重建：

```bash
cd ~/.openclaw/workspace/skills
for d in */; do
  if [ -f "$d/requirements.txt" ]; then
    echo "重建 $d 的 venv..."
    cd "$d" && python -m venv --clear .venv && .venv/bin/pip install -r requirements.txt && cd ..
  fi
done
```

### 方案二：Git 仓库（推荐，可持续同步）

```bash
# Step 1: K60 上初始化 git 仓库
ssh -p 8022 u0_a129@100.118.60.29 '
  cd ~/.openclaw/workspace/skills
  git init
  git add -A
  git commit -m "K60 skills snapshot $(date +%Y%m%d)"
'

# Step 2: 推送到 GitHub
# （在 K60 上配置 remote 然后 push，或 scp .git 目录到 PC 再 push）

# Step 3: 其他设备 clone
ssh -p 8022 u0_a171@100.91.94.44 '
  mv ~/.openclaw/workspace/skills ~/.openclaw/workspace/skills.bak 2>/dev/null
  git clone git@github.com:DeXuan/openclaw-skills.git ~/.openclaw/workspace/skills
'

# 后续同步只需 git pull
```

**优点：** 版本可追溯、增量同步、多设备统一管理。

### 方案三：rsync（最优雅，适合频繁同步）

```bash
# 从 K60 推到 Note 7
ssh -p 8022 u0_a171@100.91.94.44 \
  "mkdir -p ~/.openclaw/workspace/skills"

rsync -avz --delete \
  -e "ssh -p 8022" \
  u0_a129@100.118.60.29:~/.openclaw/workspace/skills/ \
  u0_a171@100.91.94.44:~/.openclaw/workspace/skills/
```

**注意：** Termux 默认无 rsync，需 `pkg install rsync`。`--delete` 会删除目标设备多余的技能。

## 建议

- **一次性迁移：** 方案一（tar + scp），简单可靠
- **长期维护：** 方案二（Git 仓库），技能变更可追溯
- **主力→备机日常同步：** 方案三（rsync），增量快速

技能同步后，重启 gateway 即可加载新技能：`sv restart openclaw`
