# 管道架构设计原则

## 五大核心原则

### 1. Asset-First 原则

**数据即资产** - 每个阶段产生的结果都是可独立使用的资产。

```python
# 好的设计：每个阶段输出可保存的资产
stage1_output = extract(input)      # 可保存的原始数据
stage2_output = transform(stage1)   # 可保存的处理结果
stage3_output = load(stage2)        # 可保存的最终产物
```

### 2. Explicit Contract 原则

**显式契约** - 阶段间接口明确定义。

```python
@dataclass
class StageInput:
    data: bytes
    metadata: dict
    
@dataclass  
class StageOutput:
    result: bytes
    metrics: dict
```

### 3. Incremental by Default 原则

**默认增量** - 支持断点续传和增量处理。

```python
class IncrementalStage:
    def process(self, data: Any, checkpoint: Checkpoint = None):
        if checkpoint:
            # 从 checkpoint 恢复
            data = self.resume_from(checkpoint)
        # 继续处理
```

### 4. Isolation 原则

**阶段隔离** - 每个阶段独立运行，无副作用。

```python
# 每个阶段接收输入，产生输出，不修改全局状态
def stage(input_data: T) -> U:
    # 纯函数式处理
    return transformed
```

### 5. Human-First DX 原则

**开发者体验优先** - 易于理解和调试。

```python
# 清晰的命名和文档
@stage("extract_audio")
def extract_audio(video: Video) -> Audio:
    """从视频中提取音频轨道"""
    ...
```

## 常见模式

### 验证模式

```python
def validate_and_process(data):
    if not validator.is_valid(data):
        raise ValidationError()
    return processor.process(data)
```

### 缓存模式

```python
@cached(key_func=lambda x: x.id)
def expensive_operation(data):
    ...
```

### 重试模式

```python
@retry(max_attempts=3, exceptions=NetworkError)
def unreliable_operation(data):
    ...
```
