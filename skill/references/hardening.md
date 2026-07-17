# adb 系统加固（手机作服务器必做）

前置：📱 手机开 USB 调试（设置 → 开发者选项 → USB 调试），USB 连 PC，授权弹窗选"始终允许"。
`adb devices` 显示 device 状态后执行。所有修改重启后依然有效。

## 只读体检（先诊断）

```bash
adb shell "settings get global low_power"                          # 应为 0（省电模式关）
adb shell "settings get global settings_enable_monitor_phantom_procs"  # false 为已加固
adb shell "device_config get activity_manager max_phantom_processes"
adb shell "am get-standby-bucket com.termux"                       # 5=EXEMPTED 最优
adb shell "cmd appops get com.termux RUN_ANY_IN_BACKGROUND"        # allow
adb shell "cmd app_hibernation get-state --global com.termux"      # false=未休眠
adb shell "cmd deviceidle whitelist" | grep -E "termux|tailscale"
```

## 加固命令（全套）

```bash
# 1. 关 phantom process killer（Android 12+ 限制 app 子进程 32 个，超限随机杀——服务器最大隐患）
adb shell "settings put global settings_enable_monitor_phantom_procs false"
adb shell "device_config set_sync_disabled_for_tests persistent"   # 锁定，防 Google 云配置改回
adb shell "device_config put activity_manager max_phantom_processes 2147483647"

# 2. Doze 省电白名单（com.termux 与 com.termux.boot 共享 UID，一个即覆盖两者）
adb shell "cmd deviceidle whitelist +com.termux"
adb shell "cmd deviceidle whitelist +com.tailscale.ipn"

# 3. 热点永不空闲自动关闭（PC 靠手机热点上网时必设）
adb shell "settings put global soft_ap_timeout_enabled 0"

# 4. 禁止"自动撤销未使用应用的权限"——Termux:Boot/Tailscale 装完不再打开，
#    数月后会被系统静默休眠+撤权限，自启链无声断裂且难排查
for p in com.termux com.termux.boot com.tailscale.ipn; do
  adb shell "cmd appops set $p AUTO_REVOKE_PERMISSIONS_IF_UNUSED ignore"
done
```

## 验证

```bash
adb shell "settings get global settings_enable_monitor_phantom_procs"   # → false
adb shell "device_config get activity_manager max_phantom_processes"    # → 2147483647
adb shell "device_config get_sync_disabled_for_tests"                   # → persistent
```

## 手机 UI 侧手动项（adb 做不了）

- 📱 电池策略：设置 → 应用 → Termux → 省电策略 → **无限制**
- 📱 电池保护：长期插电开充电上限 80%（小米：省电与电池 → 电池保护）
- 📱 WLAN 休眠保持连接：始终
