# TencentDB Agent Memory 配置

> 腾讯云开源的四层渐进式 AI Agent 记忆系统 v1.0.1

## 安装

```bash
openclaw plugins install @tencentdb-agent-memory/memory-tencentdb
# 自动启用，无需额外配置
```

## 验证

```bash
openclaw plugins list | grep tencentdb    # 应为 enabled v1.0.1
ls ~/.openclaw/memory-tdai/               # conversations/ records/ scene_blocks/ vectors.db
```

## 平台限制

- **Linux/macOS**: 全功能（sqlite-vec 原生扩展可用）
- **Android/Termux**: 降级模式（glibc vs bionic ABI，sqlite-vec 无法加载）
  - L0 对话采集 ✅
  - L1 事实提取 ✅
  - L2 向量搜索/去重 ❌（需云端 TencentDB 向量数据库）
  - L3 场景记忆 ❌

## 运维

```bash
# 记忆日志
tail -f $PREFIX/var/log/sv/openclaw/current | grep memory-tdai

# 数据统计
wc -l ~/.openclaw/memory-tdai/conversations/*.jsonl  # 对话数
wc -l ~/.openclaw/memory-tdai/records/*.jsonl         # 记忆数
ls -lh ~/.openclaw/memory-tdai/vectors.db              # 向量库大小

# 降级检查
grep -c "degraded" $PREFIX/var/log/sv/openclaw/current
```

## 已部署设备

| 设备 | 版本 | vectors.db | 降级次数 |
|------|------|-----------|---------|
| K60 | v1.0.1 | 8.4M | 0 |
| MIX 2S | v1.0.1 | 6.3M | 0 |
| Note 7 | v1.0.1 | 8.3M | 12(glibc) |
| Note 4X | — | — | 3GB RAM 待评估 |
