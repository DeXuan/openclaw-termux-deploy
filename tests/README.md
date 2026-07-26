# Tests

> 最小测试框架。本地运行: `cd tests && python3 -m pytest -v` 或 `python3 test_feishu_push.py`

## 运行

```bash
# 单元测试 (mock HTTP, 无需凭证)
python3 tests/test_feishu_push.py

# 或使用 pytest
python3 -m pytest tests/ -v
```

## 测试文件

| 文件 | 覆盖范围 | 类型 |
|------|---------|------|
| `test_feishu_push.py` | stdin/-m/-t 参数解析, token获取, 发送成功/失败, 配置文件缺失, 空消息 | 单元 (mock HTTP) |

## 待添加

- `test_phone_check_env.sh` — 模拟 getprop/free/df 输出验证体检流程
- `test_install_syntax.sh` — CI 中已覆盖 bash -n + ShellCheck, 无需重复
