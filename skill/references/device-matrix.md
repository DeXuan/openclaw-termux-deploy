# 机型适配矩阵与最佳实践

4 台真机完整验证（2026-07 实测，数据来自 getprop）。新设备接入时先跑：

```bash
ssh -p 8022 user@<IP> 'getprop ro.product.model; getprop ro.build.version.release; getprop ro.miui.ui.version.name'
```

按 Android 版本段对号入座，再查同代机型的专属注意项。

## 已验证机型

| 机型（实测型号） | 系统 | SoC / RAM | 角色 | 渠道 | 特记 |
|---|---|---|---|---|---|
| Redmi K60（23013RK75C） | Android 15 / HyperOS (V816) | 骁龙8+ Gen1 / 16GB | 主力机 | QQ bot | 全套 adb 加固必做 |
| Xiaomi MIX 2S | Android 10 / MIUI 12.5.1 | 骁龙845 / 6GB | 副机 | QQ bot | 免 phantom 加固 |
| Redmi Note 7 | Android 10 / MIUI 12.5.7 | 骁龙660 / 6GB | 全流程验证机 | 飞书 + QQ bot | gateway 冷启动 40-60s |
| Redmi Note 4X | Android 7.0 / MIUI 11 | 骁龙625 / 3GB | 边缘节点 | —（仅供应商） | 无 Tailscale |

⚠️ 型号考证以 `getprop ro.product.marketname` 为准（23013RK75C 是 K60 标准版，非 Pro）。

## 按 Android 版本选加固动作（决策树）

| Android 版本 | phantom process killer | 权限自动撤销 | Doze 白名单 | Tailscale App |
|---|---|---|---|---|
| 12+（K60/A15） | ⚠️ **必关**（adb） | ⚠️ **必禁** | 必做 | ✅ |
| 8–11（MIX 2S、Note 7/A10） | 无此机制，跳过 | A11+ 才有 | 必做 | ✅ |
| ≤7（Note 4X/A7） | 无 | 无 | 必做 | ❌ 装不上 |

- **Android 12+**：不关 phantom killer，Termux 子进程会被静默杀；全套命令见 [hardening.md](hardening.md)，HyperOS 还需 `device_config set_sync_disabled_for_tests persistent` 防云端回滚
- **Android 10–11**：天然免疫 phantom killer（A12 才引入）；A10 连权限自动撤销都没有——加固只剩 Doze 白名单一项
- **Android 7**：Termux 0.118 可跑、openclaw 正常编译；但 Tailscale 官方 App 不支持 → 放弃组网，走局域网固定 IP（路由器 MAC 绑定）+ SSH 管理

## 机型/系统专属注意项

### HyperOS（小米 Android 14+ 皮肤）
- APK 安装：termux-open 的 content:// 报"解析软件包错误"（坑 8）→ 复制到 `~/storage/downloads/` 用文件管理器**按路径**找到安装
- 关 phantom killer 后必须锁 `device_config`（persistent），否则设置会被云端同步回滚

### MIUI 12.5（Android 10 代机型）
- 普通「USB 调试」**没有 WRITE_SECURE_SETTINGS**（`settings put` 被拒）→ 改 settings 需另开「USB 调试（安全设置）」（要插 SIM + 登小米账号）；Doze 白名单（`dumpsys deviceidle whitelist`）和 appops 不受此限
- USB 调试开关会**静默弹回**（开启时确认弹窗被误点掉）→ SSH 里 `getprop sys.usb.config` 输出含 adb 才是真开了
- Termux 装 openssh 后 `sshd: no hostkeys available` → `ssh-keygen -A`

### 低端 SoC（骁龙 6xx 及以下）
- gateway 冷启动到 listening 要 **40–60 秒**（Note 7 骁龙660 实测）→ 验证门的 curl 多等一会，别急着判失败
- 3GB RAM 机型（Note 4X）只做供应商节点/轻量任务，别跑重 agent 工作流

## 多设备机队经验（2026-07-18 实战）

- **多 QQ bot 分诊**：每台设备挂独立 AppID（K60=102825839、MIX 2S=1903080675、Note 7=1905221791）。"QQ 无响应"**先分清用户发消息的是哪个 bot 的聊天窗口**——一台 401 离线时另一台日志完全正常，极易误判成"新部署的坏了"。对号方法：各机跑 `node -e "console.log(require(process.env.HOME+'/.openclaw/openclaw.json').channels.qqbot.appId)"`，再查对应设备日志
- **白名单联动**：同一家庭宽带下所有设备出口 IPv4 相同 → 宽带重拨/换网后**所有 QQ bot 的白名单要一起更新**；白名单加好后无需重启，插件每分钟自动重试，约 1 分钟自愈
- **OpenClawX App 协议不匹配**：gateway 日志每 0.4s 刷 `protocol mismatch client=OpenClawX Node ... min=3 max=3 expected=4`（ua=Dart，来源 127.0.0.1）= 本机装的 OpenClawX App 客户端太旧，升级到协议 v4 版或卸载该 App 即止（费电+刷爆日志，不影响渠道功能）
