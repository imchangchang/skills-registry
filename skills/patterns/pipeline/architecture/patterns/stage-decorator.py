"""
Stage Decorator 模式

使用装饰器定义管道阶段。
"""

from functools import wraps
from typing import Callable, Any
import time


class Stage:
    """阶段装饰器"""
    
    def __init__(self, name: str = None, cache: bool = False):
        self.name = name
        self.cache = cache
        self._cached_result = None
    
    def __call__(self, func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            if self.cache and self._cached_result is not None:
                return self._cached_result
            
            result = func(*args, **kwargs)
            
            if self.cache:
                self._cached_result = result
            
            return result
        
        wrapper._stage_name = self.name or func.__name__
        wrapper._stage_cache = self.cache
        return wrapper


# 使用示例
@Stage(name="extract", cache=True)
def extract_data(source: str) -> dict:
    """数据提取阶段"""
    print(f"Extracting from {source}")
    return {"raw": f"data from {source}"}


@Stage(name="transform")
def transform_data(data: dict) -> dict:
    """数据转换阶段"""
    return {"processed": data["raw"].upper()}


@Stage(name="load")
def load_data(data: dict) -> str:
    """数据加载阶段"""
    return f"Saved: {data['processed']}"


# 手动组合管道
def run_pipeline(source: str) -> str:
    step1 = extract_data(source)
    step2 = transform_data(step1)
    step3 = load_data(step2)
    return step3


if __name__ == "__main__":
    result = run_pipeline("input.txt")
    print(result)
