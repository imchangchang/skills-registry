# Progressive Pipeline Architecture - 快速参考

## 🎯 核心口诀

> **"数据资产是核心，输入输出要显式，默认增量省时间，渐进复杂不着急"**

---

## 📋 设计检查清单

### 开始设计前
- [ ] 列出所有数据资产 (输入、中间、输出)
- [ ] 画出转换依赖图
- [ ] 识别哪些阶段计算成本高 (需要缓存)
- [ ] 识别副作用 (数据库/文件/API 写入)

### 定义阶段时
- [ ] 阶段名是否描述产出的资产？(`generate_X` 而非 `run_X`)
- [ ] 输入是否显式声明来源？
- [ ] 输出类型是否明确？
- [ ] 是否有副作用？是否可隔离？

### 优化时
- [ ] 是否支持增量执行？(修改 Stage N 不需要重跑 1~N-1)
- [ ] 是否可独立测试每个阶段？
- [ ] 失败时是否能从断点恢复？
- [ ] 产物是否可观测？(血缘、版本)

---

## 🧱 三阶段标准模板

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   INGEST    │ →→→ │  TRANSFORM  │ →→→ │   DELIVER   │
│   摄入阶段   │     │   转换阶段   │     │   交付阶段   │
├─────────────┤     ├─────────────┤     ├─────────────┤
│ • 数据获取   │     │ • 清洗/处理  │     │ • 格式化    │
│ • 格式验证   │     │ • 分析/计算  │     │ • 存储输出  │
│ • 最小转换   │     │ • 模型推理   │     │ • 触发下游  │
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 🔄 阶段契约模板

```yaml
Stage: {stage_name}
Version: 1.0.0  # 版本变更触发缓存失效

Purpose: |
  一句话描述这个阶段做什么

Input:
  {input_name}:
    type: {DataType}
    from: {upstream_stage}.{output_name}
    description: 输入描述

Output:
  {output_name}:
    type: {DataType}
    description: 输出描述
    persistence: required  # required/cached/ephemeral

SideEffects:
  - {type}: {description}  # None 表示纯转换

Resources:
  cpu: {cores}
  memory: {GB}
  gpu: {optional}
  timeout: {seconds}
```

---

## ⚡ 常见模式速查

### 顺序执行
```
A → B → C
```

### 并行分支
```
    → B ─┐
A ──┬→ C ─┼→ E
    → D ─┘
```

### 条件分支
```
A → (condition ? B : C) → D
```

### 动态展开
```
items = [1, 2, 3]
A → items.map(B) → C  # 展开为 B(1), B(2), B(3) 后合并
```

---

## 🔑 缓存键设计

```
Cache Key = hash(
    stage_name +
    stage_version +
    input_hash +
    config_hash
)
```

**触发重算的条件**:
- 阶段代码版本变化
- 输入内容变化
- 配置参数变化

---

## 🏃 执行模式选择

### 决策树

```
选择执行模式
    │
    ├── 数据量 > 100MB ?
    │       ├── Yes → 函数方式（避免序列化开销）
    │       └── No → 继续判断
    │
    ├── 可能崩溃/外部调用 ?
    │       ├── Yes → 进程方式（崩溃隔离）
    │       └── No → 继续判断
    │
    ├── 需要不同 Python 版本 ?
    │       ├── Yes → 进程方式（环境隔离）
    │       └── No → 继续判断
    │
    └── 默认 → 函数方式（开发体验优先）
```

### 模式对比

| 维度 | 函数方式 | 进程方式 |
|------|----------|----------|
| **性能** | ⭐⭐⭐ 最优 | ⭐⭐ 有序列化开销 |
| **调试** | ⭐⭐⭐ pdb 直接断点 | ⭐⭐ 依赖日志 |
| **隔离** | ⭐ 共享内存 | ⭐⭐⭐ 完全隔离 |
| **并行** | ⭐ GIL 限制 | ⭐⭐⭐ 真并行 |
| **启动** | ⭐⭐⭐ 无开销 | ⭐ 有进程启动开销 |

### 推荐配置

| 场景 | 推荐模式 | 理由 |
|------|----------|------|
| 视频/图像处理 | 函数 | 数据量大，避免序列化 |
| ML 模型推理 | 函数 | 模型权重传递成本高 |
| 外部 API 调用 | 进程 | 超时/失败隔离 |
| 数据清洗 | 函数 | 纯计算，数据量大 |
| 文件格式转换 | 函数 | IO 密集型 |

---

## 📦 数据传递策略

### 黄金法则

> **"传递引用，而非数据本身"**

### 决策矩阵

| 数据大小 | 传递方式 | 示例 |
|----------|----------|------|
| < 1MB | 直接内存传递 | 配置、元数据 |
| 1MB - 100MB | 序列化传递 | 文本、小图片 |
| > 100MB | 传递引用（路径/URI） | 视频、大模型、批量数据 |
| 流式数据 | 生成器/迭代器 | 日志流、实时数据 |

### 代码示例

```python
# ❌ 坏：传递实际数据
@stage
def stage1():
    video_data = load_video("big_file.mp4")  # 2GB
    return {"video": video_data}  # 序列化 2GB！

# ✅ 好：传递引用
@stage(outputs={"video_path": FileRef})
def stage1():
    video_path = "big_file.mp4"
    return {"video_path": FileRef(path=video_path)}

@stage(inputs={"video_path": "stage1.video_path"})
def stage2(video_path: FileRef):
    stream_process(video_path.path)  # 按需流式读取
```

---

## ⚡ 自动并行化

### DAG 波次执行

```
Wave 1: A          → 顺序（无依赖）
Wave 2: B, C       → 并行（依赖已满足，互不依赖）
Wave 3: D, E       → 并行
Wave 4: F          → 顺序（等待 D,E）
```

### 识别并行机会

```python
@pipeline
def workflow():
    a = stage_a()
    
    # ✅ 可以并行：B 和 C 都依赖 A，但互不依赖
    b = stage_b(a)  # ┐
    c = stage_c(a)  # ┘ Wave 2
    
    # ✅ 可以并行：D 依赖 B，E 依赖 C，互不依赖
    d = stage_d(b)  # ┐
    e = stage_e(c)  # ┘ Wave 3
    
    # ❌ 必须顺序：F 依赖 D 和 E
    f = stage_f(d, e)  # Wave 4
```

### 并行度配置

```yaml
parallel:
  strategy: wave_based    # wave_based / greedy / sequential
  max_workers: 4          # 最大并行度，默认 CPU 核心数
  per_stage:              # 阶段级配置
    analyze_images:
      max_workers: 8      # 图片分析可高度并行
```

---

## 🚫 反模式速查

| 反模式 | 症状 | 解决 |
|--------|------|------|
| 大泥球 | 一个 Stage 做所有事 | 拆分为 3-7 个专注的 Stages |
| 隐式依赖 | 依赖未显式声明 | 所有依赖必须显式写入契约 |
| 副作用扩散 | 到处读写数据库 | 纯转换与副作用分离 |
| 过度工程 | 简单任务复杂编排 | 从简单开始，需要时再增加 |
| 大数据序列化 | 传递 GB 级数据对象 | 传递引用，按需读取 |

---

## 💡 决策树

```
开始设计管道
    │
    ▼
任务是否简单？(线性，无分支)
    │
    ├── Yes → 用简单函数/脚本即可
    │           (不需要 Pipeline 框架)
    │
    └── No → 是否需要复用中间产物？
                │
                ├── Yes → 是否需要团队协作/远程执行？
                │           │
                │           ├── Yes → 完整 Pipeline 框架
                │           │               (缓存 + 远程 + UI)
                │           │
                │           └── No → 轻量级 Pipeline
                │                           (本地 + 文件缓存)
                │
                └── No → 简单编排即可
                                (make/airflow-lite)
```

---

## 📝 代码风格指南

### 命名约定
```python
# ✅ 好: 描述产出的资产
def extract_audio_from_video(video_path) -> AudioAsset

def transcribe_audio(audio: AudioAsset) -> TranscriptAsset

def generate_markdown_document(transcript: TranscriptAsset) -> DocumentAsset

# ❌ 差: 描述动作或任务
def run_audio_extraction(video_path)

def do_transcription(audio)

def task_3(transcript)
```

### 输入输出风格
```python
# ✅ 好: 显式输入输出，无副作用
@stage(
    inputs={"video": "previous_stage.video_output"},
    outputs={"audio": AudioAsset, "metadata": MetadataAsset}
)
def extract_audio(video: VideoAsset) -> dict:
    audio = process(video)
    meta = extract_metadata(video)
    return {"audio": audio, "metadata": meta}

# ❌ 差: 隐式输入，副作用
@stage
def extract_audio():
    video = read_from_some_global_path()  # 隐式输入
    audio = process(video)
    write_to_disk(audio)  # 副作用
    update_database()  # 副作用
```

---

## 🎨 思维模型

### 管道即工厂流水线

```
原材料入库 → 加工站1 → 加工站2 → 成品出库
   │            │          │          │
   ▼            ▼          ▼          ▼
Input      Stage 1     Stage 2    Output
Asset      Transform   Transform  Asset

每个加工站:
- 有明确的输入规格
- 有明确的输出规格
- 可独立检修测试
- 产品可追溯
```

### 管道即函数组合

```
Pipeline = f3 ∘ f2 ∘ f1

其中:
- f1: Input → Intermediate1
- f2: Intermediate1 → Intermediate2
- f3: Intermediate2 → Output

每个函数都是纯函数 (无副作用)
组合产生完整数据流
```

---

## 🔗 与其他概念映射

| 概念 | Pipeline 对应 |
|------|---------------|
| 函数式编程 | Stage = 纯函数，Pipeline = 函数组合 |
| OOP | Stage = 类，Input/Output = 接口契约 |
| 微服务 | Stage = 服务，Pipeline = 服务编排 |
| Make | Stage = Rule，Asset = File |
| React | Stage = Component，Asset = Props/State |

---

## ✨ 黄金法则

1. **先画数据流图，再写代码**
2. **每个 Stage 只做一件事，做好一件事**
3. **输入输出显式声明，不要隐式依赖**
4. **产物版本化，执行可重现**
5. **从简单开始，只在需要时增加复杂度**
6. **传递引用，而非数据本身**
7. **崩溃隔离，大数据用函数，不稳定用进程**

---

> **"如果你不能画出数据流图，说明你还没想明白。"**
