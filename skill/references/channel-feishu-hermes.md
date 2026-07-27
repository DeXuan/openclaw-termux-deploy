# Hermes Agent 飞书渠道接入

Hermes Agent 通过统一消息网关原生支持飞书（Lark），WebSocket 长连接模式，无需公网 IP，NAT/蜂窝网络后可用。
与同机的 OpenClaw 飞书 bot 互不冲突（各自独立 AppID）。

## 前提

- Hermes Agent 已安装（v0.18+，实测 v0.19.0）
- 飞书开放平台创建了企业自建应用（或沙箱应用）

## 飞书开放平台配置（📱 部分手动）

1. [飞书开放平台](https://open.feishu.cn) → 创建企业自建应用
2. 开通「机器人」能力
3. 「权限管理」添加：
   - `im:message` — 获取消息
   - `im:message:send` — 发送消息
   - `im:message:read` — 读取消息（可选）
4. 「事件订阅」→ 选择「长连接」模式（WebSocket，免公网 IP）
5. 点击「创建版本」并**发布**（⚠️ 必须发布，否则不生效）
6. 从「凭证与基础信息」获取 **App ID** 和 **App Secret**

## Hermes 端配置

### 1. 写入凭证到 .env

```bash
cat >> ~/.hermes/.env << 'EOF'
FEISHU_APP_ID=cli_xxxxxxxxxxxx
FEISHU_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
```

### 2. 启动 Gateway

```bash
cd ~/.hermes && source .env
hermes gateway   # 前台运行，确认飞书连接后 Ctrl+C
```

### 3. 首次配对（首次使用必须）

Gateway 启动后，飞书里给机器人发一条消息。然后查 Gateway 日志获取配对码：

```bash
grep -i "pairing\|approve" ~/.hermes/logs/gateway.log | tail -5
```

或直接通过 CLI 列出待审批用户：

```bash
hermes pairing list
```

审批通过（替换 `PTB83LNF` 为实际码）：

```bash
hermes pairing approve feishu <PAIRING_CODE>
```

审批后用户即可正常对话，后续新消息无需再次审批。

**安全策略**：Hermes 默认陌生用户需配对审批。如需开放更多用户，在 `.env` 中配置：

```bash
FEISHU_ALLOW_ALL_USERS=true
FEISHU_DM_POLICY=open
```

## runit 后台保活

将 Hermes Gateway 加入 runit 管理，与 OpenClaw 的保活机制对齐：

```bash
export SVDIR=$PREFIX/var/service
SVC_DIR=$SVDIR/hermes-gateway
mkdir -p $SVC_DIR/log
ln -sf $PREFIX/share/termux-services/svlogger $SVC_DIR/log/run
mkdir -p $PREFIX/var/log/sv/hermes-gateway
```

**run 脚本** (`$SVC_DIR/run`)：

```sh
#!/data/data/com.termux/files/usr/bin/sh
exec 2>&1
export HOME=/data/data/com.termux/files/home
export HERMES_HOME=/data/data/com.termux/files/home/.hermes
cd $HERMES_HOME
. ./.env 2>/dev/null || true
exec /data/data/com.termux/files/home/.hermes/hermes-agent/venv/bin/hermes gateway
```

```bash
chmod +x $SVC_DIR/run
sv up hermes-gateway
sv status hermes-gateway  # → run
```

⚠️ 注意：必须用 `venv/bin/hermes gateway` 不能 `python -m hermes_cli`（hermes_cli 没有 `__main__.py`，坑 29）。

## Termux:Boot 自启

在 `~/.termux/boot/start.sh` 末尾追加（若已有 OpenClaw 的启动行，追加在之后）：

```bash
# Hermes Gateway
(cd $HOME/.hermes && source .env && $HOME/.hermes/hermes-agent/venv/bin/hermes gateway &)
```

## 验证

```bash
export SVDIR=$PREFIX/var/service
sv status hermes-gateway                            # run
grep -i "lark.*connect" $PREFIX/var/log/sv/hermes-gateway/current | tail -1  # connected to wss://msg-frontier.feishu.cn
```

飞书里给机器人发消息，有回复即闭环。

## 与 OpenClaw 飞书 bot 共存

两者互不冲突：

| | OpenClaw 飞书 | Hermes 飞书 |
|---|---|---|
| App ID | OpenClaw 注册的 | 单独新建的 |
| 协议 | WebSocket | WebSocket |
| 服务名 | `openclaw` | `hermes-gateway` |
| 运行时 | Node.js | Python |
| 端口 | 18789 (内部 gateway) | 无暴露端口 |

同一手机装两个飞书 bot，在飞书客户端里是两个不同的机器人联系人。
