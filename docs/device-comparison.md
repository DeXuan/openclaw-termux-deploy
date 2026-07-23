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
| **Python** | 3.14.6 + numpy (54 包) | — | 3.14.6 (3 包) | — |
| **git** | ✅ 2.55.0 | — | ✅ 2.55.0 | — |
| **termux-api** | ✅ v0.59.1 | — | ❌ 待安装 | — |
| **vim/nano** | ✅ | — | ❌ 待安装 | — |
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
| **K60** | 🥇 随身主力 | 旗舰性能+蜂窝移动，三渠道全活，58+55 技能，唯一有传感器/拍照/蜂窝冗余 |
| **Note 7** | 🥈 家里轻量 | QQ+飞书双活，SD660 禁并发 CLI，创意工作已交接给 K60 |
| **MIX 2S** | 🔍 待定位 | 离线中，上线后全面分析 |
| **Note 4X** | 🏅 长期备机 | 离线中，3GB 韧性标杆，微信待移除 |

---

# 各设备篇章

## K60 — 随身主力机 `mondrian`

### 硬件档案

| 项目 | 参数 |
|---|---|
| **SoC** | 骁龙 8+ Gen 1 (4nm)，8 核，Adreno 730 |
| **RAM** | 16GB LPDDR5，实测可用 ~6.9GB |
| **存储** | 462GB UFS 3.1，125GB 已用（28%），335GB 空闲 |
| **电池** | 5500mAh，健康度 GOOD，循环 540 次，当前 100% 插电 |
| **系统** | Android 15 / HyperOS V816，全队唯一仍在官方支持 |
| **特殊硬件** | 屏下指纹、红外、NFC、立体声扬声器、VC 均热板 |

### 实时运行状态 (2026-07-23)

```
运行时间:  4 天 22 小时     CPU 负载:  3.17 / 2.40 / 1.98  (70% 空闲)
内存:      15.5GB 总 / 6.9GB 可用     Swap:  16.8GB 总 / 4.3GB 用
gateway:   RSS 362MB / VmSwap 0 / 12 线程    日志:  3.7MB
电池:      插电中, 100%, 35.6°C
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
| 默认模型 | alibaba-model-studio/qwen3.7-max-preview ⚠️ 应切 deepseek-v4-flash |
| 废弃模型 | deepseek-chat ❌ 待删除 |
| plugins.allow | 7 项，ClawChat 已清理 ✅ |

### 技能

| 来源 | 数量 | 类别 |
|---|---|---|
| workspace skills | 58 个 (33MB) | 金融投研 / 风控合规 / 工具 |
| .agents skills | 55 个 (从 Note 7 合并) | 研究 / 数据分析 / 微信 |
| 百炼工具链 | modelstudioai-cli + bailian-cli | 视频/图片/语音生成 |
| 插件内置 | 7 个 | 飞书 4 + QQ 3 |

### 优势 / 待优化 / 潜力

| 🟢 优势 | 🟡 待优化 | 🚀 潜力 |
|---|---|---|
| 16GB RAM，唯一可并发 CLI | 默认模型切 deepseek-v4-flash | 本地小模型 (llama.cpp) |
| 蜂窝+WiFi 双网冗余 | 35→5 模型精简 | 手机眼 (拍照+GPS+视觉) |
| Termux:API 拍照/GPS/通知 | 电池智能充放电管理 | 飞书告警中枢 |
| Python 54 包 + numpy | IP 漂移自动检测 | 边缘计算节点 |
| 335GB 空闲 | deepseek-chat 清理 | 继承 Note 7 创意工作 |

---

## Note 7 — 家里轻量任务机 `lavender`

> 🆕 工作交接完成 (2026-07-23)：创意生成（视频/图片/配音）已移交 K60。

### 硬件档案

| 项目 | 参数 |
|---|---|
| **SoC** | 骁龙 660 (14nm)，8 核，Adreno 512 |
| **RAM** | 6GB LPDDR4X，实测可用 ~3.1GB |
| **存储** | 50GB eMMC 5.1，13GB 已用（26%），37GB 空闲 |
| **电池** | 4000mAh，⚠️ 无 termux-api 无法远程监测 |
| **系统** | Android 10 / MIUI 12.5.7，EOL 自 2021/10 |

### 实时运行状态 (2026-07-23)

```
运行时间:  4 天 17 小时     CPU 负载:  6.73 / 6.92 / 6.98 (视频传输中，传完回落)
内存:      5.6GB 总 / 3.1GB 可用     Swap:  2.5GB 总 / 666MB 用
gateway:   RSS 319MB / VmSwap 0 / 12 线程    日志:  7.3MB
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

### 🔴 核心约束：禁止并发 CLI

一次 `openclaw models list` 产生 **33.8% CPU + 267MB RAM** 孤儿进程。

```
正常:   gateway 1 进程，~319MB，~7% CPU
并发:   +1 CLI → 50-270MB，3-34% CPU → load 8+
允许:   ✅ sv status / curl / tail / ps
禁止:   ❌ models list / channels probe / agent
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

**配置方法：**

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519                        # 生成密钥
cat ~/.ssh/id_ed25519.pub | ssh 对端 'cat >> ~/.ssh/authorized_keys'    # 交换公钥
ssh -p 8022 -o BatchMode=yes 对端 'echo OK'                              # 验证
```

**应用场景：** scp 互传文件、rsync 同步技能、互相监控服务状态、远程重启 gateway。

## 技能同步

### 对比

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
| 生成视频 | 388 个文件 (短剧/配音) | 5.6GB | 后台传输 → `note7-handoff/out/` |
| 生成音频 | 10 个 MP3 (配音/旁白) | 含在 out | 同上 |
| 百炼工具 | modelstudioai-cli + bailian-cli | 2.9MB | `~/modelstudioai-cli/` + `skills/bailian-cli/` |
| Agent 技能 | .agents/skills/ 55 个 | 5.6MB | `~/.agents/skills/` 已合入 |

---

# 能力压榨与展望

> 如何充分发挥两台在线设备的全部潜力，以及未来的演进方向。

## 当前资源余量

| | K60 | Note 7 |
|---|---|---|
| **CPU 空闲** | ~70% (load 3.17/8核) | ~15% (视频传输中，传完回升) |
| **RAM 可用** | 6.9GB | 3.1GB |
| **磁盘空闲** | 335GB | 37GB |
| **Python 生态** | 54 个包 + numpy | 3 个包 |
| **定时任务** | 无 | 无 |
| **独特能力** | 摄像头/GPS/通知/蜂窝 | 固定位置/稳定网络/USB adb |

## 🟢 第一层：立即可做

### 1. 互相守望——双机健康监控

SSH 互信最直接的价值：两台设备互为对方的哨兵。

```bash
# K60 crontab: 每 5 分钟检查 Note 7
*/5 * * * * ssh -p 8022 u0_a171@100.91.94.44 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/' | grep -q 200 || \
  curl -X POST $FEISHU_WEBHOOK -H "Content-Type: application/json" \
    -d '{"msg_type":"text","content":{"text":"🚨 Note 7 gateway 无响应！"}}'

# Note 7 crontab: 每 5 分钟检查 K60（同上，对调 IP）
```

### 2. IP 漂移自动告警

K60 在蜂窝和 WiFi 间切换时出口 IP 会变，QQ 白名单失效。自动检测 + 通知：

```bash
# */10 * * * *
CUR=$(curl -4 -s https://api.ip.sb/ip)
LAST=$(cat ~/.last_ip 2>/dev/null)
if [ "$CUR" != "$LAST" ]; then
  echo "$CUR" > ~/.last_ip
  curl -X POST $FEISHU_WEBHOOK -H "Content-Type: application/json" \
    -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"⚠️ 出口 IP 变为 $CUR，需更新 QQ 白名单\"}}"
fi
```

### 3. 清理 K60 配置债务

- 默认模型：`alibaba-model-studio/qwen3.7-max-preview` → `deepseek/deepseek-v4-flash`
- 模型精简：35 → 5 个（主力 + 2 fallback + 1 视觉 + 1 应急）
- 删除退役模型：`deepseek-chat`（2026-07-24 退役）
- 清理残留：`channels.openclawwechat` (enabled=undefined)

## 🟡 第二层：能力释放

### 4. K60 "手机眼"——摄像头 + GPS 接入 bot

Termux:API 已装。其余三台永远做不到的能力：

```
用户说"拍张照"   → termux-camera-photo → 回传图片
用户说"我在哪"   → termux-location → 返回 GPS 坐标
用户说"扫这个码" → 拍照 + Python OCR/解析
```

```bash
# 拍照脚本示例
termux-camera-photo -c 0 ~/photo.jpg
# 然后通过 OpenClaw agent 或直接发到 QQ/飞书
```

### 5. 分布式定时任务

```
K60 (移动，白天活跃):                Note 7 (固定，24h):
  金融数据抓取 (交易时间)              网络质量监控 (24h)
  AI 日报生成 (每天 08:30)            日志聚合 + 轮转 (每天 03:00)
  股价预警推送 (实时)                 机队配置备份 (每天 04:00)
  视频渲染 (按需)                     QQ 白名单 IP 巡检 (每 10min)
```

Python 已装 + cron 就绪，只需写脚本。

### 6. Note 7 文件服务器

固定家庭网络 + 37GB 空闲，天然适合做共享存储：

```bash
# Note 7 起一个内网文件服务
cd ~/.openclaw/workspace/out && python -m http.server 8080
# K60 通过 Tailscale IP 访问: http://100.91.94.44:8080
# PC 也能访问，不需要 scp
```

### 7. Note 7 安装缺失工具

```bash
pkg install termux-api vim
```

有了 termux-api 就能远程监测电池（当前盲区），有了 vim 紧急排障不依赖 PC。

## 🔴 第三层：压榨极限

### 8. 本地小模型——K60 离线推理

```
16GB RAM + 8 核旗舰 + 335GB 存储 + Python + numpy
→ 安装 llama.cpp (Termux 可编译)
→ 下载 Qwen2.5-7B / DeepSeek-R1-7B 量化版 (~4GB)
→ 敏感数据不出设备的本地推理
→ 断网时仍有 AI 能力
```

Note 7 (6GB) 也能跑 0.5B-1.5B 小模型做简单分类、摘要、意图识别。

### 9. 技能自主开发

58 个技能是消费侧，下一步是生产侧：

```
K60 开发技能 → Git 仓库管理 → rsync 推送到 Note 7

例: "每日机队健康报告" 技能
  cron 触发 → SSH 收集四台状态 → Python 生成报告 → 飞书推送
```

### 10. API 网关——对外暴露服务

```
K60 上起 Python Flask/FastAPI (端口随便，Tailscale 内网):
  GET  /api/photo        → 调用摄像头拍照，返回图片
  GET  /api/location     → 返回 GPS 坐标
  POST /api/agent        → 代理 OpenClaw agent 调用
  GET  /api/fleet-status → 聚合四台设备状态

Note 7 上起轻量服务:
  GET  /api/logs         → 查询聚合日志
  GET  /api/health       → 全队健康检查
```

通过 Tailscale 固定 IP，PC 和其他设备可以直接调 API。

### 11. 消息管道——设备间异步协作

```
K60 收到复杂任务 → 拆分为子任务 → SSH 分发到 Note 7 → 结果汇聚

例: "分析这只股票"
  → K60:  抓取实时行情 + 技术指标 (Python)
  → Note7: 抓取新闻舆情 + 财报数据 (Python)
  → 汇聚到 K60 → agent 综合分析 → 回复用户
```

### 12. 统一存储层——sshfs 挂载

```bash
# K60 挂载 Note 7 的媒体库（需先 pkg install sshfs）
sshfs -p 8022 u0_a171@100.91.94.44:~/.openclaw/workspace/out \
  ~/mounts/note7-out/

# Note 7 挂载 K60 的技能库
sshfs -p 8022 u0_a129@100.118.60.29:~/.openclaw/workspace/skills \
  ~/mounts/k60-skills/
```

两台设备的文件系统融为一体，任意一台都能访问全部数据。

## 🧭 更远的展望

### 13. 四台联邦——全队协同

```
        K60 (主力) ←→ Note 7 (轻量)
         ↕               ↕
      MIX 2S (待定)  Note 4X (备机)
```

当四台全部在线+互信：
- **按能力路由**：K60 处理创意/视觉，SD660/845 处理文本，Note 4X 兜底
- **地理冗余**：K60 随身移动，其余三台在不同位置
- **模型分级**：旗舰跑大模型 (v4-pro)，中端跑小模型 (v4-flash)，低端只做转发
- **数据联邦**：每台采集不同数据源，统一汇聚分析

### 14. 自愈系统

当前依赖 runit + 人工。下一步：

```
A 机检测 B 机 gateway 挂了 → SSH 进去 sv restart
重启失败 → 飞书告警 + 尝试回滚配置
配置损坏 → 从 Git 仓库恢复上一版本
磁盘满了 → 自动清理旧日志
```

### 15. OpenClaw 原生 nodes——深度集成

当前 `openclaw nodes` 系统未启用（Android 不支持安装 node 系统服务）。如果研究清楚配对机制，可以让 K60 的 gateway 直接管理 Note 7 作为 node：

```
K60 gateway (控制平面)
  ├── Note 7 node (能力: 网络/存储/备用算力)
  ├── MIX 2S node (待定)
  └── Note 4X node (待定)
```

用户只需和 K60 一个 bot 对话，K60 自动调度背后的 node 网络。

### 16. 边缘 AI 集群

```
K60: llama.cpp 跑 7B 模型 (创意/推理/分析)
Note 7: llama.cpp 跑 1.5B 模型 (分类/摘要/意图识别)
协同: K60 处理复杂请求，Note 7 预处理+过滤

→ 不依赖云 API → 零成本推理 → 隐私数据不出设备
```

## 📊 能力矩阵

| 场景 | 难度 | 价值 | 依赖 | 预计耗时 |
|---|---|---|---|---|
| 互相健康监控+告警 | ⭐ | 🔴 高 | SSH+cron+飞书 webhook | 30min |
| IP 漂移自动检测 | ⭐ | 🔴 高 | cron+curl | 15min |
| K60 模型/配置清理 | ⭐ | 🟡 中 | openclaw CLI | 10min |
| Note 7 基础工具安装 | ⭐ | 🟡 中 | pkg install | 5min |
| K60 拍照/GPS 接入 bot | ⭐⭐ | 🟡 中 | termux-api + 脚本 | 1h |
| 分布式定时任务 | ⭐⭐ | 🟡 中 | Python+cron | 2h |
| Note 7 文件服务 | ⭐ | 🟢 低 | Python http.server | 5min |
| 本地小模型推理 | ⭐⭐⭐ | 🟡 中 | llama.cpp + 4GB 模型 | 2h |
| 飞书告警中枢 | ⭐⭐ | 🔴 高 | Python+webhook | 1h |
| API 网关 | ⭐⭐⭐ | 🟡 中 | Flask/FastAPI | 3h |
| 技能自主开发 | ⭐⭐⭐ | 🔴 高 | Python+Git | 持续 |
| 消息管道协作 | ⭐⭐⭐⭐ | 🟢 低 | SSH+脚本 | 4h |
| sshfs 统一存储 | ⭐⭐ | 🟢 低 | sshfs pkg | 30min |
| 全队四机联邦 | ⭐⭐⭐⭐ | 🔴 高 | 全队上线+互信 | 持续 |
| 自愈系统 | ⭐⭐⭐ | 🔴 高 | cron+SSH+Git | 4h |
| nodes 原生集成 | ⭐⭐⭐⭐⭐ | 🔴 高 | 研究配对机制 | 未知 |
| 边缘 AI 集群 | ⭐⭐⭐⭐ | 🔴 高 | llama.cpp×2 | 4h |

---

## 运维速查

### 一键验证

```bash
# 单台检查
ssh -p 8022 u0_a129@100.118.60.29 'sv status openclaw'   # K60
ssh -p 8022 u0_a171@100.91.94.44 'sv status openclaw'    # Note 7

# 互相检查 (利用 SSH 互信)
ssh K60 "ssh Note7 'sv status openclaw'"   # K60 查 Note 7
ssh Note7 "ssh K60 'sv status openclaw'"   # Note 7 查 K60
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
| 版本三连 | `openclaw --version` / `node --version` / SQLite 版本 |
| 渠道列表 | `openclaw channels list --all \| grep enabled` (Note 7 用日志) |
| 日志 | `$PREFIX/var/log/sv/openclaw/current` |
| 重启 | `sv restart openclaw` (先 `export SVDIR=$PREFIX/var/service`) |
| K60→Note7 | `ssh -p 8022 u0_a171@100.91.94.44` |
| Note7→K60 | `ssh -p 8022 u0_a129@100.118.60.29` |
