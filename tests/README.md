# Tests

> 测试套件：5 个文件，39+ 用例。本地: `bash tests/test_*.sh` 或 `python3 tests/test_feishu_push.py`

## 运行

```bash
# Shell 单元测试（全部）
bash tests/test_healthcheck.sh      # 自愈引擎 (8 用例)
bash tests/test_fleet_scan.sh       # 全队体检输出 (24 用例)
bash tests/test_deploy_config.sh    # 模型配置注入 (9 用例)

# Python 单元测试
python3 tests/test_feishu_push.py   # 飞书推送 (13 用例)

# 一键全跑
for t in tests/test_*.sh; do bash "$t" || exit 1; done
python3 tests/test_feishu_push.py -q
```

## 测试文件

| 文件 | 覆盖范围 | 用例数 | 类型 |
|------|---------|:--:|------|
| `test_feishu_push.py` | 参数解析、配置加载、stdin管道、大消息、特殊字符、多行 | 13 | 单元 (mock HTTP) |
| `test_healthcheck.sh` | 健康探活、503自愈恢复、SSH失败告警/静默、冷却期、重启失败 | 8 | 单元 (mock SSH) |
| `test_fleet_scan.sh` | 9维输出完整性、关键指标存在、退出码 | 24 | 集成 (mock环境) |
| `test_deploy_config.sh` | API Key缺失、设备验证、四设备注入、Key不泄露、后备变量 | 9 | 单元 (mock Python) |

## 框架

`test_runner.sh` — 轻量级 Shell 测试框架，提供 `test()` / `assert_contains()` / `assert_exit()` / `summary()` 四个断言函数，无外部依赖。

## CI 集成

CI 在每次 push/PR 时自动运行全部测试（`.github/workflows/smoke-test.yml`）。
