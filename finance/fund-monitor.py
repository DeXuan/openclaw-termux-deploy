#!/data/data/com.termux/files/usr/bin/python3
"""基金持仓监控 - K60 cron: 30 15 * * 1-5"""
import urllib.request, json, os, subprocess
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

PORTFOLIO = {
    # code: (name, amount, pnl_pct)
    '001323': ('东吴移动互联A',   2559, -12.5), '002910': ('易方达供给改革',   2497,  +2.5),
    '012635': ('国泰中证医疗C',    2775,  +8.7), '016664': ('天弘全球高端A',    1488, -15.3),
    '011609': ('易科创50联接C',    1389,  -7.4), '021528': ('财通成长优选C',    1233, -21.5),
    '021482': ('华夏红利低波A',    1171,  +4.1), '007896': ('易方达多资产FOF',  1010,  -7.3),
    '027299': ('富国电子信息A',     918,  -8.2), '000834': ('大成纳指100A',      755,  -3.3),
    '000411': ('景顺优质成长A',     668, -16.5), '022184': ('富国全球科技C',     637,  -5.6),
    '016452': ('南方纳指100A',      554,  -2.8), '007721': ('天弘标普500A',      396,  -1.1),
    '040046': ('华安纳指100A',      392,  -2.2), '019875': ('广发稀有金属C',     389, -19.2),
    '018043': ('天弘纳指100A',      386,  -3.6), '012920': ('易全球成长A',       353, -11.8),
    '017641': ('摩根标普500A',      340,  +0.1), '018230': ('易全球优质C',       318, -10.2),
    '019442': ('万家纳指100C',      283,  -1.7), '019172': ('摩根纳指100A',      185,  -2.4),
    '014915': ('财通匠心优选A',      70, -30.1),
}

STATE_FILE = os.path.expanduser("~/.fund-monitor-state.json")

def fetch_one(code):
    url = f"https://api.fund.eastmoney.com/f10/lsjz?fundCode={code}&pageIndex=1&pageSize=5"
    req = urllib.request.Request(url, headers={"Referer": "https://fund.eastmoney.com"})
    try:
        d = json.loads(urllib.request.urlopen(req, timeout=10).read().decode("utf-8"))
        return [(i["FSRQ"], float(i["DWJZ"]), float(i.get("JZZZL",0) or 0)) for i in d["Data"]["LSJZList"]]
    except (urllib.error.URLError, json.JSONDecodeError, KeyError, OSError):
        return []

def fetch_all():
    funds = {}
    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = {c: ex.submit(fetch_one, c) for c in PORTFOLIO}
        for code, fut in futures.items():
            navs = fut.result()
            if navs:
                name, amount, pnl = PORTFOLIO[code]
                funds[code] = {'name':name,'amount':amount,'pnl':pnl,'nav_today':navs[0],'navs':[n[1] for n in navs]}
    return funds

def push(text):
    subprocess.run(["python3", os.path.expanduser("~/feishu_push.py")],
                   input=text, capture_output=True, text=True, timeout=15)

def analyze(funds, prev):
    alerts, rows = [], []
    total_val = 0
    today_str = datetime.now().strftime('%Y-%m-%d')
    up_count = down_count = 0

    # 分成两组: A股当日 / QDII延迟
    a_share = []
    qdii = []

    for code, f in funds.items():
        name = f['name']; amt = f['amount']; pnl = f['pnl']
        d, nav, chg = f['nav_today']; navs = f['navs']
        total_val += amt
        if chg > 0: up_count += 1
        elif chg < 0: down_count += 1

        # 标记
        arrow = '↑' if chg > 0 else ('↓' if chg < 0 else '→')
        star = ' ●' if abs(chg) >= 3 else ''
        if pnl > 0: face = '🟢'
        elif pnl > -10: face = '🟡'
        else: face = '🔴'

        # 紧凑行: ↑东吴移动互联 6.8239 -1.7% -12%😞 ●
        short_name = name[:7]
        row = f"{arrow}{star} {short_name:<7s} {nav:>7.4f} {chg:>+5.1f}% {pnl:>+4.0f}%{face}"

        is_qdii = d != today_str
        if is_qdii: row += f" [{d[5:]}]"
        (qdii if is_qdii else a_share).append((chg, row))

        # 信号检测 (与之前相同)
        if abs(chg) >= 3:
            alerts.append(f"{'🔻' if chg<0 else '🔺'} {name}({code}) {chg:+.2f}% NAV:{nav:.4f}")
        if len(navs) >= 4:
            if navs[0] < navs[1] < navs[2]:
                cum = round((navs[0]/navs[2]-1)*100, 1)
                if cum < -3:
                    alerts.append(f"📉 连跌3日 {name}({code}) 累计{cum:+.1f}%")
            elif navs[0] > navs[1] > navs[2]:
                cum = round((navs[0]/navs[2]-1)*100, 1)
                if cum > 3:
                    alerts.append(f"📈 连涨3日 {name}({code}) 累计{cum:+.1f}%")
        k = f"{code}:pnl"
        if k in prev and prev[k] < -5 and pnl >= -5:
            alerts.append(f"🎯 回本在即 {name}({code}) 浮亏仅{pnl:+.1f}%")

    # 按涨幅降序排列
    a_share.sort(key=lambda x: -x[0])
    qdii.sort(key=lambda x: -x[0])

    # 构建消息
    header = f"📊 基金日报 {today_str[5:]}\n"
    header += f"总值{total_val:,} | 涨{up_count}跌{down_count}"
    if qdii: header += f" | QDII延迟{len(qdii)}只"
    header += "\n"

    # A股部分
    if a_share:
        header += "\n—— 当日净值 ——\n"
        header += '\n'.join(r for _, r in a_share)

    # QDII部分
    if qdii:
        header += "\n\n—— QDII延迟净值 ——\n"
        header += '\n'.join(r for _, r in qdii)

    # 信号
    if alerts:
        header += '\n\n' + '\n'.join(f"  {a}" for a in alerts[:6])

    return alerts, header

def load_state():
    try:
        with open(STATE_FILE) as f: return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, PermissionError):
        return {}

def save_state(funds, state):
    for code, f in funds.items():
        state[f"{code}:pnl"] = f['pnl']
    with open(STATE_FILE,'w') as f: json.dump(state, f)

if __name__ == '__main__':
    now = datetime.now()
    if now.weekday() >= 5: quit()
    funds = fetch_all()
    prev = load_state()
    alerts, summary = analyze(funds, prev)
    print(summary)
    push(summary)
    save_state(funds, prev)
    print(f"Done: {len(funds)} funds, {len(alerts)} alerts")
