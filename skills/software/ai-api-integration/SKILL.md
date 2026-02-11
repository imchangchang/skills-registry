---
name: ai-api-integration
version: "1.1.0"
description: AI API 集成开发最佳实践（OpenAI/Kimi），包含对话、视觉理解、流式处理和 Prompt 工程方法论
tags: ["ai", "api", "openai", "kimi", "llm", "vision", "prompt-engineering"]
---

# AI API 集成最佳实践

## 概述

OpenAI 兼容 API（如 Kimi、GPT-4o）的集成开发最佳实践，涵盖对话、视觉理解、流式处理，以及**Prompt 工程的项目化管理方法论**。

> **重要原则**：本 Skill 提供工具和方法论，具体的 Prompt 内容属于项目业务逻辑，应在项目中维护。

## 适用场景

- LLM 对话集成
- 视觉理解 (Vision)
- 流式响应处理
- 多轮对话管理
- Function Calling (工具调用)
- **Prompt 的版本化、可复现管理**

## 核心技术栈

- **openai**: OpenAI 官方客户端
- **pydantic**: 响应模型验证
- **tenacity**: 重试机制
- **pyyaml**: Prompt 元数据解析

---

## 基础用法

### 客户端初始化

```python
from openai import OpenAI

client = OpenAI(
    api_key="your-api-key",
    base_url="https://api.moonshot.cn/v1"  # Kimi
)
```

### 简单对话

```python
response = client.chat.completions.create(
    model="kimi-k2.5",
    messages=[
        {"role": "system", "content": "你是助手"},
        {"role": "user", "content": "你好"}
    ]
)
print(response.choices[0].message.content)
```

### 流式响应

```python
stream = client.chat.completions.create(
    model="kimi-k2.5",
    messages=messages,
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### 视觉理解

```python
import base64

with open("image.png", "rb") as f:
    image_base64 = base64.b64encode(f.read()).decode()

response = client.chat.completions.create(
    model="kimi-k2.5",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "描述这张图片"},
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/png;base64,{image_base64}"
                    }
                }
            ]
        }
    ]
)
```

---

## Prompt 工程方法论

### 为什么需要项目化管理 Prompt？

Prompt 是 AI 应用的核心业务逻辑，但硬编码在代码中会导致：

| 问题 | 影响 |
|------|------|
| 无法热更新 | 修改 Prompt 需重新部署 |
| 变更不可追溯 | 无法对比不同版本效果 |
| 难以协作 | 非技术人员无法参与优化 |
| 模型适配困难 | 不同模型的最优 Prompt 不同 |

### 推荐方案：文件化 + 版本化

**核心思想**：将 Prompt 从代码中提取为独立文件，纳入版本控制。

```
项目结构
├── prompts/                  # Prompt 文件库（业务资产）
│   ├── chat/
│   │   └── system-assistant.md
│   ├── code-review/
│   │   ├── reviewer.kimi-k2.5.md
│   │   └── reviewer.gpt-4o.md
│   └── ...
├── utils/
│   └── prompt_loader.py      # 加载工具
└── src/
    └── your_app.py           # 应用代码（不包含 Prompt 内容）
```

### 文件格式规范

使用 **YAML Frontmatter + Markdown** 格式：

```markdown
---
name: code-reviewer
version: "1.2.0"
description: 代码审查专家
tags: [code-review, quality]
models:
  - kimi-k2.5
parameters:
  temperature: 0.2
  max_tokens: 4000
variables:
  - code
  - language
  - context
---

# 角色

你是一位资深的 {language} 代码审查专家。

# 任务

审查以下代码...

```{language}
{code}
```
```

### Frontmatter 字段说明

| 字段 | 类型 | 用途 |
|------|------|------|
| `name` | string | Prompt 标识 |
| `version` | string | 语义化版本（追踪变更） |
| `description` | string | 用途说明 |
| `models` | list | 适用模型（用于选择最优版本） |
| `parameters` | dict | API 参数（temperature, max_tokens 等） |
| `variables` | list | 模板变量（用于校验） |

### 模型版本选择策略

同一 Prompt 可为不同模型编写优化版本：

| 优先级 | 文件名 | 说明 |
|--------|--------|------|
| 1 | `prompt.kimi-k2.5.md` | 精确匹配 |
| 2 | `prompt.kimi.md` | 前缀匹配 |
| 3 | `prompt.md` | 通用回退 |

示例：
- Kimi K2.5 使用 `reviewer.kimi-k2.5.md`（输出格式针对 Kimi 优化）
- GPT-4o 使用 `reviewer.gpt-4o.md`（JSON 模式针对 GPT 优化）
- 其他模型使用 `reviewer.md`（通用版本）

### 加载器实现

**核心功能**：
1. 解析 YAML Frontmatter
2. 自动选择模型最优版本
3. 模板变量渲染和校验
4. 提取 API 参数

**基础实现参考**（位于 `patterns/examples/prompt_loader.py`）：

```python
from dataclasses import dataclass
from pathlib import Path
import yaml

@dataclass
class Prompt:
    name: str
    content: str      # 渲染后的内容
    metadata: dict    # Frontmatter 数据
    
    def render(self, **kwargs) -> list[dict]:
        """渲染为 OpenAI messages 格式"""
        content = self.content.format(**kwargs)
        return [{"role": "system", "content": content}]
    
    def get_api_params(self) -> dict:
        """获取记录的 API 参数"""
        return self.metadata.get("parameters", {})

class PromptLoader:
    def __init__(self, prompts_dir: str | Path):
        self.prompts_dir = Path(prompts_dir)
    
    def load(self, path: str, model: str = None) -> Prompt:
        """
        加载指定 Prompt
        - path: 如 "code-review/reviewer"
        - model: 如 "kimi-k2.5"（用于版本选择）
        """
        # 实现：按优先级查找文件 -> 解析 -> 返回 Prompt
        pass
```

### 使用示例

```python
from utils.prompt_loader import PromptLoader
from openai import OpenAI

# 初始化
loader = PromptLoader("prompts")
client = OpenAI(api_key="...", base_url="...")

# 加载（自动选择 kimi-k2.5 优化版本）
prompt = loader.load("code-review/reviewer", model="kimi-k2.5")

# 渲染
messages = prompt.render(
    code="def foo(): pass",
    language="python",
    context="示例代码"
)

# 调用（使用 Prompt 记录的参数）
response = client.chat.completions.create(
    model="kimi-k2.5",
    messages=messages,
    **prompt.get_api_params()
)
```

### 工作流建议

1. **开发阶段**：在 `prompts/` 下创建/编辑 Prompt 文件
2. **测试阶段**：使用 `git diff` 对比 Prompt 变更效果
3. **部署阶段**：Prompt 文件随代码一起发布
4. **迭代阶段**：通过版本号追踪 Prompt 演进

---

## 最佳实践

### 错误处理

```python
from openai import APIError, RateLimitError

try:
    response = client.chat.completions.create(...)
except RateLimitError:
    # 指数退避重试
    pass
except APIError as e:
    # 记录错误详情
    pass
```

### 重试机制

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
def call_api(messages):
    return client.chat.completions.create(...)
```

### Token 管理

- 监控输入/输出 token 数量
- 设置 max_tokens 控制成本
- 使用 tiktoken 预计算

---

## Function Calling

```python
def get_weather(location: str, unit: str = "celsius"):
    """获取天气信息"""
    return {"temperature": 25, "unit": unit}

tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "获取指定位置的天气",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string"},
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
            },
            "required": ["location"]
        }
    }
}]

response = client.chat.completions.create(
    model="kimi-k2.5",
    messages=messages,
    tools=tools,
    tool_choice="auto"
)
```

---

## 多轮对话管理

```python
class ConversationManager:
    def __init__(self, system_prompt: str = None):
        self.messages = []
        if system_prompt:
            self.messages.append({
                "role": "system", 
                "content": system_prompt
            })
    
    def add_user_message(self, content: str):
        self.messages.append({"role": "user", "content": content})
    
    def add_assistant_message(self, content: str):
        self.messages.append({"role": "assistant", "content": content})
    
    def trim_history(self, max_messages: int = 10):
        """保留最近 N 条消息"""
        system = self.messages[0] if self.messages[0]["role"] == "system" else None
        self.messages = self.messages[-max_messages:]
        if system and self.messages[0]["role"] != "system":
            self.messages.insert(0, system)
```

---

## 项目模板

使用以下命令创建包含 Prompt 管理的新项目：

```bash
# 复制项目模板
cp -r templates/ai-project my-ai-app
cd my-ai-app

# 安装依赖
pip install openai pyyaml tenacity

# 开始使用
python examples/basic_usage.py
```

模板包含：
- `prompts/` - Prompt 文件组织示例
- `utils/prompt_loader.py` - 加载器实现
- `examples/` - 使用示例

---

## 文件清单

```
skills/software/ai-api-integration/
├── SKILL.md                          # 本文件
├── metadata.json                     # Skill 元数据
├── HISTORY.md                        # 更新历史
├── patterns/
│   └── examples/
│       ├── prompt_loader.py          # 加载器参考实现
│       └── usage_example.py          # 使用示例代码
└── templates/                        # [项目模板]
    └── ai-project/                   # 可复制的项目模板
        ├── README.md
        ├── prompts/                  # Prompt 示例
        │   ├── chat/
        │   ├── code-review/
        │   ├── vision/
        │   └── structured-output/
        ├── utils/
        │   ├── __init__.py
        │   └── prompt_loader.py
        └── examples/
            └── basic_usage.py
```

---

## AI 助手约定（强制执行）

### 识别 AI 项目

当项目满足以下条件时，**自动视为 AI 项目**：
- 使用 `openai` 或其他 LLM API 客户端
- 涉及 AI 对话、生成、分析等功能
- 文件名/目录包含 `ai`, `llm`, `chat`, `agent` 等关键词
- 项目依赖包含 `openai`, `anthropic`, `langchain` 等

### AI 项目必须遵循的约定

**[强制] Prompt 文件化管理**

AI 助手在开发 AI 功能时，**禁止将 Prompt 硬编码在代码中**。

正确做法：
```python
# [X] 禁止：硬编码 Prompt
response = client.chat.completions.create(
    messages=[{"role": "system", "content": "你是代码审查专家，请审查以下代码..."}]  # 错误！
)

# [OK] 正确：从文件加载
loader = PromptLoader("prompts")
prompt = loader.load("code-review/reviewer", model="kimi-k2.5")
messages = prompt.render(code=user_code, language="python")
```

**自动创建 Prompt 目录**

如果项目的 `AGENTS.md` 中声明了 `ai-api-integration` skill，但不存在 `prompts/` 目录：

1. **立即创建目录结构**：
   ```
   prompts/
   ├── chat/                  # 对话类 Prompts
   ├── code-review/           # 代码审查类
   ├── vision/                # 视觉分析类
   ├── structured-output/     # 结构化输出类
   └── README.md              # 项目 Prompt 使用说明
   ```

2. **创建基础 Prompt 文件**：
   - 根据当前功能需求，创建对应的 `.md` 文件
   - 使用 YAML Frontmatter 格式
   - 记录适用的模型和参数

3. **告知用户**：
   > "已自动创建 `prompts/` 目录管理 AI Prompt。Prompt 文件独立于代码，便于版本控制和微调。"

**Prompt 变更流程**

当用户要求修改 AI 行为时：
1. 定位对应的 Prompt 文件（如 `prompts/chat/assistant.md`）
2. 修改文件内容，**升级 version 字段**
3. 展示变更 diff 给用户确认
4. 如需回滚，可直接通过 git 恢复

---

## 更新历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.1.0 | 2026-02-11 | 重构 Prompt 管理为方法论；创建项目模板 |
| 1.0.0 | 2026-02-10 | 初始版本：基础 API 集成 |
