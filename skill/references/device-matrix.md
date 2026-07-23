# 机型适配矩阵与最佳实践

> 本文档回答三个问题：**新机型怎么接入**、**已知机型有什么坑**、**怎么安全升级版本**。
> 部署主流程见 [SKILL.md](../SKILL.md) 阶段 0-8；报错速查见 [pitfalls.md](pitfalls.md)（24 坑）。

## 0. 使用地图

| 你要做什么 | 看哪一节 |
|---|---|
| 接入一台**新机型** | §1 新机型接入工作流 |
| 查新机该做哪些**加固** | §2 Android 版本决策树 |
| 查某系统皮肤/硬件档位的**专属坑** | §3 皮肤与硬件注意项 |
| 查**已验证机型**的档案与版本组合 | §4 机型档案 |
| 该装哪个 **APK**、去哪下载 | §5 APK 安装包速查 |
| **升级** OpenClaw 版本 | §6 升级 SOP（必读，有事故实录） |
| **多台设备**一起管理 | §7 机队经验 |

## 1. 新机型接入工作流

```
① 识别 → ② 对号入座 → ③ 叠加注意项 → ④ 部署 → ⑤ 登记
```

1. **识别**（SSH 可用后第一件事）：

   ```bash
   ssh -p 8022 user@<IP> 'getprop ro.product.model; getprop ro.product.marketname; getprop ro.build.version.release; getprop ro.miui.ui.version.name'
   ```

   ⚠️ 型号考证以 `ro.product.marketname` 为准（例：23013RK75C 是 K60 标准版，非 Pro）。

2. **对号入座**：按 Android 版本查 §2 决策树，确定加固动作集与 Tailscale 可用性。
3. **叠加注意项**：按系统皮肤（HyperOS / MIUI…）与硬件档位（旗舰 / 低端 SoC / 小内存）查 §3。
4. **部署**：走 SKILL.md 阶段 0-8，每阶段过验证门。
5. **登记**：全部验证门通过后，把新机型按 §4 的模板补进两张表（这是本矩阵持续生长的方式）。

## 2. Android 版本决策树（加固动作集）

| Android 版本 | phantom process killer | 权限自动撤销 | Doze 白名单 | Tailscale App |
|---|---|---|---|---|
| 12+ | ⚠️ **必关**（adb） | ⚠️ **必禁** | 必做 | ✅ |
| 8–11 | 无此机制，跳过 | A11+ 才有 | 必做 | ✅ |
| ≤7 | 无 | 无 | 必做 | ❌ 装不上 |

- **Android 12+**：不关 phantom killer，Termux 子进程会被静默杀；全套命令见 [hardening.md](hardening.md)，HyperOS 还需 `device_config set_sync_disabled_for_tests persistent` 防云端回滚
- **Android 10–11**：天然免疫 phantom killer（A12 才引入）；A10 连权限自动撤销都没有——加固只剩 Doze 白名单一项
- **Android ≤7**：Termux 0.118 可跑、openclaw 正常编译；但 Tailscale 官方 App 不支持 → 放弃组网，走局域网固定 IP（路由器 MAC 绑定）+ SSH 管理

## 3. 系统皮肤 / 硬件档位注意项

新机型大概率能在这里对号入座；发现新皮肤/新档位的坑，在本节加小节。

### HyperOS（小米 Android 14+ 皮肤）
- APK 安装：termux-open 的 content:// 报"解析软件包错误"（坑 8）→ 复制到 `~/storage/downloads/` 用文件管理器**按路径**找到安装
- 关 phantom killer 后必须锁 `device_config`（persistent），否则设置会被云端同步回滚
- Termux 内 `pm list packages` 受包可见性限制会**漏报**（termux.boot / tailscale 明明装了却显示无）→ 验证已装用 adb 或看重启行为

### MIUI 12.5（Android 10 代机型）
- 普通「USB 调试」**没有 WRITE_SECURE_SETTINGS**（`settings put` 被拒）→ 改 settings 需另开「USB 调试（安全设置）」（要插 SIM + 登小米账号）；Doze 白名单（`dumpsys deviceidle whitelist`）和 appops 不受此限
- USB 调试开关会**静默弹回**（开启时确认弹窗被误点掉）→ SSH 里 `getprop sys.usb.config` 输出含 adb 才是真开了
- Termux 装 openssh 后 `sshd: no hostkeys available` → `ssh-keygen -A`
- Android 10 默认**按网络随机化 MAC** → 路由器做 MAC 绑定前，先在 WLAN 详情把该网络改为"使用设备 MAC"（否则"忘记网络"重连后绑定失效）

### 低端 SoC（骁龙 6xx 及以下）/ 小内存（≤4GB）
- gateway 冷启动到 listening 要 **40–60 秒**（骁龙660 实测）；升级后首启含 state 迁移可达 **2.5–3 分钟**（骁龙625 实测）→ 验证门的 curl 多等一会，别急着判失败
- 3GB RAM 机型只做供应商节点/轻量渠道聊天，别跑重 agent 工作流
- 同一时刻只跑**一个** openclaw CLI 实例（login / probe / agent 均为完整 node 进程）——3GB 机双开 login 实测把 gateway 连坐 OOM（坑 23）

## 4. 已验证机型档案（4 台真机，2026-07 实测）

| 机型（marketname） | 系统 | SoC / RAM | 角色 | 渠道 | 特记 |
|---|---|---|---|---|---|
| Redmi K60（23013RK75C） | Android 15 / HyperOS (V816) | 骁龙8+ Gen1 / 16GB | 主力机 | QQ bot + 飞书 | 全套 adb 加固必做 |
| Xiaomi MIX 2S | Android 10 / MIUI 12.5.1 | 骁龙845 / 6GB | 副机 | QQ bot + 飞书 | 免 phantom 加固 |
| Redmi Note 7 | Android 10 / MIUI 12.5.7 | 骁龙660 / 6GB | 全流程验证机 | 飞书 + QQ bot | gateway 冷启动 40-60s |
| Redmi Note 4X | Android 7.0 / MIUI 11 | 骁龙625 / 3GB | 轻量三渠道节点 | QQ bot + 飞书 + 微信（官方 iLink） | 无 Tailscale；node 手动 deb（§6）；微信首装验证机（channel-weixin.md） |

### 工具版本组合（2026-07-18 全队定版，全部四连验证通过）

| 设备 | OpenClaw | Node | libsqlite | Node 来源 |
|---|---|---|---|---|
| K60 | 2026.7.1-2 | 24.17.0 | 3.53.3 | 仓库（早期 nodejs-lts） |
| MIX 2S | 2026.7.1-2 | 26.4.0 | 3.53.3 | 仓库（撤版前安装） |
| Note 7 | 2026.7.1-2 | 26.4.0 | 3.53.3 | 仓库（撤版前安装） |
| Note 4X | 2026.7.1-2 | 26.4.0 | 3.53.0 | **手动 deb + apt-mark hold** |

### 新机型登记模板（部署完成后复制此行填入上面两表）

```
| <机型（marketname）> | Android x / <皮肤版本> | <SoC / RAM> | <角色> | <渠道> | <一句话特记> |
| <设备名> | <openclaw --version> | <node --version> | <sqlite_version()> | <仓库 / 手动 deb> |
```

版本取数命令：`openclaw --version; node --version; node -e "const s=require('node:sqlite');console.log(new s.DatabaseSync(':memory:').prepare('select sqlite_version() v').get().v)"`

## 5. APK 安装包速查（按机型适配）

| APK | 适用 | 下载源 | 安装方式 |
|---|---|---|---|
| Termux 主程序 | 全机型 | F-Droid 官网/镜像 | 直装（勿用 Play 版） |
| Termux:Boot `com.termux.boot_1000.apk` | 全机型必装 | `mirrors.tuna.tsinghua.edu.cn/fdroid/repo/`（F-Droid 签名，配 F_DROID 版主程序，坑 7） | cp 到 `~/storage/downloads/` → 文件管理器**按路径**安装（坑 8/9） |
| Tailscale `tailscale-android-universal-*.apk` | **Android 8+**（A7 装不上） | `pkgs.tailscale.com/stable/`（GitHub CDN 被阻断、ghproxy 全灭时的可达源） | 同上文件管理器路线；装后设「始终开启 VPN」 |
| Termux:API `com.termux.api`（versionCode 1002, v0.53.0） | 需拍照/传感器的机器 | 清华 F-Droid 镜像（GitHub debug 版签名不兼容报 -8） | 同上 |

## 6. 版本升级 SOP（金丝雀流程；事故实录见 pitfalls 坑 17-20）

**OpenClaw 2026.7.1-x 有双重启动检查**，缺一不可：

1. **CLI 层 Node 版本号**：`>=22.22.3 <23`、`>=24.15.0 <25` 或 `>=25.9.0`（26.x 满足最后一档）
2. **运行层 SQLite**：≥3.51.3（WAL 损坏防护）。Termux 的 node **动态链接系统 `libsqlite` 包** —— 报"SQLite unsafe"时先 `apt install --only-upgrade libsqlite`，**不要去折腾 Node**（错误文案会误导怪罪 Node 版本）

**Termux 仓库快照（2026-07-18，会过时，动手前重查 `apt list -a nodejs nodejs-lts`）**：
`nodejs 25.8.2` ❌（差 0.0.1）、`nodejs-lts 24.14.1` ❌（差 0.0.1）——索引里无合规版本；26.4.0 已撤出索引但 pool 文件仍在：

```bash
# 手动安装合规 node（Termux 无 /tmp！写 $HOME，坑 21）
curl -4 -L -o $HOME/nodejs_26.4.0.deb \
  https://mirrors.ustc.edu.cn/termux/apt/termux-main/pool/main/n/nodejs/nodejs_26.4.0_aarch64.deb
dpkg -i $HOME/nodejs_26.4.0.deb
apt-mark hold nodejs          # 锁版，防 apt upgrade 回退到不合规版本
# node 变更后必须重装 openclaw（native 模块按新 ABI 重编）
```

**金丝雀流程**：

1. **单台先升**：`apt install --only-upgrade libsqlite` → 确认 node 合规 → npm 升 openclaw → `sv restart`
2. 首启会跑 state 迁移（低端机 2-3 分钟），**期间别反复 restart**（会触发迁移锁，报 "migrations are already running"，~2 分钟过期自愈，坑 19）
3. **四连验证**（sv run / HTTP 200 / channels probe / agent E2E）全过，**再推其余设备**
4. E2E 报 `No API key found` = `agents/main/agent/openclaw-agent.sqlite`（auth store）被动过，回填备份（坑 20）

## 7. 多设备机队经验（含维护者实例参数，仅作格式示例）

- **多 QQ bot 分诊**：每台设备挂独立 AppID（例：K60=102825839、MIX 2S=1903080675、Note 7=1905221791、Note 4X=1905222557）。"QQ 无响应"**先分清用户发消息的是哪个 bot 的聊天窗口**——一台 401 离线时另一台日志完全正常，极易误判成"新部署的坏了"。对号方法：各机跑 `node -e "console.log(require(process.env.HOME+'/.openclaw/openclaw.json').channels.qqbot.appId)"`，再查对应设备日志
- **白名单联动**：同一家庭宽带下所有设备出口 IPv4 相同 → 宽带重拨/换网后**所有 QQ bot 的白名单要一起更新**；白名单加好后无需重启，插件每分钟自动重试，约 1 分钟自愈
- **PC 端连接脚本按设备命名**（sshk60 / sshmix2s / ssh4x / sshnote7…），每个脚本 Tailscale IP 优先 + 局域网/热点网关回退、独立 HostKeyAlias——别共用一个"sshphone"，机队一大就名不符实
- **OpenClawX App 协议不匹配**：gateway 日志每 0.4s 刷 `protocol mismatch client=OpenClawX Node ... expected=4`（ua=Dart，来源 127.0.0.1）= 本机装的 OpenClawX App 客户端太旧，升级到协议 v4 版或卸载该 App 即止（费电+刷爆日志，不影响渠道功能）
- **SSH 设备间互信**：多台设备间配置双向 SSH 免密（基于 Tailscale 固定 IP），实现 scp 互传、rsync 同步技能、互相监控 gateway。
- **双机健康监控**：`pkg install cronie` + 注册 runit → 部署 `~/healthcheck.sh`（SSH 对端 curl gateway，异常时通过 openclaw agent 推送 QQ 告警）→ `crontab` 定时触发。正常静默，仅异常时消耗 token。
- **IP 漂移检测**：移动设备（蜂窝/WiFi 切换）出口 IP 变化导致 QQ 白名单失效 → `~/check-ip.sh` 定时对比 `curl ip.sb` 结果 → 变化时 QQ 告警（含白名单更新提醒）。
- **Node.js 性能优化**：修改 `$PREFIX/var/service/openclaw/run` 中 `NODE_OPTIONS`，添加 `--max-old-space-size=4096 --max-semi-space-size=128`。16GB 设备 heap 上限提升 300%，GC 间隔延长 3.6-8x。注意 `--initial-old-space-size` 会被 Node 安全策略拦截。
