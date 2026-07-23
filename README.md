# 安卓手机一键部署 OpenClaw 小龙虾！完整打通微信 / QQ / 飞书保姆级教程（Termux 原生方案）

> **文档版本：v2.5** ｜ 最后更新：2026-07-19 ｜ 版本历史见文末
>
> 部署日期：2026-07-16（首台）
> 设备：已验证 4 台真机机队 —— Redmi K60（23013RK75C，Android 15/HyperOS）· Xiaomi MIX 2S（Android 10）· Redmi Note 7（Android 10）· Redmi Note 4X（Android 7），适配矩阵见「方案评估」章
> 环境：Termux 0.118.0（F-Droid 版），Node.js 24.17.0 / 26.4.0（按机型，见适配矩阵）
> 模型：DeepSeek V4 Flash（`deepseek/deepseek-v4-flash`）全队统一
> 渠道：QQ 机器人 ×4 + 飞书 ×4 + 微信官方 iLink ×4（Note 4X 已绑定在线，其余三台已装待绑），四台全渠道在线（OpenClaw 2026.7.1-2）
> GitHub：https://github.com/DeXuan/openclaw-termux-deploy

---

## 🧰 快速开始：部署工具箱
https://github.com/DeXuan/openclaw-termux-deploy/blob/worktree-doc-restructure/GUIDE.md
# OpenClaw Deploy — 工具箱使用指南
```bash
git clone https://github.com/DeXuan/openclaw-termux-deploy.git
cd openclaw-termux-deploy
chmod +x openclaw-deploy
./openclaw-deploy
```

彩色 TUI 工具箱，8 大功能模块，PC 和 Termux 都可以用。

| 功能 | 说明 |
|---|---|
| 🚀 新手向导 | 6 步引导式部署，零基础也能完成 |
| 📦 部署设备 | PC 远程 SSH 或本机直接安装 Node.js + OpenClaw + runit |
| 🔍 设备体检 | 一键诊断机型/版本/服务状态 |
| 📊 机队仪表盘 | 四台设备 gateway/内存/磁盘/swap/在线时长实时展示 |
| ⚙️ 服务管理 | 启停/重启/实时日志（本机 + 远程） |
| 🩺 自愈系统 | 双向互检 + 自动重启 + 内存/磁盘阈值保护 |
| 🧩 技能工具箱 | 安装/搜索/同步技能到远程设备 |
| 🤖 模型与渠道 | 模型管理、渠道状态、免费额度查询 |

**非交互模式：** `./openclaw-deploy dashboard` | `./openclaw-deploy check` | `./openclaw-deploy wizard`

> 📖 **完整使用指南：[GUIDE.md](GUIDE.md)** — 界面截图、功能详解、常见问题、进阶玩法

---

## 目录

- [方案评估：手机作为服务器](#方案评估手机作为服务器)
  - [已验证机型与适配矩阵](#已验证机型与适配矩阵)
- **第一部分：基础部署**
  - [一、前置条件（手机端首次准备）](#一前置条件手机端首次准备)
  - [二、SSH 免密登录](#二ssh-免密登录)
  - [三、安装 OpenClaw](#三安装-openclaw)
  - [四、配置模型供应商](#四配置模型供应商)
- **第二部分：服务化与系统加固**
  - [五、进程保活（runit）](#五进程保活runit)
  - [六、开机自启（Termux:Boot）](#六开机自启termuxboot)
  - [七、系统加固（adb）](#七系统加固adb)
- **第三部分：网络与远程访问**
  - [八、Tailscale 跨网络固定 IP](#八tailscale-跨网络固定-ip)
  - [九、PC 端连接工具（sshphone）](#九pc-端连接工具sshphone)
- **第四部分：对接应用**
  - [十、PC 网页控制台](#十pc-网页控制台)
  - [十一、QQ 机器人](#十一qq-机器人)
  - [十二、飞书机器人](#十二飞书机器人)
  - [十三、微信机器人（腾讯官方 iLink）](#十三微信机器人腾讯官方-ilink)
  - [十四、多渠道共存](#十四多渠道共存)
- **第五部分：附加功能**
  - [十五、远程拍照](#十五远程拍照)
  - [十六、定时任务](#十六定时任务)
- **第六部分：日常运维**
  - [十七、运维速查](#十七运维速查)
  - [十八、安全加固建议](#十八安全加固建议)
  - [十九、卸载与回滚](#十九卸载与回滚)
- **附录**
  - [踩坑速查表](#附一踩坑速查表24-坑)
  - [渠道选择对比](#附二渠道选择对比)
  - [版本历史](#附三版本历史)

---

## 方案评估：手机作为服务器

### 适用场景

| 场景 | 说明 |
|------|------|
| ✅ 24/7 个人 AI 助手 | 模型跑在云端 API，本机只做调度，负载极轻 |
| ✅ 常驻轻服务 | 聊天机器人、Webhook 接收器、爬虫、定时任务、个人 API |
| ✅ 轻量数据 | SQLite 极佳（UFS 闪存随机 IO 快），也能跑 PostgreSQL |
| ✅ 私有网络枢纽 | 配合 Tailscale 做设备互联的常在线节点 |
| ✅ 旧手机再利用 | 自带电池 + 5G，停电断宽带都不受影响 |

### 不适用场景

❌ **公网大流量服务**：无公网 IP、NAT 层多、上行带宽受限
❌ **持续满载计算**：手机被动散热，长时间满载会热降频
❌ **高可用生产业务**：Android 不是服务器 OS，别押身家性命

### 硬件对比

| | 闲置旗舰手机 | 入门云 VPS（￥30/月） | 树莓派 5 |
|---|---|---|---|
| CPU | 旗舰 8 核 | 1-2 vCPU（超售） | 4 核 A76 |
| 内存 | **16GB** | 1-2GB | 4-8GB |
| 功耗 | **3-8W** | — | ~7W |
| 断电保护 | **自带电池=天然UPS** | 机房保障 | 需另购 |
| 网络出口 | **自带 5G 独立于家宽** | 有 | 蹭家里网 |
| 新增成本 | **0（闲置设备）** | ￥360+/年 | ￥600+ |

### 已知不足与缓解

| 不足 | 缓解措施 | 对应章节 |
|------|---------|-------------|
| Android 杀后台 | wake-lock + 电池无限制 + Doze 白名单 + 关 phantom killer | 七 |
| 无 root 限制 | 高位端口、原生进程、Termux 仓库版本规避 seccomp | 八 |
| IP 随网络漂移 | Tailscale 固定 IP + 动态发现兜底 | 八、九 |
| 被动散热 | 只跑"等待型"服务 | — |
| 长期插电伤电池 | 系统电池保护限充电上限 80% | 📱手动 |

**底线**：接受"不做公网大流量、不跑持续满载"两条边界——就是一台配置优于入门 VPS 的低功耗便携服务器。

### 已验证机型与适配矩阵

本方案已在 4 台真机上完整验证（2026-07，数据来自 `getprop` 实测；型号考证以 `ro.product.marketname` 为准，23013RK75C 实为 K60 标准版而非 Pro）：

| 机型（实测型号） | 系统 | SoC / RAM | 角色 | 渠道 |
|---|---|---|---|---|
| Redmi K60（23013RK75C） | Android 15 / HyperOS (V816) | 骁龙8+ Gen1 / 16GB | 主力机 | QQ 机器人 + 飞书 + 微信（官方 iLink，待绑） |
| Xiaomi MIX 2S | Android 10 / MIUI 12.5.1 | 骁龙845 / 6GB | 副机 | QQ 机器人 + 飞书 + 微信（官方 iLink，待绑） |
| Redmi Note 7 | Android 10 / MIUI 12.5.7 | 骁龙660 / 6GB | 全流程验证机 | QQ 机器人 + 飞书 + 微信（官方 iLink，待绑） |
| Redmi Note 4X | Android 7.0 / MIUI 11 | 骁龙625 / 3GB | 轻量三渠道节点 | QQ 机器人 + 飞书 + 微信（官方 iLink） |

> 2026-07-18 定版：四台全部双渠道（QQ + 飞书）接入并经真实消息实测通过，OpenClaw 统一 2026.7.1-2。

**全队工具版本组合**（升级实战定版，全部通过四连验证；升级流程见第十七章）：

| 设备 | OpenClaw | Node | libsqlite | Node 来源 |
|---|---|---|---|---|
| K60 | 2026.7.1-2 | 24.17.0 | 3.53.3 | 仓库（早期 nodejs-lts） |
| MIX 2S | 2026.7.1-2 | 26.4.0 | 3.53.3 | 仓库（撤版前安装） |
| Note 7 | 2026.7.1-2 | 26.4.0 | 3.53.3 | 仓库（撤版前安装） |
| Note 4X | 2026.7.1-2 | 26.4.0 | 3.53.0 | **手动 deb + apt-mark hold**（坑 18） |

各机版本取数命令：

```bash
openclaw --version
node --version
node -e "const s=require('node:sqlite');console.log(new s.DatabaseSync(':memory:').prepare('select sqlite_version() v').get().v)"
```

**新机型接入工作流**（适配更多机型按此走）：

```
① 识别 → ② 对号入座 → ③ 叠加注意项 → ④ 部署 → ⑤ 登记
```

```bash
# ① 识别（SSH 可用后第一件事；型号考证以 marketname 为准）
ssh -p 8022 user@<IP> 'getprop ro.product.model; getprop ro.product.marketname; getprop ro.build.version.release; getprop ro.miui.ui.version.name'
```

② 按 Android 版本查下方决策树定加固动作集与 Tailscale 可用性 → ③ 按系统皮肤/硬件档位叠加"机型专属经验" → ④ 走第一~六章部署，每章过验证门 → ⑤ 验证全过后，把新机型补进上面两张表（机型行 + 版本组合行）。

**APK 安装包速查**（按机型适配）：

| APK | 适用 | 下载源 | 安装方式 | Release 直链 |
|---|---|---|---|---|
| Termux 主程序 `com.termux_0.118.0-fdroid.apk` | ✅ 全机型（A7-15 四机实测） | F-Droid 官网/镜像 | 直装（勿用 Play 版） | [下载](https://github.com/DeXuan/openclaw-termux-deploy/releases/download/v2.3-packages/com.termux_0.118.0-fdroid.apk) |
| Termux:Boot `com.termux.boot_0.8.1.apk` | ✅ 全机型必装 | 清华 F-Droid 镜像（坑 7：必须与主程序同 F-Droid 签名） | cp 到 `~/storage/downloads/` → 文件管理器**按路径**安装（坑 8/9） | [下载](https://github.com/DeXuan/openclaw-termux-deploy/releases/download/v2.3-packages/com.termux.boot_0.8.1.apk) |
| Tailscale `tailscale-android-universal-1.98.8.apk` | ⚠️ **仅 Android 8+**（K60/MIX 2S/Note 7）；A7 装不上 | `pkgs.tailscale.com/stable/`（官网直链，GitHub CDN 被阻断时用） | 同上；装后设「始终开启 VPN」 | [下载](https://github.com/DeXuan/openclaw-termux-deploy/releases/download/v2.3-packages/tailscale-android-universal-1.98.8.apk) |
| Termux:API `com.termux.api_0.53.0.apk` | 需拍照/传感器的机器（K60 实测） | 清华 F-Droid 镜像（GitHub debug 版签名不兼容报 -8） | 同上 | [下载](https://github.com/DeXuan/openclaw-termux-deploy/releases/download/v2.3-packages/com.termux.api_0.53.0.apk) |

> 💡 **全部安装包已归档到 GitHub Release [v2.3-packages](https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v2.3-packages)**，含五文件 + 机型对照表（OpenClaw/Node/libsqlite 组合）+ `nodejs_26.4.0_aarch64.deb`（Termux 仓库无合规 Node 时的救命包，坑 18）。Release 版文件与终端 curl 镜像版完全相同，网络受限时优先用 Release 直链。

**按 Android 版本选加固动作**（决定第七章哪些项必做）：

| Android 版本 | phantom process killer | 权限自动撤销 | Doze 白名单 | Tailscale App |
|---|---|---|---|---|
| 12+（K60） | ⚠️ **必关**（adb） | ⚠️ **必禁** | 必做 | ✅ |
| 8–11（MIX 2S、Note 7） | 无此机制，跳过 | A11+ 才有 | 必做 | ✅ |
| ≤7（Note 4X） | 无 | 无 | 必做 | ❌ 装不上，走局域网直连 + 路由器 MAC 绑定 |

**机型专属经验**：

- **HyperOS（小米 Android 14+）**：APK 安装遇 content:// "解析软件包错误"（坑 8）走文件管理器按路径安装；关 phantom killer 后必须锁 `device_config`（persistent）防云端回滚；Termux 内 `pm list packages` 受包可见性限制会**漏报**（termux.boot/tailscale 明明装了却查不到）→ 验证已装用 adb 或看重启行为
- **MIUI 12.5（Android 10 代）**：普通「USB 调试」没有 WRITE_SECURE_SETTINGS（`settings put` 被拒），改 settings 需开「USB 调试（安全设置）」（要插 SIM + 登小米账号）；调试开关会静默弹回，SSH 里 `getprop sys.usb.config` 含 adb 才算真开；openssh 装完 `sshd: no hostkeys available` → `ssh-keygen -A`；Android 10 默认**按网络随机化 MAC** → 路由器 MAC 绑定前先在 WLAN 详情改「使用设备 MAC」（否则"忘记网络"重连后绑定失效）
- **低端 SoC（骁龙 6xx 及以下）**：gateway 冷启动到 listening 要 40–60 秒（Note 7 实测）；**升级后首启含 state 迁移可达 2.5–3 分钟**（Note 4X 实测），验证 curl 多等一会别急着判失败；3GB RAM 机型（Note 4X）只做供应商节点/轻量渠道聊天
- **多机 QQ 机器人机队**：每台设备注册**独立 AppID**（QQ 里是不同的聊天窗口）。"无响应"先分清用户发的是哪个 bot 的窗口再查对应设备日志——一台白名单 401 离线时另一台日志完全正常，极易误判（2026-07-18 实例）。同一宽带下所有设备出口 IPv4 相同，宽带重拨后**所有 bot 白名单要一起更新**；白名单加好后无需重启，插件每分钟自动重试，约 1 分钟自愈
- **OpenClawX App 协议不匹配**：gateway 日志每 0.4s 刷 `protocol mismatch client=OpenClawX Node ... expected=4`（ua=Dart，来源 127.0.0.1）= 本机 OpenClawX App 太旧，升级或卸载即止；只费电刷日志，不影响渠道

---

# 第一部分：基础部署

## 一、前置条件（手机端首次准备）

从全新手机复现本部署，需先在手机上完成：

```bash
# 1. 安装 Termux —— 必须 F-Droid 版（Play 商店版已停更且签名不同）
#    https://f-droid.org/packages/com.termux/

# 2. Termux 里装 sshd 并设密码
pkg update && pkg install -y openssh
passwd          # 设置 SSH 登录密码
sshd            # 启动 sshd，默认端口 8022

# 3. 授予共享存储权限
termux-setup-storage    # 弹窗选"允许"

# 4. 查手机局域网 IP
ifconfig wlan0 | grep inet
```

> 💡 建议在**路由器后台把手机 MAC 绑定静态 IP**，否则 DHCP 续租后 IP 漂移。PC 连手机热点时手机即 PC 网关，IP 变化可通过 `(Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop` 自动发现。

---

## 二、SSH 免密登录

```bash
# PC 上生成密钥（已有则跳过）
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q

# 公钥装到手机（首次需密码）
cat ~/.ssh/id_ed25519.pub | ssh -p 8022 <用户名>@<手机IP> \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'

# 验证免密
ssh -p 8022 -o BatchMode=yes <用户名>@<手机IP> 'echo OK'
```

> ⚠️ 坑 1：必须用**局域网 IP**（WLAN/热点网段）。手机蜂窝网段 IP（10.x.x.x）TCP 能通但 SSH 握手会被运营商重置。
>
> 💡 Termux 的 sshd 不校验用户名（任意用户名都映射到应用 UID），密码是 `passwd` 命令设置的。

---

## 三、安装 OpenClaw

### 依赖准备

```bash
pkg update && pkg install -y nodejs git python make clang binutils termux-services
```

### 安装（含两个必踩坑）

```bash
# 坑 2：tree-sitter-bash 编译报 "Undefined variable android_ndk_path in binding.gyp"
#       —— gyp 检测到 Android 平台就找 NDK 变量，注入空值绕过
export GYP_DEFINES="android_ndk_path="

# 坑 3：npm 11+ 默认阻止全局安装包的 install 脚本，需显式放行
npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest
```

**验证门**：
```bash
openclaw --version                                           # → OpenClaw 2026.x.x
node -e "console.log(Object.keys(require('os').networkInterfaces()))"  # → 含 wlan 接口
```

> 💡 网上多数教程用 proot + Ubuntu 容器方案，原生 Termux 更轻更快，网络接口检测正常无需 Bionic 补丁。

---

## 四、配置模型供应商

配置文件在 `~/.openclaw/openclaw.json`（修改自动生成 `.bak` 备份）。

以 DeepSeek 为例：
```bash
openclaw onboard --non-interactive --mode local \
  --auth-choice deepseek-api-key --deepseek-api-key "$DEEPSEEK_API_KEY" \
  --skip-health --accept-risk
```

其他供应商（通义千问 / Kimi / 智谱 / 自定义中转等）：`openclaw onboard --help` 查询 `--auth-choice` 支持列表。
自定义中转用 `--auth-choice custom-api-key --custom-base-url ... --custom-model-id ...`。

> ⚠️ 坑 4：`deepseek-chat` / `deepseek-reasoner` 于 **2026-07-24 退役**，默认模型设为 `deepseek/deepseek-v4-flash` 或 `v4-pro`。

**验证门**：`openclaw models list` 列出模型且 Auth=yes。

---

# 第二部分：服务化与系统加固

## 五、进程保活（runit）

用 runit 托管替代 `nohup` 裸跑，进程被杀自动拉起。

### 创建服务

```bash
OPENCLAW_BIN=$(command -v openclaw)

mkdir -p $PREFIX/var/service/openclaw/log
cat > $PREFIX/var/service/openclaw/run <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
# ⚠️ 必须用绝对路径！Termux:Boot 启动的环境 PATH 里没有 npm 全局 bin 目录（坑 10）
# QQ/飞书白名单只支持 IPv4，强制 Node 优先走 IPv4 出口（坑 14）
export NODE_OPTIONS="--dns-result-order=ipv4first"
exec $OPENCLAW_BIN gateway
EOF
chmod +x $PREFIX/var/service/openclaw/run
ln -sf $PREFIX/share/termux-services/svlogger $PREFIX/var/service/openclaw/log/run

# 启动
. $PREFIX/etc/profile.d/start-services.sh
export SVDIR=$PREFIX/var/service
sv-enable openclaw
sv up openclaw
termux-wake-lock
```

> ⚠️ 坑 5：SSH 非登录会话不加载 profile.d，`sv` 命令前必须先 `export SVDIR=$PREFIX/var/service`。
>
> ⚠️ 坑 6：远程 `pkill -f openclaw` 会连自己的 SSH 会话一起杀掉（命令行里含关键字），用 `pkill -f "[o]penclaw"` 规避。

### 验证门（四连）

```bash
sv status openclaw                                           # → run
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/    # → 200
openclaw agent --agent main --message "只回复OK"                 # → OK
# 自愈实测：kill -9 <gateway_pid> → 15 秒内 sv status 恢复 run + HTTP 200
```

---

## 六、开机自启（Termux:Boot）

### 启动脚本

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-services.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
EOF
chmod +x ~/.termux/boot/start-services.sh
```

开机链路：`开机 → Termux:Boot → wake-lock → sshd(:8022) → runit → openclaw gateway(:18789)`

### Termux:Boot 应用

> ⚠️ 坑 7：插件必须与 Termux 主应用**同签名来源**。查来源：`termux-info | grep APK_RELEASE`。
>
> ⚠️ 坑 8：`termux-open xxx.apk` 从 SSH 触发会被 Android 后台启动限制静默拦截；小米 HyperOS 安装器解析 content:// 会报「解析错误」—— APK 复制到 `~/storage/downloads/`，用文件管理器**按路径**找到点击安装。
>
> ⚠️ 坑 9：安装后**务必打开一次** Termux:Boot（注册开机广播）；设置 → Termux → 省电策略 → **无限制**。

F-Droid 版下载（清华镜像或 GitHub Release）：
```bash
curl -sL -o ~/termux-boot.apk "https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux.boot_1000.apk"
# 或从 GitHub Release 下载（网络受限时友好）：
# https://github.com/DeXuan/openclaw-termux-deploy/releases/download/v2.3-packages/com.termux.boot_0.8.1.apk
cp ~/termux-boot.apk ~/storage/downloads/
```

### 重启验证（PC 端）

重启手机后**不碰 Termux**，1~2 分钟后：
```bash
ssh -p 8022 <用户名>@<手机IP> 'echo SSH_OK'
ssh -p 8022 <用户名>@<手机IP> \
  'curl -s -o /dev/null -w "HTTP %{http_code}" http://127.0.0.1:18789/'
```
两条都通过 = 开机自启链完整。

---

## 七、系统加固（adb）

Android 12+ 的 **phantom process killer** 限制第三方应用子进程总数（默认 32），超限随机杀——手机当服务器跑多服务时这是最大隐患。一次性 adb 操作，USB 连电脑，开 USB 调试并授权。

### 全套加固

```bash
# 1. 关 phantom process killer + 锁定 device_config（防云端回滚）
adb shell "settings put global settings_enable_monitor_phantom_procs false"
adb shell "device_config set_sync_disabled_for_tests persistent"
adb shell "device_config put activity_manager max_phantom_processes 2147483647"

# 2. Doze 省电白名单（Termux 与 Termux:Boot 共享 UID，一个即覆盖两者）
adb shell "cmd deviceidle whitelist +com.termux"
adb shell "cmd deviceidle whitelist +com.tailscale.ipn"

# 3. 热点永不空闲自动关闭（PC 靠手机热点上网时必设）
adb shell "settings put global soft_ap_timeout_enabled 0"

# 4. 禁止"自动撤销未使用应用的权限"——数月后系统静默休眠导致自启链无声断裂
for p in com.termux com.termux.boot com.tailscale.ipn; do
  adb shell "cmd appops set $p AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore"
done
```

### 只读体检（可随时复查）

```bash
adb shell "settings get global settings_enable_monitor_phantom_procs"  # → false
adb shell "device_config get activity_manager max_phantom_processes"   # → 2147483647
adb shell "device_config get_sync_disabled_for_tests"                  # → persistent
adb shell "am get-standby-bucket com.termux"                           # → 5=EXEMPTED
adb shell "cmd appops get com.termux RUN_ANY_IN_BACKGROUND"           # → allow
adb shell "cmd app_hibernation get-state --global com.termux"         # → false
adb shell "cmd deviceidle whitelist" | grep -E "termux|tailscale"     # 需在列表中
```

> 📱 手机侧手动项：电池策略 → 无限制；WLAN 休眠保持连接 → 始终；长期插电 → 开电池保护（充电上限 80%）。

---

# 第三部分：网络与远程访问

## 八、Tailscale 跨网络固定 IP

解决"手机换网络 IP 就变"的终极方案。双端组虚拟局域网，手机获得**永久不变**的 `100.x.x.x` IP。

### 双端安装

- **PC**：`winget install tailscale.tailscale` 或官网下载
- **手机**：⚠️ **必须用官方 Android App**（F-Droid / Play 商店 / GitHub release）

> ⚠️ 坑 12：Termux 命令行版 tailscale 在 Android 上 `SIGSYS: bad system call`（seccomp 拦截 Go 的 `faccessat2` 系统调用）必崩——官方 App 走系统 VPN 接口无此问题，且自带开机自连。

### 组网信息

| 设备 | Tailscale 名 | 固定 IP |
|------|-------------|---------|
| 手机 | redmi-k60 | `100.118.60.29` |
| PC | desktop-ooefhtf | `100.70.110.100` |

双端用同一账号登录后，手机 IP 在任何网络下永久不变。建议手机端开启「始终开启 VPN」确保重启自连。

---

## 九、PC 端连接工具（sshphone）

一键 SSH 到手机：优先 Tailscale 固定 IP，不通回退热点网关自动发现。保存为 `~/bin/sshphone`：

```bash
#!/bin/bash
TS_IP="100.118.60.29"   # 手机 Tailscale 固定 IP
SSH_USER="u0_a197"

if [ -n "$TS_IP" ] && timeout 2 bash -c "</dev/tcp/$TS_IP/8022" 2>/dev/null; then
  HOST="$TS_IP"
else
  HOST=$(powershell -NoProfile -Command "(Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object RouteMetric | Select-Object -First 1 -ExpandProperty NextHop)" | tr -d '\r\n ')
  [ -z "$HOST" ] && echo "错误: Tailscale 不可达且未找到默认网关" >&2 && exit 1
fi
exec ssh -p 8022 -o HostKeyAlias=termux-phone -o StrictHostKeyChecking=accept-new "$SSH_USER"@"$HOST" "$@"
```

用法：`sshphone`（进 shell）/ `sshphone '命令'` / `sshphone -N -L 18789:127.0.0.1:18789`（Dashboard 隧道）

> 💡 **机队多脚本命名**（2026-07-18 经验）：设备一多，共用一个 `sshphone` 会名不符实（TS_IP 被改指别的机器都难发现）。按设备命名一机一脚本（如 `sshk60` / `sshmix2s` / `ssh4x` / `sshnote7`），每个脚本：自己的 Tailscale IP 优先 + 局域网固定 IP（或热点网关发现）回退 + **独立 HostKeyAlias**（如 `termux-note7`，known_hosts 与 IP 解耦，换网不弹指纹确认）。无 Tailscale 的 A7 机型直接局域网 IP + 路由器 MAC 绑定。

---

# 第四部分：对接应用

OpenClaw 的核心体验不是网页控制台，而是**住进聊天软件**——在日常 IM 里跟 AI 对话。

## 十、PC 网页控制台

### 访问方式

| 方式 | 命令 | 备注 |
|------|------|------|
| 手机浏览器 | `http://127.0.0.1:18789` | 需手动输 token |
| PC SSH 隧道 | `sshphone -N -L 18789:127.0.0.1:18789` | PC 访问 `http://127.0.0.1:18789` |
| PC 一键免令牌 | 桌面 `OpenClaw控制台.bat` 双击 | 自动建隧道 + 带 token 免登录 |

### 免令牌原理

token 放在 URL 片段上（`http://127.0.0.1:18789/#token=<gateway.auth.token>`），页面加载后自动登录并从地址栏清除。桌面 `.bat` 文件内嵌了此 URL + 自动隧道检测/建立逻辑。

> ⚠️ 该 `.bat` 内嵌 token，仅存本机桌面，不可提交仓库/外发。gateway 保持 `loopback` 绑定——远程访问一律走 SSH 隧道。

---

## 十一、QQ 机器人

QQ Bot 走官方 WebSocket 网关，**无需公网 IP**（NAT 后可用）。个人机器人默认沙箱，仅测试用户可聊。

### 安装配置

```bash
openclaw plugins install @openclaw/qqbot
```

2. 📱 用户：https://q.qq.com/ 手机 QQ 扫码注册（个人主体）→ 创建机器人
   → 「开发设置」拿 AppID / AppSecret → 「沙箱配置」把自己的 QQ 号加入测试用户
3. `openclaw channels add --channel qqbot --token "AppID:AppSecret"`
4. `export SVDIR=$PREFIX/var/service && sv down openclaw && sv up openclaw`
5. 验证：`openclaw channels status --probe` → `QQ Bot default: ... connected`
6. 📱 手机 QQ 扫机器人二维码 → 私聊测试

### 两个必踩坑

**坑 13 —— `invalid appid or secret`（100016）**：AppSecret 页面显示的可能是掩码值，或离开页面后已失效。解法：「重新生成」后**立即完整复制**。

**坑 14 —— `接口访问源IP不在白名单`（401）**：QQ 平台对新机器人**强制启用 IPv4 白名单**（官方不支持关闭）。

```bash
# 查手机当前 IPv4 出口，加入 q.qq.com 开发设置的白名单
curl -4 -s https://api.ip.sb/ip
```

手机有原生 IPv6 时 Node 默认可能走 IPv6 → 白名单永远匹配不上。runit run 脚本（第五章）已内置 `NODE_OPTIONS="--dns-result-order=ipv4first"` 强制 IPv4。

⚠️ 蜂窝 IPv4 出口（CGNAT 池）会漂移 → 白名单反复失效。长期方案：① 油猴脚本关闭白名单（Greasy Fork）② 白名单填运营商网段 ③ **换飞书渠道**（无此限制）。

### 本机配置

| 项目 | 值 |
|------|---|
| AppID | `102825839` |
| 环境 | 沙箱（仅测试用户可聊） |
| 当前白名单 IP | 需定期查 `curl -4 -s https://api.ip.sb/ip` 更新 |

---

## 十二、飞书机器人

飞书相比 QQ 的优势：**无 IP 白名单限制**、WebSocket 长连接、个人免费注册。但配置流程有一个关键陷阱。

### 安装配置

```bash
openclaw plugins install @openclaw/feishu
# 推荐用交互式向导（终端里跑）：openclaw channels login --channel feishu
# 或直接改 openclaw.json：
#   channels.feishu: { enabled: true, appId: "cli_a...", appSecret: "...",
#     dmPolicy: "pairing", groupPolicy: "allowlist", requireMention: true }
```

### 飞书平台标配流程

1. https://open.feishu.cn → 创建企业自建应用
2. **添加能力 → 机器人** → 启用
3. **权限管理** → 开通核心权限：
   | 权限 | 作用 |
   |------|------|
   | `im:message` | 获取与发送消息 |
   | `im:message:send_as_bot` | 以应用身份发消息 |
   | `contact:contact.base:readonly` | 通讯录（**应用身份**，飞书发消息前提） |
   | `im:resource:upload` | 图片上传（发照片必需） |
4. **事件订阅** → 添加 `im.message.receive_v1` → 选 **WebSocket 长连接**
5. **应用发布 → 创建版本 → 发布**

### 坑 15：`230101 Sending messages to users is temporarily unavailable`

**这是飞书对接中耗时最长的大坑**（半天）。

现象：权限全开、版本已发布、WebSocket 已连接，机器人能收消息但回复永远报 `230101`。
直接用 curl 调飞书发送 API 也同样报错 → 证明是平台侧限制。

**根因**：部分企业账号下的自建应用需审核流程，审核可能卡住。
**解法**：飞书官方推荐 → 自己创建一个新企业（飞书 App → 头像 → 创建新企业），
新企业下创建应用可实现**发布免审**，`230101` 不再出现。

过程中的小问题：
- 配对码：默认 `dmPolicy: "pairing"`，新用户首次发消息会收到 6 位配对码，`openclaw pairing approve feishu <CODE>` 批准后永久有效
- 图片上传：需额外开通 `im:resource:upload` 权限，否则只发文件路径不发图片
- 频繁重启可能触发 restart-loop breaker → `openclaw doctor --fix` 修复

### 本机配置

| 项目 | 值 |
|------|---|
| App ID | `cli_aad362f211b9dd05`（新企业，免审） |
| dmPolicy | `pairing` |
| streaming | `false`（纯文本） |

---

## 十三、微信机器人（腾讯官方 iLink）

2026-07 腾讯官方为 OpenClaw 发布的微信通道（npm scope `@tencent-weixin`，iLink 协议连 `ilinkai.weixin.qq.com`，配套《微信ClawBot功能使用条款》）。纯出站长连接，**无 IP 白名单**，与飞书同级省心。Note 4X（Android 7 / 3GB）首装实测，与 QQ/飞书三渠道共存。

2026-07-19 已**全队铺开**：四台均装好插件并完成 `plugins.allow` 加固（追加用并集，别覆盖别机已有名单），Note 4X 绑定在线，其余三台待绑。**安装与绑定可分离**——未绑定的渠道空载无副作用，插件先铺、账号后补；绑定一台一个微信号，同号重复绑会互踢。

### 安装（一条命令）

```bash
pkg install -y which     # 坑 22：Termux 缺 which，安装器检测宿主会误报"未找到 openclaw"
export GYP_DEFINES="android_ndk_path="
npx -y @tencent-weixin/openclaw-weixin-cli@latest install
```

安装器自动匹配宿主兼容版本（宿主需 ≥2026.3.24）→ 装插件 → 扫码登录 → 重启 gateway。安装时宿主弹 "possible credential harvesting" 警告是对所有插件的通用巡检，预期行为非投毒（该包 Socket.dev 供应链评分 100）。

### 远程扫码（SSH 场景，终端二维码渲染不出时）

```bash
# 登录进程挂手机本地（不依赖 SSH 会话存活；日志写 $HOME，坑 21）
ssh -n -p 8022 user@<IP> 'nohup openclaw channels login --channel openclaw-weixin > ~/wx-login.log 2>&1 &'
# 轮询取登录链接（低端机 1-2 分钟才出）→ 发微信文件传输助手 → 手机点开确认绑定
ssh -n -p 8022 user@<IP> 'grep -o "https://liteapp.weixin.qq.com[^[:space:]]*" ~/wx-login.log | tail -1'
```

链接 1-2 分钟过期、进程自动刷新约 3 轮，过期重新 grep 取最新即可。成功标志：服务日志出现 `config cached for <wxid>@im.wechat`，凭据持久化，重启免扫。

### 注意（3GB 低内存机，坑 23）

同一时刻只跑**一个** openclaw CLI 实例——双开 login 实测把 gateway 连坐 OOM（runit 15 秒自愈）；`channels status --probe` 同理过重，渠道验证改 grep 服务日志。

完整 SOP（含 pkill 自杀坑、`plugins.allow` 加固、配置写回竞态坑 24）见技能文档 [skill/references/channel-weixin.md](skill/references/channel-weixin.md)。

---

## 十四、多渠道共存

QQ、飞书、微信可以同时在线、互不影响（Note 4X 三渠道实测共存）。各渠道共享同一个模型和 phone-control 插件，发消息效果完全一样。照片在 QQ 正常显示为图片，在飞书需要开通 `im:resource:upload` 权限后以图片返回。

```bash
openclaw channels status --probe
# → QQ Bot default:   ... connected ✅
# → Feishu default:   ... connected ✅
```

---

# 第五部分：附加功能

## 十五、远程拍照

通过 QQ 或飞书说「拍照」，调用手机后置摄像头拍照并回复。

### 前置：安装 Termux:API

> ⚠️ Termux:API 必须与 Termux **同签名来源**——F-Droid 版 Termux 只能配 F-Droid 版 Termux:API。GitHub debug 版签名不兼容会报安装错误码 -8。
> Termux:API 在 F-Droid 上的真实 versionCode 与 GitHub tag 号不同（如 v0.53.0 = F-Droid versionCode `1002`）。

F-Droid 签名版下载（清华镜像）：
```bash
curl -sL -o ~/termux-api-fdroid.apk "https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux.api_1002.apk"
cp ~/termux-api-fdroid.apk ~/storage/downloads/
```

📱 安装后**打开一次 Termux:API** + 设置里给**相机权限**。

### 解除限制

`~/.openclaw/openclaw.json` 中 `gateway.nodes.denyCommands` 默认禁了 `camera.snap`/`camera.clip`，
移除 → 重启网关。验证：
```bash
termux-camera-photo -c 0 /tmp/test.jpg        # 文件 > 0 字节 = 成功
openclaw agent --agent main --message "用camera工具拍张照片"    # 后台真实调用
```

> ⚠️ 拍照时 Termux 需在手机前台（Android 安全机制限制后台调相机）。

### Termux:API 其他可用功能（80+ 工具，简介见附录）

常用：`termux-battery-status`（电量）、`termux-location`（GPS）、`termux-clipboard-get/set`（剪贴板）、`termux-notification`（通知）、`termux-sms-send`（短信）、`termux-tts-speak`（语音播报）、`termux-torch`（手电筒）、`termux-volume`（音量）、`termux-sensor`（传感器）、`termux-brightness`（亮度）。

---

## 十六、定时任务

OpenClaw 内置 cron 守护进程，可设置定时任务让 AI 主动推送消息。

```bash
# 创建（例：工作日 9:00 基金分析推 QQ）
openclaw cron add --tz Asia/Shanghai --cron "0 9 * * 1-5" \
  --channel qqbot --to default --thinking medium --timeout-seconds 300 \
  "每日基金分析" \
  "用 search 工具查今天 A 股大盘指数和指定基金净值，输出简报"

# 管理
openclaw cron list                    # 所有任务
openclaw cron run <id> --wait          # 手动触发测试
openclaw cron rm <id>                  # 删除
```

> ⚠️ `thinking=high` + 大量 search 工具调用可能触发超时，建议用 `thinking=medium` + 精简 prompt。

---

# 第六部分：日常运维

## 十七、运维速查

### 日志位置

| 日志 | 路径 |
|------|------|
| runit 服务日志（主要看这个） | `$PREFIX/var/log/sv/openclaw/current` |
| openclaw 文件日志 | `$PREFIX/tmp/openclaw-*/openclaw-YYYY-MM-DD.log` |

### 常见排障

| 现象 | 排查 |
|------|------|
| SSH 连不上 | PC 与手机同网络？IP 漂了？Tailscale 固定 IP 不受影响。电池策略无限制？ |
| gateway 无响应 | `sv status` → fail/down？`tail -50` 服务日志 |
| QQ 机器人不回话 | IP 白名单过期（出口 IP 漂了）—— 查 `curl -4 -s https://api.ip.sb/ip` 更新；改好后约 1 分钟自愈无需重启 |
| QQ 不回话但本机日志正常 | 多机多 bot：用户发的可能是**另一台设备**的 bot 窗口 → 先对号（见方案评估·适配矩阵）再查 |
| 飞书机器人不回话 | WebSocket 还连着？`grep feishu` 日志 |
| 端口被占 | 改 `openclaw.json` → `gateway.port` 后重启 |
| 配置改坏 | `~/.openclaw/` 下有自动备份 `openclaw.json.bak.*` |
| 频繁重启后服务不加载渠道 | restart-loop breaker 触发 → `openclaw doctor --fix` |

### 升级 OpenClaw（金丝雀 SOP，2026-07-18 全队升级实战定稿）

**⚠️ 升级前必读**：OpenClaw 2026.7.1-x 起有**双重启动检查**，任一不过 = 拒启崩溃循环（坑 17/18）：

1. **CLI 层 Node 版本号**：`>=22.22.3 <23`、`>=24.15.0 <25` 或 `>=25.9.0`（26.x 满足最后一档）
2. **运行层 SQLite ≥3.51.3**（WAL 损坏防护）。Termux 的 node **动态链接系统 `libsqlite` 包**——报 "SQLite unsafe" 时错误文案会怪罪 Node，**真正的修法只是升 libsqlite**

**Step 0 — 逐台体检（不合规先修，再动 OpenClaw）**：

```bash
node --version        # 对照上面三档
node -e "const s=require('node:sqlite');console.log(new s.DatabaseSync(':memory:').prepare('select sqlite_version() v').get().v)"   # 需 ≥3.51.3

# libsqlite 不合规 → 一条命令修复（3.51.2 → 3.53.x）
apt update && apt install --only-upgrade -y libsqlite

# node 不合规 → 先查仓库有无合规版
apt list -a nodejs nodejs-lts
# 仓库全不合规时（2026-07-18 现状：25.8.2 / 24.14.1 各差 0.0.1），pool 里直接下 deb：
# ⚠️ Termux 没有 /tmp！输出路径写 $HOME（坑 21）
curl -4 -L -o $HOME/nodejs_26.4.0.deb \
  https://mirrors.ustc.edu.cn/termux/apt/termux-main/pool/main/n/nodejs/nodejs_26.4.0_aarch64.deb
dpkg -i $HOME/nodejs_26.4.0.deb
apt-mark hold nodejs        # 锁版，防 apt upgrade 回退到不合规版本
# node 换过版本后，下一步的 npm 重装 openclaw 是必须的（native 模块按新 ABI 重编）
```

**Step 1 — 单台金丝雀升级**：

```bash
export GYP_DEFINES="android_ndk_path="
npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest
export SVDIR=$PREFIX/var/service && sv restart openclaw
```

**Step 2 — 耐心等首启迁移**：升级后首启会跑 state 迁移（低端机 2–3 分钟）。**期间别反复 restart**——会打断迁移留下迁移锁（报 `startup migrations are already running`，坑 19），出现该报错就停手，锁约 2 分钟自动过期，runit 会自己完成。

**Step 3 — 四连验证，全过再推其余设备**：

```bash
sv status openclaw                                                # → run 且 uptime 持续增长
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/    # → 200
openclaw channels status --probe                                  # → 渠道 connected
openclaw agent --agent main --message "只回复OK"                   # → OK
```

> ⚠️ E2E 报 `No API key found for provider`：`~/.openclaw/agents/main/agent/openclaw-agent.sqlite` 是 **auth store（API key）+ 会话记忆**（坑 20）——排障时若挪动过它，把三件套（含 `-wal`/`-shm`）放回原位再重启。
>
> 💡 事故参考：并行升 4 台 = 渠道可能全队离线。金丝雀流程下实际只有 1 台中招离线 40 分钟，其余 3 台无恙。

---

## 十八、安全加固建议

1. **gateway 保持 loopback 绑定**：远程访问一律走 SSH 隧道，不要暴露到公网
2. **配好密钥后关 sshd 密码登录**：`echo "PasswordAuthentication no" >> $PREFIX/etc/ssh/sshd_config`
3. **敏感信息不要提交公共仓库**：API key、gateway token 仅存手机配置文件
4. OpenClaw agent 有执行系统命令的能力，**不要**把 gateway 暴露到公网

---

## 十九、卸载与回滚

```bash
export SVDIR=$PREFIX/var/service
sv down openclaw
rm -rf $PREFIX/var/service/openclaw
npm uninstall -g openclaw
rm -rf ~/.openclaw                          # ⚠️ 含配置/记忆/工作区
rm -f ~/.termux/boot/start-services.sh
```

---

# 附录

## 附一：踩坑速查表（24 坑）

**按场景索引**：装机 1/2/3/21 · 模型 4 · 保活 5/6/10/16/24 · 自启 7/8/9 · 网络 11/12 · 渠道 13/14/15/22 · **升级 17/18/19/20** · 资源 23

| # | 现象 | 原因 | 解法 |
|---|------|------|------|
| 1 | SSH 握手被重置 | 用了手机蜂窝网段 IP | 换 WLAN/热点网段 |
| 2 | `android_ndk_path` gyp 报错 | tree-sitter 找 NDK 变量 | `GYP_DEFINES="android_ndk_path="` |
| 3 | 装完 `openclaw: command not found` | npm 11+ 阻止 install 脚本 | `--allow-scripts=...` |
| 4 | 模型退役 | deepseek-chat 2026-07-24 退役 | 切 `deepseek-v4-flash` |
| 5 | `sv` 找不到服务目录 | 非登录会话无 SVDIR | `export SVDIR=$PREFIX/var/service` |
| 6 | pkill 后 SSH 断开 | 匹配到自身命令行 | `pkill -f "[o]penclaw"` |
| 7 | Termux:Boot 不生效 | 签名来源不同 | `termux-info` 查 APK_RELEASE |
| 8 | 装 APK 报"解析错误" | 小米等安装器 content:// 失败 | 复制到 Download 用文件管理器装 |
| 9 | `termux-open` 无反应 | Android 禁止后台弹界面 | Termux 切前台再触发 |
| 10 | 重启后服务崩溃 `openclaw: not found` | Boot 环境 PATH 无 npm 全局目录 | run 脚本写 openclaw **绝对路径** |
| 11 | 重启后 IP 变了连不上 | DHCP/热点网段随机 | Tailscale + 网关动态发现 |
| 12 | Termux 版 tailscale SIGSYS 崩溃 | seccomp 拦截 faccessat2 | 用官方 Android App |
| 13 | QQ 渠道 `invalid appid` | AppSecret 复制到掩码值 | 重新生成后立即完整复制 |
| 14 | QQ 渠道 IP 白名单 401 | 强制 IPv4 + IPv6 出口 + 蜂窝漂移 | NODE_OPTIONS 强制 IPv4 |
| 15 | 飞书 `230101` 无法发消息 | 企业审核卡住 | 创建新企业免审（第十二章） |
| 16 | 频繁重启触发 restart-loop breaker | `sv down/up` 过于频繁 | `openclaw doctor --fix` |
| 17 | gateway 崩溃循环 `SQLite support is unavailable or unsafe... requires 3.51.3+` | Termux 的 node 动态链接系统 `libsqlite`（3.51.2 有 WAL 损坏 bug）；**错误文案怪 Node 是误导** | `apt install --only-upgrade libsqlite`，Node/OpenClaw 都不用动 |
| 18 | CLI 拒跑 `Node.js >=22.22.3 <23, >=24.15.0 <25, or >=25.9.0 is required` | 仓库索引现版全不合规，26.4.0 被撤出索引 | pool 里 deb 仍在：`curl` + `dpkg -i` + `apt-mark hold nodejs`；装后**必须重装 openclaw** |
| 19 | 升级后反复报 `startup migrations are already running` | 首启 state 迁移被频繁 restart 打断，留迁移锁 | **停手别再 restart**，锁 ~2 分钟自动过期自愈 |
| 20 | E2E 报 `No API key found for provider` | `agents/main/agent/openclaw-agent.sqlite`（**auth store + 会话记忆**）被挪动 | sqlite 三件套（含 -wal/-shm）放回原位重启 |
| 21 | Termux 里 `curl -o /tmp/xxx` 静默失败 | **Termux 没有 `/tmp`** | 输出路径用 `$HOME` 或 `$PREFIX/tmp` |
| 22 | 微信安装器报"未找到 openclaw"（实际在 PATH） | Termux 默认无 `which` 二进制，安装器 `which openclaw` 检测失败 | `pkg install which` 后重跑 |
| 23 | 双开 openclaw CLI 后 SSH 全断、gateway 被杀 | CLI 均为完整 node 实例，3GB 机内存压爆 LMK 连坐 | 单机单 CLI 实例；渠道验证 grep 日志；runit 自愈 |
| 24 | 改完 `plugins.allow` 重启后仍报 "allow is empty" | 旧 gateway 退出瞬间把内存旧配置写回覆盖（竞态） | `sv down`→改→`sv up`；或重启后 grep 校验，仍在再重启一次 |

---

## 附二：渠道选择对比

| 渠道 | 网络 | 难度 | IP 白名单 | 图片 | 推荐场景 |
|------|------|------|----------|------|---------|
| **QQ 机器人** | 国内直连，WebSocket | ★★★ | **有，强制** | ✅ 正常显示 | QQ 重度用户 |
| **飞书** ⭐ | 国内直连，WebSocket | ★★★ | 无 | ⚠️ 需额外权限 | 最省心国内方案 |
| **微信（官方 iLink）** ⭐ | 国内直连，iLink 长连接 | ★★☆ | 无 | —（未测） | 微信重度用户，腾讯官方通道（第十三章） |
| **企业微信** | 国内直连 | ★★★ | 无 | — | 需微信互通 |
| **Telegram** | 需网络环境 | ★☆☆ | 无 | ✅ | 境外/有代理 |
| **PC 网页控制台** | SSH 隧道 | ★☆☆ | 无 | — | 管理/调试 |

---

## 附三：版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| v1.0 | 2026-07-16 | 初版：部署 SSH → 安装 → DeepSeek 配置 → runit 保活 → Termux:Boot 自启 |
| v1.1 | 2026-07-16 | boot 脚本加 sshd；新增目录、前置条件、重启验证、升级/排障/安全/卸载 |
| v1.2 | 2026-07-16 | 重启实测通过；坑 10（runit 绝对路径） |
| v1.3 | 2026-07-16 | 网络拓扑发现；sshphone 自动发现脚本；坑 11 |
| v1.4 | 2026-07-16 | Tailscale 双端组网；sshphone v2；坑 12 |
| v1.5 | 2026-07-17 | adb 加固：phantom killer / Doze / 热点不自动关闭 / 权限不撤销 |
| v1.6 | 2026-07-17 | 方案评估章节：适用场景/优势对比/不足 |
| v1.7 | 2026-07-17 | 第二轮 adb 体检：热点防关 + 权限防自动撤销 + 只读体检命令集 |
| v1.8 | 2026-07-17 | QQ 机器人接入；坑 13/14；NODE_OPTIONS IPv4 强制 |
| v1.9 | 2026-07-17 | 定时任务（每日基金分析）；拍照；部署技能 openclaw-android-deploy |
| v1.10 | 2026-07-17 | 飞书接入；坑 15（230101 新企业免审）+ 坑 16（restart-loop breaker） |
| **v2.0** | 2026-07-17 | **文档重构**：按功能模块重组为六大部分（基础/服务化/网络/应用/功能/运维），章节从 15 章精简为 18 章+3 附录 |
| v2.1 | 2026-07-18 | 机型适配矩阵：4 台真机（K60/MIX 2S/Note 7/Note 4X，Android 7/10/15）+ 按版本加固决策树；多机多 bot 分诊与白名单联动经验；OpenClawX App 协议不匹配处置；型号修正（23013RK75C 实为 K60 非 Pro） |
| v2.2 | 2026-07-18 | 全队定版 2026.7.1-2：四台全双渠道（QQ×4 + 飞书×4）实测通过；适配矩阵渠道列与文档头更新；Note 4X 升格为轻量双渠道节点（Node 手动 deb + hold） |
| v2.3 | 2026-07-18 | 升级章重写为金丝雀 SOP（Node/libsqlite 双重检查 + 手动 deb + 迁移锁 + auth store，全命令可执行）；适配矩阵新增全队工具版本组合表、新机型接入工作流、APK 安装包速查表 + **Release 下载直链**；机型经验补 MAC 随机化/pm 可见性/首启迁移时长；sshphone 章加机队多脚本命名；坑表 16→21（+libsqlite/手动 deb/迁移锁/auth store/无 tmp）+ 场景索引；GitHub Release **v2.3-packages**（五安装包 + 机型对照）；技能新增 phone_check_env.sh（机型体检）+ phone_install_openclaw.sh 增强（安装前合规预检） |
| v2.4 | 2026-07-19 | 微信官方 iLink 渠道接入（腾讯 `@tencent-weixin`，无 IP 白名单）：新增第十三章 + 技能 channel-weixin.md 完整 SOP（远程扫码链接法 / plugins.allow 加固）；坑表 21→23（which 缺失误报 / 低内存并发 CLI OOM）；Note 4X 升格三渠道节点（QQ+飞书+微信）实测共存；第五/六部分章节号顺延 |
| v2.5 | 2026-07-19 | 微信渠道**全队铺开**：K60/MIX 2S/Note 7 插件安装 + `plugins.allow` 并集加固（安装与绑定分离，三台待绑），重启后三台 E2E 全过、K60 三渠道 probe connected；坑表 23→24（配置写回竞态：改 allow 稳妥流程 `sv down`→改→`sv up`）；机型矩阵渠道列与文档头更新 |
