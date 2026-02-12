---
name: opencv-python
description: OpenCV Python 计算机视觉编程要点。图像处理、视频分析、相机接入和常见算法实现。
created: 2026-02-12
status: stable
---

# OpenCV Python 编程

> 计算机视觉基础操作的快速参考

## 适用场景

- 图像/视频处理
- 相机接入和采集
- 简单的计算机视觉任务

## 核心概念

### BGR vs RGB

OpenCV 使用 BGR 格式，注意与其他库的转换：
```python
import cv2
import numpy as np

# BGR → RGB
rgb_image = cv2.cvtColor(bgr_image, cv2.COLOR_BGR2RGB)
```

### 基本操作速查

```python
import cv2

# 读取/保存
img = cv2.imread("input.jpg")
cv2.imwrite("output.png", img)

# 调整大小
resized = cv2.resize(img, (640, 480))

# 灰度转换
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

# 模糊
blurred = cv2.GaussianBlur(img, (5, 5), 0)

# 边缘检测
edges = cv2.Canny(gray, 50, 150)
```

## 视频处理

```python
import cv2

cap = cv2.VideoCapture(0)  # 或视频文件路径

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # 处理帧
    processed = process_frame(frame)
    
    cv2.imshow("Video", processed)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

## 迭代记录

- 2026-02-12: 初始创建，沉淀 OpenCV 常用操作
