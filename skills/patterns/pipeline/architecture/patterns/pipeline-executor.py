"""
Pipeline Executor 模式

执行管道阶段的核心实现。
"""

from dataclasses import dataclass
from typing import List, Callable, Any, Optional
from enum import Enum, auto
import time


class StageStatus(Enum):
    PENDING = auto()
    RUNNING = auto()
    SUCCESS = auto()
    FAILED = auto()
    SKIPPED = auto()


@dataclass
class StageResult:
    stage_name: str
    status: StageStatus
    data: Any = None
    error: Optional[Exception] = None
    duration_ms: float = 0.0


class PipelineExecutor:
    """管道执行器"""
    
    def __init__(self, name: str = "pipeline"):
        self.name = name
        self.stages: List[Callable] = []
        self.results: List[StageResult] = []
    
    def add_stage(self, stage: Callable, name: Optional[str] = None):
        """添加阶段"""
        stage.__name__ = name or stage.__name__
        self.stages.append(stage)
        return self
    
    def execute(self, initial_data: Any) -> List[StageResult]:
        """顺序执行所有阶段"""
        data = initial_data
        self.results = []
        
        for stage in self.stages:
            start = time.perf_counter()
            try:
                data = stage(data)
                status = StageStatus.SUCCESS
                error = None
            except Exception as e:
                status = StageStatus.FAILED
                error = e
            
            duration = (time.perf_counter() - start) * 1000
            
            result = StageResult(
                stage_name=stage.__name__,
                status=status,
                data=data,
                error=error,
                duration_ms=duration
            )
            self.results.append(result)
            
            if status == StageStatus.FAILED:
                break
        
        return self.results
    
    def get_summary(self) -> dict:
        """获取执行摘要"""
        return {
            "total": len(self.results),
            "success": sum(1 for r in self.results if r.status == StageStatus.SUCCESS),
            "failed": sum(1 for r in self.results if r.status == StageStatus.FAILED),
            "total_duration_ms": sum(r.duration_ms for r in self.results)
        }


# 使用示例
if __name__ == "__main__":
    pipeline = PipelineExecutor("video-processing")
    
    @pipeline.add_stage
    def load_video(data: dict) -> dict:
        data["video"] = "loaded"
        return data
    
    @pipeline.add_stage  
    def extract_audio(data: dict) -> dict:
        data["audio"] = "extracted"
        return data
    
    results = pipeline.execute({"source": "input.mp4"})
    print(pipeline.get_summary())
