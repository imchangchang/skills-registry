---
name: ai-prompt-engineering
description: AI Prompt 工程化实践。定义如何设计、管理和版本化 Prompt，确保 AI 输出的一致性和可维护性。
created: 2026-02-12
status: stable
---

# AI Prompt 工程

> 与 LLM 交互的 Prompt 设计和工程化实践

## 适用场景

- 需要复用的 AI 提示词
- 多步骤 AI 工作流
- 要求输出一致性的场景

## 核心概念

### Prompt 文件化

将 Prompt 从代码中抽离，独立管理：
```
prompts/
├── transcript-optimization.md
├── image-analysis.md
└── document-merge.md
```

### YAML Frontmatter 格式

```markdown
---
name: transcript-optimization
version: "1.0.0"
description: 将原始转录优化为可读文稿
model: kimi-k2.5
parameters:
  temperature: 1
---

# 角色定义
你是专业的文稿编辑...
```

## 设计原则

1. **Prompt 即代码**：版本控制、Code Review
2. **参数化**：使用变量替换，避免硬编码
3. **可测试**：独立验证 Prompt 效果

## 快速开始

```python
from pathlib import Path
import yaml

class Prompt:
    def __init__(self, path: Path):
        content = path.read_text()
        # 解析 frontmatter
        self.meta, self.template = self._parse(content)
    
    def render(self, **kwargs) -> str:
        return self.template.format(**kwargs)

# 使用
prompt = Prompt(Path("prompts/transcript.md"))
result = llm.generate(prompt.render(text=raw_text))
```

## 迭代记录

- 2026-02-12: 初始创建，沉淀 Prompt 工程化最佳实践
