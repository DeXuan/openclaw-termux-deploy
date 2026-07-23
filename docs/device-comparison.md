# OpenClaw 四台手机机队全方位对比

> 最后更新：2026-07-23 | 全队定版：OpenClaw 2026.7.1-2
>
> **本次更新：** K60 + Note 7 深度分析、渠道/角色数据刷新、新增各设备独立章节、ClawChat 全队废弃

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

**一句话总结：** K60 是随身旗舰主力（三渠道全活+蜂窝冗余），MIX 2S 待重新定位，Note 7 是家里轻量任务机（双活，SD660 禁并发 CLI），Note 4X 是家里长期备机（双活，微信待下架）。机队最大运维痛点不是单机稳定性，而是 **QQ 白名单四台联动**——宽带重拨一次需同时更新四个 AppID。

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

**已安装的关键包：** curl, wget, vim, nano, python, python-numpy, git, termux-api (v0.59.1), termux-services (runit)

### 网络

| 路径 | 地址 | 状态 |
|---|---|---|
| **Tailscale** | 100.118.60.29 | ✅ |
| **家庭 WiFi** | 192.168.1.23 (LAN) | 🔀 当前不在家庭网络 |
| **蜂窝网络** | 出口 IP 117.136.120.99 | ✅ 当前使用中 |
| **热点网关** | PC 默认网关（自动发现） | 备用回退 |

**连接策略：** `sshk60` 脚本 Tailscale 优先 → 热点网关自动回退。作为移动设备，IP 会随网络环境变化——这是核心特性，也是运维上最需要关注的点。

### 配置分析

| 项目 | 当前值 | 评价 |
|---|---|---|
| **默认模型** | `alibaba-model-studio/qwen3.7-max-preview` | ⚠️ 应改为 `deepseek/deepseek-v4-flash` |
| **已配置模型** | 35 个 | ❌ 严重膨胀，建议精简到 5 个 |
| **废弃模型** | `deepseek-chat`（已于 2026-07-24 退役） | ❌ 需立即删除 |
| **plugins.allow** | deepseek, feishu, qianfan, qqbot, qwen, memory-core, openclaw-weixin | ✅ 已清理 ClawChat |
| **活跃渠道** | qqbot + feishu + openclaw-weixin | ✅ 三通道全活 |
| **残留条目** | `channels.openclawwechat` (enabled=undefined) | 🟡 待清理 |

### 安全加固

| 项目 | 状态 |
|---|---|
| phantom process killer | ✅ 已关 + `device_config` 锁 persistent |
| 权限自动撤销 | ✅ 已禁 |
| Doze 白名单 | ✅ termux + tailscale 已加 |
| Termux:Boot | ✅ 已装，重启自启链路正常 |
| SSH 免密 | ✅ PC 端 key 已部署 |

### 🟢 优势

- **全队最强性能**——8 核旗舰 SoC + 16GB RAM，唯一能同时跑多个 CLI 实例不死机的设备
- **移动性**——蜂窝 + WiFi 双网络，家庭宽带断了也能用，出差/通勤是唯一在线的 bot
- **传感器能力**——Termux:API 已装，支持拍照、GPS 定位、通知推送（其余三台做不到）
- **Python 生态**——numpy 已装，可以跑数据分析、定时任务、本地小模型
- **软件栈合规**——Node LTS 仓库版、libsqlite 3.53.3，升级路径最顺畅
- **存储充裕**——337GB 空闲，可以部署额外服务
- **系统最新**——Android 15 HyperOS，唯一仍在官方支持的设备

### 🟡 待优化

1. **默认模型**：应切到 `deepseek/deepseek-v4-flash`，删除退役的 `deepseek-chat`
2. **模型膨胀**：35 个已配置模型 → 精简到 5 个（主力 + 2 fallback + 1 视觉 + 1 应急）
3. **openclawwechat 残留**：channel 条目待清理
4. **Swap 偏高**：4.3GB swap 使用可能与 35 个模型元数据有关，精简后应下降
5. **电池老化风险**：540 循环 + 100% 常充 → 建议配智能插座做充放电管理
6. **无监控告警**：IP 变了没人知道，需加飞书告警
7. **IP 漂移**：蜂窝/WiFi 切换导致 QQ 白名单失效，需自动检测+通知

### 🚀 潜力

- **本地小模型** — Python + numpy + 16GB RAM + 337GB 存储，可跑 llama.cpp/ollama 离线推理
- **边缘计算节点** — 8 核旗舰 SoC 可承担数据抓取、预处理、轻量 API
- **手机眼** — Termux:API 拍照 + GPS，唯一能做视觉感知的设备
- **配置 Git 管理** — git 已装，可做全队 openclaw.json 版本控制中枢
- **飞书告警中枢** — Python + cron 实现全队健康监控 + 自动通知

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
| **尺寸/重量** | 159.2×75.2×8.1mm / 186g | USB-C + 3.5mm 耳机孔 |
| **特殊硬件** | 后置指纹、红外、48MP 主摄 (Samsung GM1) | 首款 48MP Redmi |

### 实时运行状态（2026-07-23 实测）

```
运行时间:   4 天 17 小时
CPU 负载:   8.12 (1min) / 8.17 (5min) / 7.65 (15min) ⚠️ 诊断命令残留导致
            → 孤儿进程清理后预期恢复 < 1.0
内存:       5.6GB 总量，3.0GB 可用（~54% 空闲）
Swap:       2.5GB 总量，666MB 已用（~25%）
存储:       50GB 总量，13GB 已用（26%）
电池:       ⚠️ 无 termux-api，无法远程监测
gateway:    RSS 319MB，VmSwap 0KB，12 线程
日志大小:   7.3MB（K60 的 2 倍）
USB 调试:   adb 已启用 ✅ (getprop sys.usb.config = adb)
```

### 软件栈

```
OpenClaw:   2026.7.1-2 (0790d9f)
Node.js:    v26.4.0 (仓库撤版前安装，非 LTS)
V8:         14.6.202.34
libsqlite:  3.53.3 (远超 3.51.3 安全阈值)
Termux:     F-Droid 0.118.0
Python:     3.14.6 (无 numpy)
git:        2.55.0
SSH:        OpenSSH 10.4p1
```

**已安装关键包：** curl, git, python, python-pip, termux-services (runit)
**未安装：** termux-api（无法远程监测电池）、vim/nano（无终端编辑器，紧急排障受限）

### 网络

| 路径 | 地址 | 状态 |
|---|---|---|
| **Tailscale** | 100.91.94.44 | ✅ |
| **家庭 WiFi** | 192.168.122.238 (LAN) | ✅ 当前使用中 |
| **出口 IP** | 117.136.120.99 | 与 K60 同出口 |
| **网关延迟** | 27-49ms (到 192.168.1.1) | 正常 |

> ⚠️ **LAN IP 注意：** Note 7 的局域网 IP 是 `192.168.122.238`（非直觉的 192.168.1.x 网段），
> 这是路由器 NAT 拓扑决定的，`sshnote7` 脚本中已正确配置。

### 配置分析

| 项目 | 当前值 | 评价 |
|---|---|---|
| **默认模型** | 待确认（models list 在 SD660 上太慢） | — |
| **已配置模型** | 11 个 | 🟢 合理，远优于 K60 的 35 个 |
| **plugins.allow** | feishu, qqbot, deepseek | ✅ 极简，无冗余 |
| **plugins.entries (enabled)** | deepseek, feishu, qqbot | ✅ 仅 3 个 |
| **活跃渠道** | qqbot + feishu | ✅ 双活，微信已彻底移除 |
| **残留条目** | 无 | ✅ config 干净 |

### 安全加固

| 项目 | 状态 |
|---|---|
| phantom process killer | ✅ 天然免疫 (Android 10) |
| 权限自动撤销 | ✅ 无此机制 (Android 10) |
| Doze 白名单 | ⚠️ 待确认（dumpsys 需 adb 权限检查） |
| Termux:Boot | ✅ 已装，`pm list` 可见 |
| Tailscale App | ✅ 已装，`pm list` 可见 |
| USB 调试 | ✅ `getprop sys.usb.config` = adb |
| MIUI 12.5 注意 | 普通 USB 调试无 WRITE_SECURE_SETTINGS，改 settings 需「USB 调试（安全设置）」（需 SIM + 小米账号） |

### 🟢 优势

- **配置极简**——plugins.allow 仅 3 项，11 个模型（全队最干净），没有残留条目
- **硬件可靠**——Gorilla Glass 5 双面 + 金属中框，做工扎实，适合 24/7 运行
- **系统简单**——Android 10 天然免疫 phantom killer 和权限自动撤销，加固只有 Doze 一项
- **全链路验证**——四链路自动恢复（sshd/gateway/Tailscale/双渠道）全部实测通过
- **USB 调试已确认**——`getprop sys.usb.config` 含 adb，排查时不用怀疑"开关没开"
- **6GB RAM**——比 Note 4X 多一倍，日常运行时 swap 仅用 666MB，内存压力不大

### 🔴 核心约束：禁止并发 CLI

**这是 Note 7 最重要的运维纪律。** 实测中，一次 `openclaw models list` 诊断命令产生了一个孤儿进程，消耗了 **33.8% CPU + 267MB RAM**。加上 gateway 自身的 6.9% CPU + 319MB，两个 openclaw 进程就让 8 核 SD660 的 load average 冲到 8+。

```
正常状态:   gateway 仅 1 个进程，~319MB RSS，~7% CPU
并发 CLI:   每个额外 CLI 实例 ~50-270MB RSS，~3-34% CPU
3GB 机(Note 4X): 双 CLI → gateway 被 OOM 连坐 (runit 15s 自愈)
6GB 机(Note 7):  双 CLI → CPU 满载但侥幸存活
```

**规则：**
- ✅ SSH 进来可以做：`sv status`、`curl` 探活、`tail` 日志、`ps` 查看进程
- ❌ 绝对不能做：`openclaw models list`、`openclaw channels status --probe`、`openclaw agent`
- ⚠️ 必须做 CLI 操作时：先 `sv down openclaw` 停掉 gateway，操作完立刻 `sv up`

### 🟡 待优化

1. **安装 termux-api**——无法远程监测电池，对 24/7 设备是盲区。安装后可用 `termux-battery-status` 监测健康度
2. **安装 vim 或 nano**——紧急排障时没有终端编辑器，改配置文件很麻烦（`pkg install vim`）
3. **日志轮转**——7.3MB 日志（K60 的 2 倍），建议配置 svlogd 轮转参数
4. **Node 版本风险**——v26.4.0 从仓库撤版前安装，升级 OpenClaw 时可能需要手动 deb
5. **LAN IP 网段特殊**——192.168.122.238 不在常见 192.168.1.x 网段，文档标注避免混淆
6. **Doze 白名单待确认**——dumpsys 在 MIUI 12.5 上可能受限，建议 adb 重新确认

### 🚀 潜力

- **Python 脚本引擎**——Python 3.14 + pip 已装，可跑定时任务、数据抓取、健康上报
- **git 配置同步**——git 已装，可作为机队配置仓库的拉取节点
- **轻量定时任务**——SD660 跑 gateway 仅用 ~7% CPU，剩余算力可承担 cron 定时任务
- **家里设备优势**——固定位置 + 固定网络，适合做日志聚合、健康检查中枢

---

## MIX 2S — 待重新定位 `polaris`

> 定位：**待全面分析后重新规划**。当前 QQ (1903080675) + 飞书双活。
> 状态：设备离线（2026-07-23），需上线后进行深度审计。

### 已知信息速览

| 项目 | 参数 |
|---|---|
| SoC | 骁龙 845 (10nm) |
| RAM | 6GB LPDDR4x |
| 系统 | Android 10 / MIUI 12.5.1 |
| 加固 | 免 phantom killer (A10 免疫)，仅需 Doze 白名单 |
| Tailscale | 100.104.72.125 |
| 微信 iLink | 已装未绑（待移除） |
| 特殊注意 | MAC 随机化 (AE:1A:3A:F6:F9:0C)，路由器绑定需注意 |
| 待办 | 上线后参照 K60/Note 7 模板进行全面分析 |

---

## Note 4X — 家里长期备机 `mido`

> 定位：**放在家里作为长期稳定后备**。QQ (1905222557) + 飞书双活，微信待移除。
> 特点：全队最弱硬件 (SD625/3GB)，但三渠道全活运行时间最长，韧性标杆。

### 已知信息速览

| 项目 | 参数 |
|---|---|
| SoC | 骁龙 625 (14nm) |
| RAM | 3GB LPDDR3（全队最小，禁止并发 CLI） |
| 系统 | Android 7.0 / MIUI 11（全队最老） |
| Tailscale | ❌ 不支持 (Android 7) |
| Node | 26.4.0 **手动 deb + apt-mark hold**（全队唯一，升级风险最高） |
| libsqlite | 3.53.0（全队最低，升级 OpenClaw 前必须先升） |
| 微信 iLink | ✅ 已绑定主号（**待移除**——设备下次上线时执行） |
| 特殊注意 | 电源键不灵敏，靠 Power Button Tile 磁贴重启；无 root 无法远程关机；仅 LAN 单路径可达 |
| 待办 | 上线后移除微信 iLink + 全面分析 |
