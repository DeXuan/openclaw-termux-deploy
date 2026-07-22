#!/data/data/com.termux/files/usr/bin/bash
# 百炼免费额度耗尽自动切换守护 v2
# 修复: 检测400/401/403 + crash-loop breaker自动清理 + 启动验证
# 部署: cat quota_watcher.sh | ssh user@<IP> 'cat > ~/quota_watcher.sh && chmod +x ~/quota_watcher.sh'
# 启动: nohup bash ~/quota_watcher.sh > ~/watcher.log 2>&1 &
# 前提: ~/bailian_key.txt 存放百炼 API Key

LOG_FILE="$PREFIX/var/log/sv/openclaw/current"
KEY_FILE="$HOME/bailian_key.txt"
STABILITY_DIR="$HOME/.openclaw/logs/stability"
LAST_SWITCH=0
COOLDOWN=30

echo "[watcher] $(date +%H:%M:%S) started, pid=$$"

# 启动自检：清理残留的 crash-loop breaker
if ls "$STABILITY_DIR"/*.json 2>/dev/null | grep -q crash_loop_breaker; then
  echo "[watcher] clearing stale crash-loop breaker files"
  rm -f "$STABILITY_DIR"/*.json
fi

# 确认 key 文件存在
if [ ! -f "$KEY_FILE" ]; then
  echo "[watcher] ERROR: $KEY_FILE not found! watcher cannot re-auth."
fi

# 确认 gateway 运行，否则等它起来
for i in $(seq 1 10); do
  if curl -4 -s --max-time 3 http://127.0.0.1:18789/ -o /dev/null; then
    echo "[watcher] gateway reachable"
    break
  fi
  sleep 3
done

tail -n 0 -F "$LOG_FILE" 2>/dev/null | while read -r line; do
  # 检测额度耗尽或账户异常
  TRIGGER=""
  if echo "$line" | grep -q "403.*Free quota exhausted"; then
    TRIGGER="quota"
  elif echo "$line" | grep -q "400.*Arrearage\|400.*overdue\|400.*good standing"; then
    TRIGGER="arrearage"
  elif echo "$line" | grep -q "401.*Incorrect API key"; then
    TRIGGER="bad_key"
  else
    continue
  fi

  MODEL=$(echo "$line" | grep -oP "model=\K[^\s,)]+" | head -1)
  NOW=$(date +%s)

  if [ $((NOW - LAST_SWITCH)) -lt $COOLDOWN ]; then
    echo "[watcher] $(date +%H:%M:%S) cooldown, skipping $MODEL ($TRIGGER)"
    continue
  fi

  echo "[watcher] $(date +%H:%M:%S) $TRIGGER on $MODEL"

  case "$TRIGGER" in
    quota)
      # 额度耗尽：re-auth + 切下一个模型
      if [ -f "$KEY_FILE" ]; then
        cat "$KEY_FILE" | openclaw models auth paste-api-key --provider alibaba-model-studio 2>&1 | tail -1
      fi

      node -e '
        var fs=require("fs"),home=process.env.HOME;
        var oc=JSON.parse(fs.readFileSync(home+"/.openclaw/openclaw.json","utf8"));
        var cur=oc.agents.defaults.model.primary.split("/").pop();
        // 标记耗尽
        var qp=home+"/.openclaw/free_quota.json";
        try{var q=JSON.parse(fs.readFileSync(qp,"utf8"));if(q.models&&q.models[cur]){q.models[cur].status="depleted";q.models[cur].remaining=0;q.models[cur].depleted_at=new Date().toISOString();fs.writeFileSync(qp,JSON.stringify(q,null,2))}}catch(e){}
        // 切到下一个
        var fb=oc.agents.defaults.model.fallbacks||[];
        var next=fb.length?fb[0]:"NONE";
        if(next!=="NONE"){
          oc.agents.defaults.model.primary=next;
          oc.agents.defaults.model.fallbacks=fb.slice(1);
          fs.writeFileSync(home+"/.openclaw/openclaw.json",JSON.stringify(oc,null,2));
          console.log("switched to "+next);
        }else{console.log("no fallback left")}
      ' 2>&1

      # 清理 breaker（多设备部署时常因配置变更触发）
      rm -f "$STABILITY_DIR"/*.json 2>/dev/null
      export SVDIR=$PREFIX/var/service
      sv restart openclaw 2>&1
      LAST_SWITCH=$(date +%s)
      echo "[watcher] $(date +%H:%M:%S) done"
      ;;

    arrearage|bad_key)
      # 账户/Key 问题：无法自动修，告警
      echo "[watcher] $(date +%H:%M:%S) CRITICAL: $TRIGGER - manual intervention needed"
      echo "[watcher] Key file: $KEY_FILE ($(wc -c < "$KEY_FILE") bytes)"
      ;;
  esac
done
