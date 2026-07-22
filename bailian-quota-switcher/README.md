# 百炼免费模型额度自动切换系统 v2.1

> 阿里云百炼平台提供 100+ 免费大语言模型，每个 100 万 token 独立额度。
> 本系统将这些模型部署到安卓手机 OpenClaw 网关，额度耗尽（403）自动切换到下一个。

**四台真机（K60/MIX2S/Note7/Note4X）实战验证，两天 6 次自动切换。**

---

## 目录

- [架构概览](#架构概览)
- [支持的模型](#支持的模型)
- [快速部署](#快速部署)
- [多设备分派策略](#多设备分派策略)
- [自动切换流程](#自动切换流程)
- [额度管理面板](#额度管理面板)
- [踩坑速查（16条）](#踩坑速查)
- [文件说明](#文件说明)
- [实战数据](#实战数据)
- [FAQ](#faq)

---

## 架构概览

```
┌──────────────────────────────────────────┐
│              百炼平台 (DashScope)          │
│  100+ 免费模型 × 100万 token 独立额度     │
└────────────┬─────────────────────────────┘
             │ API Key
    ┌────────┼────────┬────────┐
    ▼        ▼        ▼        ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
│ K60  │ │MIX2S │ │Note7 │ │Note4X│  ← 安卓 + Termux + OpenClaw
│qwen  │ │qwen  │ │qwen  │ │deep  │  ← 不同主模型
│3.7   │ │3.7   │ │3.7   │ │seek  │
│-max  │ │-plus │ │-max  │ │v4pro │
└──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘
   │        │        │        │
   └────────┼────────┼────────┘
            │
     ┌──────▼──────┐
     │ quota_watcher│  ← 守护进程
     │ 监控日志 403  │    每台设备独立运行
     │ 自动切换模型  │
     └─────────────┘
```

**核心思路**：
1. 每台设备配一组模型（主模型 + fallback 链）
2. watcher 监控 gateway 日志，检测到 403 自动 re-auth + 切换
3. 不同设备用不同主模型，分散额度消耗
4. 所有模型共享同一个百炼 API Key

---

## 支持的模型

仅使用 **大语言模型**（文本聊天），跳过视觉/全模态/语音/向量四类。

### 已部署的核心模型（按质量排序）

| 模型 ID | 类型 | 额度 | 特点 |
|---------|------|------|------|
| `qwen3.7-max` | 千问旗舰 | 1M | 最强推理，当前主力 |
| `qwen3.7-plus` | 千问增强 | 1M | 性价比之选 |
| `qwen3-max` | 千问三代 | 1M | 综合能力强 |
| `qwen-max` | 千问旗舰 | 1M | 经典旗舰 |
| `qwen-plus` | 千问增强 | 1M | 日常最优 |
| `deepseek-v4-pro` | DeepSeek | 1M | 推理+思考 |
| `deepseek-v4-flash` | DeepSeek | 1M | 快速响应 |
| `kimi-k2.6` | Moonshot | 1M | 长上下文 |
| `glm-5.2` | 智谱 | 1M | 国产老牌 |
| `MiniMax-M2.5` | MiniMax | 1M | 超长上下文 |

### 百炼免费模型五大分类

| 类别 | 示例模型 | 用于聊天 | 原因 |
|------|---------|:--:|------|
| **大语言模型** | qwen3.7-max, deepseek-v4-pro, kimi-k2.6 | ✅ | 文本对话 |
| 视觉模型 | qwen-vl-max, qwen-image-plus, wanx-* | ❌ | 需图片输入 |
| 全模态模型 | qwen-omni-turbo, qwen3-omni-flash | ❌ | QQ 无需多模态 |
| 语音模型 | paraformer-*, sambert-*, cosyvoice-* | ❌ | TTS/ASR 专用 |
| 向量模型 | qwen3.7-text-embedding | ❌ | Embedding 专用 |

---

## 快速部署

### 前置条件

- 安卓手机已安装 Termux + OpenClaw（参考 [openclaw-termux-deploy](https://github.com/DeXuan/openclaw-termux-deploy)）
- 百炼 API Key（`sk-ws-H...` 格式）
- PC 可 SSH 到手机

### 方式一：一键部署脚本

```bash
export BAILIAN_KEY="sk-ws-H.XXX"

# 编辑 deploy.sh 中的 DEVICES 数组
DEVICES=(
  "192.168.1.23 u0_a197 8022 K60 qwen3.7-max"
  "192.168.1.20 u0_a129 8022 MIX2S qwen3.7-plus"
)

bash scripts/deploy.sh
```

脚本会：
1. **飞行前**：curl 验证 Key 可用性
2. **部署**：写 Key → Auth → models.json → config → watcher
3. **验证**：HTTP 200 + watcher 进程数

### 方式二：手动部署

```bash
K="sk-ws-H.XXX"

# 1. 写 Key
echo "$K" | ssh -p 8022 user@<IP> 'cat > ~/bailian_key.txt'

# 2. Auth
echo "$K" | ssh -p 8022 user@<IP> \
  'openclaw models auth paste-api-key --provider alibaba-model-studio'

# 3. 部署脚本
cat scripts/quota_watcher.sh | ssh -p 8022 user@<IP> \
  'cat > ~/quota_watcher.sh && chmod +x ~/quota_watcher.sh'

cat scripts/quota_manager.sh | ssh -p 8022 user@<IP> \
  'cat > ~/quota_manager.sh && chmod +x ~/quota_manager.sh'

# 4. 配置模型（编辑 openclaw.json 的 agents.defaults.model）

# 5. 启动 watcher
ssh -p 8022 user@<IP> 'nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &'
```

---

## 多设备分派策略

不同设备用不同主模型，防止同时耗尽同一个 100 万额度：

| 设备 | 主模型 | Fallback 优先级 |
|------|--------|-----------------|
| K60 | qwen3.7-max | qwen3.7-plus → qwen-plus → deepseek-v4-pro → ... |
| MIX2S | qwen3.7-plus | qwen3.7-max → qwen-plus → deepseek-v4-flash → ... |
| Note7 | qwen3.7-max | qwen3.7-plus → deepseek-v4-pro → kimi-k2.6 → ... |
| Note4X | qwen3.7-plus | qwen3.7-max → deepseek-v4-flash → glm-5.2 → ... |

**原则**：每台 fallback 链互补，模型耗尽后不会和其他设备抢。

---

## 自动切换流程

```
用户发消息 → QQ Bot → OpenClaw Gateway → 百炼 API
                                            │
                                     ┌──────▼──────┐
                                     │ 返回 200 OK  │ → 正常回复
                                     └──────────────┘
                                     ┌──────────────┐
                                     │ 返回 403     │ → 额度耗尽
                                     └──────┬───────┘
                                            │
                                     ┌──────▼──────────┐
                                     │ watcher 检测 403 │
                                     │ (tail -F 日志)   │
                                     └──────┬──────────┘
                                            │
                                     ┌──────▼──────────┐
                                     │ 1. re-auth      │ ← paste-api-key
                                     │ 2. 标记 depleted │ ← 更新 free_quota.json
                                     │ 3. 切主模型      │ ← agents.defaults.model.primary
                                     │ 4. sv restart   │ ← 重启 gateway
                                     │ 5. 30s 冷却     │ ← 防循环切换
                                     └──────┬──────────┘
                                            │
                                     ┌──────▼──────┐
                                     │ 下一模型响应 │ → 用户收到回复
                                     └──────────────┘
```

**耗时**：K60 ~20-30 秒，Note7/Note4X ~40-60 秒

---

## 额度管理面板

```bash
$ bash ~/quota_manager.sh status

====== 免费模型额度面板 ======
时间: 2026-07-23 02:30
主模型: alibaba-model-studio/qwen3.7-max

模型                      总额度      剩余     过期       状态
----------------------------------------------------------------------
X kimi-k2.6                 100w     0w(0%)  2026-07-21  depleted
X qwen3.5-plus-2026-04-20   100w     0w(0%)  2026-07-23  depleted
O qwen3.6-27b               100w   100w(100%) 2026-07-23  active
O deepseek-v4-flash         100w   100w(100%) 2026-07-24  active
O qwen3.7-max               100w  99.9w(99%)  2026-08-20  active  ← 当前
...

总计: 10活跃 + 3耗尽 + 0过期
剩余: 1000万 / 1300万 token
```

### 命令

| 命令 | 说明 |
|------|------|
| `bash ~/quota_manager.sh status` | 查看额度面板 |
| `bash ~/quota_manager.sh deplete <model>` | 标记耗尽 + 自动切下一个 |
| `bash ~/quota_manager.sh switch` | 手动切换到下一个活跃模型 |
| `bash ~/quota_manager.sh update <model> <tokens>` | 手动更新已用 token 数 |

---

## 踩坑速查

完整版见 [references/pitfalls.md](references/pitfalls.md)，共 16 条。核心坑：

| # | 现象 | 解法 |
|---|------|------|
| 1 | 主模型 403 → 所有 fallback 报 "Couldn't sign in" | watcher 检测 403 → re-auth → 切换 |
| 2 | 手动改 config → `Invalid input` 校验失败 | 写 `agents.defaults.model.*`，不写 `models.*` |
| 3 | API Key 变成字面量 `$K` → 启动报 env var 错 | 先写文件再 Node 读取 |
| 4 | QQ/飞书/微信全部 locked by crash-loop breaker | `sv down` → 删 stability/*.json → `sv up` |
| 5 | Termux `cat > /tmp/` 静默失败 | Termux 没有 /tmp，用 `$HOME` |
| 6 | `curl 127.0.0.1:18789` 返回 000 | 加 `-4` 强制 IPv4 |

---

## 文件说明

| 文件 | 大小 | 说明 |
|------|------|------|
| `SKILL.md` | 3.6KB | Claude Code 技能定义 |
| `README.md` | 本文件 | 完整文档 |
| `scripts/deploy.sh` | 6.9KB | 一键部署（飞行前检查 + 部署 + 验证） |
| `scripts/quota_watcher.sh` | 3.6KB | 守护进程（403/400/401 全覆盖） |
| `scripts/quota_manager.sh` | 5.0KB | 额度面板 + 手动管理 |
| `scripts/phone_check_env.sh` | - | 环境体检（机型/Node/SQLite/服务/渠道） |
| `references/pitfalls.md` | 4.9KB | 16 条踩坑速查 |

---

## 实战数据

两天四机运行统计（2026-07-21 ~ 2026-07-23）：

| 指标 | 数据 |
|------|------|
| 模型自动切换次数 | 6 次 |
| IP 白名单更新 | 3 次（蜂窝漂移） |
| crash-loop breaker | 4 次（部署期间） |
| 单次切换耗时 | K60: 20-30s，低端机: 40-60s |
| 账户级故障 | 2 次（贺鑫 key 欠费、旧 key 过期） |
| 部署迭代 | 4 轮（初始 → config 路径 → key 传递 → watcher v2） |

---

## FAQ

### Q: 切换期间用户能看到什么？

A: QQ 用户发消息会收到 "Something went wrong"，20-60 秒后恢复正常。

### Q: 如果所有模型都耗尽了怎么办？

A: Watcher 会停止切换，需要通过 `quota_manager.sh status` 确认状态，更换 API Key 或等待额度重置。

### Q: 为什么不直接用付费模型？

A: 100 个模型 × 100 万 token = 1 亿免费 token。四台设备日常聊天基本够用。付费模型（¥0.8/百万 token）作为最后兜底。

### Q: 如何添加新模型？

A: 
1. 在 `~/.openclaw/agents/main/agent/models.json` 的 `alibaba-model-studio.models` 数组中添加
2. 在 `~/.openclaw/openclaw.json` 的 `agents.defaults.model.fallbacks` 末尾追加
3. `sv restart openclaw`

### Q: Watcher 死了怎么办？

A: 
```bash
nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &
```
建议加入 `~/.termux/boot/start-services.sh` 实现开机自启。

---

## 许可证

MIT License

## 相关项目

- [openclaw-termux-deploy](https://github.com/DeXuan/openclaw-termux-deploy) — OpenClaw 安卓部署完整指南
- [OpenClaw](https://github.com/openclaw/openclaw) — AI Gateway
- [阿里云百炼](https://bailian.console.aliyun.com) — 模型平台
