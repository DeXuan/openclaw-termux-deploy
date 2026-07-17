# QQ 机器人渠道接入

官方插件，走 QQ 官方 WebSocket 网关，无需公网 IP（NAT 后可用）。

## 流程

```bash
# 1. 装插件（手机上执行）
openclaw plugins install @openclaw/qqbot
```

2. 📱 指导用户：https://q.qq.com/ 手机 QQ 扫码注册（个人主体）→ 创建机器人 →
   - 「开发设置」拿 **AppID** 和 **AppSecret**
     ⚠️ 坑 13：页面显示的可能是掩码值——让用户点「重新生成」后**立即完整复制**
   - 「沙箱配置」把用户自己的 QQ 号加入**测试用户**（个人机器人默认沙箱，仅测试用户可聊）
   - 「开发设置」的 **IP 白名单**：加入手机当前 IPv4 出口（`curl -4 -s https://api.ip.sb/ip`）
     ⚠️ 白名单只支持 IPv4、平台强制启用不可关闭（坑 14，详见 pitfalls.md）

```bash
# 3. 添加渠道 + 重启
openclaw channels add --channel qqbot --token "AppID:AppSecret"
export SVDIR=$PREFIX/var/service && sv down openclaw && sv up openclaw

# 4. 验证
sleep 30 && grep -i qqbot $PREFIX/var/log/sv/openclaw/current | tail -5
# 期望: "Access token obtained successfully" + "WebSocket connected"
openclaw channels status --probe        # → QQ Bot default: ... connected
```

5. 📱 用户手机 QQ 扫「沙箱配置」页机器人二维码添加 → 私聊测试，收到 AI 回复即闭环。

## 报错分流

| 日志报错 | 处理 |
|---|---|
| `invalid appid or secret`（100016） | Secret 错了 → 重新生成完整复制（坑 13） |
| `接口访问源IP不在白名单`（401） | ① 白名单加当前 IPv4；② 确认 run 脚本有 `NODE_OPTIONS="--dns-result-order=ipv4first"`（防 Node 走 IPv6 出口）——phone_setup_service.sh 已内置 |
| 突然掉线（曾经正常） | 九成是蜂窝 IPv4 漂移 → 查新 IP 更新白名单；长期方案见 pitfalls.md 坑 14 |

## 运维提示

告知用户：蜂窝网络 IP 会漂移，白名单会反复失效。想省心建议换飞书渠道
（`@openclaw/feishu`，WebSocket 长连接，无 IP 白名单限制）。
