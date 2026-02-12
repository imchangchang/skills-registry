# Pipeline 架构实现指南

从设计思想到实际代码的落地指南。

---

## 渐进式实现路径

### Phase 1: 产物存储规范（立即可用）

**目标**: 让各 Stage 可以独立测试，无需重新执行依赖

**核心实现**:

```python
# pipeline_io.py
import json
from pathlib import Path
from datetime import datetime

def save_stage_output(
    output_dir: Path,
    stage_name: str,
    data: dict,
    artifacts: list[Path] = None
) -> Path:
    """保存 Stage 输出"""
    stage_dir = output_dir / stage_name
    stage_dir.mkdir(parents=True, exist_ok=True)
    
    output = {
        "_meta": {
            "stage": stage_name,
            "created_at": datetime.now().isoformat(),
        },
        "data": data,
        "artifacts": [
            {"name": a.name, "path": str(a.relative_to(stage_dir))}
            for a in (artifacts or [])
        ]
    }
    
    output_path = stage_dir / "output.json"
    with open(output_path, "w") as f:
        json.dump(output, f, indent=2)
    
    return output_path

def load_stage_output(output_dir: Path, stage_name: str) -> dict:
    """加载 Stage 输出"""
    output_path = output_dir / stage_name / "output.json"
    with open(output_path) as f:
        output = json.load(f)
    return output["data"]
```

**使用方式**:

```bash
# 执行 Stage 1
python stage1.py --output-dir ./pipeline/run_001/

# 单独执行 Stage 2，复用 Stage 1 结果
python stage2.py \
    --input-dir ./pipeline/run_001/stage1/ \
    --output-dir ./pipeline/run_001/
```

---

### Phase 2: Simple Runner（本周可用）

**目标**: 轻量级 runner，支持自动依赖执行和缓存

**核心功能**:
1. DAG 构建与拓扑排序
2. 波次执行（自动并行化）
3. 基于哈希的缓存机制

**简化版实现**:

```python
# simple_runner.py
from typing import Callable
from pathlib import Path
import hashlib
import json

class SimpleRunner:
    """轻量级 Pipeline Runner"""
    
    def __init__(self, cache_dir: Path = None):
        self.stages = {}
        self.cache_dir = cache_dir or Path("./.pipeline_cache")
        self.cache_dir.mkdir(exist_ok=True)
    
    def register(
        self,
        name: str,
        func: Callable,
        inputs: dict = None,
        version: str = "1.0.0"
    ):
        """注册 Stage"""
        self.stages[name] = {
            "func": func,
            "inputs": inputs or {},
            "version": version
        }
    
    def run(self, final_stage: str, initial_inputs: dict = None) -> dict:
        """运行到指定 Stage"""
        # 1. 构建依赖图
        execution_order = self._get_execution_order(final_stage)
        
        # 2. 顺序执行
        results = initial_inputs or {}
        
        for stage_name in execution_order:
            stage = self.stages[stage_name]
            
            # 准备输入
            inputs = self._prepare_inputs(stage, results)
            
            # 检查缓存
            cache_key = self._compute_cache_key(stage_name, stage, inputs)
            cached = self._get_cache(cache_key)
            
            if cached:
                print(f"[{stage_name}] Cache hit")
                results[stage_name] = cached
            else:
                print(f"[{stage_name}] Executing...")
                result = stage["func"](**inputs)
                results[stage_name] = result
                self._save_cache(cache_key, result)
        
        return results.get(final_stage)
    
    def _get_execution_order(self, final_stage: str) -> list:
        """获取执行顺序（拓扑排序）"""
        # 简化版：假设线性依赖
        order = []
        current = final_stage
        
        while current:
            order.append(current)
            stage = self.stages[current]
            # 找到第一个依赖作为前一个 stage
            deps = list(stage["inputs"].values())
            current = deps[0] if deps else None
        
        return list(reversed(order))
    
    def _prepare_inputs(self, stage: dict, results: dict) -> dict:
        """准备 Stage 输入"""
        inputs = {}
        for param, source in stage["inputs"].items():
            if source in results:
                inputs[param] = results[source]
            else:
                inputs[param] = source  # 直接值
        return inputs
    
    def _compute_cache_key(self, name: str, stage: dict, inputs: dict) -> str:
        """计算缓存键"""
        data = json.dumps({
            "name": name,
            "version": stage["version"],
            "inputs": inputs
        }, sort_keys=True, default=str)
        return hashlib.sha256(data.encode()).hexdigest()[:16]
    
    def _get_cache(self, key: str):
        """获取缓存"""
        cache_file = self.cache_dir / f"{key}.json"
        if cache_file.exists():
            with open(cache_file) as f:
                return json.load(f)
        return None
    
    def _save_cache(self, key: str, data):
        """保存缓存"""
        cache_file = self.cache_dir / f"{key}.json"
        with open(cache_file, "w") as f:
            json.dump(data, f)


# 使用示例
if __name__ == "__main__":
    runner = SimpleRunner()
    
    # 注册 stages
    runner.register("extract", lambda text: {"words": text.split()})
    runner.register(
        "count",
        lambda words: {"count": len(words)},
        inputs={"words": "extract"}
    )
    
    # 运行
    result = runner.run("count", {"text": "hello world"})
    print(result)  # {'count': 2}
```

---

### Phase 3: 完整框架（按需实现）

当以下需求出现时，考虑实现完整框架：

- [ ] 需要 Web UI 监控
- [ ] 需要分布式执行
- [ ] 需要远程执行
- [ ] 需要插件系统

---

## 从现有代码迁移

### 迁移检查清单

**现有代码分析**:
- [ ] 识别当前的数据处理步骤
- [ ] 找出中间产物
- [ ] 确定依赖关系

**渐进迁移步骤**:
1. **Week 1**: 添加产物存储（Phase 1）
   - 每个步骤输出到独立目录
   - 支持 `--input-dir` 参数

2. **Week 2**: 引入 Simple Runner（Phase 2）
   - 用 runner 编排步骤
   - 添加缓存机制

3. **Week 3**: 完善契约
   - 显式声明输入输出
   - 添加版本号

---

## 测试策略

### 单元测试每个 Stage

```python
def test_extract_stage():
    """独立测试 Stage"""
    result = extract_stage.execute(
        video_path="test.mp4"
    )
    
    assert "audio_path" in result
    assert result["duration"] > 0
```

### 使用 Mock 数据测试

```python
def test_transform_stage():
    """用 Mock 输入测试"""
    mock_input = {
        "raw_data": RawData(
            source="test",
            content=b"test content",
            metadata={}
        )
    }
    
    result = transform_stage.execute(**mock_input)
    assert "cleaned_data" in result
```

### 集成测试

```python
def test_full_pipeline():
    """测试完整管道"""
    runner = PipelineRunner()
    
    result = runner.run(
        pipeline=my_pipeline,
        inputs={"source": "test_data"}
    )
    
    assert result.success
    assert Path(result.output_path).exists()
```

---

## 常见陷阱

### 陷阱 1: 过早抽象

**症状**: 简单脚本引入复杂框架

**解决**: 
```python
# 当只有 2-3 个步骤时，保持简单
def simple_flow():
    data = step1()
    result = step2(data)
    return step3(result)

# 当有 5+ 步骤，且需要缓存时，引入框架
```

### 陷阱 2: 隐式依赖

**症状**: Stage B 偷偷读取 Stage A 的文件

**解决**:
```python
# 显式传递
@stage(inputs={"data": "stage_a.output"})
def stage_b(data): ...

# 而不是在函数内部读取文件
```

### 陷阱 3: 大数据序列化

**症状**: 传递 GB 级数据对象

**解决**:
```python
# 传递引用
return {"video_path": "/path/to/video.mp4"}

# 而不是
return {"video_data": load_video(...)}  # 2GB!
```

---

## 性能优化

### 当性能成为问题时

1. **Profiling 优先**
   ```bash
   python -m cProfile -o profile.stats pipeline.py
   ```

2. **识别瓶颈**
   - I/O 瓶颈 → 并行化
   - CPU 瓶颈 → 多进程/向量化
   - 内存瓶颈 → 流式处理

3. **针对性优化**
   - 不要过早优化
   - 测量后再优化
