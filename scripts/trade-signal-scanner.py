#!/data/data/com.termux/files/usr/bin/python3
"""交易信号扫描器 — K60 cron: */10 9-14 * * 1-5"""

import urllib.request, json, os, time, subprocess
from datetime import datetime

# ===== 自选池（可随时修改）=====
WATCHLIST = {
    'sh000001': '上证指数', 'sz399001': '深证成指', 'sz399006': '创业板指',
    'sh600519': '茅台', 'sz002594': '比亚迪', 'sh601318': '中国平安',
    'sh600036': '招商银行', 'sz000858': '五粮液', 'sh601012': '隆基绿能',
    'sz300750': '宁德时代', 'sh600900': '长江电力', 'sz000333': '美的集团',
}

CHG_ALERT  = 5.0    # 涨跌幅超过此值告警
LIMIT_PCT  = 9.0    # 逼近涨跌停告警
AMP_ALERT  = 5.0    # 日内振幅超过此值告警
COOLDOWN_S = 1800   # 同一信号30分钟内不重复报

FEISHU_CONF = os.path.expanduser("~/.fleet-dashboard.conf")
STATE_FILE  = os.path.expanduser("~/.trade-signal-state.json")

def fetch():
    codes = ','.join(WATCHLIST.keys())
    resp = urllib.request.urlopen(f'http://qt.gtimg.cn/q={codes}', timeout=10).read()
    try: text = resp.decode('gbk')
    except: text = resp.decode('utf-8', errors='replace')
    stocks = {}
    for line in text.strip().split(';'):
        if '=' not in line: continue
        code = line.split('=')[0].replace('v_','')
        data = line.split('"')[1] if '"' in line else ''
        if not data: continue
        f = data.split('~')
        if len(f) < 40: continue
        stocks[code] = {
            'name': f[1], 'price': float(f[3] or 0), 'prev_close': float(f[4] or 0),
            'chg_pct': float(f[32] or 0), 'high': float(f[33] or 0),
            'low': float(f[34] or 0), 'volume': float(f[6] or 0),
            'turnover': float(f[37] or 0), 'pe': float(f[45] or 0), 'time': f[30]
        }
    return stocks

def detect(stocks):
    signals = {}
    for code, s in stocks.items():
        alerts = []
        pct = s['chg_pct']
        if abs(pct) >= CHG_ALERT:
            alerts.append(('chg', f"{'大涨' if pct>0 else '大跌'} {pct:+.2f}%"))
        if pct >= LIMIT_PCT:   alerts.append(('limit_up', f"逼近涨停 {pct:+.2f}%"))
        if pct <= -LIMIT_PCT:  alerts.append(('limit_dn', f"逼近跌停 {pct:+.2f}%"))
        if s['high'] > 0 and s['low'] > 0:
            amp = (s['high'] - s['low']) / s['prev_close'] * 100
            if amp > AMP_ALERT:
                alerts.append(('amp', f"振幅 {amp:.1f}%"))
        if alerts: signals[code] = alerts
    return signals

def push(text):
    try:
        with open(FEISHU_CONF) as f:
            for line in f:
                line = line.strip()
                if line.startswith('FEISHU_') and '=' in line:
                    k, v = line.split('=', 1)
                    os.environ[k.strip()] = v.strip().strip('"')
    except: return
    r = subprocess.run(['python3', '-c', """
import json, urllib.request, os
token_resp = json.loads(urllib.request.urlopen(urllib.request.Request(
    "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal",
    data=json.dumps({"app_id": os.environ["FEISHU_APP_ID"], "app_secret": os.environ["FEISHU_APP_SECRET"]}).encode(),
    headers={"Content-Type": "application/json"})).read())
token = token_resp.get("tenant_access_token", "")
body = {"receive_id": os.environ["FEISHU_RECEIVE_ID"], "msg_type": "text", "content": json.dumps({"text": os.environ["MSG"]})}
resp = json.loads(urllib.request.urlopen(urllib.request.Request(
    "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id",
    data=json.dumps(body).encode(),
    headers={"Authorization": "Bearer "+token, "Content-Type": "application/json"})).read())
print("OK" if resp.get("code")==0 else f"FAIL:{resp.get('code')}")
"""], capture_output=True, text=True, timeout=15)
    print(f"Feishu: {r.stdout.strip()}")

def load_state():
    try:
        with open(STATE_FILE) as f: return json.load(f)
    except: return {}

def save_state(s):
    with open(STATE_FILE, 'w') as f: json.dump(s, f)

def should_alert(code, atype, state):
    key = f"{code}:{atype}"
    now = time.time()
    if key in state and now - state[key] < COOLDOWN_S:
        return False
    state[key] = now
    return True

if __name__ == '__main__':
    now = datetime.now()
    if now.weekday() >= 5: quit()
    hm = now.hour * 100 + now.minute
    if not (930 <= hm <= 1130 or 1300 <= hm <= 1500): quit()

    stocks = fetch()
    signals = detect(stocks)
    state = load_state()

    for code, alerts in signals.items():
        s = stocks[code]
        new = [a for t, a in alerts if should_alert(code, t, state)]
        if new:
            lines = [f"{s['name']}({code}) {s['price']:.2f} {s['chg_pct']:+.2f}%"]
            for a in new: lines.append(f"  {a}")
            lines.append(f"  vol:{s['volume']/10000:.0f}万 PE:{s['pe']:.0f}")
            push("TRADE SIGNAL\n" + '\n'.join(lines))
            print('\n'.join(lines))

    save_state(state)
