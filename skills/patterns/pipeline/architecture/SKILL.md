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

| 模式 | 说明 | 适用场景 |
|-----|------|---------|
| Sequential | 顺序执行 | 阶段间强依赖 |
| **Intra-task Parallel** | 单任务内并行 | 阶段间无依赖，可同时执行 |
| **Inter-task Pipeline** | 批量任务流水线 | 多任务交错执行，资源解耦 |
| Conditional | 条件分支 | 动态路由 |

### 单任务内并行（依赖驱动）

基于阶段间的数据依赖关系构建 DAG，无依赖的阶段并行执行：

```
        [S1: 加载数据]
             │
     ┌───────┴───────┐
     ▼               ▼
[S2: CPU预处理]  [S3: 格式校验]
     │               │
     └───────┬───────┘
             ▼
        [S4: GPU推理]
             │
            [S5: 保存结果]
```

**判断条件**: 阶段B是否依赖阶段A的输出？若不依赖，可并行。

### 批量任务流水线（资源驱动）

多任务交错执行，最大化资源利用率：

```
时间 →

任务A: [S1:CPU] [S2:GPU] [S3:IO]
任务B:         [S1:CPU] [S2:GPU] [S3:IO]
任务C:                 [S1:CPU] [S2:GPU] [S3:IO]

资源利用:
CPU: ████████░░░░░░░░
GPU: ░░░░████████░░░░
IO:  ░░░░░░░░████████
```

**为什么不是"波次并行"？**

| 策略 | 执行方式 | 资源冲突 | 总耗时 |
|------|---------|---------|--------|
| **波次并行** | A/B/C 同时执行 S1，再同时执行 S2 | CPU 争用，GPU 空闲 | 3×max(S1)+3×max(S2)... |
| **流水线** | A在S2时，B在S1 | 无冲突，资源满载 | ≈ S1+S2+S3+(n-1)×max_stage |

**核心假设**: 每个阶段设计时已最大化利用其专属资源（CPU满核/GPU满显存/IO满带宽），同时执行多个同阶段任务只会导致资源争用，不会加速。

## 实现示例

```python
from dataclasses import dataclass
from typing import List, Callable, Any
from abc import ABC, abstractmethod
import queue
import threading

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
        """单任务顺序执行"""
        data = initial_data
        for stage in self.stages:
            try:
                data = stage(data)
            except Exception as e:
                return StageResult(False, data, e)
        return StageResult(True, data)


class PipelineWorker:
    """批量任务流水线工作器"""
    
    def __init__(self, pipeline_factory: Callable[[], Pipeline]):
        """
        Args:
            pipeline_factory: 创建新 Pipeline 实例的工厂函数
                              每个任务拥有独立的 Pipeline 实例
        """
        self.pipeline_factory = pipeline_factory
        self.stage_queues: List[queue.Queue] = []
        self.workers: List[threading.Thread] = []
    
    def start(self, num_stages: int):
        """启动流水线，为每个阶段创建工作线程"""
        self.stage_queues = [queue.Queue() for _ in range(num_stages)]
        
        for i in range(num_stages):
            t = threading.Thread(target=self._stage_worker, args=(i,))
            t.daemon = True
            t.start()
            self.workers.append(t)
    
    def _stage_worker(self, stage_idx: int):
        """单个阶段的工作线程"""
        q = self.stage_queues[stage_idx]
        is_last = (stage_idx == len(self.stage_queues) - 1)
        
        while True:
            task = q.get()
            if task is None:  # 结束信号
                break
            
            task_id, pipeline, data = task
            stage = pipeline.stages[stage_idx]
            
            try:
                result = stage(data)
                if not is_last:
                    # 传递给下一阶段
                    self.stage_queues[stage_idx + 1].put((task_id, pipeline, result))
                else:
                    # 最后阶段完成
                    print(f"[Task {task_id}] Completed: {result}")
            except Exception as e:
                print(f"[Task {task_id}] Stage {stage_idx} failed: {e}")
            
            q.task_done()
    
    def submit(self, task_id: int, initial_data: Any):
        """提交新任务到流水线"""
        pipeline = self.pipeline_factory()
        self.stage_queues[0].put((task_id, pipeline, initial_data))
    
    def stop(self):
        """停止所有工作线程"""
        for q in self.stage_queues:
            q.put(None)
        for w in self.workers:
            w.join()


# 使用示例：视频处理流水线
# S1: CPU提取帧 → S2: GPU推理 → S3: IO保存结果
def create_video_pipeline():
    pipeline = Pipeline()
    pipeline.add_stage(lambda video: extract_frames_cpu(video))   # S1: CPU
    pipeline.add_stage(lambda frames: inference_gpu(frames))      # S2: GPU
    pipeline.add_stage(lambda result: save_results_io(result))    # S3: IO
    return pipeline

# 启动流水线
worker = PipelineWorker(create_video_pipeline)
worker.start(num_stages=3)

# 批量提交任务
for i, video_path in enumerate(video_list):
    worker.submit(i, video_path)

# 等待完成
worker.stop()
```

### 并行策略决策指南

```
是否是批量任务？
├─ 否（单任务）
│   └─ 阶段间是否有依赖？
│       ├─ 是 → 顺序执行
│       └─ 否 → 单任务内并行（DAG）
│
└─ 是（批量任务）
    └─ 各阶段是否使用不同资源？
        ├─ 是 → 流水线并行（推荐）
        └─ 否 → 任务级并行（同时跑多个任务）
```

| 场景 | 推荐策略 | 原因 |
|------|---------|------|
| 单图片处理：解码→预处理→推理→编码 | DAG并行 | 解码和预处理无依赖 |
| 批量图片处理：CPU解码→GPU推理→IO保存 | 流水线 | 资源解耦，无冲突 |
| 批量数据清洗：读取→清洗→写入（全IO） | 任务级并行 | 同资源，需控制并发数 |

### 关键设计要点

1. **阶段资源隔离**
   - 每个阶段应主要使用一种资源类型
   - 避免 CPU 阶段和 GPU 阶段互相干扰

2. **队列缓冲**
   - 阶段间使用队列解耦
   - 设置合理队列长度防止内存爆炸

3. **反压机制**
   - 当下游处理不过来时，上游应减速
   - 避免队列无限增长

## 迭代记录

- 2026-02-12: 从项目实践中提取，定义为通用架构模式
- 2026-02-12: 补充单任务并行和批量任务流水线详细说明
