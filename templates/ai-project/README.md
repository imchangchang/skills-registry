# AI 项目 Prompt 管理模板

本项目模板提供 AI API 集成的最佳实践，包含 Prompt 文件管理和加载工具。

## 目录结构

```
.
├── prompts/                    # Prompt 文件库（业务逻辑）
│   ├── chat/                   # 对话类 Prompts
│   ├── code-review/            # 代码审查类 Prompts
│   ├── vision/                 # 视觉分析类 Prompts
│   └── structured-output/      # 结构化输出类 Prompts
├── utils/
│   └── prompt_loader.py        # Prompt 加载工具
└── examples/
    └── basic_usage.py          # 使用示例
```

## Prompt 文件格式

采用 YAML Frontmatter + Markdown 格式：

```markdown
---
name: prompt-name
version: "1.0.0"
description: 描述用途
models:
  - kimi-k2.5
  - gpt-4o
parameters:
  temperature: 0.7
  max_tokens: 2000
variables:
  - var1
  - var2
---

# Prompt 内容

支持 {var1} 和 {var2} 模板变量...
```

## 快速开始

```python
from utils.prompt_loader import PromptLoader

loader = PromptLoader("prompts")

# 加载 Prompt（自动选择模型优化版本）
prompt = loader.load("code-review/reviewer", model="kimi-k2.5")

# 渲染并调用 API
messages = prompt.render(code="...", language="python")

response = client.chat.completions.create(
    model="kimi-k2.5",
    messages=messages,
    **prompt.get_api_params()
)
```

## 模型特定版本

支持为不同模型编写优化版本，命名约定：
- `prompt.md` - 通用版本
- `prompt.kimi-k2.5.md` - Kimi 专用版本
- `prompt.gpt-4o.md` - GPT-4o 专用版本

加载器会按优先级自动选择最优版本。

## 自定义扩展

1. 在 `prompts/` 下添加新的分类目录
2. 按照格式创建 Prompt 文件
3. 使用 `loader.list_prompts()` 查看可用 prompts
