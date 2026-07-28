"""生成四设备 OC + Hermes 配置到各自目录"""
import json, os

KEY = "sk-ws-H.EHIHDLI.FX9I.MEUCIArGuw3umiMnSo6rcrk4iCdUv6fxl6JNJXh1gRmZIV3LAiEA_mBdWXY-xpKXqE9aemlsHTgy8WriO5qedmKeFXwnDD4"
BASE = "https://dashscope.aliyuncs.com/compatible-mode/v1"

ALL = "qwen3-max,qwen3-max-2026-01-23,qwen3-max-2025-09-23,qwen3-max-preview,qwen3.7-max-2026-05-20,qwen3.7-max-2026-05-17,qwen3.7-flash-2026-07-15,qwen3.7-flash,qwen3.6-plus-2026-04-02,qwen3.6-max-preview,qwen3.6-flash-2026-04-16,qwen3.6-flash,qwen3.6-35b-a3b,qwen3.6-27b,qwen3.5-plus-2026-04-20,qwen3.5-plus-2026-02-15,qwen3.5-plus,qwen3.5-flash-2026-02-23,qwen3.5-flash,qwen3.5-397b-a17b,qwen3.5-122b-a10b,qwen3.5-35b-a3b,qwen3.5-27b,qwen3-32b,qwen3-30b-a3b,qwen3-14b,qwen3-8b,qwen3-235b-a22b,qwen3-30b-a3b-instruct-2507,qwen3-30b-a3b-thinking-2507,qwen3-235b-a22b-instruct-2507,qwen3-235b-a22b-thinking-2507,qwen-plus-latest,qwen-plus-2025-12-01,qwen-plus-2025-09-11,qwen-plus-2025-07-14,qwen-plus-2025-04-28,qwen-plus-2025-01-25,qwen-plus-1220,qwen-plus-0112,qwen-plus-character,qwen-plus,qwen-turbo,qwen-flash,qwen-flash-2025-07-28,qwen-flash-character,qwen-flash-character-2026-02-26,qwen-math-turbo,qwen-math-plus-latest,qwen-math-plus-0919,qwen-math-plus-0816,qwen-math-plus,qwen-long-latest,qwen-long-2025-01-25,qwen-long,qwen-coder-turbo,qwen-coder-plus,qwen-mt-turbo,qwen-mt-plus,qwen-mt-lite,qwen-mt-flash,deepseek-v3.2-exp,deepseek-v3.2,deepseek-v3.1,deepseek-v3,deepseek-r1-0528,deepseek-r1,deepseek-r1-distill-qwen-32b,deepseek-r1-distill-qwen-14b,deepseek-r1-distill-qwen-7b,glm-5.1,glm-5,glm-4.7,glm-4.6,glm-4.5-air,glm-4.5,glm-5.2,kimi-k2.7-code,kimi-k2.6,kimi-k2.5,kimi-k2-thinking,Moonshot-Kimi-K2-Instruct,MiniMax-M2.5,MiniMax-M2.1,qwq-plus,qvq-plus,qvq-max,gui-plus-2026-02-26,gui-plus,qwen3-coder-plus-2025-09-23,qwen3-coder-plus-2025-07-22,qwen3-coder-plus,qwen3-coder-next,qwen3-coder-flash-2025-07-28,qwen3-coder-flash,qwen3-coder-480b-a35b-instruct,qwen3-coder-30b-a3b-instruct,qwen3-next-80b-a3b-instruct,qwen3-next-80b-a3b-thinking".split(",")

OUT = os.path.expanduser("~/pool_configs")
os.makedirs(OUT, exist_ok=True)

POOLS = {
    "K60":    (ALL[0:20],   ALL[80:84]),
    "Note7":  (ALL[20:40],  ALL[84:88]),
    "MIX2S":  (ALL[40:60],  ALL[88:92]),
    "Note4X": (ALL[60:80],  ALL[92:96]),
}

for dev, (oc, h) in POOLS.items():
    # OC JSON
    oc_cfg = {"mode":"merge","providers":{"alibaba-model-studio":{"apiKey":KEY,"baseUrl":BASE,"models":[{"id":m,"name":m} for m in oc]}}}
    with open(f"{OUT}/{dev}-oc.json","w") as f: json.dump(oc_cfg,f)
    # H YAML
    lines = [f"model:\n  name: {h[0]}\n  provider: openai-api\n","fallback_model:"]
    for m in h[1:]: lines.append(f"  - model: {m}\n    provider: openai-api")
    with open(f"{OUT}/{dev}-h.yaml","w") as f: f.writelines(lines)
    print(f"{dev}: {len(oc)} OC + {len(h)} H")

# Verify
all_m = []
for dev, (oc, h) in POOLS.items(): all_m += oc + h
assert len(all_m) == len(set(all_m)), f"OVERLAP! {len(all_m)} vs {len(set(all_m))}"
print("Zero overlap verified")
print(f"Files in {OUT}")
