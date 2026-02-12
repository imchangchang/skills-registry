---
name: pipeline-architecture
description: 管道/流水线架构模式。定义阶段化的数据处理模式，支持顺序执行、并行处理和错误回退。
created: 2026-02-12
status: stable
---

# 管道架构模式

> 阶段化的数据流处理模式

## 适用场景

- 多阶段数据处理
- ETL 工作流
- 构建流水线
- 视频/音频处理链

## 核心概念

### 阶段（Stage）

管道由多个阶段组成，每个阶段负责特定处理：

```python
class PipelineStage(ABC):
    @abstractmethod
    def process(self, data: Any) -> Any:
        pass
```

### 执行模式

| 模式 | 说明 |
|-----|------|
| Sequential | 顺序执行 |
| Parallel | 阶段内并行 |
| Conditional | 条件分支 |

## 实现示例

```python
from dataclasses import dataclass
from typing import List, Callable, Any
from abc import ABC, abstractmethod

@dataclass
class StageResult:
    success: bool
    data: Any
    error: Exception = None

class Pipeline:
    def __init__(self):
        self.stages: List[Callable] = []
    
    def add_stage(self, stage: Callable):
        self.stages.append(stage)
        return self
    
    def execute(self, initial_data: Any) -> StageResult:
        data = initial_data
        for stage in self.stages:
            try:
                data = stage(data)
            except Exception as e:
                return StageResult(False, data, e)
        return StageResult(True, data)
```

## 迭代记录

- 2026-02-12: 从项目实践中提取，定义为通用架构模式
