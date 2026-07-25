#!/data/data/com.termux/files/usr/bin/python3
"""基金周报 — 每周五22:00推送  cron: 0 22 * * 5"""
import urllib.request, json, os, subprocess
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

PORTFOLIO = {
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

def fetch_one(code):
    url = f"http://api.fund.eastmoney.com/f10/lsjz?fundCode={code}&pageIndex=1&pageSize=10"
    req = urllib.request.Request(url, headers={"Referer": "https://fund.eastmoney.com"})
    try:
        d = json.loads(urllib.request.urlopen(req, timeout=10).read().decode("utf-8"))
        return [(i["FSRQ"], float(i["DWJZ"]), float(i.get("JZZZL",0) or 0)) for i in d["Data"]["LSJZList"]]
    except: return []

def push(text):
    subprocess.run(["python3", os.path.expanduser("~/feishu_push.py")],
                   input=text, capture_output=True, text=True, timeout=15)

if __name__ == '__main__':
    now = datetime.now()
    if now.weekday() != 4: quit()  # 仅周五

    print(f"[{now:%H:%M}] fetching weekly data...")
    funds = {}
    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = {c: ex.submit(fetch_one, c) for c in PORTFOLIO}
        for code, fut in futures.items():
            navs = fut.result()
            if navs:
                name, amount, pnl = PORTFOLIO[code]
                funds[code] = {'name': name, 'amount': amount, 'pnl': pnl, 'navs': navs}

    # 计算周涨跌: 最新净值 vs 约5个交易日前(取第5个nav,跳过周末)
    rows = []
    total_val = 0
    up = down = 0
    for code, f in funds.items():
        name = f['name']; amt = f['amount']; pnl = f['pnl']
        navs = f['navs']
        today_nav = navs[0][1]
        total_val += amt

        # 找约一周前的净值(第5个或最后一个)
        week_idx = min(len(navs)-1, 4)
        week_nav = navs[week_idx][1]
        week_chg = (today_nav / week_nav - 1) * 100 if week_nav > 0 else 0
        week_dates = f"{navs[week_idx][0][5:]}→{navs[0][0][5:]}"

        if week_chg > 0: up += 1
        elif week_chg < 0: down += 1

        arrow = '↑' if week_chg > 0 else ('↓' if week_chg < 0 else '→')
        star = ' ★' if abs(week_chg) >= 5 else ''
        if pnl > 0: dot = '🟢'
        elif pnl > -10: dot = '🟡'
        else: dot = '🔴'

        short = name[:7]
        rows.append((week_chg, f"{arrow}{star} {short:<7s} {today_nav:>7.4f} {week_chg:>+5.1f}% {pnl:>+4.0f}%{dot}"))

    rows.sort(key=lambda x: -x[0])  # 按周涨幅降序

    # 构建消息
    today_str = now.strftime('%m/%d')
    msg = f"📊 基金周报 {today_str}\n"
    msg += f"总值{total_val:,} | 周涨{up}跌{down}\n"
    msg += '\n'.join(r for _, r in rows)

    # Top3/Bottom3
    top3 = [r for _, r in rows[:3]]
    bot3 = [r for _, r in rows[-3:]]
    msg += f"\n\n🏆 周涨幅TOP3"
    msg += '\n' + '\n'.join(f"  {r}" for r in top3)
    msg += f"\n💔 周跌幅TOP3"
    msg += '\n' + '\n'.join(f"  {r}" for r in bot3)

    print(msg)
    push(msg)
    print("Done")
