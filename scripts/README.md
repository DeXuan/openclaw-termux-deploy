# Scripts 目录

> 按场景分类的脚本清单。部署新设备 → 运维监控 → 自愈 → 金融插件。

## 🚀 部署

| 脚本 | 运行位置 | 用途 |
|------|---------|------|
| `phone_install_openclaw.sh` | 手机 Termux（SSH 管道） | 安装 Node.js + OpenClaw + 编译依赖，含坑17/18合规预检 |
| `phone_setup_service.sh` | 手机 Termux（SSH 管道） | 配置 runit 保活 + Termux:Boot 开机自启 + 坑25 shebang 修复 |
| `phone_check_env.sh` | 手机 Termux（SSH 管道） | 一键体检：机型/Node/SQLite/OpenClaw/自启链/服务/渠道 |
| `uninstall.sh` | 手机 Termux（SSH 管道） | 6步卸载：停服务→清crontab→清脚本→清boot→npm卸载→配置（支持 --dry-run / --keep-config） |

```bash
# 典型部署流程
cat phone_install_openclaw.sh | ssh -p 8022 user@<IP> 'sh -'
cat phone_setup_service.sh  | ssh -p 8022 user@<IP> 'sh -'
cat phone_check_env.sh      | ssh -p 8022 user@<IP> 'sh -'
```

## 🩺 自愈系统

| 脚本 | 运行位置 | 监控目标 | 频率 |
|------|---------|---------|------|
| `k60-healthcheck.sh` | K60 | Note 7（Tailscale） | */5 |
| `note7-healthcheck.sh` | Note 7 | K60（Tailscale） | */5 |
| `mix2s-healthcheck.sh` | MIX 2S | K60（Tailscale） | */5 |
| `note4x-healthcheck.sh` | Note 4X | K60（LAN only） | */5 |
| `self-check.sh` | 每台设备 | 本机磁盘/内存/Swap | */10 |

部署方式（TUI 菜单 [6] 或手动）：
```bash
# 远程安装
cat k60-healthcheck.sh | ssh -p 8022 user@<IP> \
  'cat > ~/healthcheck.sh && chmod +x ~/healthcheck.sh'
# 添加 crontab
ssh user@<IP> '(crontab -l 2>/dev/null; echo "*/5 * * * * ~/healthcheck.sh") | crontab -'
```

## 📊 监控与告警

| 脚本 | 用途 | 频率 |
|------|------|------|
| `fleet-dashboard.sh` | 四设备状态汇总 → 飞书推送 | 每天 08:57 |
| `check-ip.sh` | IPv4 出口漂移检测 → 飞书告警 | */10 |
| `check-version.sh` | npm 扫描 OpenClaw 新版本 → 飞书告警 | 周一 10:37 |
| `backup-configs.sh` | 四设备配置拉取备份到 K60（tar.gz，30天保留） | 周日 02:00 |
| `channel-health.sh` | 渠道巡检：grep gateway 日志检测 QQ/飞书/微信连通性 + 1006/401 告警 | */15 |
| `channel-flow.sh` | 消息流监控：追踪收→处理→回复生命周期，未回复检测 + 响应延迟 + 模型错误 | */5 |
| `rolling-upgrade.sh` | 金丝雀升级：preflight→canary(Note7)→逐台升级→摘要（支持 --dry-run） | 手动 |
| `restore-configs.sh` | 配置还原：从备份目录恢复 openclaw.json/models.json/sqlite 到指定设备（还原前自动备份当前配置） | 手动 |
| `alert-dedup.sh` | 告警去重模块：同 key 30min 冷却防刷屏（被 channel-health/flow/self-check source） | 自动 |

## 🔧 基础设施

| 脚本 | 用途 |
|------|------|
| `feishu_push.py` | 飞书消息推送公共模块（stdin 管道或 `-m` 参数），其他脚本统一调用它 |
| `runit-service_openclaw_run` | runit run 脚本模板（手动参考，实际部署由 phone_setup_service.sh 生成） |
| `termux-boot_start-openclaw.sh` | Termux:Boot 启动脚本模板 |

## 💰 金融插件

> 已移至 [`../finance/`](../finance/) 目录。详见 [`finance/README.md`](../finance/README.md)。

| 脚本 | 用途 | 频率 |
|------|------|------|
| `fund-monitor.py` | 23 只基金净值日报（A股+QDII分区，涨跌信号+回本告警） | 交易日 15:30 |
| `fund-weekly.py` | 基金周报（5日涨跌+TOP3/BOTTOM3） | 周五 22:00 |
| `trade-signal-scanner.py` | A股自选池交易信号（涨跌停逼近/振幅/量能） | 交易时段 */10 |

## 🔗 相关目录

- `../lib/common.sh` — 设备配置 / SSH / UI 组件
- `../lib/menus.sh` — TUI 菜单实现
- `../skill/scripts/` — 技能引用副本（与 scripts/ 同步）
- `../bailian-quota-switcher/scripts/` — 百炼额度管理脚本
- `../finance/` — 金融分析脚本（基金日报/周报/交易信号）
