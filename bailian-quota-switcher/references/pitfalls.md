# 百炼免费模型已知踩坑（16条，两天四机实战验证）

## 核心坑

### 坑 1：403 导致 auth profile 全局失效 ⚠️ 最频繁

**现象**：主模型返回 403 (quota exhausted)，fallback 链上所有模型报 `Couldn't sign in to alibaba-model-studio`

**原因**：OpenClaw 把单个模型的 403 误判为 provider 级别的 auth 失效

**解法**：Watcher 检测 403 → `paste-api-key` 重认证 → 切主模型 → `sv restart`

### 坑 2：config 路径写错触发校验失败

**现象**：手动编辑 `c.models.default/fallbacks` 后 `openclaw config validate` 报 `Invalid input`

**原因**：正确路径是 `c.agents.defaults.model.primary` 和 `c.agents.defaults.model.fallbacks`

**解法**：永远只读写 `c.agents.defaults.model.*`，部署完立即 `delete c.models.default; delete c.models.fallbacks`

### 坑 3：API Key 在 SSH 单引号中不展开

**现象**：Gateway 启动报 `Environment variable "K" is missing or empty`，models.json 中 Key 是字面量 `$K`

**原因**：Bash 单引号内变量不展开；Node 不认环境变量引用的 Key 字符串

**解法**（三选一）：
- **推荐**：先 `echo "$KEY" | ssh ... 'cat > ~/bailian_key.txt'`，再 Node 里 `fs.readFileSync` 读取
- SSH heredoc: `ssh ... bash -s << ENDSSH` + 双引号内变量
- JSON 里直接拼接：在 PC 侧用 Node 生成完整 JSON 再传

### 坑 4：crash-loop breaker 锁死全部渠道

**现象**：反复重启 gateway 后 QQ/飞书/微信全部 `channel autostart suppressed by crash-loop breaker`

**触发条件**：300 秒内 3 次非正常退出

**解法**：
```bash
export SVDIR=$PREFIX/var/service
sv down openclaw
rm -f ~/.openclaw/logs/stability/*.json
sv up openclaw
```
部署前先清理，重启时用 `sv down/up` 而非 `sv restart` 减少触发概率。

## 部署坑

### 坑 5：Termux 没有 /tmp

**现象**：`cat > /tmp/xxx` 静默失败，文件不存在

**解法**：用 `$HOME/xxx` 或 `$PREFIX/tmp`

### 坑 6：curl 走 IPv6 导致 HTTP:000

**现象**：gateway 在跑但 `curl http://127.0.0.1:18789/` 返回 000

**解法**：`curl -4` 强制 IPv4。某些设备 Node 默认走 IPv6，127.0.0.1 的 IPv6 映射不一定通

### 坑 7：低端机启动慢

**现象**：骁龙 660 的 Note7，gateway 冷启动到 HTTP 200 需 40-60 秒，state 迁移需 3 分钟

**解法**：部署后等 15 秒再验证 HTTP，升级后等 2-3 分钟再判断失败

### 坑 8：models.json 中 model 未定义但被 fallback 引用

**现象**：`Unknown model: alibaba-model-studio/qwen-turbo`

**原因**：fallback 链里有，models.json 里没有

**解法**：部署后跑 `openclaw models list | grep alibaba` 确认模型数量匹配

### 坑 9：多设备同时部署导致全队离线

**现象**：并行部署 4 台设备时，反复 config 变更 + 重启导致某些设备 crash-loop

**解法**：逐台部署，每台验证完再下一台。金丝雀：先一台 → 验证 → 再推全队

## 账号坑

### 坑 10："仅使用免费额度"模式导致全部模型 403

**现象**：所有模型返回 403，即使各自还有 100 万独立额度

**原因**：百炼控制台开启了"仅使用免费额度"，账户总免费配额（非模型级）耗尽后全局封

**解法**：去百炼控制台关掉该模式，或确认账户有余额

### 坑 11：账户欠费

**现象**：`400 Arrearage / Access denied, account not in good standing`

**解法**：百炼控制台充值。两个 Key 分别检查：`curl -4 -s -w "%{http_code}" https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions -H "Authorization: Bearer $KEY" ...`

### 坑 12：Key 被 revoke

**现象**：`401 Incorrect API key`

**解法**：去百炼控制台重新生成。旧 key 废了就废了，没法恢复

## 额度坑

### 坑 13：API 返回的额度与 Excel 不一致

**现象**：Excel 显示 100 万剩余，API 返回 403

**原因**：
- Key 不同（Excel 是贺鑫的 key，手机上配的是旧 key）
- 账户级限额与模型级限额不同步
- "仅使用免费额度"模式提前截断

**解法**：部署前先用 curl 验证 Key 返回 HTTP 200；同一时间只用同一个 Key

### 坑 14：两个 Key 额度互相不知

**现象**：切到贺鑫的 key 后以为所有模型都有额度，实际旧 key 和贺鑫 key 各有独立配额

**解法**：一台设备只配一个 Key；Key 切换时重置额度追踪数据

## Watcher 坑

### 坑 15：Watcher 随 SSH 会话退出而终止

**现象**：SSH 断开后 watcher 进程消失

**解法**：必须用 `nohup ... &` 启动；加入 `~/.termux/boot/start-services.sh` 确保重启后自动拉起

### 坑 17：Provider 名称不统一导致 "Unknown model"

**现象**：`All models failed: Unknown model: alibaba-model-studio/qwen3.7-max`，但 models.json 里有该模型

**原因**：不同部署批次用了不同 provider 名。有的设备用 `dashscope`，有的用 `alibaba-model-studio`。OpenClaw 的 config 引用 `alibaba-model-studio/xxx`，但 models.json 里是 `dashscope.xxx` → 找不到

**解法**：
```bash
node -e '
var m=JSON.parse(fs.readFileSync(process.env.HOME+"/.openclaw/agents/main/agent/models.json","utf8"));
if(m.providers["dashscope"]){
  m.providers["alibaba-model-studio"]=m.providers["dashscope"];
  delete m.providers["dashscope"];
  fs.writeFileSync(...,JSON.stringify(m,null,2));
}
'
```

### 坑 18：free_quota.json 缺失导致 watcher 崩溃

**现象**：Watcher 日志报 `ENOENT: no such file or directory, open '...free_quota.json'`

**原因**：旧版 watcher（v1）没有 try/catch 包裹 free_quota.json 读取，文件不存在时直接抛异常

**解法**：
- 升级到 watcher v2.2（有 try/catch + 启动自建文件）
- 手动创建：`echo '{"models":{}}' > ~/.openclaw/free_quota.json`

### 坑 19：旧 provider 残骸在 openclaw.json 中

**现象**：Gateway 启动报 `models.providers.alibaba-model-studio: custom model providers must declare models`

**原因**：openclaw.json 中有残缺的 provider 定义（只有 baseUrl 没有 models）。这通常是之前手动编辑留下的

**解法**：
```bash
node -e '
var c=JSON.parse(fs.readFileSync(process.env.HOME+"/.openclaw/openclaw.json","utf8"));
["dashscope","alibaba-model-studio","qwen-portal"].forEach(function(id){
  if(c.models&&c.models.providers) delete c.models.providers[id];
});
fs.writeFileSync(...,JSON.stringify(c,null,2));
'
```

### 坑 16：Watcher 冷却时间太短导致循环切换

**现象**：模型 A 耗尽 → 切到 B → 立刻又切到 C（因为 B 的实际请求还没发出）

**解法**：COOLDOWN=30 秒，两次切换间隔至少 30 秒；`sv restart` 后等 gateway 完全启动
