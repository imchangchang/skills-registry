---
name: video-processing
description: 视频处理最佳实践，包含 FFmpeg、OpenCV 和关键帧提取。
created: 2026-02-12
status: stable
---

# 视频处理最佳实践

## 概述

视频处理开发最佳实践，包含 FFmpeg、OpenCV 和关键帧提取。

## 适用场景

- 视频分析和处理
- 关键帧提取
- 图像预筛选
- 视频转码

## 核心技术栈

- **ffmpeg-python**: FFmpeg 封装
- **opencv-python**: 图像处理
- **Pillow**: 图像操作

## FFmpeg 基础

### 提取音频
```python
import ffmpeg

ffmpeg.input("video.mp4").output("audio.wav", vn=None, acodec="pcm_s16le", ar=16000, ac=1).run()
```

### 提取关键帧
```python
ffmpeg.input("video.mp4").filter('fps', fps=1/30).output("frame_%04d.jpg").run()
```

### 获取视频信息
```python
probe = ffmpeg.probe("video.mp4")
video_info = next(s for s in probe['streams'] if s['codec_type'] == 'video')
duration = float(video_info['duration'])
width = int(video_info['width'])
height = int(video_info['height'])
```

## OpenCV 基础

### 读取和显示
```python
import cv2

# 读取视频
cap = cv2.VideoCapture("video.mp4")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    # 处理帧
    
cap.release()
```

### 图像预筛选
```python
def is_interesting_frame(frame):
    """判断帧是否包含有价值内容"""
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # 边缘检测
    edges = cv2.Canny(gray, 50, 150)
    edge_ratio = np.count_nonzero(edges) / edges.size
    
    # 变化率检测（对比相邻帧）
    # ...
    
    return edge_ratio > threshold
```

### 直方图比较
```python
def compare_frames(frame1, frame2):
    """比较两帧的相似度"""
    hist1 = cv2.calcHist([frame1], [0], None, [256], [0, 256])
    hist2 = cv2.calcHist([frame2], [0], None, [256], [0, 256])
    return cv2.compareHist(hist1, hist2, cv2.HISTCMP_CORREL)
```

## 关键帧提取策略

### 基于时间间隔
```python
def extract_keyframes(video_path, interval_sec=30):
    """按时间间隔提取关键帧"""
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    interval_frames = int(fps * interval_sec)
    
    frames = []
    frame_count = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if frame_count % interval_frames == 0:
            frames.append(frame)
        frame_count += 1
    
    cap.release()
    return frames
```

### 基于场景变化
```python
def extract_scenes(video_path, threshold=0.7):
    """基于场景变化提取关键帧"""
    cap = cv2.VideoCapture(video_path)
    prev_frame = None
    keyframes = []
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        if prev_frame is not None:
            similarity = compare_frames(prev_frame, frame)
            if similarity < threshold:  # 场景变化
                keyframes.append(frame)
        else:
            keyframes.append(frame)
            
        prev_frame = frame
    
    cap.release()
    return keyframes
```

## 待完善
- [ ] 添加完整处理流程示例
- [ ] 补充性能优化技巧
- [ ] 补充多线程处理
- [ ] 补充 GPU 加速
