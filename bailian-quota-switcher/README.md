# 百炼免费模型额度自动切换系统

> 阿里云百炼平台 100+ 免费大语言模型，每个 100 万 token 独立额度。
> 部署到安卓手机 OpenClaw 网关，额度耗尽（403）自动切换到下一个。
> **四台真机（K60/MIX2S/Note7/Note4X）实战验证，Android 7~15 全覆盖。**

---

## 目录

1. [架构概览](#1-架构概览)
2. [支持的模型](#2-支持的模型)
3. [快速部署](#3-快速部署)
4. [多设备分派策略](#4-多设备分派策略)
5. [自动切换流程](#5-自动切换流程)
6. [Watcher 守护进程](#6-watcher-守护进程)
7. [额度管理面板](#7-额度管理面板)
8. [开机自启配置](#8-开机自启配置)
9. [踩坑速查（16条）](#9-踩坑速查)
10. [运维命令速查](#10-运维命令速查)
11. [文件结构](#11-文件结构)
12. [版本更新记录](#12-版本更新记录)

---

## 1. 架构概览

```
┌──────────────────────────────────────────┐
│              百炼平台 (DashScope)          │
│  100+ 免费模型 × 100万 token 独立额度     │
└────────────┬─────────────────────────────┘
             │ API Key (sk-ws-H...)
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
     │ quota_watcher│  ← 每台设备独立运行
     │ tail -F 日志  │
     │ 检测403自动切  │
     │ 30s冷却防循环  │
     └─────────────┘
```

**核心策略**：每台设备独立模型分派 + watcher 自动切换 + 互补 fallback 链 = 四个模型池互不冲突。

---

## 2. 支持的模型

### 百炼免费模型五大分类

| 类别 | 示例 | QQ 聊天 | 原因 |
|------|------|:--:|------|
| **大语言模型** | qwen3.7-max, deepseek-v4-pro, kimi-k2.6, glm-5.2 | ✅ | 文本对话 |
| 视觉模型 | qwen-vl-max, qwen-image-plus, wanx-* | ❌ | 需图片输入 |
| 全模态模型 | qwen-omni-turbo, qwen3-omni-flash | ❌ | 多余模态 QQ 用不上 |
| 语音模型 | paraformer-*, sambert-*, cosyvoice-* | ❌ | TTS/ASR 专用 |
| 向量模型 | qwen3.7-text-embedding | ❌ | Embedding 专用 |

本系统 **仅部署大语言模型**，其余四类跳过。

### 核心模型清单

| 模型 ID | 来源 | 额度 | contextWindow | 特点 |
|---------|------|------|:---:|------|
| `qwen3.7-max` | 通义千问 | 1M | 128K | 最强推理，当前主力 |
| `qwen3.7-plus` | 通义千问 | 1M | 128K | 性价比之选 |
| `qwen3-max` | 通义千问 | 1M | 128K | 三代旗舰 |
| `qwen-max` | 通义千问 | 1M | 32K | 经典旗舰 |
| `qwen-plus` | 通义千问 | 1M | 131K | 日常最优 |
| `qwen-turbo` | 通义千问 | 1M | 1M | 轻量快速 |
| `deepseek-v4-pro` | DeepSeek | 1M | 128K | 推理+思考链 |
| `deepseek-v4-flash` | DeepSeek | 1M | 128K | 快速响应 |
| `deepseek-v3.2` | DeepSeek | 1M | 128K | 稳定版 |
| `kimi-k2.6` | Moonshot | 1M | 128K | 长上下文 |
| `kimi-k2.7-code` | Moonshot | 1M | 128K | 代码增强 |
| `glm-5.2` | 智谱 | 1M | 128K | 国产老牌 |
| `MiniMax-M2.5` | MiniMax | 1M | 1M | 超长上下文 |
| `qwq-plus` | 通义千问 | 1M | 128K | 深度推理 |
| `qwen3-coder-plus` | 通义千问 | 1M | 128K | 代码专用 |

> 完整列表见 [阿里云百炼文档](https://help.aliyun.com/zh/model-studio/)

---

## 3. 快速部署

### 前置条件

- 安卓手机已安装 Termux + OpenClaw + runit（参考 [openclaw-termux-deploy](https://github.com/DeXuan/openclaw-termux-deploy)）
- 百炼 API Key
- PC 可 SSH 到手机

### 方式一：一键部署脚本

```bash
export BAILIAN_KEY="sk-ws-H.XXX"

# 编辑 scripts/deploy.sh 的 DEVICES 数组
DEVICES=(
  "192.168.1.23 u0_a197 8022 K60 qwen3.7-max"
  "192.168.1.20 u0_a129 8022 MIX2S qwen3.7-plus"
)

bash scripts/deploy.sh
```

脚本自动执行：飞行前 Key 校验 → 写 Key → Auth → 写 models.json → 写 config → 清 breaker → 重启 gateway → 健康验证。

### 方式二：手动部署

#### Step 1: 写 Key + Auth

```bash
echo "$KEY" | ssh -p 8022 user@<IP> 'cat > ~/bailian_key.txt'
echo "$KEY" | ssh -p 8022 user@<IP> \
  'openclaw models auth paste-api-key --provider alibaba-model-studio'
```

#### Step 2: 配置模型

编辑 `~/.openclaw/agents/main/agent/models.json`，添加 `alibaba-model-studio` provider：

```json
{
  "providers": {
    "alibaba-model-studio": {
      "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
      "api": "openai-completions",
      "apiKey": "sk-ws-H.XXX",
      "models": [
        {"id":"qwen3.7-max","name":"Qwen3.7 Max",...},
        {"id":"qwen3.7-plus","name":"Qwen3.7 Plus",...}
      ]
    }
  }
}
```

#### Step 3: 设置主模型 + fallback

编辑 `~/.openclaw/openclaw.json`：

```
⚠️ 必须写在 agents.defaults.model 路径下！绝对不能写 models.default！
```

```bash
node -e '
var c=JSON.parse(fs.readFileSync(process.env.HOME+"/.openclaw/openclaw.json","utf8"));
c.agents.defaults.model.primary="alibaba-model-studio/qwen3.7-max";
c.agents.defaults.model.fallbacks=[
  "alibaba-model-studio/qwen3.7-plus",
  "alibaba-model-studio/deepseek-v4-pro",
  "alibaba-model-studio/kimi-k2.6"
];
delete c.models.default;    // 必须删！
delete c.models.fallbacks;   // 必须删！
fs.writeFileSync(p,JSON.stringify(c,null,2));
'
```

#### Step 4: 部署 Watcher

```bash
cat scripts/quota_watcher.sh | ssh -p 8022 user@<IP> \
  'cat > ~/quota_watcher.sh && chmod +x ~/quota_watcher.sh'
ssh -p 8022 user@<IP> 'nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &'
```

#### Step 5: 重启验证

```bash
ssh -p 8022 user@<IP> 'export SVDIR=$PREFIX/var/service && sv restart openclaw'
sleep 10
ssh -p 8022 user@<IP> \
  'curl -4 -s --max-time 5 http://127.0.0.1:18789/ -o /dev/null -w "HTTP:%{http_code}\n"'
```

---

## 4. 多设备分派策略

不同设备用不同主模型，避免四台同时耗尽同一个 100 万额度：

| 设备 | 主模型 | Fallback 优先级（互补） |
|------|--------|-------------------------|
| K60 | qwen3.7-max | qwen3.7-plus → qwen-max → qwen-plus → deepseek-v4-pro → deepseek-v4-flash → kimi-k2.6 → glm-5.2 |
| MIX2S | qwen3.7-plus | qwen3.7-max → qwen-max → qwen-plus → deepseek-v4-pro → deepseek-v4-flash → kimi-k2.6 → glm-5.2 |
| Note7 | qwen3.7-max | qwen3.7-plus → qwen-plus → deepseek-v4-pro → deepseek-v4-flash → kimi-k2.6 → glm-5.2 → MiniMax-M2.5 |
| Note4X | qwen3.7-plus | qwen3.7-max → qwen-plus → deepseek-v4-flash → deepseek-v4-pro → kimi-k2.6 → glm-5.2 → MiniMax-M2.5 |

**原则**：每台 fallback 链排序略有不同，避免耗尽后多台跳到同一个模型。

---

## 5. 自动切换流程

```
用户发消息 → QQ Bot → Gateway → 百炼 API
                                    │
                             ┌──────▼──────┐
                             │ 返回 200 OK  │ → 正常回复用户
                             └──────────────┘
                             ┌──────────────┐
                             │ 返回 403     │ → 当前模型额度耗尽
                             └──────┬───────┘
                                    │
                             ┌──────▼──────────┐
                             │ watcher 检测到   │ ← tail -F 日志
                             │ "403 Free quota │
                             │  exhausted"     │
                             └──────┬──────────┘
                                    │
                             ┌──────▼──────────┐
                             │ 1. re-auth      │ ← paste-api-key 修复 auth 污染
                             │ 2. 标记 depleted │ ← 更新 free_quota.json
                             │ 3. 切主模型      │ ← agents.defaults.model.primary
                             │ 4. sv restart   │ ← 重启 gateway
                             │ 5. 30s 冷却     │ ← 防循环
                             └──────┬──────────┘
                                    │
                             ┌──────▼──────┐
                             │ 下一模型响应 │ → 用户收到新回复
                             └──────────────┘
```

**耗时**：K60 骁龙8+ ~20-30s / Note7 骁龙660 ~40-60s / Note4X 骁龙625 ~50-70s

**切换期间**：用户发消息会看到 "Something went wrong"，切换完自动恢复。

---

## 6. Watcher 守护进程

`scripts/quota_watcher.sh` — 每台设备后台运行。

### 检测范围

| 错误码 | 行为 |
|:--:|------|
| 403 Free quota exhausted | **自动修复**：re-auth → 标记耗尽 → 切下一模型 → 重启 |
| 400 Arrearage / overdue | **告警**：账户欠费，需人工充值 |
| 401 Incorrect API key | **告警**：Key 失效，需人工更换 |

### 启动/停止

```bash
# 启动
nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &

# 查看
cat ~/watcher.log
ps aux | grep quota_watcher

# 停止
pkill -f quota_watcher
```

### 冷却机制

两次切换最小间隔 30 秒，防止两个模型连续耗尽陷入死循环。

---

## 7. 额度管理面板

`scripts/quota_manager.sh` — 手动管理工具。

```bash
bash ~/quota_manager.sh status    # 查看面板
bash ~/quota_manager.sh deplete <model>  # 标记耗尽 + 自动切
bash ~/quota_manager.sh switch    # 手动切下一个
bash ~/quota_manager.sh update <model> <tokens>  # 手动更新用量
```

### 面板示例

```
====== 免费模型额度面板 ======
时间: 2026-07-23 02:30
主模型: alibaba-model-studio/qwen3.7-max

模型                      总额度      剩余     过期       状态
----------------------------------------------------------------------
X kimi-k2.6                 100w     0w(0%)  2026-07-21  depleted
O qwen3.7-max               100w  99.9w(99%)  2026-08-20  active  ← 当前
O qwen3.7-plus              100w   100w(100%) 2026-09-01  active
...

总计: 10活跃 + 3耗尽 + 0过期
剩余: 1000万 / 1300万 token
```

---

## 8. 开机自启配置

为每台设备的 watcher 配置 Termux:Boot 自启动：

```bash
# 添加自启
ssh -p 8022 user@<IP> '
  grep -q "quota_watcher" ~/.termux/boot/start-services.sh 2>/dev/null || {
    echo "" >> ~/.termux/boot/start-services.sh
    echo "# 百炼免费额度自动切换守护" >> ~/.termux/boot/start-services.sh
    echo "nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &" >> ~/.termux/boot/start-services.sh
  }
'

# 确认
ssh -p 8022 user@<IP> 'grep quota_watcher ~/.termux/boot/start-services.sh'
```

**前提**：手机已安装 Termux:Boot，Termux 电池策略设为"无限制"。

> 部署脚本 `deploy.sh` 不自动配置 boot 脚本——boot 路径因 Termux 版本不同而异。建议手动确认。

---

## 9. 踩坑速查

完整版见 [references/pitfalls.md](references/pitfalls.md)，以下为最常见 6 条：

### 坑 1：403 → auth 全局污染

**现象**：主模型 403，后续所有 fallback 模型报 `Couldn't sign in`

**原因**：OpenClaw 把单模型 403 误判为 provider 级别 auth 失效

**解法**：Watcher 检测到 403 → `paste-api-key` 重认证 → 切换

### 坑 2：config 路径写错

**现象**：`openclaw config validate` 报 `Invalid input`

**正确路径**：
```
✅ c.agents.defaults.model.primary
✅ c.agents.defaults.model.fallbacks
❌ c.models.default        ← 写这里必崩
❌ c.models.fallbacks       ← 同上
```

### 坑 3：Key 变量不展开

**现象**：Gateway 启动报 `Environment variable "K" is missing or empty`

**原因**：SSH 单引号内 `$K` 不展开

**解法**：先 `echo "$KEY" | ssh ... 'cat > ~/bailian_key.txt'`，再 Node `fs.readFileSync`

### 坑 4：crash-loop breaker 锁渠道

**现象**：QQ/飞书/微信全部 `channel autostart suppressed`

**解法**：
```bash
sv down openclaw
rm -f ~/.openclaw/logs/stability/*.json
sv up openclaw
```

### 坑 5：Termux 没有 /tmp

**解法**：用 `$HOME` 或 `$PREFIX/tmp`

### 坑 6：curl IPv6

**现象**：Gateway 跑着但 `curl http://127.0.0.1:18789/` 返 000

**解法**：`curl -4` 强制 IPv4

---

## 10. 运维命令速查

```bash
# ── 环境诊断 ──
cat scripts/phone_check_env.sh | ssh -p 8022 user@<IP> 'sh -'  # 一键体检

# ── Gateway ──
export SVDIR=$PREFIX/var/service
sv status openclaw               # 查看状态
sv restart openclaw               # 重启
tail -20 $PREFIX/var/log/sv/openclaw/current  # 查看日志

# ── 模型 ──
openclaw models list | grep alibaba   # 列出百炼模型
openclaw models status               # 当前模型状态
openclaw channels status --probe     # 渠道状态

# ── Watcher ──
ps aux | grep quota_watcher          # 是否活着
cat ~/watcher.log                     # 最近日志
pkill -f quota_watcher               # 停止
nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &  # 启动

# ── 手动切换 ──
bash ~/quota_manager.sh deplete <model>  # 耗尽 + 切下一个
bash ~/quota_manager.sh status           # 查看面板
```

---

## 11. 文件结构

```
bailian-quota-switcher/
├── README.md                ← 本文件（唯一文档）
├── SKILL.md                 ← Claude Code 技能定义（精简版）
├── scripts/
│   ├── deploy.sh            ← 一键部署（飞行前 Key 验证 + 部署 + 健康检查）
│   ├── quota_watcher.sh     ← 守护进程 v2（403/400/401 全覆盖）
│   ├── quota_manager.sh     ← 额度面板 + 手动管理
│   └── phone_check_env.sh   ← 环境体检（机型/Node/SQLite/服务/渠道）
└── references/
    └── pitfalls.md          ← 16 条踩坑详情
```

| 文件 | 大小 | 所在位置 |
|------|------|---------|
| README.md | ~12KB | 设备 `~/.claude/skills/bailian-quota-switcher/` |
| SKILL.md | ~6KB | 同上 |
| deploy.sh | ~7KB | 设备 `~/` （部署时将脚本推送到此处） |
| quota_watcher.sh | ~4KB | 设备 `~/` |
| quota_manager.sh | ~5KB | 设备 `~/` |
| pitfalls.md | ~5KB | 技能参考目录 |

---

## 12. 版本更新记录

### v2.2 (2026-07-23)

- **新增**：watcher 启动自建 `free_quota.json`（缺失不再崩溃）
- **新增**：deploy.sh 清理旧 provider 残骸（`dashscope`/`qwen-portal` 等）
- **新增**：deploy.sh Step 4 创建 `free_quota.json`
- **新增**：3 条踩坑（#17 Provider名不统一、#18 free_quota.json缺失、#19 旧provider残骸）
- **修复**：多设备 provider 名称不统一问题（统一为 `alibaba-model-studio`）
- **优化**：deploy.sh 步骤从 6 步扩展到 7 步，覆盖更全面

### v2.1 (2026-07-23)

- **新增**：boot 自启配置说明（§8）
- **优化**：合并 README.md 为单一文档，SKILL.md 精简为技能定义
- **改进**：文档目录结构化，方便快速定位
- **修复**：quota_watcher.sh 新增启动自检（清 breaker + 等 gateway）
- **补充**：运维命令速查表（§10）

### v2.0 (2026-07-22)

- **新增**：watcher 检测 400/401（不只是 403）
- **新增**：飞行前 Key 验证
- **新增**：deploy.sh 一键部署
- **新增**：crash-loop breaker 自动清理
- **修复**：config 路径错误（`models.*` → `agents.defaults.model.*`）
- **修复**：Key `$K` 字面量问题（改用文件传递）
- **补充**：16 条踩坑速查

### v1.0 (2026-07-21)

- **初始版本**：watcher + quota_manager + 模型配置
- K60 单台验证
- 覆盖 15 个免费模型

---

## 相关链接

- [openclaw-termux-deploy](https://github.com/DeXuan/openclaw-termux-deploy) — OpenClaw 安卓部署
- [阿里云百炼控制台](https://bailian.console.aliyun.com) — 模型管理/API Key
- [百炼模型定价](https://help.aliyun.com/zh/model-studio/model-pricing) — 免费额度说明
