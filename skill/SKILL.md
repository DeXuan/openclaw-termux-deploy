---
name: openclaw-android-deploy
description: 在安卓手机上通过 Termux 完整部署 OpenClaw AI 网关 + Hermes Agent 自进化 AI 框架（原生方案，无需 root/proot），覆盖 SSH 远程管理、模型供应商配置、runit 进程保活、Termux:Boot 开机自启、Tailscale 固定 IP、adb 系统加固、QQ/飞书/微信（官方 iLink）机器人渠道接入、Hermes 飞书渠道、全队版本升级（Node/libsqlite 适配）、金丝雀编译+venv分发多设备快速部署，内置 34 个实战踩坑的修复方案和 4 台真机（Android 7/10/15）的机型适配矩阵与工具版本组合。当用户要求在手机/旧手机/安卓设备上部署 OpenClaw 或 Hermes、把手机改造成 AI 服务器/低功耗服务器、复刻 openclaw-termux 部署、升级机队版本、排查已部署服务的故障（掉线/不回话/重启失联/升级后拒启）、或进行 OpenClaw+Hermes 双引擎共部署时使用。
---

# OpenClaw 安卓手机部署

把一台安卓手机改造成 24/7 运行 OpenClaw 的低功耗服务器。全程从 PC 通过 SSH 远程操作，
手机端只需少量手动步骤（会明确标注 📱）。

**核心原则**：每个阶段结束必须通过"验证门"才能进入下一阶段；任何报错先查
[references/pitfalls.md](references/pitfalls.md)（34 个已知坑的现象→解法速查（主表1-26 + Hermes 27-34））。

**机型差异**：接入新设备，按 [references/device-matrix.md](references/device-matrix.md) §1「新机型接入工作流」
走：识别（getprop）→ 决策树对号 → 皮肤/硬件注意项叠加 → 部署 → **登记回矩阵**。
已验证 K60 / MIX 2S / Note 7 / Note 4X 四台（Android 7/10/15），全队 2026.7.1-2 定版。

**版本升级**：升级 OpenClaw 前必读 device-matrix.md §6「升级 SOP（金丝雀流程）」——
2026.7.1-x 有 Node 版本号 + SQLite 双重启动检查，Termux 仓库 Node 可能全不合规（坑 17/18）。

**环境体检**：[scripts/phone_check_env.sh](scripts/phone_check_env.sh) 一键诊断机型识别、node/libsqlite 合规、
openclaw 版本、boot 自启链、服务状态 —— 部署前后、升级前、故障时都可跑，输出 `[PASS]/[FAIL]/[SKIP]` 附坑号与修复命令。
```bash
cat scripts/phone_check_env.sh | ssh -p 8022 user@<IP> 'sh -'
```

**安装包下载**：GitHub Release [v2.3-packages](https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v2.3-packages)
提供四机型全套 APK/nodejs deb + 机型对照表，仓库 README v2.3 APK 速查表同步更新。

**实例参考**：https://github.com/DeXuan/openclaw-termux-deploy（完整文档 + 安装包备份 Releases）

## 阶段 0：前提（📱 手机端手动，一次性）

指导用户在手机上完成：

1. 安装 **F-Droid 版 Termux**（勿用 Play 商店版）
2. Termux 内执行：`pkg update && pkg install -y openssh && passwd && sshd && termux-setup-storage`
3. 查手机 IP：`ifconfig wlan0 | grep inet`（⚠️ 坑 1：别用 10.x 蜂窝网段 IP）

**拓扑判断**：若 PC 通过该手机热点上网，则手机 IP = PC 默认网关，可用
`(Get-NetRoute -DestinationPrefix 0.0.0.0/0).NextHop` 自动发现（Windows）。

## 阶段 1：SSH 免密

```bash
[ -f ~/.ssh/id_ed25519.pub ] || ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -q
cat ~/.ssh/id_ed25519.pub | ssh -p 8022 user@<手机IP> \
  'mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

首次连接需密码：ssh 不能非交互输密码时，用 askpass 环境变量方式（密码不落盘）：
`SSHPASS='密码' SSH_ASKPASS=<echo $SSHPASS 的脚本> SSH_ASKPASS_REQUIRE=force DISPLAY=:0 ssh ...`

**验证门**：`ssh -p 8022 -o BatchMode=yes user@<IP> 'echo OK'` 输出 OK。

部署 PC 端连接脚本：按 [scripts/sshphone.template](scripts/sshphone.template) 生成 `~/bin/sshphone`
（先只填热点网关回退逻辑，Tailscale IP 留待阶段 6 后补）。

## 阶段 2：安装 OpenClaw

把 [scripts/phone_install_openclaw.sh](scripts/phone_install_openclaw.sh) 通过 ssh 管道在手机上执行：

```bash
cat scripts/phone_install_openclaw.sh | ssh -p 8022 user@<IP> 'sh -'
```

脚本已内置坑 2（`GYP_DEFINES="android_ndk_path="`）、坑 3（npm `--allow-scripts`），
**v2.3 新增安装前合规预检**：自动升级 libsqlite（坑 17）+ 校验 node 版本（坑 18），
不合规直接报错给修复命令再退出，避免装完才发现拒启。

**验证门**：输出 OpenClaw 版本号 + `netif:` 行含 wlan 接口（原生 Termux 无需 Bionic 补丁）。

## 阶段 3：配置模型供应商

先问用户：用哪家供应商 + API Key。DeepSeek 官方无交互配置：

```bash
openclaw onboard --non-interactive --mode local \
  --auth-choice deepseek-api-key --deepseek-api-key "KEY" --skip-health --accept-risk
```

其他供应商：`openclaw onboard --help` 查 `--auth-choice` 支持列表（含 qwen/kimi/zai/openai 等）。
自定义中转用 `--auth-choice custom-api-key --custom-base-url ... --custom-model-id ...`。
配置文件在 `~/.openclaw/openclaw.json`（改动自动生成 .bak）。

⚠️ 模型选择注意 deepseek-chat/reasoner 已于 2026-07-24 退役，用 `deepseek/deepseek-v4-flash` 或 `v4-pro`。

**验证门（必须两步，缺一不可）**：
1. `openclaw models list` 列出模型且 Auth=yes
2. **E2E 实测**：`openclaw agent --agent main --message "只回复OK"` → 模型真实回复 "OK"

⚠️ `models list` Auth=yes **不代表 Gateway 能用该 key**（坑 26：`onboard --*-api-key` 只更新 JSON 不更新 SQLite auth store）。E2E 失败报 400/403 时立即查 [pitfalls.md](references/pitfalls.md) 坑 26。

## 阶段 4：进程保活（runit）

把 [scripts/phone_setup_service.sh](scripts/phone_setup_service.sh) 通过 ssh 管道执行。
脚本自动处理坑 10（openclaw 绝对路径）、坑 14（`NODE_OPTIONS` 强制 IPv4）、
坑 5（SVDIR），并创建 Termux:Boot 启动脚本（wake-lock + sshd + 服务群）。

**验证门**（三连）：
1. `sv status openclaw` → run
2. `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/` → 200
3. 自愈实测：`kill -9 <gateway pid>`，15 秒后 sv status 恢复 run
4. E2E：`openclaw agent --agent main --message "只回复OK"` → 模型真实回复

⚠️ 远程 kill 时用 `pkill -f "[o]penclaw"` 防止杀掉自己的 SSH 会话（坑 6）。

## 阶段 5：开机自启（📱 部分手动）

1. 查 Termux 来源：`termux-info | grep APK_RELEASE`（坑 7：Termux:Boot 必须同签名来源）
2. F_DROID 版下载：`curl -sL -o ~/termux-boot.apk https://mirrors.tuna.tsinghua.edu.cn/fdroid/repo/com.termux.boot_1000.apk`
3. `cp` 到 `~/storage/downloads/`，📱 让用户用**文件管理器按路径**找到并安装
   （坑 8：小米等安装器解析 termux-open 的 content:// 会报错；坑 9：termux-open 需 Termux 前台）
4. 📱 安装后打开一次 Termux:Boot；设置 → Termux 电池策略无限制

**验证门**：重启手机，不碰 Termux，2 分钟后 PC 端 SSH 直连成功 + gateway HTTP 200。

## 阶段 6：Tailscale 固定 IP（可选，强烈推荐；⚠️ 要求 Android 8+，Android 7 机型跳过走局域网直连）

⚠️ 坑 12：**不要用 Termux 二进制版 tailscale**（Android seccomp 拦截 faccessat2 必崩），
用官方 Android App：GitHub `tailscale/tailscale-android` releases 下载 APK，同阶段 5 方式安装。

1. 📱 App 登录（与 PC 同账号）+ 同意 VPN + 系统设置开"始终开启 VPN"
2. PC：`tailscale login`（给用户 URL）；`tailscale status` 拿手机的 100.x IP
3. 更新 sshphone：把 100.x IP 填入 `TS_IP`（Tailscale 优先，热点网关回退）

**验证门**：`ssh -p 8022 user@100.x.x.x 'echo OK'` 任何网络下成功。

## 阶段 7：系统加固（可选，📱 需 USB 连接一次）

USB 调试授权后按 [references/hardening.md](references/hardening.md) 执行：关 phantom process
killer、Doze 白名单、热点防自动关闭、禁权限自动撤销。含只读体检命令可先诊断后修。
⚠️ 哪些项必做取决于 Android 版本（A12+ 全套；A10-11 只需 Doze；MIUI 12.5 的 settings put 受限）——
按 [references/device-matrix.md](references/device-matrix.md) 决策树执行。

## 阶段 8：聊天渠道（可选）

- **QQ 机器人**：见 [references/channel-qqbot.md](references/channel-qqbot.md)（含 IP 白名单双坑处理）
- **飞书**：`openclaw plugins install @openclaw/feishu`，WebSocket 长连接，无 IP 白名单限制，最省心
- **微信（腾讯官方 iLink）**：`npx -y @tencent-weixin/openclaw-weixin-cli@latest install`，同样无
  IP 白名单，见 [references/channel-weixin.md](references/channel-weixin.md)（which 前置坑 22、远程扫码链接法、低内存坑 23）
- 渠道总览：`openclaw channels list --all`

## 终验清单

```bash
sv status openclaw                                    # run
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/   # 200
openclaw channels status --probe                      # 渠道 connected（如已配）
openclaw agent --agent main --message "只回复OK"       # 模型 E2E
# 重启手机 → 全链路自动恢复（sshd + gateway + VPN + 渠道）
```

## 阶段 9：Hermes Agent 共部署（可选，K60 验证通过 2026-07-27）

在一台已部署 OpenClaw 的安卓手机上叠加安装 Hermes Agent（Python 自进化 AI 框架），
两者共用同一 Termux + runit + Tailscale 基础设施，运行时互不冲突。

**共存原理**：OpenClaw = Node.js，Hermes = Python，不同技术栈、不同端口、独立 runit 服务。
K60（骁龙 8+ Gen1 / 16GB RAM）实测剩余 6.8GB 内存，Hermes 闲置仅 ~80MB，绰绰有余。

**前置检查**：Python ≥3.11 且 <3.15（Termux 仓库现为 3.14.6，需处理坑 27）、
已有 OpenClaw 的 runit/Tailscale 基础设施可直接复用。

### 安装

```bash
# 1. 预装系统包（避免 pip 编译 psutil 等失败，坑 28）
pkg install -y python-psutil python-cryptography rust binutils

# 2. 一键安装（国内镜像）
curl -fsSL https://res1.hermesagent.org.cn/install.sh | bash
# 若 Python 3.14.6 报 requires-python <3.14（坑27），手动处理：
cd ~/.hermes/hermes-agent
sed -i 's/<3.14"/<3.15"/' pyproject.toml
# 修复 version 命令的 PROJECT_ROOT bug
sed -i 's|print(f"Install directory: {PROJECT_ROOT}")|from pathlib import Path; print(f"Install directory: {Path(__file__).parent.parent.resolve()}")|' hermes_cli/main.py
# 重建 venv 继承系统 psutil/cryptography
rm -rf venv && python -m venv venv --system-site-packages
source venv/bin/activate
export ANDROID_API_LEVEL=$(getprop ro.build.version.sdk)
pip install -e '.[termux]' -c constraints-termux.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
ln -sf $PWD/venv/bin/hermes $PREFIX/bin/hermes
```

### 多设备快速部署（金丝雀编译 + venv 分发）

首台设备（推荐 K60，骁龙 8+ Gen1 编译最快）完整走上面安装流程后，
其余同架构设备只需拷贝已编译的 venv，跳过数小时的 Rust 编译：

```bash
# 源设备（已装好 Hermes 的）→ 目标设备，LAN/tar 管道秒传（坑31）：
ssh <源设备> 'cd ~/.hermes/hermes-agent && tar czf - venv/'   | ssh <目标设备> 'cd ~/.hermes/hermes-agent && tar xzf -'

# 目标设备上还需：
# 1. 克隆代码（不含 venv） + 应用代码修复
# 2. 确保 Python 3.14 + 系统包（坑32：python-cffi 可能缺失，从源设备 scp .so）
# 3. 删 venv 版 cryptography（坑34）：pip uninstall -y cryptography
# 4. 写 .env + config.yaml + 链接 hermes → /bin/
```

⚠️ **Python 版本必须一致**（都是 3.14.6 aarch64）。若目标设备 Python < 3.14，
先 `apt install python` 升级（建议先换中科大源，坑33）。若 Python 升级后缺
`_cffi_backend`（坑32），从源设备 scp 拷贝 `.so` 文件。

**实测效率**：

| 方式 | K60（首台） | Note 7（拷贝） | Note 4X（拷贝） |
|------|:--:|:--:|:--:|
| 耗时 | ~10 分钟 | **~2 分钟** | **~3 分钟**（含 Python 升级 + cffi 修复） |
| 关键瓶颈 | Rust 编译 maturin/cryptography | tar 管道传输 58MB | apt 换源 + Python 3.13→3.14 |

### 配置模型（阿里云百炼 OpenAI 兼容）

```bash
# ~/.hermes/.env
OPENAI_API_KEY=sk-ws-xxxx
OPENAI_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
```

```yaml
# ~/.hermes/config.yaml
model:
  name: qwen3.7-plus-2026-05-26
  provider: openai-api
```

**验证门**：`cd ~/.hermes && source .env && hermes chat -q "只回复OK" --yolo --max-turns 1` → 模型回复 OK

### 飞书渠道

见 [references/channel-feishu-hermes.md](references/channel-feishu-hermes.md)（凭证 → 启动 gateway → 配对审批 → runit 保活）。

### runit 服务

```bash
export SVDIR=$PREFIX/var/service
SVC_DIR=$SVDIR/hermes-gateway
mkdir -p $SVC_DIR/log $PREFIX/var/log/sv/hermes-gateway
ln -sf $PREFIX/share/termux-services/svlogger $SVC_DIR/log/run
# run 脚本用 venv/bin/hermes gateway（不能 python -m hermes_cli，坑 29）
```

### 共存终验

```bash
sv status openclaw hermes-gateway   # 两个都是 run
# OpenClaw: curl 127.0.0.1:18789 → 200
# Hermes:  grep "lark.*connect" $PREFIX/var/log/sv/hermes-gateway/current | tail -1
# → connected to wss://msg-frontier.feishu.cn
```

## 日常运维速查

- 体检命令：`cat scripts/phone_check_env.sh | ssh -p 8022 user@<IP> 'sh -'`（一键诊断机型/版本/自启/服务/渠道，附坑号）
- 掉线排查第一反应：蜂窝 IP 漂移（QQ 白名单失效）或热点网段变化 → pitfalls.md 坑 11/14
- 多台设备各挂 QQ bot 时，"无响应"先分清用户发的是哪个 bot 窗口 → device-matrix.md 机队经验
- 升级：`GYP_DEFINES="android_ndk_path=" npm install -g --allow-scripts=... openclaw@latest` 后 sv 重启
- 日志：`$PREFIX/var/log/sv/openclaw/current`
