#!/usr/bin/env python3
"""
Pipeline 执行引擎骨架

支持：
- DAG 构建与拓扑排序
- 波次执行（自动并行化）
- 基于哈希的缓存机制
- 多种执行模式（函数/进程）
"""

import hashlib
import json
from abc import ABC, abstractmethod
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Optional, Literal
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor


# ============ 数据模型 ============

@dataclass
class Stage:
    """Stage 定义"""
    name: str
    version: str
    execute: Callable
    inputs: dict = field(default_factory=dict)  # {参数名: 来源 stage}
    outputs: list = field(default_factory=list)
    side_effects: list = field(default_factory=list)
    executor: Literal["function", "process"] = "function"


@dataclass
class StageResult:
    """Stage 执行结果"""
    stage_name: str
    success: bool
    data: dict = field(default_factory=dict)
    error: Optional[str] = None
    duration_seconds: float = 0.0
    cache_hit: bool = False
    input_hash: str = ""
    output_hash: str = ""


@dataclass
class ExecutionContext:
    """执行上下文"""
    run_id: str
    output_dir: Path
    mode: Literal["serial", "parallel", "incremental"] = "incremental"
    use_cache: bool = True
    force_rerun: list = field(default_factory=list)
    max_workers: int = 4


# ============ 缓存管理 ============

class CacheManager:
    """基于文件系统的缓存管理"""
    
    def __init__(self, cache_dir: Path):
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
    
    def _get_cache_path(self, cache_key: str) -> Path:
        """获取缓存文件路径"""
        return self.cache_dir / f"{cache_key}.json"
    
    def compute_cache_key(self, stage: Stage, inputs: dict) -> str:
        """计算缓存键"""
        data = {
            "stage": stage.name,
            "version": stage.version,
            "inputs": self._hash_inputs(inputs)
        }
        json_str = json.dumps(data, sort_keys=True, default=str)
        return hashlib.sha256(json_str.encode()).hexdigest()[:16]
    
    def _hash_inputs(self, inputs: dict) -> str:
        """计算输入哈希"""
        json_str = json.dumps(inputs, sort_keys=True, default=str)
        return hashlib.sha256(json_str.encode()).hexdigest()[:16]
    
    def get(self, cache_key: str) -> Optional[dict]:
        """获取缓存"""
        cache_path = self._get_cache_path(cache_key)
        if cache_path.exists():
            with open(cache_path) as f:
                return json.load(f)
        return None
    
    def put(self, cache_key: str, data: dict) -> None:
        """存储缓存"""
        cache_path = self._get_cache_path(cache_key)
        with open(cache_path, "w") as f:
            json.dump(data, f, indent=2)


# ============ DAG 构建 ============

class DAG:
    """有向无环图"""
    
    def __init__(self):
        self.nodes: dict[str, Stage] = {}
        self.edges: dict[str, list[str]] = defaultdict(list)  # node -> dependents
        self.dependencies: dict[str, list[str]] = defaultdict(list)  # node -> dependencies
    
    def add_node(self, stage: Stage) -> None:
        """添加节点"""
        self.nodes[stage.name] = stage
        # 解析依赖关系
        for input_name, source in stage.inputs.items():
            if isinstance(source, str) and "." in source:
                upstream_stage = source.split(".")[0]
                self.edges[upstream_stage].append(stage.name)
                self.dependencies[stage.name].append(upstream_stage)
    
    def topological_sort(self) -> list[str]:
        """拓扑排序"""
        in_degree = {name: len(self.dependencies[name]) for name in self.nodes}
        queue = [name for name, degree in in_degree.items() if degree == 0]
        result = []
        
        while queue:
            node = queue.pop(0)
            result.append(node)
            
            for dependent in self.edges[node]:
                in_degree[dependent] -= 1
                if in_degree[dependent] == 0:
                    queue.append(dependent)
        
        if len(result) != len(self.nodes):
            raise ValueError("Graph contains cycles!")
        
        return result
    
    def get_execution_waves(self) -> list[list[str]]:
        """
        获取执行波次
        
        同一波次的节点可以并行执行
        """
        # 计算每个节点的层级（最大依赖深度）
        levels = {}
        
        def compute_level(node: str) -> int:
            if node in levels:
                return levels[node]
            
            deps = self.dependencies[node]
            if not deps:
                levels[node] = 0
            else:
                levels[node] = max(compute_level(d) for d in deps) + 1
            return levels[node]
        
        for node in self.nodes:
            compute_level(node)
        
        # 按层级分组
        max_level = max(levels.values()) if levels else 0
        waves = []
        
        for level in range(max_level + 1):
            wave = [node for node, lvl in levels.items() if lvl == level]
            if wave:
                waves.append(wave)
        
        return waves


# ============ 执行引擎 ============

class PipelineExecutor:
    """Pipeline 执行引擎"""
    
    def __init__(self, context: ExecutionContext):
        self.context = context
        self.cache = CacheManager(context.output_dir / "cache")
        self.results: dict[str, StageResult] = {}
        self.dag = DAG()
    
    def add_stage(self, stage: Stage) -> None:
        """添加 Stage"""
        self.dag.add_node(stage)
    
    def execute(self) -> dict[str, StageResult]:
        """执行完整管道"""
        if self.context.mode == "serial":
            return self._execute_serial()
        elif self.context.mode == "parallel":
            return self._execute_parallel()
        else:  # incremental
            return self._execute_incremental()
    
    def _execute_serial(self) -> dict[str, StageResult]:
        """顺序执行"""
        order = self.dag.topological_sort()
        
        for stage_name in order:
            self._execute_stage(self.dag.nodes[stage_name])
        
        return self.results
    
    def _execute_parallel(self) -> dict[str, StageResult]:
        """并行执行（波次模式）"""
        waves = self.dag.get_execution_waves()
        
        for wave in waves:
            print(f"\n[Wave] Executing: {', '.join(wave)}")
            
            if len(wave) == 1:
                # 单个节点，直接执行
                self._execute_stage(self.dag.nodes[wave[0]])
            else:
                # 多个节点，并行执行
                with ThreadPoolExecutor(max_workers=self.context.max_workers) as pool:
                    futures = {
                        pool.submit(self._execute_stage, self.dag.nodes[name]): name
                        for name in wave
                    }
                    for future in futures:
                        future.result()  # 等待完成
        
        return self.results
    
    def _execute_incremental(self) -> dict[str, StageResult]:
        """增量执行（带缓存）"""
        waves = self.dag.get_execution_waves()
        
        for wave in waves:
            for stage_name in wave:
                stage = self.dag.nodes[stage_name]
                
                # 检查是否强制重运行
                if stage_name in self.context.force_rerun:
                    print(f"[{stage_name}] Force rerun requested")
                    self._execute_stage(stage)
                    continue
                
                # 准备输入
                inputs = self._prepare_inputs(stage)
                cache_key = self.cache.compute_cache_key(stage, inputs)
                
                # 检查缓存
                if self.context.use_cache:
                    cached = self.cache.get(cache_key)
                    if cached:
                        print(f"[{stage_name}] Cache hit! Skipping execution")
                        self.results[stage_name] = StageResult(
                            stage_name=stage_name,
                            success=True,
                            data=cached["data"],
                            cache_hit=True,
                            input_hash=cache_key
                        )
                        continue
                
                # 执行 Stage
                self._execute_stage(stage, inputs, cache_key)
        
        return self.results
    
    def _prepare_inputs(self, stage: Stage) -> dict:
        """准备 Stage 输入"""
        inputs = {}
        
        for param_name, source in stage.inputs.items():
            if isinstance(source, str):
                if "." in source:
                    # 引用上游输出: "stage_name.output_name"
                    upstream_stage, output_name = source.split(".", 1)
                    if upstream_stage in self.results:
                        upstream_result = self.results[upstream_stage]
                        # 支持嵌套路径: "stage.data.field"
                        value = upstream_result.data
                        for key in output_name.split("."):
                            value = value.get(key) if isinstance(value, dict) else getattr(value, key, None)
                        inputs[param_name] = value
                    else:
                        raise ValueError(f"Upstream stage '{upstream_stage}' not found")
                else:
                    # 直接值
                    inputs[param_name] = source
            else:
                inputs[param_name] = source
        
        return inputs
    
    def _execute_stage(
        self,
        stage: Stage,
        inputs: Optional[dict] = None,
        cache_key: Optional[str] = None
    ) -> StageResult:
        """执行单个 Stage"""
        print(f"\n[{stage.name}] Executing...")
        
        if inputs is None:
            inputs = self._prepare_inputs(stage)
        
        start_time = datetime.now()
        
        try:
            # 根据执行器类型选择执行方式
            if stage.executor == "function":
                result_data = stage.execute(**inputs)
            else:
                # 进程方式（简化版，实际可能需要序列化/IPC）
                result_data = stage.execute(**inputs)
            
            duration = (datetime.now() - start_time).total_seconds()
            
            # 计算输出哈希
            output_hash = hashlib.sha256(
                json.dumps(result_data, sort_keys=True, default=str).encode()
            ).hexdigest()[:16]
            
            result = StageResult(
                stage_name=stage.name,
                success=True,
                data=result_data if isinstance(result_data, dict) else {"result": result_data},
                duration_seconds=duration,
                input_hash=cache_key or "",
                output_hash=output_hash
            )
            
            # 存储缓存
            if cache_key and self.context.use_cache:
                self.cache.put(cache_key, {"data": result.data})
            
            print(f"[{stage.name}] Success in {duration:.2f}s")
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            result = StageResult(
                stage_name=stage.name,
                success=False,
                error=str(e),
                duration_seconds=duration
            )
            print(f"[{stage.name}] Failed: {e}")
        
        self.results[stage.name] = result
        return result


# ============ 使用示例 ============

if __name__ == "__main__":
    print("=" * 60)
    print("Pipeline Executor Demo")
    print("=" * 60)
    
    # 创建执行上下文
    context = ExecutionContext(
        run_id=datetime.now().strftime("%Y%m%d_%H%M%S"),
        output_dir=Path("./pipeline_output"),
        mode="incremental",
        use_cache=True,
        max_workers=4
    )
    
    # 创建执行器
    executor = PipelineExecutor(context)
    
    # 定义 Stages
    def stage_a_execute():
        """第一阶段：生成基础数据"""
        return {"value": 10, "items": [1, 2, 3]}
    
    def stage_b_execute(value: int):
        """第二阶段：处理数据（依赖 A）"""
        return {"doubled": value * 2, "squared": value ** 2}
    
    def stage_c_execute(value: int):
        """第三阶段：并行处理（依赖 A）"""
        return {"tripled": value * 3}
    
    def stage_d_execute(doubled: int, tripled: int):
        """第四阶段：合并结果（依赖 B 和 C）"""
        return {"sum": doubled + tripled}
    
    # 添加 Stages
    executor.add_stage(Stage(
        name="stage_a",
        version="1.0.0",
        execute=stage_a_execute,
        inputs={},
        outputs=["value", "items"]
    ))
    
    executor.add_stage(Stage(
        name="stage_b",
        version="1.0.0",
        execute=stage_b_execute,
        inputs={"value": "stage_a.value"},
        outputs=["doubled", "squared"]
    ))
    
    executor.add_stage(Stage(
        name="stage_c",
        version="1.0.0",
        execute=stage_c_execute,
        inputs={"value": "stage_a.value"},
        outputs=["tripled"]
    ))
    
    executor.add_stage(Stage(
        name="stage_d",
        version="1.0.0",
        execute=stage_d_execute,
        inputs={
            "doubled": "stage_b.doubled",
            "tripled": "stage_c.tripled"
        },
        outputs=["sum"]
    ))
    
    # 显示执行波次
    print("\n[DAG Analysis]")
    waves = executor.dag.get_execution_waves()
    for i, wave in enumerate(waves):
        print(f"  Wave {i+1}: {', '.join(wave)}")
    
    # 执行管道
    print("\n[Execution]")
    results = executor.execute()
    
    # 显示结果
    print("\n[Results]")
    for name, result in results.items():
        status = "[OK]" if result.success else "[X]"
        cache_info = "(cached)" if result.cache_hit else ""
        print(f"  {status} {name}: {result.data} {cache_info}")
