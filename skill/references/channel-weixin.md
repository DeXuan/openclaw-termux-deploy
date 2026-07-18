# 微信渠道接入（腾讯官方 iLink）

> 2026-07 腾讯官方发布的 OpenClaw 微信通道：npm scope `@tencent-weixin`，底层 iLink 协议
> （`ilinkai.weixin.qq.com`）连微信官方服务器，配套《微信ClawBot功能使用条款》。
> 纯出站长连接，**无 IP 白名单问题**（与飞书同级省心，比 QQ 渠道少一大坑）。
> 首装验证机：Note 4X（Android 7 / 3GB，2026-07-19，QQ+飞书+微信三渠道共存）。

## 前置

- 宿主 OpenClaw ≥ 2026.3.24（GHSA-m3mh-3mpg-37hw 安装期漏洞修复线）
- **Termux 必装 `which`**：`pkg install -y which`（坑 22——安装器用 `execSync("which openclaw")`
  检测宿主，缺 which 会误报"未找到 openclaw"）
- 安装时宿主弹 *"Environment variable access combined with network send — possible credential
  harvesting"* 警告：这是 OpenClaw 对所有插件的通用巡检，**预期行为非投毒**（该包 Socket.dev
  供应链评分 100，腾讯官方 scope）

## 安装

```bash
export GYP_DEFINES="android_ndk_path="   # 坑 2 惯例
npx -y @tencent-weixin/openclaw-weixin-cli@latest install
```

安装器自动完成：检测宿主版本 → 匹配兼容 dist-tag → `openclaw plugins install
@tencent-weixin/openclaw-weixin@<tag>` → 扫码登录 → 重启 gateway。
SSH 无 TTY 时扫码步骤会失败留待手动，属正常，走下节链接法。

## 远程扫码（PC SSH 场景）

终端 ASCII 二维码经 SSH/工具链常渲染不出来，用**链接法**：

```bash
# 登录进程挂手机本地（不依赖 SSH 会话存活；Termux 无 /tmp，日志写 $HOME，坑 21）
ssh -n -p 8022 user@<IP> 'nohup openclaw channels login --channel openclaw-weixin > ~/wx-login.log 2>&1 & echo started'

# 轮询提取登录链接（低端机 CLI 启动 1-2 分钟才出链接）
ssh -n -p 8022 user@<IP> 'grep -o "https://liteapp.weixin.qq.com[^[:space:]]*" ~/wx-login.log | tail -1'
```

拿到 `liteapp.weixin.qq.com/q/...` 链接 → 发到微信（文件传输助手）→ 手机上点开确认绑定。
链接 **1-2 分钟过期**，进程自动刷新二维码（约 3 轮后退出）——过期就再 grep 取最新一条，
进程退出则重新 nohup 一轮。
⚠️ 若要先清理旧登录进程，`pkill -f "[c]hannels login"` **必须单独一次 ssh 执行**——与真正的
login 命令写进同一条复合命令会匹配到父 shell 自杀（ssh exit 255 零输出，坑 6 变体）。

登录成功标志：服务日志出现 `[openclaw-weixin] config cached for <wxid>@im.wechat`；
凭据持久化，重启免扫。完事清理 `rm ~/wx-login.log`。

## ⚠️ 低内存机注意（坑 23）

- **同一时刻只跑一个 openclaw CLI 实例**：login / probe / agent 每个都是完整 node 进程
  （数百 MB）。3GB 机双开 login 实测把 gateway 一起 OOM（runit 15s 自愈拉回，QQ/飞书自动重连）
- `channels status --probe` 在 3GB 机上过重会卡死 → 渠道验证改查日志：
  `grep -aiE "weixin|feishu|qqbot" $PREFIX/var/log/sv/openclaw/current | tail`

## 验证门

1. 日志见 `config cached for ...@im.wechat`
2. 微信里真实发一条消息 → bot 回复（最强 E2E）
3. 既有渠道未被连累：日志 qqbot `Gateway resumed` / feishu `WebSocket client started`

## 装完加固（可选）

gateway 启动提示 `plugins.allow is empty` 时，显式声明信任插件防未授权自动加载——
`openclaw.json` 设 `"plugins": {"allow": ["feishu", "openclaw-weixin", "qqbot"], ...}`
（按本机实际插件列，勿动 entries 里的供应商条目），顺手删历史脏条目
（如 `plugins.entries.qwen-portal-auth`），改完 `sv restart openclaw` 并重跑验证门。
⚠️ 改 allow 时若 gateway 正在运行，其退出瞬间可能把内存里的**旧配置写回**（坑 24，Note 7 实测：
改完首次重启警告仍在，二次重启才生效）——稳妥流程 `sv down` → 改配置 → `sv up`，
或改完重启后 `grep "allow is empty"` 校验，仍在就再重启一次。
