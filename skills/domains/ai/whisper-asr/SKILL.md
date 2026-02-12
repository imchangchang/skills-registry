---
name: whisper-asr
description: Whisper 语音识别最佳实践。涵盖模型选择、本地部署、性能优化和结果后处理。
created: 2026-02-12
status: stable
---

# Whisper 语音识别

> 使用 Whisper.cpp 进行本地语音识别的技术要点

## 适用场景

- 本地语音转文字（隐私敏感）
- 批量音频处理
- 实时/准实时语音识别

## 模型选择

| 模型 | 大小 | 速度 | 准确率 | 推荐场景 |
|-----|------|------|--------|---------|
| tiny | 39 MB | 最快 | 一般 | 快速测试 |
| base | 94 MB | 快 | 较好 | 实时应用 |
| small | 244 MB | 中等 | 好 | 平衡选择 |
| medium | 786 MB | 慢 | 很好 | **生产推荐** |
| large | 1.5 GB | 最慢 | 最好 | 高精度需求 |

## 核心概念

### 本地部署优势

- 隐私：数据不出本地
- 成本：无 API 调用费用
- 速度：无网络延迟

### 性能优化

- 使用 GPU 加速（如果可用）
- 合适的模型大小选择
- 音频预处理（降噪、重采样）

## 快速开始

```python
import subprocess
from pathlib import Path

def transcribe(audio_path: Path, model: str = "medium") -> str:
    """使用 Whisper.cpp 进行转录"""
    cmd = [
        "./whisper-cli",
        "-m", f"models/ggml-{model}.bin",
        "-f", str(audio_path),
        "--language", "zh",
        "--output-txt"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout
```

## 迭代记录

- 2026-02-12: 初始创建，沉淀 Whisper 本地部署经验
