# 踩坑速查（26 坑全录）

按报错现象查找。来源：2026-07 四台真机（K60 / MIX 2S / Note 7 / Note 4X）实战部署与全队升级。

**按场景索引**：装机 1/2/3/21 · 模型 4 · 保活 5/6/10/16/24/25 · 自启 7/8/9 · 网络 11/12 · 渠道 13/14/15/22 · **升级 17/18/19/20** · 资源 23 · **换 Key 26**

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
| 22 | 微信官方安装器报 `未找到 openclaw，请先安装`（实际 openclaw 在 PATH 且能跑） | 安装器用 `execSync("which openclaw")` 检测宿主，Termux 默认**没有 `which` 二进制**（`command -v` 是 shell 内建，人工验证时反而发现不了差异） | `pkg install which` 后重跑安装器 |
| 23 | 双开 openclaw CLI（如两个 `channels login`）后 SSH 全断 exit 255、gateway 被杀重启 | 每个 CLI 都是完整 node 实例（数百 MB），3GB 机内存压爆触发 LMK 连坐；`channels status --probe` 同理过重卡死 | 单机同一时刻只跑**一个** CLI 实例；渠道验证改 grep 服务日志；gateway 靠 runit 自愈（15s） |
| 24 | 改完 `plugins.allow` 重启后日志仍报 `plugins.allow is empty` | 修改配置时 gateway 正在运行，其收到 TERM 退出瞬间把内存里的旧配置**写回覆盖**了新文件（Note 7 实测中招，其余三台一次成功，属竞态） | 稳妥流程 `sv down` → 改配置 → `sv up`；或改完重启后 `grep "allow is empty"` 校验，仍在就再重启一次 |
| 25 | runit 日志循环 `./run: exec: openclaw: not found`，但 SSH 里 `which openclaw` 和 `openclaw --version` 都正常 | Android/Termux **没有 `/usr/bin/env`**，npm 全局 bin symlink → `.mjs` 的 shebang `#!/usr/bin/env node` 在内核 `exec()` 时找不到解释器。**交互 shell（bash）会自行处理 shebang 所以人工测试正常，极具迷惑性** | 见下方详解 |

| 26 | `openclaw onboard --alibaba-model-studio-api-key`（或 `--deepseek-api-key` 等）执行成功、`openclaw models list` Auth=yes，但 **E2E 仍然报 400/403 Auth 错误** | **`onboard --*-api-key` 只更新 `openclaw.json` 的 `models.providers.*.apiKey`（模型目录用），不更新 `openclaw-agent.sqlite` 的 `auth_profile_store` 表（Gateway 实际鉴权用）**。两个存储独立，Gateway 发起 API 调用时从 SQLite 取 key。 | 见下方详解（含 Python 一键修复脚本） |

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

## 坑 25 详解：shebang `/usr/bin/env` 陷阱

**现象**：runit 日志每秒刷 `./run: 4: exec: /data/data/.../openclaw: not found`，gateway 始终起不来。但 SSH 进去手动跑 `which openclaw` 正常、`openclaw --version` 正常，容易误判为"服务配置问题"。

**根因**：`npm install -g openclaw` 创建的全局 bin 是一个 symlink → `../lib/node_modules/openclaw/openclaw.mjs`。`.mjs` 文件第一行 shebang 是 `#!/usr/bin/env node`。Android/Linux 内核在执行脚本时，必须找到 shebang 指定的解释器。但 Android 文件系统**没有 `/usr/bin/env`**（Termux 的 `env` 在 `$PREFIX/bin/env` 即 `/data/data/com.termux/files/usr/bin/env`）。

**为什么 SSH 里能跑但 runit 不能**：交互 shell（bash）遇到 shebang 指向不存在的路径时，会**自行在 PATH 中搜索**解释器并执行。但 runit 的 `runsv` 通过 `exec()` 系统调用启动 run 脚本，再由 shell 的 `exec` 触发内核的二进制加载器——内核不走 shell 的 fallback 逻辑，直接报 ENOENT。

**影响范围**：2026-07-25 全队检修确认——Note 4X 已挂（本坑触发）、K60/Note 7 在跑但重启必挂（定时炸弹）、MIX 2S 已免疫（2026-07-20 手工建了 bash wrapper）。

**修复方案（二选一）**：

```bash
# 方案A：只修 runit run 脚本（最小改动，Note 4X 采用）
# 把 run 里的 "exec $OPENCLAW_BIN gateway" 改为直接调 node：
exec $PREFIX/bin/node $PREFIX/lib/node_modules/openclaw/openclaw.mjs gateway

# 方案B：替换 npm symlink 为 bash wrapper（根治，MIX 2S/K60/Note 7 采用）
OPENCLAW_BIN=$(command -v openclaw)
NPM_ROOT=$(npm root -g)
rm "$OPENCLAW_BIN"
cat > "$OPENCLAW_BIN" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec node NPM_ROOT/openclaw/openclaw.mjs "$@"
EOF
chmod +x "$OPENCLAW_BIN"
```

**预防**：`phone_setup_service.sh` v2.6+ 已在创建 runit 服务前自动执行方案 B，新部署不再踩此坑。

## 坑 26 详解：`onboard --*-api-key` 不更新 SQLite auth store

**现象**：`openclaw onboard --non-interactive --alibaba-model-studio-api-key "新key"` 执行成功，`openclaw models list` 显示 Auth=yes，但 E2E（`openclaw agent --agent main --message "只回复OK"`）仍然报 400/403 Auth 错误。直接 `curl` 用新 key 调 API 能通，排除 key 本身无效。

**根因**：OpenClaw 有两套独立的 key 存储，`onboard --*-api-key` 只更新了第一套：

| 存储层 | 位置 | 用途 | onboard 更新？ |
|--------|------|------|:---:|
| JSON config | `openclaw.json` → `models.providers.*.apiKey` | 模型目录（价格/能力） | ✅ |
| JSON config | `~/.openclaw/agents/main/agent/models.json` → `providers.*.apiKey` | Agent 级模型配置 | ❌ |
| **SQLite auth store** | `~/.openclaw/agents/main/agent/openclaw-agent.sqlite` → `auth_profile_store` 表 | **Gateway 实际鉴权取 key** | ❌ |

Gateway 发起 API 调用时从 SQLite 的 `auth_profile_store` 取 key，JSON 文件里的 key 只用于模型目录展示。所以你换了 JSON 里的 key，Gateway 根本看不见。

**诊断**：日志中 `profile=sha256:0a63006cdda5`（auth profile hash）与新旧 key 的 sha256 都对不上 → 确认 SQLite 里还有第三把更早的 key。

```bash
# 查 SQLite 里实际存的 key（会暴露明文）
python3 -c "
import sqlite3, json
db = sqlite3.connect('$HOME/.openclaw/agents/main/agent/openclaw-agent.sqlite')
row = db.execute(\"SELECT store_json FROM auth_profile_store WHERE store_key='primary'\").fetchone()
data = json.loads(row[0])
for p, cfg in data['profiles'].items():
    print(f'{p}: {cfg[\"key\"][:30]}...')
db.close()
"
```

**修复**（Python 一键脚本，停 gateway → 更新 SQLite → 清 cooldown → 启 gateway）：

```bash
# 停 gateway
export SVDIR=$PREFIX/var/service && sv down openclaw

# 更新 key + 清 cooldown
python3 -c "
import sqlite3, json
NEW_KEY = 'sk-新key'
db = sqlite3.connect('$HOME/.openclaw/agents/main/agent/openclaw-agent.sqlite')

# 1. 更新 auth_profile_store 的 key
row = db.execute(\"SELECT store_json FROM auth_profile_store WHERE store_key='primary'\").fetchone()
data = json.loads(row[0])
data['profiles']['alibaba-model-studio:manual']['key'] = NEW_KEY
db.execute(\"UPDATE auth_profile_store SET store_json=? WHERE store_key='primary'\", (json.dumps(data),))

# 2. 清 auth cooldown（否则 Gateway 会跳过该 provider 不重试）
row2 = db.execute(\"SELECT state_json FROM auth_profile_state WHERE state_key='primary'\").fetchone()
sdata = json.loads(row2[0])
us = sdata.get('usageStats', {}).get('alibaba-model-studio:manual', {})
us['cooldownUntil'] = 0
us['cooldownReason'] = ''
us['errorCount'] = 0
us['failureCounts'] = {}
db.execute(\"UPDATE auth_profile_state SET state_json=? WHERE state_key='primary'\", (json.dumps(sdata),))
db.commit()
db.close()
print('Done')
"

# 启 gateway + 验证
sv up openclaw && sleep 20
curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:18789/  # → 200
openclaw agent --agent main --message '只回复OK'                   # → OK
```

**预防**：
1. **换 key 后必须跑 E2E**，`models list` Auth=yes 不足为凭
2. 部署新设备首选 `openclaw onboard --non-interactive --auth-choice <provider>` **不带 `--skip-health`**，让 onboard 自己跑 E2E 验证（失败会报错）
3. 手工换 key 时直接用上面的 Python 脚本，**同时更新 SQLite + 清 cooldown**，不要只跑 `onboard`

**其他 provider 同理**：`--deepseek-api-key`、`--openai-api-key` 等所有 `--*-api-key` 参数都有相同问题。SQLite 里的 profile key 名是 `{provider}:manual`（如 `deepseek:default`、`openai:manual`），对应修改即可。

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

## Hermes Agent 共部署坑（2026-07-27 K60 实战）

| # | 现象 | 原因 | 解法 |
|---|------|------|------|
| 27 | `hermes-agent requires Python <3.14,>=3.11`（3.14.6 被拒） | Termux 仓库 Python 已到 3.14.6，Hermes v0.19.0 pyproject.toml `requires-python` 锁 `<3.14` | 改 `pyproject.toml` 的 `requires-python` 为 `">=3.11,<3.15"`；同时改 `hermes_cli/main.py` 的 `_print_fast_version_info()` 函数内 `PROJECT_ROOT` 引用（3.14 的模块级执行顺序暴露了旧 bug：该变量定义在函数调用之后，需在函数体内 `from pathlib import Path` + `Path(__file__).parent.parent.resolve()` 内联计算） |
| 28 | pip 装 `.[termux]` 时 `psutil` 报 `platform android is not supported` | psutil PyPI 无 Android wheel，源码构建检查 platform 拒绝 | 先 `pkg install python-psutil python-cryptography rust binutils` 从 Termux 仓库预装系统包，然后 `python -m venv venv --system-site-packages` 创建 venv（继承系统 psutil/cryptography），再 `pip install -e '.[termux]'` |
| 29 | runit `exec python -m hermes_cli gateway` 报 `No module named hermes_cli.__main__` | `hermes_cli` 没有 `__main__.py`，入口是 `venv/bin/hermes` CLI 脚本 | run 脚本用 `exec /path/to/venv/bin/hermes gateway`（不是 `python -m`） |
| 30 | `config.yaml` 的 `default_provider`/`default_model` 不生效，始终走 OpenRouter | config.yaml 顶层 key 不是 `default_provider`/`default_model`，模型配置在 `model:` 段下 | 正确格式：`model: {name: qwen3.7-plus-2026-05-26, provider: openai-api}`（YAML 字典）。`OPENAI_API_KEY` + `OPENAI_BASE_URL` 写在 `.env` 里 |
| 31 | `scp -r` 拷 venv 极慢（几千个小文件，>10 分钟未完成）| `scp -r` 对大量小文件每文件一次握手，LAN 下也慢 | **tar 管道直传**：`ssh src 'cd ~/.hermes/hermes-agent && tar czf - venv/' \| ssh dst 'cd ~/.hermes/hermes-agent && tar xzf -'`，58MB 压缩流秒传（Note 7→Note 4X 实测 <30 秒）|
| 32 | Python 3.13→3.14 升级后 `ModuleNotFoundError: No module named '_cffi_backend'` | Termux `python` 包升级时不自动带 `python-cffi`，旧版 cffi .so 与新 Python ABI 不兼容 | 从另一台已装好的同版本设备 scp：`_cffi_backend.cpython-314-aarch64-linux-android.so` + `cffi/` 目录 → `$PREFIX/lib/python3.14/site-packages/`。同时删掉 venv 里的 pip 版 cryptography（`pip uninstall -y cryptography`），让 `--system-site-packages` venv 自动 fallback 到系统版 |
| 33 | Note 4X/低端机 apt 下载极慢（`grimler.se` 国外源）| 旧部署未换国内源，84 个包 pending update | `echo "deb https://mirrors.ustc.edu.cn/termux/apt/termux-main stable main" > $PREFIX/etc/apt/sources.list` |
| 34 | venv 跨设备移植后 cryptography 崩溃 | pip 安装的 `cryptography` 含 Rust 编译的 `_rust` 绑定，链接了源设备的系统库，目标设备 ABI 不兼容 | **移植 SOP**：① 目标设备 `pkg install python-cffi`（缺则从源设备 scp .so）② `pip uninstall -y cryptography` 删 venv 版 ③ 系统 cryptography 通过 `--system-site-packages` 自动接管 |
