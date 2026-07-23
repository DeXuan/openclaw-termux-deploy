# OpenClaw 四台手机机队全方位对比

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
| **微信官方 (iLink)** | 已装未绑 | 已装未绑 | 已装未绑 | ✅ **已绑定（占主号）** |
| **ClawChat 微信小程序** | ✅ E2E 通过 (bot_id=20233850) | ❌ | ❌ | ❌ |
| **渠道总数** | 4 (含 1 未绑) | 3 (含 1 未绑) | 3 (含 1 未绑) | 3 (全活) |

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
| **K60** | 🥇 主力机 | 性能最强，16GB RAM 无 OOM 风险；唯一支持 ClawChat 小程序；Termux:API 支持拍照/传感器；渠道最全 |
| **MIX 2S** | 🥈 稳定副机 | 骁龙 845 次旗舰性能，加固最简单（Android 10 天然免疫 phantom killer）；QQ + 飞书双通道稳定运行 |
| **Note 7** | 🥉 验证机 | 全流程部署验证机，骁龙 660 冷启动慢但四链路（sshd/gateway/TS/双渠道）自动恢复全部验证通过 |
| **Note 4X** | 🏅 韧性标杆 | 唯一三渠道全活设备（含微信 iLink 主号绑定）；唯一 Qwen 供应商；3GB RAM 下稳定运行，但禁止并发 CLI 实例 |

### 重启后自愈能力

| 设备 | sshd | gateway | Tailscale | QQ | 飞书 | 微信 | 全部通过 |
|---|---|---|---|---|---|---|---|
| K60 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| MIX 2S | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ |
| Note 7 | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ |
| Note 4X | ✅ | ✅ | N/A | ✅ | ✅ | ✅ | ✅ |

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

**一句话总结：** K60 是全能旗舰主力，MIX 2S 是加固最简单的稳定副机，Note 7 是全流程验证的可靠中端，Note 4X 是 3GB 内存下三渠道全活的韧性标杆。机队最大运维痛点不是单机稳定性，而是 **QQ 白名单四台联动**——宽带重拨一次需同时更新四个 AppID。
