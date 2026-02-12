---
name: python-pipeline
description: Python 多阶段数据处理流水线设计。定义如何构建可扩展、可观测的数据处理流程，适用于视频处理、ETL、AI 工作流等场景。
created: 2026-02-12
status: stable
---

# Python Pipeline 设计

> 构建多阶段数据处理流水线的 Python 实践

## 适用场景

- 视频/音频多阶段处理
- 数据 ETL 流程
- AI 推理工作流
- 任何需要分阶段处理数据的场景

## 核心概念

### Stage（阶段）

每个 Stage 是独立的处理单元：
- 明确的输入/输出契约
- 单一职责
- 可独立测试

### Pipeline（流水线）

Stages 的有向组合：
```
Input → Stage1 → Stage2 → Stage3 → Output
```

### 数据传递

- 小数据：直接内存传递
- 大数据：传递引用（文件路径）

## 设计原则

1. **Stage 独立性**：每个 Stage 可独立运行
2. **显式数据流**：输入输出明确声明
3. **错误隔离**：单个 Stage 失败不影响其他
4. **可观测性**：每个 Stage 可监控进度

## 快速开始

```python
from dataclasses import dataclass
from pathlib import Path
from typing import Any

@dataclass
class Stage:
    name: str
    process: callable
    
    def run(self, input_data: Any) -> Any:
        return self.process(input_data)

class Pipeline:
    def __init__(self):
        self.stages = []
    
    def add(self, stage: Stage):
        self.stages.append(stage)
        return self
    
    def run(self, initial_input: Any) -> Any:
        data = initial_input
        for stage in self.stages:
            data = stage.run(data)
        return data

# 使用示例
pipeline = Pipeline()
pipeline.add(Stage("extract", extract_audio))
       .add(Stage("transcribe", transcribe))
       .add(Stage("generate", generate_doc))

result = pipeline.run(video_path)
```

## 迭代记录

- 2026-02-12: 初始创建，从 video2markdown 项目抽象出通用模式
