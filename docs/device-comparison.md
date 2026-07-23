# OpenClaw 四台手机机队

> 最后更新：2026-07-23 | 全队定版：OpenClaw 2026.7.1-2

---

## 一、硬件规格

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **代号** | mondrian | polaris | lavender | mido |
| **SoC** | 骁龙 8+ Gen 1 (4nm) | 骁龙 845 (10nm) | 骁龙 660 (14nm) | 骁龙 625 (14nm) |
| **CPU** | 1×3.0GHz X2 + 3×2.5GHz A710 + 4×1.8GHz A510 | 4×2.8GHz Kryo 385 Gold + 4×1.8GHz Silver | 4×2.2GHz Kryo 260 Gold + 4×1.8GHz Silver | 8×2.0GHz Cortex-A53 |
| **GPU** | Adreno 730 | Adreno 630 | Adreno 512 | Adreno 506 |
| **RAM** | 16GB LPDDR5 | 6GB LPDDR4x | 6GB LPDDR4X | 3GB LPDDR3 |
| **存储** | UFS 3.1 462GB (125GB 已用) | UFS 2.1 (无 microSD) | eMMC 5.1 50GB (13GB 已用) | eMMC 5.1 (支持 microSD) |
| **屏幕** | 6.67" AMOLED 3200×1440 120Hz | 5.99" IPS LCD 2160×1080 | 6.3" IPS LCD 2340×1080 | 5.5" IPS LCD 1920×1080 |
| **电池** | 5500mAh / 67W+30W 无线 | 3400mAh / 18W+7.5W 无线 | 4000mAh / 18W QC4 | 4100mAh / 10W |
| **发布年份** | 2022 | 2018 | 2019 | 2017 |
| **性能档位** | 🟢 旗舰 | 🟡 次旗舰 | 🟠 中端 | 🔴 低端 |

## 二、操作系统与加固

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **Android 版本** | 15 / HyperOS V816 | 10 / MIUI 12.5.1 | 10 / MIUI 12.5.7 | 7.0 / MIUI 11 |
| **官方支持** | ✅ 活跃更新中 | ❌ EOL (2020/12) | ❌ EOL (2021/10) | ❌ EOL |
| **phantom killer** | ⚠️ 已关+锁 persistent | ✅ 天然免疫 | ✅ 天然免疫 | ✅ 天然免疫 |
| **权限自动撤销** | ⚠️ 已禁 | ✅ 无此机制 | ✅ 无此机制 | ✅ 无此机制 |
| **Doze 白名单** | ✅ | ✅ | ⚠️ 待 adb 确认 | ✅ |
| **root** | 无 | 无 | 无 | 无 (su 空壳) |
| **加固难度** | 🔴 高（全套 adb） | 🟢 低 | 🟢 低 | 🟢 低 |

## 三、网络与连接

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **局域网 IP** | 192.168.1.23 | 192.168.1.20 | **192.168.122.238** | 192.168.1.19 |
| **Tailscale IP** | 100.118.60.29 | 100.104.72.125 | 100.91.94.44 | ❌ 不支持 |
| **出口 IP** | 117.136.120.99 (蜂窝) | — (离线) | 117.136.120.99 | — (离线) |
| **SSH 用户/端口** | u0_a129:8022 | u0_a129:8022 | u0_a171:8022 | u0_a129:8022 |
| **PC 连接** | `sshk60` (TS→热点) | `sshmix2s` (TS→LAN) | `sshnote7` (TS→LAN) | `ssh4x` (仅 LAN) |
| **可达性冗余** | TS + 蜂窝热点 | TS + LAN | TS + LAN | 仅 LAN |
| **设备间互信** | ✅ ↔ Note 7 | ❌ | ✅ ↔ K60 | ❌ |

```
网络拓扑:
家庭宽带 ──┬── K60 .... 192.168.1.23 + TS 100.118.60.29  [移动时切蜂窝 117.136.120.99]
           ├── MIX 2S . 192.168.1.20 + TS 100.104.72.125  [离线]
           ├── Note 7 . 192.168.122.238 + TS 100.91.94.44 [固定家庭]
           ├── Note 4X  192.168.1.19                      [离线，无 TS]
           └── PC ..... TS 100.70.110.100
```

## 四、软件栈

| 维度 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **OpenClaw** | 2026.7.1-2 | 2026.7.1-2 | 2026.7.1-2 | 2026.7.1-2 |
| **Node.js** | 24.17.0 (LTS) | 26.4.0 | 26.4.0 | 26.4.0 手动 deb |
| **libsqlite** | 3.53.3 | 3.53.3 | 3.53.3 | 3.53.0 ⚠️ |
| **Node 来源** | 仓库原生 | 撤版前安装 | 撤版前安装 | 手动 deb+hold |
| **Termux** | F-Droid 0.118.0 | F-Droid 0.118+ | F-Droid 0.118.0 | F-Droid 0.118+ |
| **Python** | 3.14.6 + numpy | — | 3.14.6 | — |
| **git** | ✅ 2.55.0 | — | ✅ 2.55.0 | — |
| **termux-api** | ✅ v0.59.1 | — | ❌ 缺失 | — |
| **vim/nano** | ✅ | — | ❌ 缺失 | — |
| **gateway 冷启动** | ~10s | ~20s | 40-60s | 2.5-3min |
| **升级风险** | 🟢 低 | 🟡 中 | 🟡 中 | 🔴 高 |

## 五、渠道矩阵

| 渠道 | K60 | MIX 2S | Note 7 | Note 4X |
|---|---|---|---|---|
| **QQ 机器人** | ✅ 102825839 | ✅ 1903080675 | ✅ 1905221791 | ✅ 1905222557 |
| **飞书** | ✅ | ✅ (流式卡片已修) | ✅ (长连接) | ✅ |
| **微信 iLink** | ✅ 970ed7c8f462-im-bot | 已装未绑 | 🗑️ 已移除 | ✅ 主号 (待移除) |
| **渠道总数** | **3 全活** | 2 + 1 未绑 | **2 全活** | 3 (含待移除) |

> ⚠️ ClawChat 全队废弃 (2026-07-23)
>
> **QQ 白名单联动：** 四台同出口 (当前 117.136.120.99)，宽带重拨 → q.qq.com 四台同更 → 1 分钟自愈

## 六、角色定位

| 设备 | 角色 | 说明 |
|---|---|---|
| **K60** | 🥇 随身主力 | 旗舰性能+蜂窝移动，三渠道全活，58+55 技能，唯一传感器/拍照，**已继承 Note 7 创意工作** |
| **Note 7** | 🥈 家里轻量 | QQ+飞书双活，SD660 禁并发 CLI，**创意工作已交接给 K60** |
| **MIX 2S** | 🔍 待定位 | 离线中，上线后全面分析 |
| **Note 4X** | 🏅 长期备机 | 离线中，3GB 韧性标杆，微信待移除 |

---

# 各设备篇章

## K60 — 随身主力机 `mondrian`

### 硬件档案

| 项目 | 参数 |
|---|---|
| **SoC** | 骁龙 8+ Gen 1 (4nm)，8 核，Adreno 730 |
| **RAM** | 16GB LPDDR5，实测可用 ~7.7GB |
| **存储** | 462GB UFS 3.1，125GB 已用（28%），337GB 空闲 |
| **电池** | 5500mAh，健康度 GOOD，循环 540 次，当前 100% 插电 |
| **系统** | Android 15 / HyperOS V816，全队唯一仍在官方支持 |
| **特殊硬件** | 屏下指纹、红外、NFC、立体声扬声器、VC 均热板 |

### 实时运行状态

```
运行时间:  4 天 22 小时     CPU 负载:  0.75 / 0.94 / 1.52
内存:      15.5GB 总 / 7.7GB 可用    Swap:  16.8GB 总 / 4.3GB 用
gateway:   RSS 362MB / VmSwap 0 / 12 线程   日志:  3.7MB
电池:      插电中, 100%, 35.6°C
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v24.17.0 LTS (仓库原生) | libsqlite 3.53.3
Python 3.14.6 + numpy | git 2.55.0 | termux-api v0.59.1
```

### 网络

| 路径 | 地址 | 状态 |
|---|---|---|
| Tailscale | 100.118.60.29 | ✅ |
| 家庭 WiFi | 192.168.1.23 | 🔀 当前不在 |
| 蜂窝网络 | 出口 117.136.120.99 | ✅ 当前使用 |
| SSH 互信 | ↔ Note 7 (100.91.94.44) | ✅ |

### 配置

| 项目 | 状态 |
|---|---|
| 活跃渠道 | qqbot + feishu + openclaw-weixin |
| 已配置模型 | 35 个 ⚠️ 建议精简到 5 个 |
| 默认模型 | alibaba-model-studio/qwen3.7-max-preview ⚠️ |
| 废弃模型 | deepseek-chat ❌ 待删除 |
| plugins.allow | 7 项，ClawChat 已清理 ✅ |
| 安全加固 | phantom 已关+锁 / Doze ✅ / Boot ✅ / SSH 免密 ✅ |

### 技能

| 来源 | 数量 | 说明 |
|---|---|---|
| workspace skills | 58 个 (33MB) | SkillHub 社区+技能包，金融投研/风控合规为主 |
| .agents skills | 🆕 55 个 | 从 Note 7 合并，研究/数据/微信工具 |
| 百炼工具链 | 🆕 modelstudioai-cli + bailian-cli | 视频/图片/语音生成 |
| 插件内置 | 7 个 | 飞书 4 + QQ 3 |

**金融投研：** stocks, finance-radar, fund-realtime-scraper, joinquant, quant-strategy, quant, quant-backtest-strategy, stock-strategy-backtester, openclaw-backtester

**风控合规：** sec, fintech-risk-control, riskofficer, a-share-risk-alert, pe-compliance-expert-pro, position-risk-manager, quant-risk-dashboard, finance-risk-assessment

**工具：** find-skill-skillhub, tianji-business-search

### 优势 / 待优化 / 潜力

| 🟢 优势 | 🟡 待优化 | 🚀 潜力 |
|---|---|---|
| 16GB RAM，唯一可并发 CLI | 默认模型切 deepseek-v4-flash | 本地小模型 (llama.cpp) |
| 蜂窝+WiFi 双网冗余 | 35→5 模型精简 | 手机眼 (拍照+视觉) |
| Termux:API 拍照/GPS/通知 | 电池智能充放电管理 | 飞书告警中枢 |
| Python+numpy+git 全配 | IP 漂移自动检测+通知 | 边缘计算节点 |
| 337GB 空闲 + 58+55 技能 | deepseek-chat 清理 | 🆕 继承 Note 7 视频/图片生成 |

---

## Note 7 — 家里轻量任务机 `lavender`

> 🆕 **工作交接完成 (2026-07-23)：** 创意生成工作（视频/图片/配音）已移交 K60。

### 硬件档案

| 项目 | 参数 |
|---|---|
| **SoC** | 骁龙 660 (14nm)，8 核，Adreno 512 |
| **RAM** | 6GB LPDDR4X，实测可用 ~3.0GB |
| **存储** | 50GB eMMC 5.1，13GB 已用（26%） |
| **电池** | 4000mAh，⚠️ 无 termux-api 无法远程监测 |
| **系统** | Android 10 / MIUI 12.5.7，EOL 自 2021/10 |
| **USB 调试** | ✅ adb 已启用 (getprop sys.usb.config = adb) |

### 实时运行状态

```
运行时间:  4 天 17 小时     CPU 负载:  正常 < 1.0 (孤儿进程已清理)
内存:      5.6GB 总 / 3.0GB 可用     Swap:  2.5GB 总 / 666MB 用
gateway:   RSS 319MB / VmSwap 0 / 12 线程    日志:  7.3MB
```

### 软件栈

```
OpenClaw 2026.7.1-2 | Node v26.4.0 (撤版前) | libsqlite 3.53.3
Python 3.14.6 | git 2.55.0 | 缺: termux-api, vim/nano
```

### 网络

| 路径 | 地址 | 状态 |
|---|---|---|
| Tailscale | 100.91.94.44 | ✅ |
| 家庭 WiFi | 192.168.122.238 | ✅ |
| 出口 IP | 117.136.120.99 | 与 K60 同 |
| SSH 互信 | ↔ K60 (100.118.60.29) | ✅ |
| 网关延迟 | 27-49ms | 正常 |

### 配置

| 项目 | 状态 |
|---|---|
| 活跃渠道 | qqbot + feishu |
| 已配置模型 | 11 个 🟢 |
| plugins.allow | feishu, qqbot, deepseek（全队最简） |
| 微信 iLink | 🗑️ 已移除 |
| 残留条目 | 无 ✅ 全队最干净 |

### 技能

| 来源 | 数量 | 说明 |
|---|---|---|
| 用户技能 | 1 个 (bailian-cli) | 🆕 已同步到 K60 |
| .agents skills | 55 个 (5.6MB) | 🆕 已全部移交 K60 |
| 插件内置 | 7 个 | 飞书 4 + QQ 3 |

### 🔴 禁止并发 CLI

```
正常:   gateway 1 进程，~319MB，~7% CPU
并发:   +1 CLI → ~50-270MB，~3-34% CPU → CPU load 8+
3GB 机: 双 CLI → gateway OOM 连坐
6GB 机: 双 CLI → CPU 满载但幸存

规则:   ✅ sv status / curl / tail / ps
        ❌ models list / channels probe / agent
```

### 优势 / 待优化

| 🟢 优势 | 🟡 待优化 |
|---|---|
| 配置极简 (3 plugins / 11 models) | 安装 termux-api (电池盲区) |
| A10 天然免疫 phantom killer | 安装 vim/nano (紧急排障) |
| 全链路自动恢复验证通过 | 日志轮转 (7.3MB) |
| 与 K60 SSH 互信 ✅ | Node 26.4.0 升级风险 |
| 创意工作已交接 ✅ | — |

---

## MIX 2S — 待重新定位 `polaris`

> 离线中 (2026-07-23)。上线后按此模板全面分析。

| 项目 | 数值 |
|---|---|
| SoC | 骁龙 845 (10nm) / 6GB LPDDR4x |
| 系统 | Android 10 / MIUI 12.5.1 |
| Tailscale | 100.104.72.125 |
| 渠道 | QQ (1903080675) + 飞书 + 微信 iLink (已装未绑) |
| 待办 | 全面分析、微信移除、技能盘点、SSH 互信配置 |

---

## Note 4X — 家里长期备机 `mido`

> 离线中 (2026-07-23)。上线后移除微信 iLink + 全面分析。

| 项目 | 数值 |
|---|---|
| SoC | 骁龙 625 (14nm) / 3GB LPDDR3 (禁并发 CLI) |
| 系统 | Android 7.0 / MIUI 11 |
| Tailscale | ❌ 不支持 |
| Node | 26.4.0 手动 deb + apt-mark hold |
| libsqlite | 3.53.0 (全队最低) |
| 渠道 | QQ (1905222557) + 飞书 + 微信 iLink (主号，待移除) |
| 待办 | 移除微信、全面分析、技能盘点 |

---

# 机队运维

## SSH 设备间互信

K60 ↔ Note 7 已配置双向免密，基于 Tailscale 固定 IP。

```
K60  → Note 7:  ssh -p 8022 u0_a171@100.91.94.44     ✅
Note 7 → K60:  ssh -p 8022 u0_a129@100.118.60.29     ✅
```

**配置：**
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519                        # 生成密钥
cat ~/.ssh/id_ed25519.pub | ssh 对端 'cat >> ~/.ssh/authorized_keys'    # 交换公钥
ssh -p 8022 -o BatchMode=yes 对端 'echo OK'                              # 验证
```

**应用：** scp 互传文件、rsync 同步技能、互相监控服务状态。

## 技能同步

### 快速对比

| | K60 | Note 7 |
|---|---|---|
| workspace | 58 个 (33MB) | 0 |
| .agents | 55 个 ← 从 Note 7 合并 | 55 个 → 已移交 |
| 百炼 | modelstudioai-cli + bailian ✅ | 原持有 → 已移交 |

### 同步方案

```bash
# 一次性: tar + scp (利用 SSH 互信)
ssh K60 'tar czf ~/skills.tar.gz -C ~/.openclaw/workspace skills/'
ssh K60 'scp -P 8022 ~/skills.tar.gz Note7:~/.openclaw/note7-handoff/'

# 长期: rsync 直推
rsync -avz -e "ssh -p 8022" \
  ~/.openclaw/workspace/skills/ \
  u0_a171@100.91.94.44:~/.openclaw/workspace/skills/

# 版本管理: Git 仓库
cd ~/.openclaw/workspace/skills && git init && git push  # 其他设备 git pull
```

> ⚠️ 含 Python `.venv` 的技能需在目标设备重建 venv。

## Note 7 → K60 工作交接

**时间：** 2026-07-23 | **方式：** SSH 互信直传 (Note 7 → K60)

| 类别 | 内容 | 大小 | K60 存储位置 |
|---|---|---|---|
| Agent 记忆 | openclaw-agent.sqlite + state DB | 3.4MB | `note7-handoff/` (参考，不覆盖) |
| 工作区 | AGENTS/IDENTITY/SOUL/USER/TOOLS + memory | ~50KB | `workspace/note7-*.md` (前缀防冲突) |
| 生成图片 | 26 张 AI 图片 + QQ 下载 | 23MB | `media/outbound/` 已合入 |
| 生成视频 | 388 个文件 (短剧/配音) | 5.6GB | 后台传输中 → `note7-handoff/out/` |
| 生成音频 | 10 个 MP3 (配音/旁白) | 含在 out | 同上 |
| 百炼工具 | modelstudioai-cli + bailian-cli | 2.9MB | `~/modelstudioai-cli/` + `skills/bailian-cli/` |
| Agent 技能 | .agents/skills/ 55 个 | 5.6MB | `~/.agents/skills/` 已合入 |

视频 5.6GB 通过 tar 流式管道直传（Note 7 → Tailscale → K60），不经过 PC。

---

## 运维速查

### 一键验证

```bash
# 单台检查
ssh -p 8022 u0_a129@100.118.60.29 'sv status openclaw'   # K60
ssh -p 8022 u0_a171@100.91.94.44 'sv status openclaw'    # Note 7

# 互相检查 (利用 SSH 互信)
ssh -p 8022 u0_a129@100.118.60.29 \
  "ssh -p 8022 u0_a171@100.91.94.44 'sv status openclaw'"  # K60 查 Note 7
```

### 升级流程

```
① K60 (旗舰) → ② MIX 2S → ③ Note 7 → ④ Note 4X
每步验证: sv status → curl :18789 → channels probe → agent E2E
```

### 关键命令

| 操作 | 命令 |
|---|---|
| 出口 IP | `curl -4 -s https://api.ip.sb/ip` |
| 版本三连 | `openclaw --version` / `node --version` / SQLite 版本查询 |
| 渠道列表 | `openclaw channels list --all \| grep enabled` (Note 7 用 grep 日志) |
| 日志 | `$PREFIX/var/log/sv/openclaw/current` |
| 重启 | `sv restart openclaw` (先 `export SVDIR=$PREFIX/var/service`) |
| K60→Note7 | `ssh -p 8022 u0_a171@100.91.94.44` |
| Note7→K60 | `ssh -p 8022 u0_a129@100.118.60.29` |
