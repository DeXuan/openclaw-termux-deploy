#!/data/data/com.termux/files/usr/bin/python3
"""飞书消息推送 — 全队统一模块
用法:
  echo "消息内容" | python3 ~/feishu_push.py              # stdin 管道
  python3 ~/feishu_push.py -m "消息内容"                   # 命令行参数
  python3 ~/feishu_push.py -t "标题" -m "消息内容"          # 带标题前缀
  python3 ~/feishu_push.py -t "⚠️ 告警" < /tmp/alert.txt   # stdin + 标题

凭证文件 ~/.fleet-dashboard.conf:
  FEISHU_APP_ID=cli_xxxxxxxxxxxx
  FEISHU_APP_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  FEISHU_RECEIVE_ID=ou_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
"""
import json, os, sys, urllib.request

CONF = os.path.expanduser("~/.fleet-dashboard.conf")
API_AUTH = "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal"
API_SEND = "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id"

def load_conf():
    """从 ~/.fleet-dashboard.conf 读取飞书凭证"""
    cfg = {}
    try:
        with open(CONF) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    k, v = line.split('=', 1)
                    cfg[k.strip()] = v.strip().strip('"').strip("'")
    except (FileNotFoundError, PermissionError):
        print(f"ERROR: {CONF} 不存在或无权限", file=sys.stderr)
        sys.exit(2)
    for key in ('FEISHU_APP_ID', 'FEISHU_APP_SECRET', 'FEISHU_RECEIVE_ID'):
        if key not in cfg:
            print(f"ERROR: {CONF} 缺少 {key}", file=sys.stderr)
            sys.exit(2)
    return cfg

def get_token(cfg):
    """获取 tenant_access_token"""
    body = json.dumps({
        "app_id": cfg['FEISHU_APP_ID'],
        "app_secret": cfg['FEISHU_APP_SECRET']
    }).encode()
    req = urllib.request.Request(API_AUTH, data=body,
        headers={"Content-Type": "application/json"})
    try:
        resp = json.loads(urllib.request.urlopen(req, timeout=10).read())
        token = resp.get("tenant_access_token", "")
        if not token:
            print(f"ERROR: 飞书 token 获取失败: {resp}", file=sys.stderr)
            sys.exit(3)
        return token
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as e:
        print(f"ERROR: 飞书 API 不可达: {e}", file=sys.stderr)
        sys.exit(3)

def send(token, receive_id, text):
    """发送 text 消息"""
    content = json.dumps({"text": text})
    body = json.dumps({
        "receive_id": receive_id,
        "msg_type": "text",
        "content": content
    }).encode()
    req = urllib.request.Request(API_SEND, data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        })
    try:
        resp = json.loads(urllib.request.urlopen(req, timeout=10).read())
        code = resp.get("code", -1)
        if code == 0:
            return True
        else:
            print(f"ERROR: 飞书发送失败 code={code}: {resp.get('msg','')}", file=sys.stderr)
            return False
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as e:
        print(f"ERROR: 飞书发送异常: {e}", file=sys.stderr)
        return False

def main():
    import argparse
    p = argparse.ArgumentParser(description="飞书消息推送")
    p.add_argument("-m", "--message", help="消息内容（不指定则读 stdin）")
    p.add_argument("-t", "--title", help="标题前缀（可选）")
    args = p.parse_args()

    # 消息来源：-m 参数 > stdin
    text = args.message
    if text is None:
        text = sys.stdin.read().strip()
    if not text:
        print("ERROR: 消息为空（-m 参数或 stdin 管道至少一个）", file=sys.stderr)
        sys.exit(1)

    if args.title:
        text = f"{args.title}\n{text}"

    cfg = load_conf()
    token = get_token(cfg)
    ok = send(token, cfg['FEISHU_RECEIVE_ID'], text)
    if ok:
        print("feishu_push: OK")
        sys.exit(0)
    else:
        sys.exit(4)

if __name__ == '__main__':
    main()
