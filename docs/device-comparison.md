# OpenClaw 安卓手机机队

> 最后更新：2026-07-23 | 全队定版：OpenClaw 2026.7.1-2

## 机队概览

四台退役安卓手机组成 OpenClaw 机器人机队，Termux + runit 保活，Tailscale 组网，QQ + 飞书 + 微信 iLink 多渠道接入。

| 设备 | 代号 | SoC | RAM | 系统 | 角色 | 渠道 |
|---|---|---|---|---|---|---|
| **K60** | mondrian | 8+ Gen 1 | 16GB | A15 | 🥇 随身主力 | QQ + 飞书 + 微信 |
| **Note 7** | lavender | 660 | 6GB | A10 | 🥈 家里轻量 | QQ + 飞书 |
| **MIX 2S** | polaris | 845 | 6GB | A10 | 🔍 待定位 | QQ + 飞书 |
| **Note 4X** | mido | 625 | 3GB | A7 | 🏅 长期备机 | QQ + 飞书 + 微信(待移除) |

```
网络: 家庭宽带(出口 117.186.4.220) + Tailscale 组网
K60  ↔ Note 7  SSH 互信 ✅
ClawChat 全队废弃 (2026-07-23)
QQ 白名单: 四台联动，宽带重拨需同时更新
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

### 运行状态 (2026-07-23 实测)

```
CPU:  load 3.17 (70% 空闲)    内存: 15.5GB 总 / 6.9GB 可用
Swap: 16.8GB 总 / 4.3GB 用    gateway: RSS 362MB / 12 线程
磁盘: 125GB 已用 (28%) / 335GB 空闲    日志: 3.7MB
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v24.17.0 LTS (仓库原生) | libsqlite 3.53.3
Python 3.14.6 (54 包, 含 numpy) | git 2.55.0 | SSH 10.4p1
```

### 网络

| 路径 | 地址 | 说明 |
|---|---|---|
| Tailscale | 100.118.60.29 | 首选通道 |
| WiFi | 192.168.1.23 | 家庭网络（当前不在） |
| 蜂窝 | 出口 117.136.120.99 | 移动时使用 |
| 热点网关 | PC 默认网关 | `sshk60` 自动回退 |
| SSH 互信 | ↔ Note 7 (100.91.94.44) | ✅ |

> 作为移动设备，IP 随网络环境变化——这是核心特性，也是 QQ 白名单最需要关注的点。

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 102825839 |
| 飞书 | ✅ |
| 微信 iLink | ✅ 970ed7c8f462-im-bot |
| 已配置模型 | 35 个 ⚠️ 建议精简到 5 |
| 默认模型 | alibaba-model-studio/qwen3.7-max-preview ⚠️ 应切 deepseek-v4-flash |
| 废弃模型 | deepseek-chat ❌ 待删除 |

### 技能

| 位置 | 数量 | 类别 |
|---|---|---|
| `workspace/skills/` | 58 个 (33MB) | 金融投研 / 风控合规 / 工具 |
| `.agents/skills/` | 55 个 | 研究分析 / 数据 / 微信（从 Note 7 合并） |
| `skills/bailian-cli/` | 1 个 | 百炼 CLI（从 Note 7 合并） |
| `~/modelstudioai-cli/` | 工具链 | 视频/图片/语音生成（从 Note 7 合并） |

### 安全加固

phantom killer 已关+锁 persistent · 权限自动撤销已禁 · Doze ✅ · Boot ✅ · SSH 免密 ✅

### 诊断

| 🟢 优势 | 🟡 待优化 | 🚀 潜力 |
|---|---|---|
| 16GB，唯一可并发 CLI | 默认模型切 deepseek-v4-flash | 本地小模型 (llama.cpp) |
| 蜂窝+WiFi 双网冗余 | 35→5 模型精简 | 手机眼 (拍照+GPS+视觉) |
| 摄像头/GPS/通知 | 电池 540 循环智能充放电 | 飞书告警中枢 |
| Python 54 包 + numpy | IP 漂移自动检测 | 边缘计算 + API 网关 |
| 335GB 空闲 | deepseek-chat 清理 | 继承 Note 7 创意工作 |

---

## Note 7 — 家里轻量任务机

> 🆕 创意生成工作（视频/图片/配音）已于 2026-07-23 移交 K60。

### 硬件

| 项目 | 参数 |
|---|---|
| SoC / RAM / 存储 | 骁龙 660 (14nm) / 6GB LPDDR4X / 50GB eMMC 5.1 |
| 电池 | 4000mAh，⚠️ 无 termux-api 无法远程监测 |
| 系统 | Android 10 / MIUI 12.5.7（EOL 2021/10） |
| USB | ✅ adb 已启用 (getprop sys.usb.config = adb) |

### 运行状态 (2026-07-23 实测)

```
CPU:  load 6.73 (视频传输中，传完回落)   内存: 5.6GB 总 / 3.1GB 可用
Swap: 2.5GB 总 / 666MB 用    gateway: RSS 319MB / 12 线程
磁盘: 13GB 已用 (26%) / 37GB 空闲    日志: 7.3MB (需轮转)
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v26.4.0 (撤版前安装) | libsqlite 3.53.3
Python 3.14.6 (3 包) | git 2.55.0 | 缺: termux-api, vim/nano
```

### 网络

| 路径 | 地址 |
|---|---|
| Tailscale | 100.91.94.44 |
| WiFi | 192.168.122.238 |
| 出口 | 117.136.120.99 (与 K60 同) |
| 网关延迟 | 27-49ms |

### 渠道 & 模型

| 项目 | 状态 |
|---|---|
| QQ | ✅ AppID 1905221791 |
| 飞书 | ✅ |
| 微信 iLink | 🗑️ 已移除 |
| 已配置模型 | 11 个 🟢 |
| plugins.allow | feishu, qqbot, deepseek（全队最简） |
| 残留条目 | 无 ✅ |

### 🔴 禁止并发 CLI

一次 `openclaw models list` 产生 **33.8% CPU + 267MB RAM** 孤儿进程，CPU load 冲到 8+。

```
✅ sv status / curl / tail / ps
❌ models list / channels probe / agent
```

### 诊断

| 🟢 优势 | 🟡 待优化 |
|---|---|
| 配置极简 (3 plugins) | pkg install termux-api vim |
| A10 天然免疫 phantom killer | 日志轮转 (7.3MB) |
| 全链路自动恢复验证通过 | Node 26.4.0 升级风险 |
| 与 K60 SSH 互信 ✅ | — |

---

## MIX 2S — 待重新定位

> 离线中。上线后按 K60/Note 7 模板全面分析。

| 项目 | 数值 |
|---|---|
| SoC | 骁龙 845 / 6GB |
| 系统 | Android 10 / MIUI 12.5.1 |
| Tailscale | 100.104.72.125 |
| 渠道 | QQ (1903080675) + 飞书 + 微信 iLink (已装未绑) |
| 待办 | 全面分析、移除微信、技能盘点、SSH 互信 |

---

## Note 4X — 长期备机

> 离线中。上线后移除微信 + 全面分析。

| 项目 | 数值 |
|---|---|
| SoC | 骁龙 625 / 3GB (禁并发 CLI) |
| 系统 | Android 7.0 / MIUI 11（全队最老） |
| Tailscale | ❌ 不支持 (A7) |
| Node | 26.4.0 手动 deb + apt-mark hold |
| libsqlite | 3.53.0（全队最低） |
| 渠道 | QQ (1905222557) + 飞书 + 微信 iLink (主号，待移除) |

---

# 联合作业与运维

## SSH 设备间互信

K60 ↔ Note 7 已配置双向免密（Tailscale 固定 IP）。

```bash
# 配置
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub | ssh 对端 'cat >> ~/.ssh/authorized_keys'

# 使用
ssh -p 8022 u0_a171@100.91.94.44     # K60 → Note 7
ssh -p 8022 u0_a129@100.118.60.29    # Note 7 → K60
```

**应用：** scp 互传、rsync 同步技能、互相监控 gateway、远程重启。

## 技能同步

| | K60 | Note 7 |
|---|---|---|
| workspace | 58 个 (33MB) | 0 |
| .agents | 55 个 ← 合并自 Note 7 | 55 个 → 已移交 |
| 百炼 | modelstudioai-cli + bailian | 原持有 → 已移交 |

```bash
# 一次性
ssh K60 'tar czf ~/skills.tar.gz -C ~/.openclaw/workspace skills/'
ssh K60 'scp -P 8022 ~/skills.tar.gz Note7:~/.openclaw/note7-handoff/'

# 长期: rsync 直推 (利用 SSH 互信)
rsync -avz -e "ssh -p 8022" ~/.openclaw/workspace/skills/ Note7:~/.openclaw/workspace/skills/

# 版本管理: Git 仓库 (推荐)
cd ~/.openclaw/workspace/skills && git init && git push  # 其他设备 git pull
```

> ⚠️ 含 `.venv` 的技能需在目标设备 `python -m venv --clear .venv && .venv/bin/pip install -r requirements.txt`

## Note 7 → K60 工作交接

| 类别 | 内容 | 大小 | K60 存储 |
|---|---|---|---|
| Agent 记忆 | openclaw-agent.sqlite + state DB | 3.4MB | `note7-handoff/` (参考，不覆盖主 DB) |
| 工作区 | AGENTS/IDENTITY/SOUL 等 + memory | ~50KB | `workspace/note7-*.md` |
| 图片 | 26 张 AI 生成 + QQ 下载 | 23MB | `media/outbound/` 已合入 |
| 视频/音频 | 388 个文件 (短剧/配音) | 5.6GB | `note7-handoff/out/` (后台传输中) |
| 百炼 | modelstudioai-cli + bailian | 2.9MB | `~/modelstudioai-cli/` + `skills/bailian-cli/` |
| 技能 | .agents/skills/ 55 个 | 5.6MB | `~/.agents/skills/` 已合入 |

---

# 能力路线图

> 资源余量：K60 CPU 70% 空闲 + 6.9GB RAM + 335GB 磁盘 · Note 7 37GB 磁盘 + 固定网络

## 🟢 第一层：立即可做（基础设施）

### 双机健康监控

```bash
# 各机 crontab 每 5 分钟 SSH 互检 gateway
*/5 * * * * ssh 对端 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/' | grep -q 200 || \
  curl -X POST $FEISHU_WEBHOOK -d '{"msg_type":"text","content":{"text":"🚨 对端 gateway 无响应"}}'
```

### IP 漂移自动告警

```bash
# */10 * * * * — K60 在蜂窝/WiFi 切换时 IP 会变，QQ 白名单需同步更新
CUR=$(curl -4 -s https://api.ip.sb/ip)
[ "$CUR" != "$(cat ~/.last_ip)" ] && echo "$CUR" > ~/.last_ip && \
  curl -X POST $FEISHU_WEBHOOK -d '{"msg_type":"text","content":{"text":"⚠️ IP → '$CUR'"}}'
```

### 清理配置债务

- K60 默认模型切 `deepseek/deepseek-v4-flash`
- 模型 35→5 精简，删除退役的 `deepseek-chat`
- 清理 `openclawwechat` 残留条目
- Note 7: `pkg install termux-api vim`

## 🟡 第二层：能力释放

### K60 "手机眼"（独有能力）

```
用户说"拍张照"  → termux-camera-photo → 回传图片
用户说"我在哪"  → termux-location → 返回 GPS
用户说"扫这个码" → 拍照 + Python OCR
```

### 分布式定时任务

```
K60 (移动，白天):              Note 7 (固定，24h):
  金融数据抓取 (交易时间)        网络质量监控
  AI 日报 (08:30)              日志聚合+轮转 (03:00)
  股价预警 (实时)              配置备份 (04:00)
  视频渲染 (按需)              IP 巡检 (每 10min)
```

### Note 7 文件服务

```bash
cd ~/.openclaw/workspace/out && python -m http.server 8080
# → http://100.91.94.44:8080 (Tailscale 内网可访问)
```

## 🔴 第三层：压榨极限

### 本地小模型

```
K60:  llama.cpp + Qwen2.5-7B (~4GB) → 离线推理，敏感数据不出设备
Note7: llama.cpp + 0.5B-1.5B 模型 → 意图分类、文本摘要
```

### API 网关

```
K60 Flask/FastAPI:
  GET  /photo · /location · POST /agent · GET /fleet-status
Note7 轻量:
  GET  /logs · /health
→ PC/其他设备通过 Tailscale IP 直接调用
```

### 消息管道协作

```
K60 收复杂任务 → 拆分 → SSH 分发 Note7 → 汇聚回复
例: "分析这只股票" → K60 行情+指标, Note7 新闻+财报 → 综合分析
```

### 统一存储 (sshfs)

```bash
sshfs -p 8022 Note7:~/out ~/mounts/note7-out/
sshfs -p 8022 K60:~/skills ~/mounts/k60-skills/
```

## 🧭 远景

- **四机联邦：** 全队上线+互信 → 按能力/模型分级路由 → 地理冗余
- **自愈系统：** A 机检测 B 机异常 → SSH 重启 → 失败告警 → Git 回滚配置
- **nodes 原生集成：** 研究 `openclaw nodes` 配对，K60 gateway 纳管 Note 7 为 node
- **边缘 AI 集群：** K60(7B) + Note7(1.5B) 双模型协同，零成本推理

## 📊 场景矩阵

| 场景 | 难度 | 价值 | 耗时 | 依赖 |
|---|---|---|---|---|
| 双机健康监控+告警 | ⭐ | 🔴 高 | 30min | cron+飞书 webhook |
| IP 漂移自动检测 | ⭐ | 🔴 高 | 15min | cron+curl |
| K60 配置清理 | ⭐ | 🟡 中 | 10min | openclaw CLI |
| Note 7 工具安装 | ⭐ | 🟡 中 | 5min | pkg install |
| 手机眼 (拍照/GPS) | ⭐⭐ | 🟡 中 | 1h | termux-api |
| 分布式定时任务 | ⭐⭐ | 🟡 中 | 2h | Python+cron |
| 文件服务 | ⭐ | 🟢 低 | 5min | http.server |
| 飞书告警中枢 | ⭐⭐ | 🔴 高 | 1h | Python+webhook |
| 本地小模型推理 | ⭐⭐⭐ | 🟡 中 | 2h | llama.cpp |
| API 网关 | ⭐⭐⭐ | 🟡 中 | 3h | Flask/FastAPI |
| 技能自主开发 | ⭐⭐⭐ | 🔴 高 | 持续 | Python+Git |
| 消息管道协作 | ⭐⭐⭐⭐ | 🟢 低 | 4h | SSH+脚本 |
| sshfs 统一存储 | ⭐⭐ | 🟢 低 | 30min | pkg install sshfs |
| 四机联邦 | ⭐⭐⭐⭐ | 🔴 高 | 持续 | 全队上线+互信 |
| 自愈系统 | ⭐⭐⭐ | 🔴 高 | 4h | cron+SSH+Git |
| nodes 原生集成 | ⭐⭐⭐⭐⭐ | 🔴 高 | 未知 | API 研究 |
| 边缘 AI 集群 | ⭐⭐⭐⭐ | 🔴 高 | 4h | llama.cpp ×2 |

---

# 附录：速查表

## A. 硬件对比

| | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| SoC | 8+ Gen 1 (4nm) | 845 (10nm) | 660 (14nm) | 625 (14nm) |
| RAM | 16GB LPDDR5 | 6GB LPDDR4x | 6GB LPDDR4X | 3GB LPDDR3 |
| 存储 | 462GB UFS 3.1 | UFS 2.1 | 50GB eMMC | eMMC 5.1 |
| 电池 | 5500mAh | 3400mAh | 4000mAh | 4100mAh |
| 年份 | 2022 | 2018 | 2019 | 2017 |

## B. 系统与网络

| | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| Android | 15 / HyperOS | 10 / MIUI 12.5 | 10 / MIUI 12.5 | 7.0 / MIUI 11 |
| 加固难度 | 🔴 高 | 🟢 低 | 🟢 低 | 🟢 低 |
| Tailscale | 100.118.60.29 | 100.104.72.125 | 100.91.94.44 | ❌ |
| LAN IP | 192.168.1.23 | 192.168.1.20 | 192.168.122.238 | 192.168.1.19 |
| SSH 互信 | ↔ Note 7 | ❌ | ↔ K60 | ❌ |

## C. 软件与升级风险

| | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| Node | 24.17.0 LTS | 26.4.0 | 26.4.0 | 26.4.0 deb |
| libsqlite | 3.53.3 | 3.53.3 | 3.53.3 | 3.53.0 |
| Python | 3.14+numpy | — | 3.14 | — |
| git | ✅ | — | ✅ | — |
| 升级风险 | 🟢 | 🟡 | 🟡 | 🔴 |

## D. 运维命令

| 操作 | 命令 |
|---|---|
| 服务状态 | `sv status openclaw` (先 `export SVDIR=$PREFIX/var/service`) |
| Gateway 探活 | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/` |
| 查出口 IP | `curl -4 -s https://api.ip.sb/ip` |
| 版本三连 | `openclaw --version` / `node --version` / SQLite 查询 |
| 渠道列表 | `openclaw channels list --all \| grep enabled` (Note 7 用日志) |
| 重启 | `sv restart openclaw` |
| 日志 | `$PREFIX/var/log/sv/openclaw/current` |
| K60→Note7 | `ssh -p 8022 u0_a171@100.91.94.44` |
| Note7→K60 | `ssh -p 8022 u0_a129@100.118.60.29` |
| 升级流程 | ① K60 → ② MIX 2S → ③ Note 7 → ④ Note 4X |
