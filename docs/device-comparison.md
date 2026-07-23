# OpenClaw 安卓手机机队

> 最后更新：2026-07-23 | 全队定版：OpenClaw 2026.7.1-2

## 机队概览

四台退役安卓手机组成 OpenClaw 机器人机队，Termux + runit 保活，Tailscale 组网，QQ + 飞书 + 微信 iLink 多渠道接入。K60 ↔ Note 7 已配置 SSH 互信 + 定时健康监控 + IP 漂移检测。

| 设备 | 代号 | SoC | RAM | 系统 | 角色 | 渠道 |
|---|---|---|---|---|---|---|
| **K60** | mondrian | 8+ Gen 1 | 16GB | A15 | 🥇 随身主力 | QQ + 飞书 + 微信 |
| **Note 7** | lavender | 660 | 6GB | A10 | 🥈 家里轻量 | QQ + 飞书 |
| **MIX 2S** | polaris | 845 | 6GB | A10 | 🔍 待定位 | QQ + 飞书 |
| **Note 4X** | mido | 625 | 3GB | A7 | 🏅 长期备机 | QQ + 飞书 + 微信(待移除) |

```
网络: 家庭宽带(出口 117.186.4.220) + Tailscale 组网
K60 ↔ Note 7  SSH 互信 ✅  crond 健康监控 ✅  IP 漂移告警 ✅
ClawChat 全队废弃 · QQ 白名单四台联动
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
| SSH 互信 | ↔ Note 7 (100.91.94.44) | ✅ |

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

### 定时监控 (2026-07-23 部署)

```bash
# crontab
*/5  * * * * ~/healthcheck.sh   # SSH 检查 Note 7 gateway
*/10 * * * * ~/check-ip.sh      # 检测出口 IP 变化
```

**健康检查** (`~/healthcheck.sh`)：SSH 到 Note 7 探活 gateway，异常时通过 K60 的 QQ bot 推送告警。

**IP 漂移检测** (`~/check-ip.sh`)：对比当前出口 IP 与上次记录，变化时通过 QQ bot 推送新 IP + 白名单更新提醒。

正常时静默，不产生消息、不消耗 token。

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
| SSH 互信 | ↔ K60 ✅ |

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 1905221791 |
| 飞书 | ✅ |
| 微信 iLink | 🗑️ 已移除 |
| plugins.allow | feishu, qqbot, deepseek（全队最简） |

### 定时监控

```bash
# crontab: 每 5 分钟 SSH 检查 K60 gateway，异常时通过 Note 7 QQ bot 告警
*/5 * * * * ~/healthcheck.sh
```

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

---

## MIX 2S — 待重新定位

> 离线中。上线后按此模板全面分析 + 部署监控。

| 项目 | 数值 |
|---|---|
| SoC | 骁龙 845 / 6GB |
| 系统 | Android 10 / MIUI 12.5.1 |
| Tailscale | 100.104.72.125 |
| 渠道 | QQ (1903080675) + 飞书 + 微信 iLink (已装未绑) |
| 待办 | 全面分析、移除微信、技能盘点、SSH 互信、部署 crond 监控 |

---

## Note 4X — 长期备机

> 离线中。上线后移除微信 + 全面分析。

| 项目 | 数值 |
|---|---|
| SoC | 骁龙 625 / 3GB (禁并发 CLI) |
| 系统 | Android 7.0 / MIUI 11 |
| Tailscale | ❌ 不支持 (A7) |
| Node | 26.4.0 手动 deb + apt-mark hold |
| libsqlite | 3.53.0（全队最低） |
| 渠道 | QQ (1905222557) + 飞书 + 微信 iLink (主号，待移除) |

---

# 联合作业与运维

## SSH 互信

```bash
ssh -p 8022 u0_a171@100.91.94.44     # K60 → Note 7 ✅
ssh -p 8022 u0_a129@100.118.60.29    # Note 7 → K60 ✅
```

## 双机健康监控 (2026-07-23 部署)

| 监控方 | 目标 | 频率 | 告警方式 |
|---|---|---|---|
| K60 | Note 7 gateway | 每 5 分钟 | K60 QQ bot (102825839) |
| Note 7 | K60 gateway | 每 5 分钟 | Note 7 QQ bot (1905221791) |
| K60 | 出口 IP 变化 | 每 10 分钟 | K60 QQ bot |

**原理：**

```
K60 crond → SSH Note7 → curl 127.0.0.1:18789 → 200=正常 非200=QQ告警
Note7 crond → SSH K60 → curl 127.0.0.1:18789 → 200=正常 非200=QQ告警
K60 crond → curl ip.sb → 对比上次IP → 变化=QQ告警(含白名单更新提醒)
```

**正常时静默，不作任何操作，不消耗 token。** 仅在异常时触发 `openclaw agent` 推送 QQ 消息。

**部署文件：**

| 文件 | 位置 | 说明 |
|---|---|---|
| `~/healthcheck.sh` | K60, Note 7 | 健康检查脚本 |
| `~/check-ip.sh` | K60 | IP 漂移检测 |
| crontab | K60: `*/5 + */10` · Note 7: `*/5` | 定时触发 |

## 技能同步

| | K60 | Note 7 |
|---|---|---|
| workspace | 58 个 (33MB) | 0 |
| .agents | 55 个 ← 合并自 Note 7 | 55 个 → 已移交 |
| 百炼 | modelstudioai-cli + bailian | 原持有 → 已移交 |

```bash
# rsync 直推 (利用 SSH 互信)
rsync -avz -e "ssh -p 8022" ~/.openclaw/workspace/skills/ Note7:~/.openclaw/workspace/skills/
# Git 版本管理 (推荐)
cd ~/.openclaw/workspace/skills && git init && git push
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

### ✅ 双机健康监控（已部署）

K60 ↔ Note 7 双向 SSH 巡检 + QQ 告警。

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

### API 网关 / 消息管道 / sshfs / 四机联邦 / 自愈系统 / nodes 集成 / 边缘 AI

（详见此前版本路线图）

## 📊 场景矩阵

| 场景 | 难度 | 价值 | 状态 |
|---|---|---|---|
| 双机健康监控+告警 | ⭐ | 🔴 高 | ✅ 已部署 |
| IP 漂移自动检测 | ⭐ | 🔴 高 | ✅ 已部署 |
| 免费额度保护 | ⭐⭐ | 🔴 高 | ⬜ 待认证 |
| K60 配置清理 | ⭐ | 🟡 中 | ⬜ |
| 手机眼 (拍照/GPS) | ⭐⭐ | 🟡 中 | ⬜ |
| 分布式定时任务 | ⭐⭐ | 🟡 中 | ⬜ |
| 文件服务 | ⭐ | 🟢 低 | ⬜ |
| 飞书告警中枢 | ⭐⭐ | 🔴 高 | ⬜ |
| 本地小模型推理 | ⭐⭐⭐ | 🟡 中 | ⬜ |
| 四机联邦 | ⭐⭐⭐⭐ | 🔴 高 | ⬜ |
| 自愈系统 | ⭐⭐⭐ | 🔴 高 | ⬜ |
| 边缘 AI 集群 | ⭐⭐⭐⭐ | 🔴 高 | ⬜ |

---

# 附录：速查表

## A. 硬件对比

| | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| SoC | 8+ Gen 1 (4nm) | 845 (10nm) | 660 (14nm) | 625 (14nm) |
| RAM | 16GB LPDDR5 | 6GB LPDDR4x | 6GB LPDDR4X | 3GB LPDDR3 |
| 存储 | 462GB UFS 3.1 | UFS 2.1 | 50GB eMMC | eMMC 5.1 |
| 电池 | 5500mAh | 3400mAh | 4000mAh | 4100mAh |

## B. 系统与网络

| | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| Android | 15 / HyperOS | 10 / MIUI 12.5 | 10 / MIUI 12.5 | 7.0 / MIUI 11 |
| Tailscale | 100.118.60.29 | 100.104.72.125 | 100.91.94.44 | ❌ |
| LAN IP | 192.168.1.23 | 192.168.1.20 | 192.168.122.238 | 192.168.1.19 |
| SSH 互信 | ↔ Note 7 | ❌ | ↔ K60 | ❌ |
| crond 监控 | ✅ | ❌ | ✅ | ❌ |

## C. 软件与升级

| | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| Node | 24.17.0 LTS | 26.4.0 | 26.4.0 | 26.4.0 deb |
| libsqlite | 3.53.3 | 3.53.3 | 3.53.3 | 3.53.0 |
| Python | 3.14+numpy | — | 3.14 | — |
| cronie | ✅ | — | ✅ | — |
| NODE_OPTIONS | `max-old=4096 semi=128` | 默认 | 默认 | 默认 |
| 升级风险 | 🟢 | 🟡 | 🟡 | 🔴 |

## D. 运维命令

| 操作 | 命令 |
|---|---|
| 服务状态 | `sv status openclaw` (先 `export SVDIR=$PREFIX/var/service`) |
| Gateway 探活 | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/` |
| 查出口 IP | `curl -4 -s https://api.ip.sb/ip` |
| 健康检查日志 | `cat ~/healthcheck.log` |
| IP 漂移日志 | `cat ~/check-ip.log` (K60) / `cat ~/.last_ip` |
| 定时任务 | `crontab -l` |
| 版本三连 | `openclaw --version` / `node --version` / SQLite 版本 |
| 重启 | `sv restart openclaw` |
| 日志 | `$PREFIX/var/log/sv/openclaw/current` |
| K60→Note7 | `ssh -p 8022 u0_a171@100.91.94.44` |
| Note7→K60 | `ssh -p 8022 u0_a129@100.118.60.29` |
| 升级流程 | ① K60 → ② MIX 2S → ③ Note 7 → ④ Note 4X |
