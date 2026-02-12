# Pipeline 框架设计细节

本文档详细说明 Pipeline 执行框架的设计决策和实现细节。

---

## 执行模式决策

### 三种执行方式对比

| 维度 | 函数方式 | 进程方式 |
|------|----------|----------|
| **性能** | [OK] 最优 | [X] 有序列化开销 |
| **调试** | [OK] pdb 直接断点 | [X] 依赖日志 |
| **隔离** | [X] 共享内存 | [OK] 完全隔离 |
| **并行** | [X] GIL 限制 | [OK] 真并行 |

### 决策指南

```
选择执行模式
    │
    ├── 数据量 > 100MB ?
    │       ├── Yes → 函数方式（避免序列化开销）
    │       └── No → 继续判断
    │
    ├── 可能崩溃/外部调用 ?
    │       ├── Yes → 进程方式（崩溃隔离）
    │       └── No → 继续判断
    │
    └── 默认 → 函数方式（开发体验优先）
```

### 推荐配置

| 场景 | 推荐模式 | 理由 |
|------|----------|------|
| 视频/图像处理 | 函数 | 数据量大，避免序列化 |
| ML 模型推理 | 函数 | 模型权重传递成本高 |
| 外部 API 调用 | 进程 | 超时/失败隔离 |
| 数据清洗 | 函数 | 纯计算，数据量大 |

---

## 数据传递策略

### 核心原则

> **"传递引用，而非数据本身"**

### 决策矩阵

| 数据大小 | 传递方式 | 示例 |
|----------|----------|------|
| < 1MB | 直接内存传递 | 配置、元数据 |
| 1MB - 100MB | 序列化传递 | 文本、小图片 |
| > 100MB | 传递引用（路径/URI） | 视频、大模型 |
| 流式数据 | 生成器/迭代器 | 日志流 |

### 代码示例

```python
# 坏：传递实际数据
@stage
def stage1():
    video_data = load_video("big_file.mp4")  # 2GB
    return {"video": video_data}  # 序列化 2GB！

# 好：传递引用
@stage(outputs={"video_path": FileRef})
def stage1():
    return {"video_path": FileRef(path="big_file.mp4")}

@stage(inputs={"video_path": "stage1.video_path"})
def stage2(video_path: FileRef):
    stream_process(video_path.path)  # 按需流式读取
```

---

## 自动并行化机制

### DAG 波次执行模型

```
依赖图：        执行波次：
    A           Wave 1: A
   / \          Wave 2: B, C  (并行)
  B   C         Wave 3: D, E  (并行)
  |   |         Wave 4: F
  D   E
   \ /
    F
```

### 并行机会识别

```python
@pipeline
def workflow():
    a = stage_a()
    
    # [OK] 可以并行：B 和 C 都依赖 A，但互不依赖
    b = stage_b(a)  # ┐ Wave 2
    c = stage_c(a)  # ┘
    
    # [OK] 可以并行：D 依赖 B，E 依赖 C
    d = stage_d(b)  # ┐ Wave 3
    e = stage_e(c)  # ┘
    
    # [X] 必须顺序：F 依赖 D 和 E
    f = stage_f(d, e)  # Wave 4
```

### 波次执行算法

```python
class DAGExecutor:
    def execute(self, dag: DAG):
        # 1. 拓扑排序，计算每个节点的层级
        levels = dag.topological_levels()
        
        # 2. 按波次执行
        for level in range(max(levels.values()) + 1):
            # 获取当前波次的所有节点
            nodes_in_wave = [
                node for node, lvl in levels.items() 
                if lvl == level
            ]
            
            # 3. 并行执行当前波次
            with ThreadPoolExecutor(max_workers=self.max_workers) as pool:
                futures = [
                    pool.submit(self.run_node, node) 
                    for node in nodes_in_wave
                ]
                wait(futures)
```

---

## 产物存储规范

### 目录结构

```
pipeline_outputs/
├── runs/
│   └── {run_id}/              # 格式: 20240212_100000_abc123
│       ├── run.json           # 运行元数据
│       ├── manifest.json      # Stage 清单和状态
│       ├── stage1_analyze/
│       │   ├── output.json    # 序列化输出
│       │   └── artifacts/     # 附属产物
│       └── ...
├── cache/                     # 缓存目录
│   └── {cache_key}/
└── latest -> runs/{latest}/   # 软链接
```

### 产物数据格式

```json
{
    "_meta": {
        "stage": "stage1_analyze",
        "version": "2.0.0",
        "created_at": "2024-02-12T10:00:00Z",
        "duration_seconds": 2.5,
        "input_hash": "sha256:abc123...",
        "output_hash": "sha256:def456..."
    },
    "data": {
        "video_info": {...}
    },
    "artifacts": [
        {"name": "preview.jpg", "path": "artifacts/preview.jpg", "type": "image"}
    ]
}
```

---

## 缓存机制设计

### 缓存键计算

```python
def compute_cache_key(stage: Stage, inputs: dict) -> str:
    """计算缓存键"""
    data = {
        "stage": stage.name,
        "version": stage.version,
        "inputs": hash_inputs(inputs)
    }
    return sha256(json.dumps(data, sort_keys=True)).hexdigest()[:16]
```

### 缓存命中判断

```python
def can_use_cache(stage: Stage, inputs: dict, cached_output: Path) -> bool:
    """判断是否可以使用缓存"""
    if not cached_output.exists():
        return False
    
    current_key = compute_cache_key(stage, inputs)
    cached_key = load_hash(cached_output.with_suffix(".hash"))
    
    return current_key == cached_key
```

---

## 依赖关系管理

### 依赖类型

**数据依赖（Data Dependency）**:
```python
stage_b(input=stage_a.output)
# 真正的数据流依赖，必须等待
```

**控制依赖（Control Dependency）**:
```python
stage_b(should_run=config.enabled)
# 运行时决定是否执行，影响 DAG 构建
```

### 依赖声明方式

```python
@stage(
    inputs={
        "data": "stage_a.output_data",      # 数据依赖
        "config": "global.config"           # 配置依赖
    }
)
def stage_b(data, config): ...
```

---

## 错误处理与弹性

### 失败重试

```python
@stage(
    retry_policy={
        "max_attempts": 3,
        "backoff": "exponential",
        "retry_on": [TimeoutError, ConnectionError]
    }
)
def unstable_api_call(): ...
```

### 断点续传

```python
# 从指定 stage 恢复执行
pipeline.run(from_stage="stage_3", reuse_run="20240212_100000")
```

### 降级执行

```python
@stage(
    fallback="fallback_stage"  # 失败时执行备选方案
)
def main_processing(): ...

def fallback_stage():
    # 简化版处理逻辑
    pass
```
