# OpenClaw 安卓手机机队

> 最后更新：2026-07-23 | 全队定版：OpenClaw 2026.7.1-2
>
> **全队就绪：** 4 机 SSH 互信 · crond 自愈全覆盖 · TS 三机互联 · 59 技能三机同步 · QQ+飞书全队双活

## 机队概览

四台退役安卓手机组成 OpenClaw 机器人机队，Termux + runit 保活，K60/Note 7/MIX 2S 三台 Tailscale 组网，Note 4X 仅 LAN。QQ + 飞书全队双活，K60 额外保留微信 iLink。4 机 SSH 全互信 + crond 自愈监控全覆盖。

| 设备 | 代号 | SoC | RAM | 系统 | 角色 | 渠道 |
|---|---|---|---|---|---|---|
| **K60** | mondrian | 8+ Gen 1 | 16GB | A15 | 🥇 随身主力 | QQ + 飞书 + 微信 |
| **Note 7** | lavender | 660 | 6GB | A10 | 🥈 家里轻量 | QQ + 飞书 |
| **MIX 2S** | polaris | 845 | 6GB | A10 | 🥉 稳定副机 | QQ + 飞书 |
| **Note 4X** | mido | 625 | 3GB | A7 | 🏅 韧性备机 | QQ + 飞书 |

```
TS 组网: K60 · Note 7 · MIX 2S  |  Note 4X 仅 LAN (A7不支持)
4 机 SSH 全互信 ✅  crond 全队覆盖 ✅  自愈监控 ✅  IP 漂移告警 ✅
```

---

# 设备详情

## K60 — 随身主力机

### 硬件

| 项目 | 参数 |
|---|---|
| SoC / RAM / 存储 | 骁龙 8+ Gen 1 (4nm) / 16GB LPDDR5 / 462GB UFS 3.1 |
| 电池 | 5500mAh，健康度 GOOD，540 循环，100% 插电中 |
| 系统 | Android 15 / HyperOS V816（全队唯一仍在官方支持） |
| 特殊硬件 | 屏下指纹、红外、NFC、VC 均热板 |
| 传感器 | 摄像头、GPS、通知（Termux:API v0.59.1 已装） |

### 运行状态 (2026-07-23)

```
CPU:  load 3.17 (70% 空闲)    内存: 15.5GB 总 / 6.9GB 可用
Swap: 16.8GB 总 / 4.3GB 用    gateway: RSS 349MB / 12 线程
磁盘: 125GB 已用 (28%) / 335GB 空闲    日志: 3.7MB
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v24.17.0 LTS | libsqlite 3.53.3
Python 3.14.6 (54 包, 含 numpy) | git 2.55.0 | cronie
```

### 网络

| 路径 | 地址 | 说明 |
|---|---|---|
| Tailscale | 100.118.60.29 | 首选通道 |
| WiFi | 192.168.1.23 | 家庭网络（当前不在） |
| 蜂窝 | 出口 117.136.120.99 | 移动时使用 |
| 热点网关 | PC 默认网关 | `sshk60` 自动回退 |
| SSH 互信 | ↔ Note 7 (TS) · MIX 2S (TS+LAN) · Note 4X (LAN) | ✅ |

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 102825839 |
| 飞书 | ✅ |
| 微信 iLink | ✅ 970ed7c8f462-im-bot |
| 默认模型 | alibaba-model-studio/qwen3.7-max-preview |
| 实际主力 | alibaba-model-studio/qwen3.7-max-2026-06-08（百炼免费额度） |

### 技能

| 位置 | 数量 | 类别 |
|---|---|---|
| `workspace/skills/` | 58 个 (33MB) | 金融投研 / 风控合规 / 工具 |
| `.agents/skills/` | 55 个 | 研究分析 / 数据 / 微信（从 Note 7 合并） |
| `skills/bailian-cli/` | 1 个 | 百炼 CLI（从 Note 7 合并） |
| `~/modelstudioai-cli/` | 工具链 | 视频/图片/语音生成（从 Note 7 合并） |

### 安全加固

phantom killer 已关+锁 persistent · 权限自动撤销已禁 · Doze ✅ · Boot ✅ · SSH 免密 ✅

### 性能优化 (2026-07-23)

修改 runit 服务配置，调整 Node.js V8 引擎参数：

```bash
# $PREFIX/var/service/openclaw/run
export NODE_OPTIONS="--dns-result-order=ipv4first --max-old-space-size=4096 --max-semi-space-size=128"
```

| 指标 | 优化前 | 优化后 | 变化 |
|---|---|---|---|
| **Node heap 上限** | 1120MB | **4480MB** | +300% |
| **GC 老生代阈值** | 1120MB | **4096MB** | Major GC 间隔 ↑ 3.6x |
| **GC 新生代阈值** | 16MB | **128MB** | Scavenge 间隔 ↑ 8x |
| **gateway RSS** | 362MB | 349MB | -13MB |
| **启动时间** | 13.6s | 14.5s | 持平（瓶颈在模型元数据） |

> ⚠️ `--initial-old-space-size` 被 Node 安全策略拦截，已移除。

### 监控与自愈 (2026-07-23 部署)

```bash
# crontab
*/5  * * * * ~/healthcheck.sh   # SSH 检查 Note 7 gateway → 自愈 → 告警
*/10 * * * * ~/check-ip.sh      # 检测出口 IP 变化 → 告警
*/10 * * * * ~/self-check.sh    # 本地内存/磁盘/swap 阈值保护
```

| 脚本 | 职责 | 自愈能力 |
|---|---|---|
| `healthcheck.sh` | SSH 探活 Note 7 gateway | ✅ 异常时远程 `sv restart`（最多 2 次），10 分钟冷却期 |
| `check-ip.sh` | 出口 IP 漂移检测 | 仅告警（需人工更新 QQ 白名单） |
| `self-check.sh` | 磁盘 > 90% / 内存 < 500MB / swap > 80% | ✅ 自动清理日志/npm cache；内存不足时重启 gateway |

> 正常时静默，不产生消息、不消耗 token。详见[自愈系统](#自愈系统)。

### 诊断

| 🟢 优势 | 🟡 待优化 | 🚀 潜力 |
|---|---|---|
| 16GB，唯一可并发 CLI | 模型 35→5 精简 | 本地小模型 (llama.cpp) |
| 蜂窝+WiFi 双网冗余 | 电池 540 循环智能充放电 | 手机眼 (拍照+GPS+视觉) |
| 摄像头/GPS/通知 | — | 飞书告警中枢 |
| Python 54 包 + numpy | — | 边缘计算 + API 网关 |
| 335GB 空闲 + crond 监控 | — | 继承 Note 7 创意工作 |

---

## Note 7 — 家里轻量任务机

> 🆕 创意生成工作已移交 K60。cronie 已装，每 5 分钟 SSH 检查 K60 gateway。

### 硬件

| 项目 | 参数 |
|---|---|
| SoC / RAM / 存储 | 骁龙 660 (14nm) / 6GB LPDDR4X / 50GB eMMC 5.1 |
| 电池 | 4000mAh，⚠️ 无 termux-api 无法远程监测 |
| 系统 | Android 10 / MIUI 12.5.7（EOL 2021/10） |
| USB | ✅ adb 已启用 (getprop sys.usb.config = adb) |

### 运行状态 (2026-07-23)

```
CPU:  load 6.73 (视频传输中)   内存: 5.6GB 总 / 3.1GB 可用
Swap: 2.5GB 总 / 666MB 用    gateway: RSS 319MB / 12 线程
磁盘: 13GB 已用 (26%) / 37GB 空闲    日志: 7.3MB
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v26.4.0 | libsqlite 3.53.3
Python 3.14.6 (3 包) | git 2.55.0 | cronie | 缺: termux-api, vim/nano
```

### 网络

| 路径 | 地址 |
|---|---|
| Tailscale | 100.91.94.44 |
| WiFi | 192.168.122.238 |
| 出口 | 117.136.120.99 |
| SSH 互信 | ↔ K60 (TS) · MIX 2S (TS+LAN) · Note 4X (LAN) | ✅ |

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 1905221791 |
| 飞书 | ✅ |
| 微信 iLink | 🗑️ 已移除 |
| plugins.allow | feishu, qqbot, deepseek（全队最简） |

### 监控与自愈

```bash
# crontab
*/5  * * * * ~/healthcheck.sh   # SSH 检查 K60 gateway → 自愈 → 告警
*/10 * * * * ~/self-check.sh    # 本地内存/磁盘/swap 阈值保护
```

| 脚本 | 职责 | 自愈能力 |
|---|---|---|
| `healthcheck.sh` | SSH 探活 K60 gateway | ✅ 异常时远程 `sv restart`（最多 2 次），10 分钟冷却期 |
| `self-check.sh` | 磁盘 > 90% / 内存 < 300MB / swap > 80% | ✅ 自动清理；内存不足时重启 gateway |

> 正常时静默。详见[自愈系统](#自愈系统)。

### 🔴 禁止并发 CLI

`openclaw models list` 产生 **33.8% CPU + 267MB RAM** 孤儿进程。

> ✅ sv status / curl / tail / ps
> ❌ models list / channels probe / agent
>
> 注意：告警时 `openclaw agent` 仅在异常时触发（极少），不影响正常负载。

### 诊断

| 🟢 优势 | 🟡 待优化 |
|---|---|
| 配置极简 (3 plugins) | pkg install termux-api vim |
| A10 天然免疫 phantom killer | 日志轮转 (7.3MB) |
| 全链路自动恢复验证通过 | Node 26.4.0 升级风险 |
| SSH 互信 + crond 监控 ✅ | — |

## MIX 2S — 稳定副机

### 硬件

| 项目 | 参数 |
|---|---|
| SoC / RAM / 存储 | 骁龙 845 (10nm) / 6GB LPDDR4x / 111GB UFS 2.1 |
| 电池 | 3400mAh，支持 18W 有线 + 7.5W 无线 |
| 系统 | Android 10 / MIUI 12.5.1（EOL 2020/12，全队加固最简单） |
| 特殊 | 后置指纹、无耳机孔、陶瓷后盖 (189g) |

### 运行状态 (2026-07-23)

```
CPU:  load 0.05 (极低)       内存: 5.5GB 总 / 3.1GB 可用
Swap: 2.5GB 总 / 619MB 用    gateway: RSS 357MB
磁盘: 18GB 已用 (17%) / 93GB 空闲
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v26.4.0 | libsqlite 3.53.3
Python 3.14.6 | git 2.55.0 | cronie | 缺: termux-api
```

### 网络

| 路径 | 地址 | 说明 |
|---|---|---|
| Tailscale | 100.104.72.125 | ✅ 首选通道 (APK 重装) |
| WiFi | 192.168.1.20 | LAN 回退 |
| MAC | ⚠️ 随机 MAC | AE:1A:3A:F6:F9:0C |
| SSH 互信 | ↔ K60 / Note 7 / Note 4X | ✅ |

### 监控与自愈

```bash
# crontab
*/5  * * * * ~/healthcheck.sh   # SSH 检查 K60 gateway (LAN)
*/10 * * * * ~/self-check.sh    # 本地内存/磁盘/swap 阈值保护
```

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 1903080675 |
| 飞书 | ✅ cli_aad1a7849078dd01 |
| 微信 iLink | 🗑️ 已移除 |
| 默认模型 | alibaba-model-studio/deepseek-v4-flash (百炼免费) |
| 技能 | 59 个 (从 K60 同步) |
| plugins.allow | qqbot, deepseek, feishu |

### 诊断

| 🟢 优势 | 🟡 待优化 |
|---|---|
| A10 天然免疫 phantom/权限撤销 | wlan0 无 IP (走 TS 不受影响) |
| 加固最简单（仅 Doze） | 随机 MAC 需路由器绑定 |
| 845 性能稳定，load 仅 0.05 | — |
| TS+LAN 双路径冗余 | — |
| 双渠道 QQ+飞书 + 59 技能 | — |
| 磁盘 17% 余量大 | — |

---

## Note 4X — 韧性备机

### 硬件

| 项目 | 参数 |
|---|---|
| SoC / RAM / 存储 | 骁龙 625 (14nm) / 3GB LPDDR3 / 23GB eMMC 5.1 |
| 电池 | 4100mAh，支持 10W 有线 |
| 系统 | Android 7.0 / MIUI 11（全队最老，EOL） |
| 特殊 | 有耳机孔、红外、后置指纹、支持 microSD (全队唯一) |
| 硬件问题 | ⚠️ 电源键不灵敏，已装 Power Button Tile (F-Droid) 通过磁贴重启 |

### 运行状态 (2026-07-23)

```
CPU:  load 5.01 (高)           内存: 2.8GB 总 / 875MB 可用
Swap: 1GB zram / 298MB 用      gateway: RSS 391MB
磁盘: 12GB 已用 (52%) / 11GB 空闲
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v26.4.0 (手动deb+hold) | libsqlite 3.53.3
Python 3.13.13 | git 2.53.0 | cronie
```

### 网络

| 路径 | 地址 |
|---|---|
| WiFi | 192.168.1.19 (仅 LAN 直连) |
| Tailscale | ❌ Android 7 不支持 |

### 监控与自愈

```bash
# crontab
*/5  * * * * ~/healthcheck.sh   # SSH 检查 K60 gateway (LAN)
*/10 * * * * ~/self-check.sh    # 本地内存/磁盘/swap 阈值保护
```

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 1905222557 |
| 飞书 | ✅ cli_aad19b0b53b89d24 |
| 微信 iLink | 🗑️ 已移除 |
| 模型供应商 | qwen-portal / deepseek / alibaba-model-studio |
| 技能 | 0 (3GB 内存限制，仅保留核心) |
| plugins.allow | feishu, qqbot |

### 🔴 禁止并发 CLI

3GB RAM 下 `openclaw channels probe` 或 `models list` 必 OOM。禁止任何 `openclaw agent` / `channels probe` / `models list` 命令，仅用 `grep` 查日志。

### 已完成 (2026-07-23)

- ✅ SQLite 3.53.0 → 3.53.3
- ✅ 微信 iLink 已从 plugins.allow 移除
- ✅ quota_watcher.sh 已清理
- ✅ crond + healthcheck + self-check 已部署

### 诊断

| 🟢 优势 | 🟡 待优化 |
|---|---|
| 双渠道 QQ+飞书在线 | Load 持续偏高 (SD625 瓶颈) |
| qwen-portal 唯一供应商 | 仅 LAN，无 Tailscale 冗余 |
| 4100mAh 大电池续航好 | 3GB 内存禁并发 CLI |
| 支持 microSD 扩展 | 0 技能 (内存限制) |
| 耳机孔/红外等复古优势 | — |

---

# 联合作业与运维

## SSH 互信（2026-07-23 全队打通）

```
K60  ←TS→  Note 7    ←TS→  MIX 2S      (TS 全互联)
K60  ←TS→  MIX 2S
K60  ←LAN→ Note 4X   (Note 4X 仅 LAN)
Note 7  ←LAN→ Note 4X
MIX 2S ←LAN→ Note 4X
```

> K60 / Note 7 / MIX 2S 三台通过 Tailscale 互联。Note 4X (Android 7) 仅 LAN 与其余三台通信。

## 自愈系统

> 部署时间：2026-07-23 | 设计原则：**检测 → 修复 → 修复无效才告警**
>
> 脚本位置：`scripts/` → `k60-healthcheck.sh` / `note7-healthcheck.sh` / `self-check.sh`

### 架构

```
Layer 1  进程守护    runit (15s 自动拉起 gateway)
Layer 2  异常感知    互检探活 + IP 漂移 + 本地自检
Layer 3  自动修复    ★ SSH 远程重启 + 重试 + 冷却机制
Layer 4  预防保护    ★ 内存/磁盘/swap 阈值自动清理
Layer 5  交叉容灾    远期（待 OpenClaw nodes 配通）
```

### 互检自愈流程

```
检测 HTTP 200？
  ├─ 是 → 静默退出
  └─ 否
      ├─ SSH 不通？ → 对方可能关机，立即告警
      ├─ 10 分钟内重启过？ → 冷却期，跳过
      └─ 自愈循环（最多 2 次）
           ├─ ssh 远程 sv restart openclaw
           ├─ 等 20s 重新探活
           ├─ HTTP 200 恢复 → 记录日志，静默退出
           └─ 2 次后仍失败 → QQ 告警「自愈失败，需人工介入」
```

### 本地自检

每 10 分钟执行，各设备独立运行：

| 检测项 | 阈值 | 动作 | 是否告警 |
|---|---|---|---|
| 磁盘使用率 | > 90% | 截断大日志 + 清理 3 天前旧日志 + npm cache clean | 否 |
| 可用内存 | < 500MB | 截断日志 + sync + drop_caches → 仍不足则重启 gateway | 否 |
| Swap 使用率 | > 80% | 无法主动释放（Android 限制），发告警提醒关注 | ✅ QQ |
| Gateway 自检 | HTTP ≠ 200 | 只记录，由对端 healthcheck 处理（避免重复操作） | 否 |

### Cron 调度

| 设备 | 脚本 | 频率 | 监控目标 |
|---|---|---|---|
| K60 | `~/healthcheck.sh` | */5 min | Note 7 (Tailscale) → 自愈重启 |
| K60 | `~/check-ip.sh` | */10 min | 出口 IP 漂移 → 告警 |
| K60 | `~/self-check.sh` | */10 min | 本地内存/磁盘/swap/自检 |
| Note 7 | `~/healthcheck.sh` | */5 min | K60 (Tailscale) → 自愈重启 |
| Note 7 | `~/self-check.sh` | */10 min | 本地内存/磁盘/swap/自检 |
| MIX 2S | `~/healthcheck.sh` | */5 min | K60 (LAN) → 仅记录 |
| MIX 2S | `~/self-check.sh` | */10 min | 本地内存/磁盘/swap/自检 |
| Note 4X | `~/healthcheck.sh` | */5 min | K60 (LAN) → 仅记录 |
| Note 4X | `~/self-check.sh` | */10 min | 本地内存/磁盘/swap/自检 |

### 日志

```bash
cat ~/healthcheck.log        # 互检自愈日志（重启/告警）
cat ~/self-check.log         # 本地自检日志（清理动作）
cat ~/self-check.alert.log   # 本地自检告警（swap 超阈值）
cat ~/healthcheck.last_restart  # 上次自愈重启时间戳
```

## 技能同步

| | K60 | Note 7 | MIX 2S | Note 4X |
|---|---|---|---|---|
| workspace skills | 59 (33MB) | 59 (已同步) | 59 (已同步) | 0 (内存限制) |
| .agents | 55 | 55 (已移交) | 0 | 0 |
| 百炼工具链 | modelstudioai-cli + bailian | — | — | — |

```bash
# K60 → 其他设备 tar 直传 (利用 SSH 互信)
ssh k60 "cd ~/.openclaw/workspace && tar czf - skills/ | ssh -p 8022 <target> 'cd ~/.openclaw/workspace && tar xzf -'"
```

## Note 7 → K60 工作交接

| 类别 | 大小 | 状态 |
|---|---|---|
| Agent 记忆 | 3.4MB | `note7-handoff/` 参考，不覆盖 |
| 工作区 | ~50KB | `workspace/note7-*.md` |
| 图片 | 23MB | `media/outbound/` 已合入 |
| 视频/音频 | 5.6GB | `note7-handoff/out/` |
| 百炼工具链 | 2.9MB | 已安装 |
| .agents 技能 | 5.6MB | 已合入 |

---

# 能力路线图

> 资源余量：K60 CPU 70% 空闲 + 6.9GB RAM + 335GB 磁盘 · Note 7 37GB 磁盘 + 固定网络

## 🟢 第一层：立即可做

### ✅ 全队自愈监控（已部署）

K60 ↔ Note 7 双向 SSH 巡检 + 自动重启 + QQ 告警。MIX 2S / Note 4X 监控 K60。4 机本地自检全覆盖。

### ✅ IP 漂移自动告警（已部署）

出口 IP 变化 → K60 QQ bot 推送新 IP + 白名单更新提醒。

### 模型免费额度保护

```bash
bl auth login --console          # PC 端 OAuth → scp config 到 K60
bl usage freetier --all          # 所有模型免费额度耗尽自动停用
bl usage summary                 # 每日额度巡检
```

### K60 配置清理

- 模型 35→5 精简
- 默认模型切 deepseek-v4-flash
- 删除退役的 deepseek-chat

## 🟡 第二层：能力释放

### K60 "手机眼"

拍照/定位/扫码——Termux:API 已装。

### 分布式定时任务

K60 (白天) 金融抓取 + 日报 + 预警 · Note 7 (24h) 网络监控 + 日志轮转 + 备份。

### Note 7 文件服务

```bash
cd ~/.openclaw/workspace/out && python -m http.server 8080
```

## 🔴 第三层：压榨极限

### 本地小模型

K60: llama.cpp + Qwen2.5-7B · Note7: 0.5B-1.5B 分类摘要。

### API 网关 / 消息管道 / sshfs / 四机联邦 / nodes 集成 / 边缘 AI

（详见此前版本路线图）

## 📊 场景矩阵

| 场景 | 难度 | 价值 | 状态 |
|---|---|---|---|
| 双机自愈监控 | ⭐ | 🔴 高 | ✅ 已部署 |
| IP 漂移自动检测 | ⭐ | 🔴 高 | ✅ 已部署 |
| 免费额度保护 | ⭐⭐ | 🔴 高 | ⬜ 待认证 |
| K60 配置清理 | ⭐ | 🟡 中 | ⬜ |
| 手机眼 (拍照/GPS) | ⭐⭐ | 🟡 中 | ⬜ |
| 分布式定时任务 | ⭐⭐ | 🟡 中 | ⬜ |
| 文件服务 | ⭐ | 🟢 低 | ⬜ |
| 飞书告警中枢 | ⭐⭐ | 🔴 高 | ⬜ |
| 本地小模型推理 | ⭐⭐⭐ | 🟡 中 | ⬜ |
| 四机联邦 | ⭐⭐⭐⭐ | 🔴 高 | ⬜ |
| 自愈系统 | ⭐⭐⭐ | 🔴 高 | ✅ 已部署 |
| 边缘 AI 集群 | ⭐⭐⭐⭐ | 🔴 高 | ⬜ |

---

# 附录：速查表

## A. 硬件对比

| | K60 | Note 7 | MIX 2S | Note 4X |
|---|---|---|---|---|
| **算力** | 🥇 8+ Gen1 | 🥈 660 | 🥉 845 | 🏅 625 |
| **内存** | 16GB | 6GB | 6GB | 3GB |
| **系统** | A15 | A10 | A10 | A7 |
| **渠道** | QQ+飞书+微信 | QQ+飞书 | QQ+飞书 | QQ+飞书 |
| **网络** | TS+蜂窝+WiFi | TS+LAN | TS+LAN | 仅 LAN |
| **加固** | HyperOS 复杂 | 天然免疫 | 天然免疫 | 无 root |
| **技能** | 59 | 59 | 59 | 0 (内存限制) |

**一句话总结：** K60 是全能旗舰主力，Note 7 是全流程验证的可靠轻量机，MIX 2S 是加固最简单的 845 稳定副机，Note 4X 是 3GB 内存下韧性标杆。机队最大运维痛点不是单机稳定性，而是 **QQ 白名单四台联动**——宽带重拨一次需同时更新四个 AppID。

---

## B. K60 技能清单

> 统计时间：2026-07-23 | 总计 106 个技能，63 个就绪，11 个待配置，32 个已禁用
>
> 安装命令：`openclaw skills install <slug>` | 搜索：`openclaw skills search <关键词>`

### 11.1 金融投资（29 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `stock-research-engine` | 个股基本面深度研究（A股/港股/美股），买方基金经理视角 | ✅ |
| `financial-roe-analysis` | 杜邦分析体系深度财务分析，拆解 ROE 驱动因素 | ✅ |
| `a-share-risk-alert` | A股风险预警 / ST 预警 / 退市风险排查 | ✅ |
| `stock-cyq-analyzer` | 筹码分布分析（CYQ），获利盘/主力成本/筹码集中度 | ✅ |
| `stock-monitor` | 股票实时行情监控 + 价格/涨跌幅预警 | ✅ |
| `stock-performance-express` | A股业绩快报查询（营收/净利润/EPS/ROE） | ✅ |
| `股票价值投资分析` | 护城河分析 + DCF 估值 + 管理层评估 + 行业分析 | ✅ |
| `finance-radar` | 美股 + 加密货币分析，8 维度评分 + 热门扫描 | ✅ |
| `fund-analyzer` | 基金净值/收益/风险分析 + 持仓回测 + 同类对比 | ✅ |
| `基金实时估值抓取` | 基于重仓股实时行情加权计算基金预计涨跌幅 | ✅ |
| `hithink-finance` | 同花顺金融数据：A股行情/财报/指数/板块/基金 | ✅ |
| `investlog-ai` | 美股实时数据：估值/财报/分析师/内幕交易/机构持仓 | ✅ |
| `stocks` | Yahoo Finance 56+ 金融数据工具 | ✅ |
| `cn-financial-scraper` | 1330 家中国金融机构全量爬取 + 反爬增强 | ✅ |
| `pytdx-api` | 通达信 pytdx：A股/期货 K线/分时/财务/板块数据 | ✅ |
| `sec-finance-ai` | 美股 SEC EDGAR 数据库：10-K/10-Q/8-K/内幕交易 | ✅ |
| `position-risk-manager` | 仓位管理/移动止盈/阶梯止盈/核心-卫星策略 | ✅ |
| `fintech-risk-control` | 金融风控策略：决策树/分箱/评分卡/信用风险 | ✅ |
| `backtester` | 策略回测框架：SMA/RSI/MACD/布林带 | ✅ |
| `stock-strategy-backtester` | 股票策略回测（胜率/收益率/回撤/夏普比率） | ✅ |
| `onequant-backtest` | OneQuant 4.0 量化平台：102 API + 回测 + 选股 | ✅ |
| `joinquant` | 聚宽量化交易平台：数据查询 + 策略回测 + 模拟实盘 | ✅ |
| `quant-risk-dashboard` | 量化风控仪表板：VaR/CVaR/压力测试/头寸限制 | ✅ |
| `taoguba-crawler` | 淘股吧博客爬取，获取股市见解 | ✅ |
| `industry-research-analyst` | 投行级行业深度研究：产业链/竞争格局/驱动因素 | ✅ |
| `私募` | 15 年经验私募合规专家，8 大模块审查 + Word 报告 | ✅ |
| `ai-stock-analyst` | AI A股分析师（AkShare 实时数据 + 评分报告） | 🔧 待配置 |
| `finance-research-report` | A股每周投研 PDF 报告生成器 | 🔧 待配置 |
| `quant-strategy` | 量化策略编写回测 + 因子分析 | 🔧 待配置 |

### 11.2 数据分析（9 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `data-analyst-pro` | 10 大场景数据诊断，六阶分析 + 快慢车道，直接出结论和图表 | ✅ |
| `auto-data-analysis-claw` | 自动化财务与业务数据分析，生成专业报表 | ✅ |
| `data-visualization` | 智能数据可视化：柱状/折线/饼图/热力图/旭日图等 11 种图表 | ✅ |
| `smart-charts` | 读取 CSV/Excel/JSON，自动推荐最佳图表，生成交互式 ECharts | ✅ |
| `chat2duckdb` | DuckDB 引擎：对 CSV/JSON/Parquet/Excel 执行 SQL 分析 | ✅ |
| `data-tag` | 数据标注校验：自动校验结果列，错误标红、不确定标黄 | ✅ |
| `budget-vs-actual` | 预算 vs 实际差异分析，生成管理评述和滚动预测 | ✅ |
| `Business Intelligence` | BI 仪表板/KPI 定义/决策报告 | 🔧 待配置 |
| `riskofficer` | 组合风险管理：VaR/蒙特卡洛/压力测试/风险平价 | 🔧 待配置 |

### 11.3 商业查询（2 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `business-search` | 天机商查：工商/股东/司法/知识产权/ICP 备案等全维度企业情报 | ✅ |
| `bainiu-enterprise-data-query` | 白牛企业信息查询：工商/股权/司法/行政/知识产权/关系图谱 | ✅ |

### 11.4 渠道运营：QQ + 飞书（7 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `qqbot-channel` | QQ 频道管理：成员/频道/发言管理，写操作前确认 | ✅ |
| `qqbot-media` | QQ 机器人富媒体收发：图片/语音/视频 | ✅ |
| `qqbot-remind` | QQ 机器人定时提醒：一次性/周期提醒，支持增删查 | ✅ |
| `feishu-doc` | 飞书文档读写操作 | ✅ |
| `feishu-drive` | 飞书云盘文件管理 | ✅ |
| `feishu-perm` | 飞书文档/文件权限管理 | ✅ |
| `feishu-wiki` | 飞书知识库导航与查询 | ✅ |

### 11.5 内容与媒体（7 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `wechat-article` | 微信公众号文章抓取，支持 Markdown/HTML/Text/JSON/Excel 五种格式 | ✅ |
| `wxpublic-fetch` | 指定公众号 + 日期范围批量抓取文章存为本地 Markdown | ✅ |
| `wechat-hot-article-extractor` | 提取微信 10w+ 热门文章（近期时间窗口） | ✅ |
| `wechat-top-account` | 公众号综合实力排行榜 TOP50（日/周/月榜 + 垂直领域筛选） | ✅ |
| `wechat-analyzer` | 微信聊天记录分析 Web 应用（Flask + 暗色主题） | ✅ |
| `douyin-content-surge` | 抖音每日点赞飙升榜 TOP50（按赛道/历史回溯） | ✅ |
| `meme-maker` | 搜索 meme 模板 + 生成表情包图片 | ✅ |

### 11.6 开发工具（4 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `spike` | 快速原型验证：可行性评估 + 方案对比报告 | ✅ |
| `skill-creator` | 创建/编辑/审核/校验 AgentSkill 和 SKILL.md | ✅ |
| `clawhub` | ClawHub 技能仓库：搜索/安装/更新/发布/同步 | ✅ |
| `diagram-maker` | 生成 SVG/HTML 或 Excalidraw 图表（架构图/流程图/白板） | ✅ |
| `node-inspect-debugger` | Node.js 调试：断点/CDP/堆内存/CPU 性能分析 | ✅ |
| `python-debugpy` | Python 调试：pdb/breakpoint/远程 debugpy 连接 | ✅ |

### 11.7 系统与运维（4 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `healthcheck` | 主机安全审计：SSH/防火墙/更新/暴露面/备份/磁盘加密 | ✅ |
| `node-connect` | OpenClaw 节点配对诊断（Android/iOS/macOS） | ✅ |
| `taskflow` | 多步骤分离任务协调，持久化状态 + 子任务管理 | ✅ |
| `find-skill-skillhub` | SkillHub 平台技能搜索（关键词 + 标签筛选） | ✅ |

### 11.8 效率与生活（3 个）

| 技能 | 一句话能力 | 状态 |
|---|---|---|
| `weather` | 天气查询（当前 + 预报），支持位置/降雨/温度/旅行规划 | ✅ |
| `notion` | Notion CLI/API：页面/Markdown/数据源/文件/评论/搜索 | ✅ |
| `周公解梦` | 传统周公解梦 + 现代心理学双语解梦，双版本解读 + 吉凶建议 | ✅ |

### 11.9 技能来源分布

| 来源 | 数量 | 说明 |
|---|---|---|
| `openclaw-workspace` | 49 | 用户手动安装的工作区技能（`~/.openclaw/workspace/skills/`） |
| `openclaw-bundled` | 9 (就绪) + 28 (禁用) | OpenClaw 内置技能，平台不适用的默认禁用 |
| `openclaw-extra` | 7 | OpenClaw 扩展技能包：QQ/飞书渠道管理 |

### 11.10 快速导入其他设备

```bash
# 从 K60 导出已安装技能列表
openclaw skills list --json > /tmp/k60-skills.json

# 在其他设备上批量安装（筛选 workspace 来源的）
# 方式一：逐个安装
openclaw skills install <skill-slug>

# 方式二：通过 git 同步 workspace skills 目录
scp -r k60:~/.openclaw/workspace/skills/ target:~/.openclaw/workspace/skills/

# 方式三：SkillHub 搜索安装
openclaw skills search <关键词>
openclaw skills install <slug>
```

> **注意：** Note 7（SD660）安装大量技能后首次加载会慢（40-60s 冷启动），建议只安装常用技能。Note 4X（3GB RAM）禁止同时安装超过 10 个 workspace 技能以免 OOM。
