---
name: pipeline-architecture
description: 渐进式管道架构 - 构建复杂数据处理工作流的元设计思想，适用于多阶段处理、数据转换、可重复执行的工作流设计
created: 2025-02-12
status: stable
tags: [architecture, data-flow, workflow, design-pattern]
---

# Progressive Pipeline Architecture

> 一种用于构建复杂数据处理工作流的元设计思想
> 
> 核心观点：程序 = 数据资产的转换图

## 适用场景

- 多阶段数据处理（ETL、数据清洗、特征工程）
- AI 生成流程（AIGC、视频处理、文档生成）
- 复杂构建系统（编译、测试、部署）
- 科学计算工作流（模拟、分析、可视化）
- 任何需要**可重复执行**、**中间产物可观测**、**支持增量计算**的任务

## 核心哲学

### 1. 数据流即程序 (Data Flow as Code)

程序的本质是数据的流动和转换，而非代码的执行。

```
复杂程序 = 简单单元的有向组合
```

### 2. 渐进式复杂度 (Progressive Complexity)

从最简单的开始，只在需要时增加复杂度。

```
简单脚本 ──→ 多阶段管道 ──→ 复杂 DAG ──→ 分布式执行
```

**关键洞察**: 80% 的场景只需要 20% 的功能。

### 3. 可观测性即架构 (Observability as Architecture)

如果一个管道不可观测，它就不存在。

- **数据血缘** (Lineage): 数据从哪来，到哪去
- **可重现性** (Reproducibility): 相同输入 → 相同输出
- **可调试性** (Debuggability): 每一步的中间状态可见

## 五大设计原则

| 原则 | 定义 | 实践要点 |
|------|------|----------|
| **P1: Asset-First** | 管道是数据资产的转换图，而非任务集合 | 命名聚焦产出：`generate_cleaned_data` 而非 `run_cleaning_task` |
| **P2: Explicit Contract** | 输入和输出必须显式声明 | 契约包含：名称、类型、来源、副作用 |
| **P3: Incremental by Default** | 只执行改变的部分，其余从缓存复用 | 缓存键：`hash(stage_version + input_hash + config)` |
| **P4: Isolation & Composability** | 每个阶段独立，可单独测试、任意组合 | 支持顺序、分支、条件、映射四种组合模式 |
| **P5: Human-First DX** | Python 原生 > DSL > YAML | 装饰器/注解 > 继承 > 接口实现 |

## 架构模式

### 模式 A: 三阶段标准化

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Ingest    │ →→→ │  Transform  │ →→→ │   Deliver   │
│   (摄入)    │     │   (转换)    │     │   (交付)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

**适用场景**: 几乎所有 ETL 类任务

### 模式 B: 分层缓存

```
Layer 3: Execution Cache  (函数输出，内存级)
Layer 2: Stage Cache      (阶段产物，磁盘级)
Layer 1: Artifact Store   (持久化存储，远程级)
```

### 模式 C: 配置-代码分离

- **配置**: 阶段如何连接、使用什么资源
- **代码**: 阶段具体做什么

### 模式 D: 副作用隔离

纯转换与副作用分离，副作用集中管理。

## 核心概念

| 概念 | 说明 |
|------|------|
| **Stage** | 工作流节点，有明确的输入、输出、执行函数 |
| **Pipeline** | Stage 的有向无环图 (DAG) |
| **Asset** | 数据资产，是 Stage 的产出物 |
| **Run** | 一次完整的执行实例，有唯一的 run_id |
| **Artifact** | Stage 的输出产物，包括序列化数据和附属文件 |
| **Cache** | 基于输入哈希的缓存机制 |

## 关键决策矩阵

### 执行模式选择

| 场景 | 推荐模式 | 理由 |
|------|----------|------|
| 数据量 > 100MB | 函数方式 | 避免序列化开销 |
| 可能崩溃/外部调用 | 进程方式 | 崩溃隔离 |
| 需要不同 Python 版本 | 进程方式 | 环境隔离 |
| 默认 | 函数方式 | 开发体验优先 |

### 数据传递策略

> **黄金法则：传递引用，而非数据本身**

| 数据大小 | 传递方式 | 示例 |
|----------|----------|------|
| < 1MB | 直接内存传递 | 配置、元数据 |
| 1MB - 100MB | 序列化传递 | 文本、小图片 |
| > 100MB | 传递引用（路径/URI） | 视频、大模型 |
| 流式数据 | 生成器/迭代器 | 日志流 |

## 快速开始

### Step 1: 识别数据资产

1. 输入是什么？（文件、API 响应、数据库表）
2. 中间产物有哪些？（清洗后数据、特征、模型）
3. 最终输出是什么？（报告、API 响应、文件）

### Step 2: 绘制转换图

```
Raw Data → Cleaned → Features → Model → Predictions
```

### Step 3: 定义阶段契约

```yaml
Stage: extract_text_from_pdf
Version: 1.0.0
Purpose: 从 PDF 提取文本内容
Input:
  pdf_path: {type: FilePath, from: user_upload}
Output:
  text_content: {type: TextContent}
  metadata: {type: PDFMetadata}
SideEffects: None
```

### Step 4: 实现与迭代

1. 先实现最简单的线性管道
2. 添加缓存机制
3. 添加错误处理
4. 优化性能

## 反模式

| 反模式 | 症状 | 解决 |
|--------|------|------|
| 大泥球管道 | 一个 Stage 做所有事 | 拆分为 3-7 个 focused stages |
| 隐式依赖 | 依赖未显式声明 | 所有依赖写入契约 |
| 副作用扩散 | 到处读写数据库 | 纯转换与副作用分离 |
| 过度工程 | 简单任务复杂编排 | 从简单开始，需要时再增加 |
| 大数据序列化 | 传递 GB 级数据对象 | 传递引用，按需读取 |

## 应用场景矩阵

| 场景 | 核心模式 | 关键考量 |
|------|----------|----------|
| 数据清洗/ETL | 三阶段标准化 | 增量更新、数据质量检查 |
| 机器学习 | Asset-First + 分层缓存 | 实验追踪、模型版本 |
| 文档处理 | 副作用隔离 | 格式转换、多模态处理 |
| API 编排 | 动态展开 | 错误处理、超时控制 |
| 构建系统 | 增量 by Default | 依赖追踪、远程缓存 |
| 科学计算 | 隔离与组合 | 可重现性、环境管理 |
| AIGC 流程 | 条件执行 | 模型选择、成本优化 |

## 代码模式

参见 [patterns/](./patterns/) 目录：

- `three-stage-standard.py` - 三阶段标准模板
- `stage-decorator.py` - Stage 装饰器模式
- `pipeline-executor.py` - 执行引擎骨架

## 参考资料

- [references/quick-ref.md](./references/quick-ref.md) - 速查卡片、决策树
- [references/design-principles.md](./references/design-principles.md) - 详细设计原则
- [references/framework-design.md](./references/framework-design.md) - 框架设计细节
- [references/implementation-guide.md](./references/implementation-guide.md) - 实现指南

## 黄金法则

1. **先画数据流图，再写代码**
2. **每个 Stage 只做一件事，做好一件事**
3. **输入输出显式声明，不要隐式依赖**
4. **产物版本化，执行可重现**
5. **从简单开始，只在需要时增加复杂度**
6. **传递引用，而非数据本身**
7. **崩溃隔离，大数据用函数，不稳定用进程**

---

> **"如果你不能画出数据流图，说明你还没想明白。"**
