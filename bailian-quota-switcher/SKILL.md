---
name: bailian-quota-switcher
description: >
  阿里云百炼免费模型额度耗尽自动切换。部署 watcher 守护进程监控 403 错误并自动切换到下一个有额度的模型。
  适用：安卓 Termux + OpenClaw 网关环境。
  触发场景：(1) 部署百炼免费模型自动切换系统到安卓设备 (2) 配置 API Key + 模型列表 (3) 403 Free quota exhausted 时自动切换模型 (4) 查看各设备模型额度面板 (5) 多设备分派不同主模型分散额度消耗。
  关键词：百炼、阿里云、免费额度、403、自动切换、qwen、deepseek、kimi、glm、MiniMax、quota exhausted、bailian、dashscope
---

# 百炼免费模型额度自动切换 v2.2

> 完整文档见 [README.md](README.md) | 版本记录见 README §12 | 踩坑见 [README.md §踩坑速查](README.md#踩坑速查16-条)

基于 **两天四机（K60/MIX2S/Note7/Note4X）实战打磨**。每台安卓手机配一组百炼免费大语言模型（各 100 万 token 独立额度），watcher 守护进程监控日志中的 403 错误，自动 re-auth + 切换到下一个模型。

## 文件结构

```
bailian-quota-switcher/
├── SKILL.md                      # 本文件：核心流程 + 快速开始
├── README.md                     # 详细文档（独立分发用）
├── scripts/
│   ├── deploy.sh                 # 一键部署：飞行前验证 → 清理 breaker → 部署 → 健康检查
│   ├── quota_watcher.sh          # 守护进程 v2：403/400/401 全覆盖 + 启动自检
│   ├── quota_manager.sh          # 手动管理：status / switch / deplete / update
│   └── phone_check_env.sh        # 环境体检：机型/Node/SQLite/OpenClaw/服务/渠道一键诊断
└── references/
    └── pitfalls.md               # 16 条踩坑速查（必读）
```

## 快速开始

### 1. 安装技能

```bash
# 放到 Claude Code 技能目录
cp bailian-quota-switcher.skill ~/.claude/skills/
cd ~/.claude/skills && unzip bailian-quota-switcher.skill
```

之后说"部署百炼免费模型"或"403 自动切换"或"K60 QQ 连不上了"都会触发。

### 2. 部署到设备

```bash
export BAILIAN_KEY="sk-ws-H.XXX"
# 编辑 scripts/deploy.sh 的 DEVICES 数组
bash scripts/deploy.sh
```

飞行前自动 curl 验证 Key（HTTP 非 200 告警）。逐台部署，含健康验证。

### 3. 手动运维

```bash
# 额度面板
bash ~/quota_manager.sh status

# 标记耗尽 + 自动切下一个
bash ~/quota_manager.sh deplete <model>

# 查看 watcher 日志
cat ~/watcher.log

# 检查 watcher 是否活着
ps aux | grep quota_watcher

# 环境体检（一键诊断）
cat scripts/phone_check_env.sh | ssh -p 8022 user@<IP> 'sh -'
```

## 核心流程

```
设备上的 watcher 监控 gateway 日志
  → 检测到 "403 Free quota exhausted"
  → openclaw models auth paste-api-key (修复 auth 污染)
  → 标记当前模型 depleted → 更新 free_quota.json
  → c.agents.defaults.model.primary = 下一个模型
  → sv restart openclaw
  → 30 秒冷却期

Watcher 同时检测：
  - 400 Arrearage（账户欠费）→ 告警，不做切换
  - 401 Incorrect API key → 告警，不做切换
```

## ⚠️ 关键注意事项（两天实战精华）

### Config 路径（最重要！）

```
✅ c.agents.defaults.model.primary     ← 主模型在这里
✅ c.agents.defaults.model.fallbacks   ← fallback 链在这里
❌ c.models.default                    ← 写这里会触发校验失败
❌ c.models.fallbacks                   ← 同上
```

模型定义（baseUrl、models 列表、apiKey）在 `~/.openclaw/agents/main/agent/models.json`。
全局 `openclaw.json` 中的 `models.providers.alibaba-model-studio` **不能**有残缺定义——要么完整，要么删除。

### API Key 传递

SSH 单引号内变量不展开！正确方式：
```bash
# 1. 先写文件
echo "$KEY" | ssh ... 'cat > ~/bailian_key.txt'
# 2. Node 里读取
node -e 'var k=fs.readFileSync(process.env.HOME+"/bailian_key.txt","utf8").trim(); ...'
```

### crash-loop breaker

300 秒内 3 次非正常退出触发。部署前清理：
```bash
rm -f ~/.openclaw/logs/stability/*.json
sv down openclaw; sleep 2; sv up openclaw
```

### 飞行前验证

部署前 curl 验证 Key，遇到过三种不可自动修复的错误：
- 400 Arrearage — 账户欠费
- 401 Incorrect API key — Key 失效
- 403（"只免"模式全局封）— 账户级免费配额耗尽

### 低端机启动时间

骁龙 660/625 机型冷启动到 HTTP 200 需 40-60 秒，state 迁移需 2-3 分钟。

## 多设备模型分派

不同设备用不同主模型，避免同时消耗同一个 100 万额度：

```
K60    → qwen3.7-max      (999,936 剩余)
MIX2S  → qwen3.7-plus     (1,000,000)
Note7  → qwen3.7-max      (1,000,000)
Note4X → qwen3.7-plus     (1,000,000)
```

每台 fallback 链互补组成。

## 模型分类（五类，仅用第一类）

| 类别 | 示例 | 用于 QQ 聊天 |
|------|------|:--:|
| 大语言模型 | qwen3.7-max, deepseek-v4-pro, kimi-k2.6, glm-5.2, MiniMax-M2.5 | ✅ |
| 视觉模型 | qwen-vl-max, qwen-image-plus, wanx-* | ❌ |
| 全模态模型 | qwen-omni-turbo, qwen3-omni-flash | ❌ |
| 语音模型 | paraformer-*, sambert-*, cosyvoice-* | ❌ |
| 向量模型 | qwen3.7-text-embedding | ❌ |

## 已知问题

详见 [README.md §踩坑速查](README.md#踩坑速查16-条)（16 条）。

**核心坑**：403 导致 auth profile 全局失效。OpenClaw 把单个模型的 403 误判为 provider 级 auth 失败，使所有 fallback 模型报 "Couldn't sign in"。Watcher 通过 re-auth 绕过。

## 实战数据

两天四机运行统计：
- 模型切换次数：6 次（kimi-k2.6 ×3, qwen3.5-plus ×2, deepseek-v4-flash ×1）
- IP 白名单更新：3 次（蜂窝 IP 漂移）
- crash-loop breaker 触发：4 次（反复部署导致）
- 单次切换耗时：20-30 秒（K60），40-60 秒（Note7/Note4X）
