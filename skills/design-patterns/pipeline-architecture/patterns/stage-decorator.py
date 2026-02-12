#!/usr/bin/env python3
"""
Stage 装饰器模式

使用 Python 装饰器简化 Stage 定义
"""

import functools
import hashlib
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Optional
from datetime import datetime


# ============ 核心类型 ============

@dataclass
class StageMeta:
    """Stage 元数据"""
    name: str
    version: str
    inputs: dict = field(default_factory=dict)
    outputs: dict = field(default_factory=dict)
    side_effects: list = field(default_factory=list)


@dataclass
class StageResult:
    """Stage 执行结果"""
    stage_name: str
    data: dict
    artifacts: list[Path] = field(default_factory=list)
    meta: dict = field(default_factory=dict)


# ============ Stage 装饰器 ============

def stage(
    name: Optional[str] = None,
    version: str = "1.0.0",
    inputs: Optional[dict] = None,
    outputs: Optional[dict] = None,
    side_effects: Optional[list] = None
):
    """
    Stage 装饰器
    
    使用方式：
        @stage(
            name="extract_text",
            version="1.0.0",
            inputs={"pdf_path": str},
            outputs={"text": str, "metadata": dict}
        )
        def extract_text(pdf_path: str) -> dict:
            # 实现...
            return {"text": "...", "metadata": {}}
    
    Args:
        name: Stage 名称，默认使用函数名
        version: 版本号，变更时触发缓存失效
        inputs: 输入契约 {参数名: 类型}
        outputs: 输出契约 {返回值字段: 类型}
        side_effects: 副作用列表
    """
    def decorator(func: Callable) -> Callable:
        stage_name = name or func.__name__
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> StageResult:
            # 构建输入字典用于哈希计算
            input_dict = {
                "args": args,
                "kwargs": kwargs
            }
            
            # 计算输入哈希（用于缓存）
            input_hash = _compute_hash(input_dict)
            
            # 执行前记录
            start_time = datetime.now()
            print(f"[{stage_name}] Starting execution...")
            print(f"[{stage_name}] Input hash: {input_hash[:16]}")
            
            # 执行函数
            result_data = func(*args, **kwargs)
            
            # 执行后记录
            duration = (datetime.now() - start_time).total_seconds()
            print(f"[{stage_name}] Completed in {duration:.2f}s")
            
            # 包装为 StageResult
            return StageResult(
                stage_name=stage_name,
                data=result_data if isinstance(result_data, dict) else {"result": result_data},
                meta={
                    "version": version,
                    "input_hash": input_hash,
                    "duration_seconds": duration,
                    "executed_at": datetime.now().isoformat()
                }
            )
        
        # 附加元数据到函数
        wrapper._stage_meta = StageMeta(
            name=stage_name,
            version=version,
            inputs=inputs or {},
            outputs=outputs or {},
            side_effects=side_effects or []
        )
        wrapper._is_stage = True
        
        return wrapper
    return decorator


def _compute_hash(obj: Any) -> str:
    """计算对象的哈希值"""
    try:
        json_str = json.dumps(obj, sort_keys=True, default=str)
        return hashlib.sha256(json_str.encode()).hexdigest()
    except (TypeError, ValueError):
        return hashlib.sha256(str(obj).encode()).hexdigest()


# ============ 使用示例 ============

@stage(
    name="extract_audio",
    version="1.0.0",
    inputs={"video_path": str},
    outputs={"audio_path": str, "duration": float}
)
def extract_audio(video_path: str) -> dict:
    """从视频提取音频"""
    # 模拟处理
    print(f"  Extracting audio from: {video_path}")
    
    audio_path = video_path.replace(".mp4", ".wav")
    
    return {
        "audio_path": audio_path,
        "duration": 120.5  # 假设的时长
    }


@stage(
    name="transcribe",
    version="1.0.0",
    inputs={"audio_path": str},
    outputs={"text": str, "segments": list},
    side_effects=["api_call"]
)
def transcribe(audio_path: str) -> dict:
    """语音识别（可能有副作用：API 调用）"""
    print(f"  Transcribing: {audio_path}")
    
    # 模拟 API 调用
    return {
        "text": "Hello world, this is a test transcription.",
        "segments": [
            {"start": 0.0, "end": 2.5, "text": "Hello world"},
            {"start": 2.5, "end": 5.0, "text": "this is a test"}
        ]
    }


@stage(
    name="analyze_sentiment",
    version="1.0.0",
    inputs={"text": str},
    outputs={"sentiment": str, "score": float}
)
def analyze_sentiment(text: str) -> dict:
    """情感分析"""
    print(f"  Analyzing sentiment: {text[:50]}...")
    
    # 模拟分析
    return {
        "sentiment": "positive",
        "score": 0.85
    }


# ============ 管道组合 ============

def create_pipeline():
    """创建简单的顺序管道"""
    
    def pipeline(video_path: str):
        """视频处理管道"""
        # Stage 1: 提取音频
        audio_result = extract_audio(video_path)
        
        # Stage 2: 语音识别
        transcript_result = transcribe(audio_result.data["audio_path"])
        
        # Stage 3: 情感分析
        sentiment_result = analyze_sentiment(transcript_result.data["text"])
        
        return {
            "audio": audio_result,
            "transcript": transcript_result,
            "sentiment": sentiment_result
        }
    
    return pipeline


# ============ 并行分支示例 ============

@stage(name="extract_frames", version="1.0.0")
def extract_frames(video_path: str, interval: int = 5) -> dict:
    """提取视频帧"""
    print(f"  Extracting frames from: {video_path}")
    return {
        "frame_paths": [f"frame_{i}.jpg" for i in range(10)],
        "interval": interval
    }


@stage(name="detect_scenes", version="1.0.0")
def detect_scenes(video_path: str) -> dict:
    """场景检测"""
    print(f"  Detecting scenes in: {video_path}")
    return {
        "scene_changes": [0.0, 15.5, 32.0, 58.5]
    }


def parallel_analysis_pipeline(video_path: str):
    """
    并行分析管道
    
    extract_frames 和 detect_scenes 都依赖 video_path，但互不依赖
    可以并行执行
    """
    from concurrent.futures import ThreadPoolExecutor
    
    print("=" * 50)
    print("Wave 1: Parallel Analysis")
    print("=" * 50)
    
    with ThreadPoolExecutor(max_workers=2) as executor:
        # 提交两个独立的任务
        future_frames = executor.submit(extract_frames, video_path)
        future_scenes = executor.submit(detect_scenes, video_path)
        
        # 等待两者完成
        frames_result = future_frames.result()
        scenes_result = future_scenes.result()
    
    return {
        "frames": frames_result,
        "scenes": scenes_result
    }


# ============ 主程序 ============

if __name__ == "__main__":
    print("=" * 50)
    print("Stage Decorator Pattern Demo")
    print("=" * 50)
    
    # 示例 1: 顺序管道
    print("\n[示例 1] 顺序管道")
    pipeline = create_pipeline()
    results = pipeline("./video.mp4")
    
    print("\n" + "-" * 50)
    print("Results:")
    for name, result in results.items():
        print(f"  {name}: {list(result.data.keys())}")
    
    # 示例 2: 并行分支
    print("\n[示例 2] 并行分支")
    parallel_results = parallel_analysis_pipeline("./video.mp4")
    
    print("\n" + "-" * 50)
    print("Parallel Results:")
    for name, result in parallel_results.items():
        print(f"  {name}: {list(result.data.keys())}")
