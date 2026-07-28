import json, os

MODELS = {
    "mode": "merge",
    "providers": {
        "alibaba-model-studio": {
            "apiKey": "sk-ws-H.EHIHDLI.FX9I.MEUCIArGuw3umiMnSo6rcrk4iCdUv6fxl6JNJXh1gRmZIV3LAiEA_mBdWXY-xpKXqE9aemlsHTgy8WriO5qedmKeFXwnDD4",
            "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
            "models": [
                {"id": "qwen-plus-2025-07-28", "name": "qwen-plus"},
                {"id": "deepseek-v3.2", "name": "deepseek-v3.2"},
                {"id": "glm-5", "name": "glm-5"},
                {"id": "qwen3-coder-plus", "name": "qwen3-coder"},
                {"id": "qwen3.7-max-2026-06-08", "name": "qwen3.7-max"},
                {"id": "kimi-k2.7-code", "name": "kimi-k2.7"},
                {"id": "deepseek-r1-distill-qwen-32b", "name": "deepseek-r1"},
            ]
        }
    }
}

cfg = os.path.join(os.environ["HOME"], ".openclaw", "openclaw.json")
with open(cfg) as f:
    c = json.load(f)
c["models"] = MODELS
with open(cfg, "w") as f:
    json.dump(c, f, indent=2)
print("models synced")
