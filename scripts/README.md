# 工具脚本

本目录收录部署中实际使用的脚本（均为线上生效版本的副本）。

| 文件 | 安装位置 | 作用 |
|------|---------|------|
| `../sshphone` | PC：`C:\Users\<user>\bin\sshphone`（Git Bash PATH 内） | 一键 SSH 到手机：优先 Tailscale 固定 IP `100.118.60.29`，不通回退"手机=PC默认网关"自动发现（热点拓扑） |
| `termux-boot_start-openclaw.sh` | 手机：`~/.termux/boot/start-openclaw.sh`（需 `chmod +x`，配合 Termux:Boot 应用） | 开机自启链：wake-lock → sshd → runit 服务群 |
| `runit-service_openclaw_run` | 手机：`$PREFIX/var/service/openclaw/run`（需 `chmod +x`，配合 termux-services） | openclaw gateway 的 runit 服务定义，进程被杀自动拉起。⚠️ 必须用 openclaw **绝对路径**（boot 环境 PATH 无 npm 全局目录，坑 10） |

安装方法与完整上下文见根目录 [README.md](../README.md)。

## 安装包备份

本次部署用到的安装包（APK/MSI，含 SHA256 校验）已备份在
[Releases v1.4](https://github.com/DeXuan/openclaw-termux-deploy/releases/tag/v1.4)：
Termux:Boot 0.8.1 (F-Droid 签名) / Tailscale Android 1.98.8 / Tailscale Windows 1.98.9。
