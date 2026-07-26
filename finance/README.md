# 金融工具集

> 独立于 OpenClaw 部署工具箱的金融分析脚本，可单独部署使用。

| 脚本 | 功能 | 建议 crontab |
|------|------|:--:|
| `fund-monitor.py` | 23只基金净值日报（A股+QDII，涨跌信号+回本告警） | 交易日 15:30 |
| `fund-weekly.py` | 基金周报（5日涨跌+TOP3/BOTTOM3） | 周五 22:00 |
| `trade-signal-scanner.py` | A股自选池交易信号（涨跌停逼近/振幅/量能） | 交易时段 */10 |

## 快速开始

```bash
# 部署到 Termux 手机
cat fund-monitor.py | ssh -p 8022 user@<IP> 'cat > ~/fund-monitor.py'
ssh -p 8022 user@<IP> 'python3 ~/fund-monitor.py'

# 配置 crontab 定时执行
(crontab -l 2>/dev/null; echo "30 15 * * 1-5 python3 ~/fund-monitor.py") | crontab -
```

## 依赖

- Python 3
- 飞书推送: 依赖 `feishu_push.py`（位于 `../scripts/feishu_push.py`）

## 数据源

东方财富基金 API（`api.fund.eastmoney.com`）
