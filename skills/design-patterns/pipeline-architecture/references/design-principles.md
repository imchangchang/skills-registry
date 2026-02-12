# Pipeline Architecture - 详细设计原则

本文档详细阐述 Progressive Pipeline Architecture 的五大设计原则。

---

## P1: Asset-First (资产优先)

### 核心理念

管道是**数据资产的转换图**，而非任务的集合。

**思维转变**:
```
Task-Centric:         Asset-Centric:
  "运行任务A"          "生成 cleaned_data"
  "运行任务B"          "基于 cleaned_data 生成 model"
  "运行任务C"          "基于 model 生成 predictions"
```

### 实践要点

**命名聚焦产出**:
```python
# 好的命名：描述产出的资产
def extract_audio_from_video(video_path) -> AudioAsset
def transcribe_audio(audio: AudioAsset) -> TranscriptAsset
def generate_markdown_document(transcript: TranscriptAsset) -> DocumentAsset

# 差的命名：描述动作或任务
def run_audio_extraction(video_path)
def do_transcription(audio)
def task_3(transcript)
```

**产物版本化**: 每个 Asset 都有唯一标识，支持血缘追踪。

**血缘追踪**: 自动记录 Asset 的生产者和消费者。

### 为什么重要

1. **可观测性**：关注资产让数据流向清晰可见
2. **可复用性**：资产是独立的，可在不同管道中复用
3. **可调试性**：可以检查每个中间资产的状态

---

## P2: Explicit Contract (显式契约)

### 核心理念

每个阶段的输入和输出必须显式声明。

### 契约内容

```yaml
Stage: extract_text_from_pdf
  Input:
    - pdf_path: FilePath (来自 user_upload)
  Output:
    - text_content: TextContent
    - metadata: PDFMetadata
  SideEffect: None
  Resources:
    - CPU: 1 core
    - Memory: 512MB
    - Timeout: 30s
```

### 契约要素

| 要素 | 说明 | 示例 |
|------|------|------|
| 输入 | 名称、类型、来源 | `pdf_path: FilePath from user_upload` |
| 输出 | 名称、类型 | `text_content: TextContent` |
| 副作用 | 外部影响 | `db_write`, `api_call`, `file_write` |
| 资源 | 执行需求 | `CPU: 4 cores`, `GPU: 1` |

### 代码实践

```python
# 好的：显式输入输出，无副作用
@stage(
    inputs={"video": "previous_stage.video_output"},
    outputs={"audio": AudioAsset, "metadata": MetadataAsset}
)
def extract_audio(video: VideoAsset) -> dict:
    audio = process(video)
    meta = extract_metadata(video)
    return {"audio": audio, "metadata": meta}

# 差的：隐式输入，副作用
@stage
def extract_audio():
    video = read_from_some_global_path()  # 隐式输入
    audio = process(video)
    write_to_disk(audio)  # 副作用
    update_database()  # 副作用
```

---

## P3: Incremental by Default (默认增量)

### 核心理念

只执行改变的部分，其余从缓存复用。

### 关键机制

**输入指纹**: 基于内容哈希 (Content Hash) 而非时间戳

```python
def compute_cache_key(stage, inputs):
    return hash(
        stage.name +
        stage.version +
        hash_inputs(inputs) +
        hash_config(stage.config)
    )
```

**缓存键组成**:
```
Cache Key = hash(
    stage_name +
    stage_version +
    input_hash +
    config_hash
)
```

**级联失效**:
```
输入变更 → 当前阶段重算 → 下游级联重算
```

### 应用场景

| 场景 | 效果 |
|------|------|
| 开发阶段 | 修改 Stage 3 不需要重跑 Stage 1-2 |
| 调试阶段 | 可以直接加载 Stage 2 的输出检查 |
| 协作阶段 | 团队共享缓存避免重复计算 |

### 触发重算的条件

1. **阶段代码版本变化** - 修改 Stage 实现，version 应更新
2. **输入内容变化** - 输入数据哈希改变
3. **配置参数变化** - 配置影响输出结果

---

## P4: Isolation & Composability (隔离与组合)

### 核心理念

每个阶段是独立的计算单元，可单独测试、可任意组合。

### 隔离级别

| 级别 | 机制 | 强度 |
|------|------|------|
| 进程隔离 | 每个阶段独立进程 | 最强 |
| 环境隔离 | 每个阶段可指定不同依赖环境 | 中 |
| 状态隔离 | 阶段间不共享可变状态 | 基础 |

### 组合模式

**顺序组合**:
```
A → B → C
```

**分支组合**（并行）:
```
    → B ─┐
A ──┬→ C ─┼→ E
    → D ─┘
```

**条件组合**:
```
A → (condition ? B : C) → D
```

**映射组合**（动态展开）:
```
items = [1, 2, 3]
A → items.map(B) → C
# 展开为: B(1), B(2), B(3) 后合并
```

### 测试友好性

每个 Stage 可以：
1. **独立单元测试** - 无需运行完整管道
2. **Mock 输入测试** - 提供假数据测试边界情况
3. **集成测试** - 组合多个 Stages 测试交互

---

## P5: Human-First DX (开发者体验优先)

### 核心理念

工具应该适应人的思维，而非相反。

### 设计选择优先级

| 维度 | 优先 | 次选 | 避免 |
|------|------|------|------|
| 语言 | Python/JavaScript 原生 | DSL | YAML |
| 定义方式 | 装饰器/注解 | 继承 | 接口实现 |
| 部署 | 本地优先 | 云端优先 | - |
| 显式程度 | 显式 > 隐式 | 但合理的默认值可以降低显式成本 | - |

### 为什么 Python 原生优先

```python
# 好的：Python 原生代码
@stage(inputs={"data": "upstream.cleaned"})
def analyze(data: DataFrame) -> dict:
    result = data.groupby("category").sum()
    return {"summary": result}

# 差的：YAML 配置
# pipeline.yaml:
#   stages:
#     - name: analyze
#       function: stages.analyze
#       inputs:
#         data: upstream.cleaned
```

Python 原生的优势：
- **IDE 支持** - 类型检查、自动补全、重构
- **调试友好** - pdb 断点直接可用
- **版本控制** - 代码审查、diff 清晰
- **生态丰富** - 任意 Python 库可用

### 渐进式复杂度

```
Phase 1 (单体):
  def my_flow():
      a = stage_a()
      b = stage_b(a)

Phase 2 (装饰器):
  @stage(outputs={"a": A})
  def stage_a(): ...

Phase 3 (配置分离):
  # 只在需要时引入配置
  pipeline.yaml:
    - stage: a
      function: stages:stage_a

Phase 4 (动态编排):
  # 运行时根据条件动态构建 DAG
```

---

## 五大原则的协同

这五个原则不是独立的，而是相互支撑：

```
Asset-First (关注焦点)
       ↓
Explicit Contract (定义接口)
       ↓
Isolation (确保独立) ←→ Incremental (基于独立性实现缓存)
       ↓
Human-First (让开发者愉快地使用)
```

**示例**: 为什么 Asset-First 使 Incremental 成为可能

- Asset-First 让每个阶段产出明确的数据资产
- Explicit Contract 定义了资产的格式和来源
- 这使得系统可以计算资产的哈希，实现缓存
- 因为 Isolation 确保阶段独立，所以缓存不会污染

---

## 违反原则的后果

| 违反原则 | 后果 |
|----------|------|
| 不 Asset-First | 无法追踪数据流向，难以调试 |
| 不 Explicit Contract | 隐式依赖导致执行顺序不确定 |
| 不 Incremental | 每次都要全量重算，开发效率低 |
| 不 Isolation | 阶段间耦合，无法单独测试 |
| 不 Human-First | 开发者抗拒使用，转回简单脚本 |
