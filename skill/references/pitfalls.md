# 踩坑速查（21 坑全录）

按报错现象查找。来源：2026-07 四台真机（K60 / MIX 2S / Note 7 / Note 4X）实战部署与全队升级。

**按场景索引**：装机 1/2/3/21 · 模型 4 · 保活 5/6/10/16 · 自启 7/8/9 · 网络 11/12 · 渠道 13/14/15 · **升级 17/18/19/20**

| # | 现象 | 原因 | 解法 |
|---|------|------|------|
| 1 | SSH 握手被重置 `kex_exchange_identification: Connection reset by peer` | 连了手机蜂窝网段 IP（10.x.x.x） | 用 WLAN/热点网段 IP |
| 2 | npm 装 openclaw 报 `Undefined variable android_ndk_path in binding.gyp` | tree-sitter 的 gyp 在 Android 平台找 NDK 变量 | `export GYP_DEFINES="android_ndk_path="` 后重装 |
| 3 | npm 装完 `openclaw: command not found`，日志有 `allow-scripts` 警告 | npm 11+ 默认阻止全局包 install 脚本 | `npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest` |
| 4 | 模型退役警告 | deepseek-chat/reasoner 2026-07-24 退役 | 默认模型改 `deepseek/deepseek-v4-flash` 或 `v4-pro` |
| 5 | `sv` 报 `unable to change to service directory` | 非登录 SSH 会话不加载 profile.d，无 SVDIR | 先 `export SVDIR=$PREFIX/var/service` |
| 6 | 远程 pkill 后 SSH 连接断开 | `pkill -f openclaw` 匹配到自己 SSH 会话的命令行 | 用 `pkill -f "[o]penclaw"`（方括号技巧） |
| 7 | Termux:Boot 装上不生效/装不上 | 插件与 Termux 主应用签名来源不同 | `termux-info \| grep APK_RELEASE` 确认来源，F_DROID 版配 F-Droid 签名 APK |
| 8 | 手机安装 APK 报"解析软件包错误"（文件本身完好） | 小米 HyperOS 等安装器解析 content:// URI 失败 | APK 复制到 `~/storage/downloads/`，用文件管理器**按路径**（非分类标签）找到点击安装 |
| 9 | `termux-open xxx.apk` 无反应 | Android 10+ 禁止后台应用拉起界面（SSH 触发时 Termux 在后台） | 📱 让用户把 Termux 切到前台再触发，或直接走坑 8 的文件管理器路线 |
| 10 | 重启后服务崩溃循环 `./run: exec: openclaw: not found` | Termux:Boot 环境 PATH 无 npm 全局 bin 目录 | run 脚本写 openclaw **绝对路径**（`command -v openclaw` 取得） |
| 11 | 手机重启后 SSH 连不上（IP 变了） | 热点网段随机化（HyperOS 每次重启换网段）；或 DHCP 漂移 | 热点拓扑：手机=PC 默认网关，动态发现；跨网络：Tailscale 固定 IP |
| 12 | Termux 里跑 tailscale 秒崩 `SIGSYS: bad system call` | Android seccomp 拦截 Go 二进制的 faccessat2 调用 | 放弃命令行版，装官方 Android App（走系统 VPN 接口） |
| 13 | QQ 渠道 `invalid appid or secret`（100016） | AppSecret 复制到页面掩码值，或离开页面后失效 | 开放平台「重新生成」后立即完整复制 |
| 14 | QQ 渠道 `接口访问源IP不在白名单`（401） | 平台强制 IPv4 白名单 + Node 走 IPv6 出口 + 蜂窝 IP 漂移 | 见下方详解 |
| 15 | 飞书 `230101 Sending messages to users is temporarily unavailable` | 企业审核卡住 | 创建新企业免审（详见部署文档第十二章） |
| 16 | 频繁 `sv down/up` 后服务不加载渠道 | restart-loop breaker 触发 | `openclaw doctor --fix` |
| 17 | gateway 崩溃循环 `SQLite support is unavailable or unsafe... requires SQLite 3.51.3+` | Termux 的 node 动态链接系统 `libsqlite` 包（3.51.2 有 WAL 损坏 bug），**错误文案怪 Node 版本是误导** | `apt install --only-upgrade libsqlite`（→3.53.x）即解，Node/OpenClaw 都不用动 |
| 18 | CLI 拒跑 `Node.js >=22.22.3 <23, >=24.15.0 <25, or >=25.9.0 is required` | Termux 仓库索引现版全不合规（25.8.2/24.14.1 各差 0.0.1），26.4.0 被撤出索引 | pool 里 deb 仍在：手动 `curl` + `dpkg -i` 装 26.4.0 + `apt-mark hold nodejs` 锁版；装后**必须重装 openclaw**（native ABI） |
| 19 | 升级后反复报 `startup migrations are already running for this state directory` | 首启 state 迁移被频繁 `sv restart` 打断，留下迁移锁 | **停手别再 restart**，锁 ~2 分钟自动过期，runit 会自己完成迁移 |
| 20 | E2E 报 `No API key found for provider "..."，Auth store: .../openclaw-agent.sqlite` | 排障时挪走了 `agents/main/agent/openclaw-agent.sqlite`——它是 **auth store（API key）+ 会话记忆** | 把备份的 sqlite 三件套（含 -wal/-shm）放回原位再重启 |
| 21 | Termux 里 `curl -o /tmp/xxx` 静默失败（文件不存在） | **Termux 没有 `/tmp` 目录** | 输出路径用 `$HOME` 或 `$PREFIX/tmp` |

## 坑 14 详解：QQ IP 白名单

QQ 开放平台对新机器人强制启用 IP 白名单（官方不支持关闭），且白名单**只支持 IPv4**。

```bash
# ① 查手机当前 IPv4 出口，加入 q.qq.com 开发设置的白名单
curl -4 -s https://api.ip.sb/ip

# ② 手机有原生 IPv6 时 Node 默认可能走 IPv6 → 白名单永远匹配不上
#    确认 runit run 脚本里有这行（phone_setup_service.sh 已内置）：
export NODE_OPTIONS="--dns-result-order=ipv4first"
```

蜂窝 IPv4 出口（CGNAT）会漂移 → 白名单反复失效。长期方案：
1. 油猴脚本「QQ开放平台机器人关闭IP白名单」（Greasy Fork，非官方）
2. 白名单填运营商网段（若平台支持 CIDR）
3. **换飞书渠道**（无白名单限制，终局方案）

## 其他经验

- **升级用金丝雀流程**（2026-07-18 全队 -2 升级实录）：单台先升（libsqlite → node 合规确认 → npm 升 openclaw → sv restart → 四连验证），全过再推其余设备。当天并行升 4 台的话会全队渠道离线——实际单台中招离线 40 分钟,其余 3 台无恙
- **多设备多 QQ bot 误诊**（2026-07-18）："QQ 无响应"先分清用户发消息的是哪个 bot 的窗口——机队每台设备挂独立 AppID，一台 401 离线时另一台日志完全正常，容易误判成"新部署的坏了"。对号入座方法见 device-matrix.md 机队经验
- **gateway 日志刷 `protocol mismatch client=OpenClawX Node ... expected=4`**（ua=Dart，127.0.0.1 每 0.4s 一次）：本机装的 OpenClawX App 客户端协议版本旧于 gateway，升级或卸载该 App 即止；只费电刷日志，不影响渠道
- **白名单修好后无需重启**：qqbot 插件每分钟自动重试 /gateway，白名单生效后约 1 分钟自动恢复（2026-07-18 实测：401 离线 2.5h → 加 IP → 62s 后 Gateway ready）
- **GitHub 推不上去但 gh 命令正常**：某些网络下 github.com:443 被阻断而 api/uploads/ssh.github.com:443 可达。
  `~/.ssh/config` 加 `Host github.com → HostName ssh.github.com, Port 443`，remote 换 SSH 地址
- **cmd 批处理写中文注释会炸**（GBK/UTF-8 编码问题）：.bat 文件保持纯 ASCII
- **Termux 的 sshd 不校验用户名**，任意用户名映射到应用 UID；密码由 `passwd` 设置
- **手机端媒体库不显示新文件**：Termux 直接写入的文件未被索引，文件管理器要按路径浏览
