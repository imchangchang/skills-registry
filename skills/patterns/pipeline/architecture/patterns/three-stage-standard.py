"""
三阶段标准化模式

标准化管道：Extract → Transform → Load
"""

from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Optional
from dataclasses import dataclass

T = TypeVar('T')
U = TypeVar('U')
V = TypeVar('V')


@dataclass
class StageContext:
    """阶段上下文"""
    stage_name: str
    config: dict
    metadata: dict


class ExtractStage(Generic[T], ABC):
    """提取阶段基类"""
    
    @abstractmethod
    def extract(self, source: str, context: StageContext) -> T:
        """从源提取数据"""
        pass
    
    def validate(self, data: T) -> bool:
        """验证提取的数据"""
        return data is not None


class TransformStage(Generic[T, U], ABC):
    """转换阶段基类"""
    
    @abstractmethod
    def transform(self, data: T, context: StageContext) -> U:
        """转换数据"""
        pass


class LoadStage(Generic[U, V], ABC):
    """加载阶段基类"""
    
    @abstractmethod
    def load(self, data: U, destination: str, context: StageContext) -> V:
        """加载数据到目标"""
        pass


class ThreeStagePipeline(Generic[T, U, V]):
    """三阶段管道"""
    
    def __init__(
        self,
        extract: ExtractStage[T],
        transform: TransformStage[T, U],
        load: LoadStage[U, V]
    ):
        self.extract = extract
        self.transform = transform
        self.load = load
    
    def run(self, source: str, destination: str, config: dict = None) -> V:
        """执行完整管道"""
        cfg = config or {}
        
        # Extract
        extract_ctx = StageContext("extract", cfg, {})
        raw_data = self.extract.extract(source, extract_ctx)
        if not self.extract.validate(raw_data):
            raise ValueError("Extract validation failed")
        
        # Transform
        transform_ctx = StageContext("transform", cfg, {"source": source})
        processed_data = self.transform.transform(raw_data, transform_ctx)
        
        # Load
        load_ctx = StageContext("load", cfg, {"destination": destination})
        result = self.load.load(processed_data, destination, load_ctx)
        
        return result


# 使用示例：视频处理管道
class VideoExtractStage(ExtractStage[bytes]):
    def extract(self, source: str, context: StageContext) -> bytes:
        with open(source, 'rb') as f:
            return f.read()


class VideoTransformStage(TransformStage[bytes, bytes]):
    def transform(self, data: bytes, context: StageContext) -> bytes:
        # 视频处理逻辑
        return data  # 简化示例


class VideoLoadStage(LoadStage[bytes, str]):
    def load(self, data: bytes, destination: str, context: StageContext) -> str:
        with open(destination, 'wb') as f:
            f.write(data)
        return destination


if __name__ == "__main__":
    pipeline = ThreeStagePipeline(
        VideoExtractStage(),
        VideoTransformStage(),
        VideoLoadStage()
    )
    # result = pipeline.run("input.mp4", "output.mp4")
