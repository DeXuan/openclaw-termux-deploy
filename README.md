# OpenClaw 手机部署完全记录（Termux 原生方案）

> **文档版本：v1.8** ｜ 最后更新：2026-07-17 ｜ 版本历史见文末
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
- [方案评估：手机作为服务器](#方案评估手机作为服务器)
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
- [十三、服务器化加固（adb 关闭进程杀手）](#十三服务器化加固adb-关闭进程杀手)
- [十四、接入 QQ 机器人](#十四接入-qq-机器人)
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

## 方案评估：手机作为服务器

### 适用场景

| 场景 | 说明 |
|------|------|
| ✅ 24/7 个人 AI 助手 | 本部署的主用途。OpenClaw 这类"编排型"服务模型跑在云端 API，本机只做调度，负载极轻（实测 13 小时无人值守，load < 1，gateway 内存占用几十 MB 量级） |
| ✅ 常驻轻服务 | Telegram/微信 bot、Webhook 接收器、定时任务、爬虫、RSS、个人 API |
| ✅ 轻量数据 | SQLite 极佳（UFS 4.0 随机 IO 快），Termux 也有 PostgreSQL 包 |
| ✅ 私有网络枢纽 | 配合 Tailscale 做个人设备互联的常在线节点 |
| ✅ 旧手机再利用 / 差旅便携 | 自带电池 + 5G，停电、断宽带都不影响运行 |

### 不适用场景

- ❌ **公网大流量服务**：蜂窝网络无公网 IP、NAT 层多、上行带宽有限（靠 Tailscale 解决"自己人访问"，但不适合对公众提供服务）
- ❌ **持续满载计算**：编译农场、视频转码、本地大模型推理 —— 手机是被动散热，持续高负载会热降频
- ❌ **高可用生产业务**：Android 不是服务器 OS，无论怎么加固，可用性承诺都到不了生产级

### 优势

以本机（Redmi K60 Pro）对比常见方案：

| | 手机（K60 Pro） | 入门云 VPS（¥30/月） | 树莓派 5 |
|---|---|---|---|
| CPU | 旗舰 8 核（骁龙8 Gen2） | 1-2 vCPU（超售） | 4 核 A76 |
| 内存 | **16GB** | 1-2GB | 4-8GB |
| 存储 | 462GB UFS4.0（IO 极快） | 40GB | SD 卡（慢） |
| 功耗 | **3-8W** | — | ~7W |
| 断电保护 | **自带电池 = 天然 UPS** | 机房保障 | 需另购 |
| 网络出口 | **自带 5G，独立于家宽** | 有 | 蹭家里网络 |
| 便携性 | **口袋里** | — | 需要供电和网络 |
| 新增成本 | **0**（已有设备） | ¥360+/年 | ¥600+ 一次性 |

### 不足与缓解

| 不足 | 缓解措施 | 本部署状态 |
|------|---------|-----------|
| Android 杀后台（最大敌人） | wake-lock + 电池无限制 + Doze 白名单 + 关闭 phantom process killer（第十三章） | ✅ 已全部落实 |
| 无 root 限制 | <1024 端口用高位端口替代；跑不了 Docker → 直接跑原生进程；部分二进制 seccomp 崩溃（坑 12）→ 用官方 App/Termux 仓库版本 | ✅ 已绕过 |
| IP 随网络漂移 | Tailscale 固定 IP（第十二章）+ sshphone 兜底 | ✅ 已根治 |
| 长期插电伤电池 | 系统「电池保护」限制充电上限 80% | ⚠️ 建议开启 |
| 被动散热 | 只跑"等待型"服务，避免持续满载；别套厚壳、远离阳光 | ✅ 负载特性天然匹配 |
| 系统更新/意外重启 | 全链路开机自启（sshd + 服务群 + VPN），已实测 | ✅ 已验证 |

**一句话结论**：作为个人"编排型"服务的常驻服务器，这套方案硬件配置和成本都优于入门 VPS
和树莓派；只要接受"不做公网大流量、不跑持续满载"两条边界，它就是一台合格的低功耗便携服务器。

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
# QQ 白名单只支持 IPv4，强制 Node 优先走 IPv4 出口（坑 14）
export NODE_OPTIONS="--dns-result-order=ipv4first"
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

## 十三、服务器化加固（adb 关闭进程杀手）

Android 12+ 的 **phantom process killer** 限制第三方应用的子进程总数（默认 32 个），
超限会随机杀进程 —— 手机当服务器跑多个服务时这是最大隐患。关闭需要 adb（一次性操作）：

**前置**：手机开 USB 调试（设置 → 更多设置 → 开发者选项 → USB 调试），USB 连接电脑，
授权弹窗勾选"始终允许"。

```bash
adb devices                # 确认设备出现且状态为 device

# 1. 关闭 phantom process 监控（settings 持久，重启不丢）
adb shell "settings put global settings_enable_monitor_phantom_procs false"

# 2. 上限调到最大 + 锁定 device_config 不被云端配置重置
adb shell "device_config set_sync_disabled_for_tests persistent"
adb shell "device_config put activity_manager max_phantom_processes 2147483647"

# 3. Termux / Tailscale 加入 Doze 省电白名单
adb shell "cmd deviceidle whitelist +com.termux"
adb shell "cmd deviceidle whitelist +com.tailscale.ipn"

# 验证
adb shell "settings get global settings_enable_monitor_phantom_procs"   # → false
adb shell "device_config get activity_manager max_phantom_processes"    # → 2147483647
adb shell "device_config get_sync_disabled_for_tests"                   # → persistent
adb shell "cmd deviceidle whitelist" | grep -E "termux|tailscale"
```

> 💡 com.termux 与 com.termux.boot 共享 UID，白名单一个即覆盖两者。
> 本机已于 2026-07-17 全部执行并验证生效。

### 补充加固（第二轮体检发现）

```bash
# 6. 热点永不空闲自动关闭（PC 靠手机热点上网时必设，否则 PC 断开片刻热点就自动关）
adb shell "settings put global soft_ap_timeout_enabled 0"

# 7. 禁止系统对关键应用"自动撤销未使用应用的权限"
#    Termux:Boot / Tailscale 这类装完几乎不再打开的应用，数月后会被系统自动休眠并
#    撤销权限 —— 开机自启链会静默断裂，且很难排查
for p in com.termux com.termux.boot com.tailscale.ipn; do
  adb shell "cmd appops set $p AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore"
done

# 体检命令（只读，可随时复查）
adb shell "settings get global low_power"                      # 0 = 省电模式关
adb shell "am get-standby-bucket com.termux"                   # 5 = EXEMPTED 最优
adb shell "cmd appops get com.termux RUN_ANY_IN_BACKGROUND"    # allow
adb shell "cmd app_hibernation get-state --global com.termux"  # false = 未休眠
```

---

## 十四、接入 QQ 机器人

OpenClaw 的高效用法是"住进聊天软件"——网页控制台只是管理面板。支持的中国特色渠道有
飞书 / 企业微信 / 微信 / QQ。本机选 **QQ Bot**：官方插件，走 QQ 官方 WebSocket 网关，
**无需公网 IP**（NAT 后可用）。

### 14.1 安装与配置

```bash
# 1. 装官方插件
openclaw plugins install @openclaw/qqbot

# 2. QQ 开放平台 https://q.qq.com/ 手机QQ扫码注册（个人主体）→ 创建机器人 →
#    「开发设置」拿 AppID 与 AppSecret
#    「沙箱配置」把自己的 QQ 号加入测试用户（个人机器人默认沙箱，仅测试用户可聊）

# 3. 添加渠道并重启
openclaw channels add --channel qqbot --token "AppID:AppSecret"
export SVDIR=$PREFIX/var/service && sv down openclaw && sv up openclaw

# 4. 验证（应显示 connected）
openclaw channels status --probe
grep -i qqbot $PREFIX/var/log/sv/openclaw/current | tail -5
```

使用：手机 QQ 扫「沙箱配置」页的机器人二维码添加 → 私聊直接对话，群聊需 `@机器人`。

### 14.2 两个必踩的坑

**坑 13 —— `invalid appid or secret`（100016）**：AppSecret 页面显示的可能是掩码值，
或离开页面后已失效。解法：「重新生成」后**立即完整复制**。

**坑 14 —— `接口访问源IP不在白名单`（401）**：QQ 平台对新机器人**强制启用 IP 白名单**
（官方不支持关闭），且**只支持 IPv4**。处理分两步：

```bash
# ① 查当前 IPv4 出口，加入平台白名单
curl -4 -s https://api.ip.sb/ip

# ② 手机有原生 IPv6 时，Node 可能走 IPv6 出口 → 白名单永远匹配不上
#    在服务 run 脚本里强制 IPv4（见第五章脚本，已包含）：
export NODE_OPTIONS="--dns-result-order=ipv4first"
```

⚠️ **蜂窝网络的 IPv4 出口会漂移**（CGNAT 池），白名单会反复失效——机器人突然没反应，
九成是这个。长期方案三选一：

| 方案 | 说明 |
|------|------|
| 油猴脚本关闭白名单 | Greasy Fork「QQ开放平台机器人关闭IP白名单」，提交时自动清空并关闭；非官方手段，可能随平台更新失效 |
| 白名单填运营商大段 | 若平台支持 CIDR 网段（如移动 `39.144.0.0/16` 一类），可大幅降低失效频率 |
| **换飞书渠道** | 无 IP 白名单限制，WebSocket 长连接，个人免费——最省心的终局方案 |

---

## 遗留事项

- [x] 手机重启一次，验证开机自启全链路（2026-07-16 已验证通过：sshd 自启 ✅，gateway 修复 PATH 坑后自启 ✅，E2E 模型调用 ✅）
- [x] boot 脚本加一行 `sshd`，让重启后 SSH 也自动可用（2026-07-16 已加）
- [x] 路由器后台给手机绑定静态 IP（不适用：本拓扑无路由器，手机热点网段随机且无 root 不可固定 → 已用 `sshphone` 动态发现方案根治，见 1.3）
- [x] 可选：Tailscale 组网，获得跨网络永久固定 IP（2026-07-16 已完成，见第十二章；sshphone 已升级为 Tailscale 优先）
- [ ] 可选：清理配置里的 stale 插件项 `plugins.entries.qwen-portal-auth`（无害警告）
- [x] 按需接入消息渠道（2026-07-17 已接入 QQ 机器人并实测对话正常，见第十四章；飞书/企业微信可按需再加）

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
| 13 | QQ 渠道 `invalid appid or secret` | AppSecret 复制到掩码值/已失效 | 重新生成后立即完整复制 |
| 14 | QQ 渠道`接口访问源IP不在白名单` | 平台强制 IPv4 白名单 + 蜂窝 IP 漂移 + Node 走 IPv6 出口 | 白名单加当前 IPv4 + `NODE_OPTIONS` 强制 IPv4（详见 14.2） |

---

## 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| v1.0 | 2026-07-16 | 初版：完整部署过程记录（SSH 免密 / 环境 / 安装 / DeepSeek 配置 / runit 保活 / Termux:Boot 自启），踩坑 1~8 |
| v1.1 | 2026-07-16 | boot 脚本加入 sshd；完善结构：新增目录、前置条件、重启验证方法、升级/排障/安全加固/卸载章节，踩坑 9 |
| v1.2 | 2026-07-16 | 重启实测通过；发现并修复坑 10（runit 服务需写 openclaw 绝对路径） |
| v1.3 | 2026-07-16 | 发现真实网络拓扑（PC 连手机热点，无独立路由器）；新增 sshphone 自动发现脚本（1.3 节）根治 IP 漂移，踩坑 11 |
| v1.4 | 2026-07-16 | Tailscale 双端组网（第十二章）：手机获得永久固定 IP 100.118.60.29，任何网络可达；sshphone 升级为 Tailscale 优先 + 热点网关回退，踩坑 12 |
| v1.5 | 2026-07-17 | 服务器化加固（第十三章）：adb 关闭 phantom process killer、锁定 device_config、Termux/Tailscale 加入 Doze 白名单；8.1 补充 PC 免令牌访问 |
| v1.6 | 2026-07-17 | 新增「方案评估」章节：手机作服务器的适用场景、优势对比（VPS/树莓派）、不足与缓解措施 |
| v1.7 | 2026-07-17 | 第二轮 adb 体检与加固：热点禁止空闲自动关闭、关键应用禁止权限自动撤销；附只读体检命令集 |
| v1.8 | 2026-07-17 | 接入 QQ 机器人（第十四章）：官方插件 + WebSocket 网关；踩坑 13/14（AppSecret 掩码、IP 白名单/IPv6 出口问题及 NODE_OPTIONS 修复）；服务脚本同步更新 |
