# 本地模型接入配置

> 让 huashu-data-pro 能在**完全离线**状态下跑通多专家分析——这是 AMD 视频第四段的关键承诺：
> 「数据一个字节都没离开这台机器」。

## 两种后端都支持

| 后端 | 协议 | 默认端口 | 何时选 |
|------|------|---------|--------|
| **LM Studio** | OpenAI 兼容（`/v1/chat/completions`）| 1234 | 花叔主力方案，GUI 加载 70B/120B 模型方便 |
| **Ollama** | 原生 `/api/chat` | 11434 | 命令行派、喜欢 `ollama pull` 的用户 |

skill 同时支持，靠 `LOCAL_LLM_BASE_URL` 的路径自动识别。

## 环境变量契约

```bash
# 通用
export LOCAL_LLM_BASE_URL="http://127.0.0.1:1234/v1"   # LM Studio
# 或
export LOCAL_LLM_BASE_URL="http://127.0.0.1:11434"     # Ollama

export LOCAL_LLM_MODEL="qwen2.5-72b-instruct"          # 模型标识符
export LOCAL_LLM_API_KEY="lm-studio"                   # 可选，LM Studio 默认任意值；Ollama 忽略
export LOCAL_LLM_TIMEOUT="600"                         # 秒，默认 600；120B 模型首 token 慢，放宽
```

**不写 `LOCAL_LLM_BASE_URL` → skill 默认走会话当前模型**（云端），向下兼容。

## 命令行开关

```bash
huashu-data-pro analyze data.xlsx --local             # 启用本地
huashu-data-pro analyze data.xlsx                     # 默认云端（向下兼容）
huashu-data-pro analyze data.xlsx --local --model qwen2.5-120b   # 覆盖环境变量
```

`--local` 触发后：
1. 读 `LOCAL_LLM_BASE_URL`，没有就报错退出，**不要静默降级到云端**（演示要的就是本地）
2. 启动前 ping 一次 base_url，ping 不通立刻报错，不要等三个 subagent 都 timeout
3. 终端打出 `[local] backend=lmstudio model=qwen2.5-72b-instruct @ 127.0.0.1:1234`

## 最小调用片段（Python，给 subagent 里调用模型用）

```python
import os
import requests

BASE = os.getenv("LOCAL_LLM_BASE_URL", "").rstrip("/")
MODEL = os.getenv("LOCAL_LLM_MODEL", "qwen2.5-72b-instruct")
TIMEOUT = int(os.getenv("LOCAL_LLM_TIMEOUT", "600"))
KEY = os.getenv("LOCAL_LLM_API_KEY", "lm-studio")

def is_ollama() -> bool:
    # Ollama 的 base_url 不带 /v1
    return "/v1" not in BASE

def chat(messages: list[dict]) -> str:
    if is_ollama():
        r = requests.post(f"{BASE}/api/chat", timeout=TIMEOUT, json={
            "model": MODEL,
            "messages": messages,
            "stream": False,
        })
        r.raise_for_status()
        return r.json()["message"]["content"]
    # OpenAI 兼容（LM Studio）
    r = requests.post(f"{BASE}/chat/completions", timeout=TIMEOUT,
                      headers={"Authorization": f"Bearer {KEY}"},
                      json={
                          "model": MODEL,
                          "messages": messages,
                          "stream": False,
                      })
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"]
```

## 启动前自检脚本（3 秒搞定）

```bash
# 检查 LM Studio
curl -s http://127.0.0.1:1234/v1/models | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok:', [m['id'] for m in d['data']])"

# 检查 Ollama
curl -s http://127.0.0.1:11434/api/tags | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok:', [m['name'] for m in d['models']])"
```

三个 subagent 并行启动前，主进程**必做**这个自检，避免录制时静默卡住。

## 模型选型建议（视频演示场景）

| 模型 | 推理速度（AMD 锐龙 AI MAX+ 395 实测）| 适用 | 备注 |
|------|---------------------------|------|------|
| Qwen 2.5 72B Instruct | 可接受，每 token 约 30–60ms | **推荐主力**，速度+质量平衡 | 70B 是舒适区 |
| Qwen 2.5 120B | 较慢，首 token 5-10s | 高精度场景 | 视频里提到的 120B demo 用这档 |
| Llama 3.3 70B | 类似 72B | 英文场景更好 | 中文数据分析场景让位给 Qwen |

花叔视频脚本里的「120B 本地跑起来的样子」对应这里的 Qwen 2.5 120B。

## 离线稳定性清单（录制前夜必过）

- [ ] `unset ALL_PROXY HTTP_PROXY HTTPS_PROXY`（本地调用别被代理拦截）
- [ ] LM Studio GUI 确认模型已加载、"Server" tab 是 Start 状态
- [ ] WIFI 关掉，再跑一次 `huashu-data-pro analyze examples/sample_finance.xlsx --formats all --local --experts all`
- [ ] 三种格式产出都打开检查：HTML、xlsx、pptx
- [ ] 时钟记录端到端耗时，对齐视频脚本里的「8 分钟」承诺

## 踩坑记录（按需补充）

- **LM Studio 的 context 默认只有 4096**。数据稍大就截断。GUI 里手动调到 16k 或 32k，根据模型上限。
- **Ollama 的 keep-alive 默认 5 分钟**。演示前确认模型已热载，避免第一个 subagent 耗 30 秒加载。
- **PingFang SC 字体在 Linux 跑的 Ollama 容器里没有**。Excel 报告用了 PingFang SC，纯 Mac 环境下才显示正确。
- **macOS 系统代理别勾 127.0.0.1 也走代理**，否则本地调用直接超时。
