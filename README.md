# OpenClaw 手机部署完全记录（Termux 原生方案）

> **文档版本：v1.4** ｜ 最后更新：2026-07-16 ｜ 版本历史见文末
>
> 部署日期：2026-07-16
> 设备：Redmi K60 Pro (23013RK75C)，HyperOS / Android 15，8核，16GB 内存
> 环境：Termux 0.118.0（F-Droid 版），Node.js v24.17.0
> 结果：OpenClaw 2026.7.1 gateway 常驻运行，DeepSeek V4 Flash 模型，进程自动拉起 + 开机自启（重启实测通过）
> 网络：PC 通过手机热点上网，手机即 PC 的默认网关。HyperOS 热点**每次重启随机换网段**（实测 87.x → 223.x），用 `sshphone` 脚本自动发现网关 IP 无需硬编码

---

## 目录

- [〇、前置条件（手机端首次准备）](#〇前置条件手机端首次准备)
- [架构总览](#架构总览)
- [一、SSH 连接与免密登录](#一ssh-连接与免密登录)
- [二、Termux 环境准备](#二termux-环境准备)
- [三、安装 OpenClaw](#三安装-openclaw含两个关键坑)
- [四、配置 DeepSeek](#四配置-deepseek)
- [五、服务保活（termux-services / runit）](#五服务保活termux-services--runit)
- [六、开机自启（Termux:Boot）](#六开机自启termuxboot)
- [七、验证清单](#七验证清单)
- [八、日常使用与维护](#八日常使用与维护)
- [九、故障排查](#九故障排查)
- [十、安全加固建议](#十安全加固建议)
- [十一、卸载与回滚](#十一卸载与回滚)
- [十二、Tailscale 跨网络固定 IP](#十二tailscale-跨网络固定-ip)
- [遗留事项](#遗留事项)
- [附：踩坑速查表](#附本次踩坑速查表)

---

## 〇、前置条件（手机端首次准备）

从全新手机复现本部署，需先在**手机上**完成（本次部署时这些已就绪）：

```bash
# 1. 安装 Termux —— 必须 F-Droid 版（Play 商店版已停更且签名不同）
#    https://f-droid.org/packages/com.termux/

# 2. Termux 里装 sshd 并设密码
pkg update && pkg install -y openssh
passwd          # 设置 SSH 登录密码
sshd            # 启动 sshd，默认端口 8022

# 3. 授予共享存储权限（后面装 Termux:Boot 要用）
termux-setup-storage    # 弹窗选"允许"

# 4. 查手机当前 IP（PC 连手机热点时，手机 IP = PC 的默认网关，见 1.3 的 sshphone）
ifconfig wlan0 | grep inet
```

---

## 架构总览

```
                        互联网
                          ↑ 蜂窝网络 (rmnet_data)
┌─────────────────────── Redmi K60 Pro ───────────────────────┐
│  Termux (F-Droid 版)                                         │
│  ├─ sshd :8022            ← PC 远程管理（密钥免密）           │
│  ├─ runit (termux-services)                                  │
│  │   └─ openclaw gateway :18789 (loopback, token 认证)       │
│  │        └─ DeepSeek API (deepseek-v4-flash)                │
│  ├─ termux-wake-lock      ← 防休眠                           │
│  ├─ Termux:Boot v0.8.1    ← 开机自启 ~/.termux/boot/*.sh     │
│  └─ Tailscale App 1.98.8  ← 永久固定 IP: 100.118.60.29       │
└──────────────────────────────────────────────────────────────┘
                          ↑ WiFi 热点（⚠️ 网段每次重启随机变）
                          │
                    PC（Windows）
     Tailscale: 100.70.110.100 ←─虚拟组网─→ 手机 100.118.60.29
     sshphone：优先 Tailscale 固定 IP，回退热点网关自动发现
```

> 📌 **拓扑关键点**：本环境没有独立路由器 —— PC 连的是**手机热点**，手机既是服务器
> 也是网关。HyperOS 热点每次重启会**随机更换网段**（实测 `192.168.87.x → 192.168.223.x`），
> 且无 root 无法固定（Android 系统行为，Termux 碰不到网络配置）。
> 解法不是静态 IP，而是**动态发现**：手机永远是 PC 的默认网关，一查即得（见 1.3）。

---

## 一、SSH 连接与免密登录

### 1.1 正确的连接方式

```bash
# 通用方式（需要知道 IP）
ssh -p 8022 u0_a197@<手机IP>

# 推荐：自动发现脚本（IP 变了也不怕，原理见下方说明）
sshphone    # 等价于 ssh -p 8022 u0_a197@<当前手机网关IP>
sshphone 'echo 远程命令'
```

> 📌 **网络拓扑说明**：PC 通过手机热点上网 → 手机 = PC 的默认网关 → 运行
> `(Get-NetRoute 0.0.0.0/0).NextHop` 就是手机当前 IP → `sshphone` 脚本自动取这个值。
> HyperOS 热点每次重启随机换网段（本次实测：`192.168.87.x` → `192.168.223.x`），
> `sshphone` 彻底消除手动查 IP 的麻烦。
>
> ⚠️ 坑 1：别用手机**蜂窝网段**的 IP（10.x.x.x），TCP 能通但 SSH 握手会被重置
> （`kex_exchange_identification: Connection reset by peer`）。
>
> 💡 Termux 的 sshd 不校验用户名（任意用户名都映射到应用 UID），密码是 `passwd` 命令设置的。

### 1.2 配置密钥免密

```bash
# PC 上生成密钥（已有则跳过）
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q

# 公钥装到手机（首次需密码）
cat ~/.ssh/id_ed25519.pub | ssh -p 8022 u0_a197@192.168.87.183 \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'

# 验证免密
ssh -p 8022 -o BatchMode=yes u0_a197@192.168.87.183 'echo OK'
```

### 1.3 sshphone 自动发现脚本（PC 端，一劳永逸）

保存为 `C:\Users\gdx\bin\sshphone`（Git Bash 的 PATH 已含该目录），`chmod +x`：

```bash
#!/bin/bash
# sshphone — 自动发现手机热点 IP 并 SSH（手机 = PC 默认网关，网段随机也不怕）
# 用法: sshphone [命令...]   无参数进交互 shell
GW=$(powershell -NoProfile -Command "(Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object RouteMetric | Select-Object -First 1 -ExpandProperty NextHop)" | tr -d '\r\n ')
if [ -z "$GW" ]; then
  echo "错误: 未找到默认网关（PC 没连手机热点？）" >&2
  exit 1
fi
exec ssh -p 8022 -o HostKeyAlias=termux-phone -o StrictHostKeyChecking=accept-new u0_a197@"$GW" "$@"
```

用法示例（选项也能透传，实测有效）：

```bash
sshphone                                  # 交互式 shell
sshphone 'sv status openclaw'             # 执行远程命令
sshphone -N -L 18789:127.0.0.1:18789      # Dashboard 隧道
```

> 💡 `HostKeyAlias=termux-phone` 让 known_hosts 记录与 IP 解耦，换网段不会反复弹主机指纹确认。
> 局限：仅适用于"PC 连手机热点"拓扑；若两者改为连同一路由器，脚本需改为扫描或手动传 IP。

---

## 二、Termux 环境准备

```bash
# 基础运行时（Node ≥22 即可，实测 v24.17.0）
pkg update && pkg install -y nodejs git

# 编译工具链 —— npm 装 OpenClaw 时 tree-sitter 需要原生编译，必装
pkg install -y python make clang binutils
```

---

## 三、安装 OpenClaw（含两个关键坑）

```bash
# 坑 2：tree-sitter-bash 编译报 "Undefined variable android_ndk_path in binding.gyp"
#       —— gyp 检测到 Android 平台就找 NDK 变量，注入空值绕过
export GYP_DEFINES="android_ndk_path="

# 坑 3：npm 11+ 默认阻止全局安装包的 install 脚本（allow-scripts 安全机制），
#       需显式放行，否则 tree-sitter 原生绑定和 openclaw 捆绑插件不会构建
npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest

# 验证
openclaw --version
# → OpenClaw 2026.7.1 (2d2ddc4)

# 验证网络接口检测（原生 Termux 正常，无需 proot 方案的 Bionic 补丁）
node -e "console.log(Object.keys(require('os').networkInterfaces()))"
```

> 💡 网上多数教程用 proot + Ubuntu 容器方案，原生 Termux 更轻更快，本次实测可行。

---

## 四、配置 DeepSeek

配置文件：`~/.openclaw/openclaw.json`（修改会自动生成 `.bak` 备份）

关键配置段：

```json
{
  "models": {
    "mode": "merge",
    "providers": {
      "deepseek": {
        "baseUrl": "https://api.deepseek.com/v1",
        "apiKey": "sk-39b4****（完整 key 在手机配置文件里）",
        "api": "openai-completions",
        "models": [
          { "id": "deepseek-chat",      "name": "DeepSeek Chat" },
          { "id": "deepseek-reasoner",  "name": "DeepSeek Reasoner" },
          { "id": "deepseek-v4-flash",  "name": "DeepSeek V4 Flash" },
          { "id": "deepseek-v4-pro",    "name": "DeepSeek V4 Pro" }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": { "primary": "deepseek/deepseek-v4-flash" }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": { "mode": "token", "token": "（见配置文件 gateway.auth.token）" }
  }
}
```

> ⚠️ 坑 4：`deepseek-chat` / `deepseek-reasoner` 于 **2026-07-24 退役**（现路由到 V4 Flash），
> 默认模型已切到 `deepseek/deepseek-v4-flash`。想换 `deepseek-v4-pro` 只需改
> `agents.defaults.model.primary` 一行后重启服务。
>
> 💡 全新安装可直接用官方无交互向导：
> ```bash
> openclaw onboard --non-interactive --mode local \
>   --auth-choice deepseek-api-key --deepseek-api-key "$DEEPSEEK_API_KEY" \
>   --skip-health --accept-risk
> ```

---

## 五、服务保活（termux-services / runit）

用 runit 托管替代 `nohup` 裸跑，进程被杀自动拉起：

```bash
pkg install -y termux-services

# 创建 openclaw 服务
mkdir -p $PREFIX/var/service/openclaw/log
cat > $PREFIX/var/service/openclaw/run <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
# 必须用绝对路径！Termux:Boot 启动的环境 PATH 里没有 npm 全局 bin 目录（坑 10）
exec /data/data/com.termux/files/home/.npm-global/bin/openclaw gateway
EOF
chmod +x $PREFIX/var/service/openclaw/run
ln -sf $PREFIX/share/termux-services/svlogger $PREFIX/var/service/openclaw/log/run

# 启动服务管理器 + 服务
. $PREFIX/etc/profile.d/start-services.sh
sv-enable openclaw
sv up openclaw

# 防休眠
termux-wake-lock
```

> ⚠️ 坑 5：SSH 非登录会话不加载 profile.d，`sv` 命令会报
> "unable to change to service directory"，需先 `export SVDIR=$PREFIX/var/service`。
>
> ⚠️ 坑 6：远程 `pkill -f openclaw` 会连自己的 SSH 会话一起杀掉（命令行里含关键字），
> 用 `pkill -f "[o]penclaw"` 规避。

**自动拉起实测**：`kill -9` 杀掉 gateway 进程（pid 13798）后，runit 在 15 秒内自动重启
（新 pid 14760），dashboard 恢复 HTTP 200。

---

## 六、开机自启（Termux:Boot）

### 6.1 启动脚本

```bash
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/start-openclaw.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
termux-wake-lock
sshd
. /data/data/com.termux/files/usr/etc/profile.d/start-services.sh
EOF
chmod +x ~/.termux/boot/start-openclaw.sh
```

开机链路：`开机 → Termux:Boot → wake-lock → sshd(:8022) → runit → openclaw gateway(:18789)`

### 6.2 安装 Termux:Boot 应用（v0.8.1，26KB）

> ⚠️ 坑 7：插件必须与 Termux 主应用**同签名来源**。查来源：`termux-info | grep APK_RELEASE`
> （本机为 `F_DROID`）。F-Droid 官方源国内超时，用清华镜像。
>
> ⚠️ 坑 8：`termux-open xxx.apk` 从 SSH 触发会被 Android 后台启动限制静默拦截；
> Termux 前台再触发能弹安装器，但**小米 HyperOS 安装器解析 content:// 会报「解析错误」**
> （APK 本身完好，hash/签名/targetSdk 均验证正常）。
> **最终方案**：复制到 /sdcard/Download，用文件管理器按路径（非分类标签）找到后点击安装。

```bash
# 手机上下载（清华 F-Droid 镜像，versionCode 1000 = v0.8.1）
curl -sL -o ~/termux-boot.apk https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux.boot_1000.apk

# 复制到共享存储（需已执行过 termux-setup-storage）
cp ~/termux-boot.apk ~/storage/downloads/termux-boot-0.8.1.apk
# → 手机文件管理 →「内部存储」→ Download → 点击安装（纯净模式拦截选「继续安装」）

# 验证已安装
pm path com.termux.boot
```

### 6.3 手机端手动设置（必做）

1. 安装后**打开一次 Termux:Boot**（注册开机广播）
2. 设置 → 应用设置 → Termux → 省电策略 → **无限制**（小米杀后台激进）
3. 建议：设置 → WLAN → 高级设置 → 休眠时保持 WLAN 连接 → **始终**

---

## 七、验证清单

### 7.1 日常四连验

```bash
# 1. 服务状态
export SVDIR=$PREFIX/var/service
sv status openclaw
# → run: openclaw: (pid xxxx) ...

# 2. Dashboard 可达
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18789/
# → 200

# 3. 端到端模型调用
openclaw agent --agent main --message "只回复两个字母: OK"
# → OK

# 4. 确认生效模型
grep "agent model" $PREFIX/var/log/sv/openclaw/current | tail -1
# → agent model: deepseek/deepseek-v4-flash (thinking=high)
```

### 7.2 重启全链路验证（PC 端执行）

重启手机后**不碰 Termux**，等 1~2 分钟，在 PC 上：

```bash
# sshd 自动起来了吗（sshphone 顺带解决重启后 IP 变化问题）
sshphone 'echo SSH_OK'

# gateway 自动起来了吗
sshphone 'export SVDIR=$PREFIX/var/service; sv status openclaw; curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:18789/'
```

两条都通过 = 开机自启链路完整可用。
（2026-07-16 实测：sshd ✅；gateway 首次暴露 PATH 坑（坑 10），修复后 ✅；E2E 模型调用 ✅）

---

## 八、日常使用与维护

### 8.1 访问 Dashboard

- **手机浏览器**：`http://127.0.0.1:18789`（token 在 `~/.openclaw/openclaw.json` → `gateway.auth.token`）
- **PC 访问**（gateway 仅绑定回环，需 SSH 隧道）：
  ```bash
  sshphone -N -L 18789:127.0.0.1:18789
  # 然后 PC 浏览器打开 http://127.0.0.1:18789
  ```
- **PC 免令牌一键打开**：token 可以放在 URL 片段里自动登录（UI 读取后存入当前标签页
  sessionStorage 并从地址栏清除）：
  ```
  http://127.0.0.1:18789/#token=<gateway.auth.token 的值>
  ```
  已做成桌面双击脚本 `OpenClaw控制台.bat`：检测隧道 → 没有就用 sshphone 自动建 →
  带 token 打开浏览器。⚠️ 该脚本内嵌 token，仅存本机，勿提交仓库/外发。

### 8.2 常用管理命令（SSH 上手机后）

```bash
export SVDIR=$PREFIX/var/service          # sv 命令前必设
sv status openclaw                        # 查看状态
sv down openclaw / sv up openclaw         # 停止 / 启动
tail -f $PREFIX/var/log/sv/openclaw/current   # 服务日志
openclaw models list                      # 已配置模型
openclaw gateway status                   # gateway 自检
openclaw doctor                           # 诊断修复
```

### 8.3 升级 OpenClaw

```bash
export GYP_DEFINES="android_ndk_path="    # 编译环境变量每次升级都要带
npm install -g --allow-scripts=openclaw,@google/genai,protobufjs,tree-sitter-bash openclaw@latest
export SVDIR=$PREFIX/var/service
sv down openclaw && sv up openclaw
openclaw --version && openclaw doctor     # 大版本升级后 doctor 会自动迁移配置
```

### 8.4 接入消息渠道（未来扩展）

当前未接渠道（仅 WebUI/CLI）。要接 Telegram / 企业微信 / WhatsApp 时：

```bash
openclaw channels list                    # 看支持的渠道
openclaw onboard                          # 交互式向导里选渠道（在手机 Termux 前台跑）
```

### 8.5 切换模型

```bash
# 改 ~/.openclaw/openclaw.json → agents.defaults.model.primary
# 可选值：deepseek/deepseek-v4-flash（当前）| deepseek/deepseek-v4-pro
# 改完重启：sv down openclaw && sv up openclaw
```

---

## 九、故障排查

### 9.1 日志位置汇总

| 日志 | 路径 |
|------|------|
| runit 服务日志（主要看这个） | `$PREFIX/var/log/sv/openclaw/current` |
| openclaw 文件日志 | `$PREFIX/tmp/openclaw-*/openclaw-YYYY-MM-DD.log` |
| npm 安装日志 | `~/.npm/_logs/` |

### 9.2 常见问题

**SSH 连不上 / 超时**
1. 先用 `sshphone` 连（自动发现 IP，覆盖 90% 的"连不上"= IP 变了的情况）
2. `sshphone` 报"未找到默认网关" → PC 没连手机热点，重连热点后再试
3. 手机刚重启：等 1~2 分钟让 Termux:Boot 跑完；若一直不通，手动打开一次 Termux（会触发 sshd）
4. 息屏被杀：检查电池策略是否"无限制"、WLAN 休眠保持是否"始终"
5. 想固定地址（任何网络下都不变）→ 上 Tailscale（手机+PC 各装一个，获得永久 100.x.x.x IP）

**gateway 起不来 / dashboard 无响应**
```bash
export SVDIR=$PREFIX/var/service
sv status openclaw                             # fail/down？
tail -50 $PREFIX/var/log/sv/openclaw/current   # 看报错
openclaw doctor                                # 自动诊断修复
```

**端口 18789 被占用**
改 `~/.openclaw/openclaw.json` 的 `gateway.port` 为其他端口（如 18790）后重启服务，
不要杀占用端口的其他进程。

**npm 升级/安装报编译错误**
按顺序检查：`pkg install -y python make clang binutils` 装齐了吗 →
`GYP_DEFINES` 设了吗 → `--allow-scripts` 带了吗（见第三章）。

**配置改坏了**
`~/.openclaw/` 下有自动备份 `openclaw.json.bak`（多份带序号），直接覆盖回去。

---

## 十、安全加固建议

1. **gateway 保持 loopback 绑定**：`bind` 别改成 `lan`/`0.0.0.0`，远程访问一律走 SSH 隧道
2. **禁用 sshd 密码登录**（已配好密钥后）：
   ```bash
   echo "PasswordAuthentication no" >> $PREFIX/etc/ssh/sshd_config
   pkill -f "[s]shd" && sshd
   ```
3. **敏感信息**：API key、gateway token 只存在手机 `~/.openclaw/openclaw.json`；
   本文档已脱敏，可转发
4. OpenClaw agent 有执行系统命令的能力，**不要**把 gateway 暴露到公网

---

## 十一、卸载与回滚

```bash
# 停止并移除服务
export SVDIR=$PREFIX/var/service
sv down openclaw
rm -rf $PREFIX/var/service/openclaw

# 卸载程序与数据（数据目录含配置/记忆/工作区，删前想清楚）
npm uninstall -g openclaw
rm -rf ~/.openclaw

# 移除开机脚本 + 手机上卸载 Termux:Boot 应用
rm -f ~/.termux/boot/start-openclaw.sh
```

---

## 十二、Tailscale 跨网络固定 IP

解决"手机换任何网络（热点/WiFi/流量）IP 都会变"的终极方案：双端组虚拟局域网，
手机获得**永久不变**的 `100.x.x.x` IP，PC 在任何能上网的地方都能直连。

### 12.1 本机组网信息

| 设备 | Tailscale 名 | 固定 IP | 客户端 |
|------|-------------|---------|--------|
| 手机 | redmi-k60 | `100.118.60.29` | Android App 1.98.8 |
| PC | desktop-ooefhtf | `100.70.110.100` | Windows 1.98.9 (winget) |

账号：GitHub（DeXuan），管理后台 https://login.tailscale.com/admin/machines

### 12.2 安装过程

**PC 端**：
```bash
winget install tailscale.tailscale
tailscale login    # 输出授权 URL，浏览器打开登录
tailscale ip -4    # 查看本机固定 IP
```

**手机端**：
> ⚠️ 坑 12：Termux 命令行版 tailscale 不可用 —— 官方 Go 二进制在 Android 上
> `SIGSYS: bad system call`（seccomp 拦截 `faccessat2`），Termux 官方仓库也无此包。
> **必须用官方 Android App**（走系统 VPN 接口，无 seccomp 问题，自带开机自连）。

1. 下载 APK：GitHub `tailscale/tailscale-android` releases（约 100MB），
   scp 传到手机 `~/storage/downloads/`，文件管理器安装（同坑 8 流程）
2. 打开 App → Sign in（与 PC 同一账号）→ 同意 VPN 连接请求
3. 系统设置 → VPN → Tailscale 齿轮 → **始终开启 VPN**（重启自动连）

### 12.3 使用

```bash
# SSH：sshphone 已自动优先走 Tailscale（不通才回退热点网关发现）
sshphone 'sv status openclaw'

# 手动直连（任何网络下都是这个地址）
ssh -p 8022 u0_a197@100.118.60.29

# Dashboard 隧道（跨网络也能用）
sshphone -N -L 18789:127.0.0.1:18789
```

> 💡 gateway 仍绑定 loopback（安全默认）。如想让 PC 免隧道直接访问 Dashboard，
> 可把 `openclaw.json` 的 `gateway.bind` 改为 `"tailnet"`，风险自担（有 token 认证）。

---

## 遗留事项

- [x] 手机重启一次，验证开机自启全链路（2026-07-16 已验证通过：sshd 自启 ✅，gateway 修复 PATH 坑后自启 ✅，E2E 模型调用 ✅）
- [x] boot 脚本加一行 `sshd`，让重启后 SSH 也自动可用（2026-07-16 已加）
- [x] 路由器后台给手机绑定静态 IP（不适用：本拓扑无路由器，手机热点网段随机且无 root 不可固定 → 已用 `sshphone` 动态发现方案根治，见 1.3）
- [x] 可选：Tailscale 组网，获得跨网络永久固定 IP（2026-07-16 已完成，见第十二章；sshphone 已升级为 Tailscale 优先）
- [ ] 可选：清理配置里的 stale 插件项 `plugins.entries.qwen-portal-auth`（无害警告）
- [ ] 可选：按需接入消息渠道（Telegram / 企业微信 / WhatsApp，见 8.4）

---

## 附：本次踩坑速查表

| # | 现象 | 原因 | 解法 |
|---|------|------|------|
| 1 | SSH 握手被重置 | 连了错误网段的 IP | 用局域网 IP |
| 2 | `android_ndk_path` gyp 报错 | tree-sitter 在 Android 找 NDK | `GYP_DEFINES="android_ndk_path="` |
| 3 | 装完无 openclaw 命令 | npm 11+ 阻止 install 脚本 | `--allow-scripts=...` 放行 |
| 4 | deepseek-chat 即将失效 | 2026-07-24 模型退役 | 切 `deepseek-v4-flash` |
| 5 | `sv` 找不到服务目录 | 非登录会话无 SVDIR | `export SVDIR=$PREFIX/var/service` |
| 6 | pkill 断开自己 SSH | 匹配到自身命令行 | `pkill -f "[o]penclaw"` |
| 7 | 插件签名要求 | Termux 插件须同来源 | `termux-info` 查 APK_RELEASE |
| 8 | 小米装 APK 解析错误 | HyperOS 安装器 + content:// | 复制到 Download 用文件管理器装 |
| 9 | termux-open 无反应 | Android 禁止后台应用弹界面 | Termux 切前台后再触发 |
| 10 | 重启后服务崩溃循环 `openclaw: not found` | Termux:Boot 环境的 PATH 无 `~/.npm-global/bin` | run 脚本里写 openclaw **绝对路径** |
| 11 | 手机重启后 IP 变了连不上 | HyperOS 热点重启随机换网段 | 用 `sshphone` 脚本自动发现（原理：手机 = PC 网关） |
| 12 | Termux 版 tailscale 崩溃 `SIGSYS` | Android seccomp 拦截 Go 的 `faccessat2` 调用 | 用官方 Android App（系统 VPN 接口） |

---

## 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| v1.0 | 2026-07-16 | 初版：完整部署过程记录（SSH 免密 / 环境 / 安装 / DeepSeek 配置 / runit 保活 / Termux:Boot 自启），踩坑 1~8 |
| v1.1 | 2026-07-16 | boot 脚本加入 sshd；完善结构：新增目录、前置条件、重启验证方法、升级/排障/安全加固/卸载章节，踩坑 9 |
| v1.2 | 2026-07-16 | 重启实测通过；发现并修复坑 10（runit 服务需写 openclaw 绝对路径） |
| v1.3 | 2026-07-16 | 发现真实网络拓扑（PC 连手机热点，无独立路由器）；新增 sshphone 自动发现脚本（1.3 节）根治 IP 漂移，踩坑 11 |
| v1.4 | 2026-07-16 | Tailscale 双端组网（第十二章）：手机获得永久固定 IP 100.118.60.29，任何网络可达；sshphone 升级为 Tailscale 优先 + 热点网关回退，踩坑 12 |
