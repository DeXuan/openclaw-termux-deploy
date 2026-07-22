#!/data/data/com.termux/files/usr/bin/bash
# 百炼免费模型额度管理器
# 用法: bash ~/quota_manager.sh [status|switch|deplete <model>|update <model> <tokens>]

QUOTA_FILE="$HOME/.openclaw/free_quota.json"
CONFIG_FILE="$HOME/.openclaw/openclaw.json"

status() {
  echo "====== 免费模型额度面板 ======"
  echo "时间: $(date '+%Y-%m-%d %H:%M')"

  CURRENT=$(node -e "var c=require('$CONFIG_FILE');console.log(c.agents?.defaults?.model?.primary||'N/A')" 2>/dev/null)
  echo "主模型: $CURRENT"
  echo ""

  printf "%-42s %8s %10s %-12s %s\n" "模型" "总额度" "剩余" "过期" "状态"
  printf "%s\n" "-------------------------------------------------------------------------------"

  node -e "
    var q=require('$QUOTA_FILE'),now=new Date();
    Object.keys(q.models).forEach(function(id){
      var m=q.models[id],r=m.remaining||0,t=m.total||0,p=Math.round(r/t*100);
      var expired=new Date(m.expiry)<now;
      var s=m.status;
      if(expired&&s==='active')s='expired';
      var i=s==='active'?'O':s==='depleted'?'X':'E';
      var l=i+' '+id;while(l.length<42)l+=' ';
      l+=' '+(t/10000).toFixed(0)+'w    '+(r/10000).toFixed(0)+'w('+p+'%)';
      while(l.length<62)l+=' ';l+=m.expiry+' '+s;
      console.log(l);
    });
  "
  echo ""

  echo "Fallback:"
  node -e "var c=require('$CONFIG_FILE');(c.agents?.defaults?.model?.fallbacks||[]).forEach(function(f,i){console.log('  '+(i+1)+'. '+f)})" 2>/dev/null

  echo ""
  node -e "
    var q=require('$QUOTA_FILE'),now=new Date();
    var tr=0,tc=0,a=0,d=0,e=0;
    Object.keys(q.models).forEach(function(id){
      var m=q.models[id];
      if(new Date(m.expiry)<now){e++;return;}
      tc+=m.total;tr+=m.remaining;
      if(m.status==='active')a++;if(m.status==='depleted')d++;
    });
    console.log('总计: '+a+'活跃 + '+d+'耗尽 + '+e+'过期');
    console.log('剩余: '+(tr/10000).toFixed(0)+'万 / '+ (tc/10000).toFixed(0)+'万 token');
  "
}

switch_next() {
  NEXT=$(node -e "
    var fs=require('fs'),home=process.env.HOME;
    var q=require('$QUOTA_FILE'),now=new Date();
    var oc=JSON.parse(fs.readFileSync(home+'/.openclaw/openclaw.json','utf8'));
    var cur=(oc.agents.defaults.model.primary||'').split('/').pop();
    var next=null,found=false;
    Object.keys(q.models).forEach(function(id){
      var m=q.models[id];
      if(new Date(m.expiry)<now||m.status!=='active')return;
      if(!found&&cur===id){found=true;return;}
      if(found&&!next)next=id;
    });
    if(!next)Object.keys(q.models).forEach(function(id){
      var m=q.models[id];
      if(new Date(m.expiry)>=now&&m.status==='active'&&!next)next=id;
    });
    if(!next){console.log('NONE');process.exit(0);}
    oc.agents.defaults.model.primary='alibaba-model-studio/'+next;
    oc.agents.defaults.model.fallbacks=Object.keys(q.models)
      .filter(function(id){return id!==next&&q.models[id].status==='active'&&new Date(q.models[id].expiry)>=now;})
      .map(function(id){return 'alibaba-model-studio/'+id;});
    fs.writeFileSync(home+'/.openclaw/openclaw.json',JSON.stringify(oc,null,2));
    console.log(next);
  ")

  if [ "$NEXT" = "NONE" ]; then
    echo "ERROR: 所有免费模型已耗尽！"
    return 1
  fi
  echo "Switched: alibaba-model-studio/$NEXT"
  export SVDIR=$PREFIX/var/service && sv restart openclaw 2>/dev/null
  sleep 5
  status
}

deplete() {
  MODEL=$1
  [ -z "$MODEL" ] && { echo "Usage: bash ~/quota_manager.sh deplete <model_id>"; return 1; }

  node -e "
    var q=require('$QUOTA_FILE');
    if(!q.models['$MODEL']){console.log('ERROR: $MODEL not found');process.exit(1);}
    q.models['$MODEL'].status='depleted';q.models['$MODEL'].remaining=0;
    q.models['$MODEL'].depleted_at=new Date().toISOString();
    q.updated_at=new Date().toISOString();
    require('fs').writeFileSync('$QUOTA_FILE',JSON.stringify(q,null,2));
    console.log('Depleted: $MODEL');
  " || return 1
  switch_next
}

update_usage() {
  MODEL=$1; USED=$2
  [ -z "$MODEL" ] || [ -z "$USED" ] && { echo "Usage: bash ~/quota_manager.sh update <model> <tokens>"; return 1; }

  node -e "
    var q=require('$QUOTA_FILE');
    if(!q.models['$MODEL']){console.log('ERROR: $MODEL not found');process.exit(1);}
    q.models['$MODEL'].remaining=Math.max(0,q.models['$MODEL'].remaining-$USED);
    if(q.models['$MODEL'].remaining<=0){
      q.models['$MODEL'].status='depleted';q.models['$MODEL'].depleted_at=new Date().toISOString();
      console.log('Quota exhausted! Run: bash ~/quota_manager.sh deplete $MODEL');
    }
    q.updated_at=new Date().toISOString();
    require('fs').writeFileSync('$QUOTA_FILE',JSON.stringify(q,null,2));
    console.log('$MODEL: -$USED, remaining='+q.models['$MODEL'].remaining);
  "
}

case "${1:-status}" in
  status)   status ;;
  switch)   switch_next ;;
  deplete)  deplete "$2" ;;
  update)   update_usage "$2" "$3" ;;
  *)        echo "Usage: bash ~/quota_manager.sh [status|switch|deplete <model>|update <model> <tokens>]" ;;
esac
