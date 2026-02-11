---
name: session-management
description: Vibe Coding 会话管理规范，包含 session 记录保存、上下文恢复、.ai-context 目录使用规范。适用于所有 Vibe Coding 项目的 AI 协作开发。
created: 2024-01-15
status: draft
---

# Session 管理规范

## 适用场景

- 需要保存开发会话上下文供后续恢复
- 多阶段开发需要保持连续性
- 多 AI 代理协作需要共享上下文
- 项目初始化时需要恢复之前的决策记录

## 核心概念

### 什么是 Session？

Session（会话）是一次完整的开发活动记录，包含：
- 开发目标和范围
- 关键决策和理由
- 遇到的问题和解决方案
- 下一步计划

### 为什么需要 Session 管理？

1. **连续性**: 中断后可以恢复上下文
2. **可追溯**: 理解决策的历史演进
3. **可共享**: 多个 AI 代理可以读取相同上下文
4. **可审计**: 回顾开发过程中的关键节点

## 目录结构规范

### .ai-context/ 目录

所有 Vibe Coding 项目应该在根目录创建 `.ai-context/`：

```
project-root/
├── .ai-context/              # AI 上下文目录
│   ├── session-2024-01-15.md # 具体会话记录
│   ├── session-2024-01-20.md # 另一个会话
│   └── README.md             # 索引说明
├── AGENTS.md                 # 引用 session
└── .gitignore                # 忽略 .ai-context/
```

### 与 docs/ 的区别

| 目录 | 用途 | 受众 |
|------|------|------|
| `.ai-context/` | Session 记录、临时上下文 | AI 助手 |
| `docs/` | 正式文档、用户指南 | 人类开发者 |

## Session 文件格式

### 命名规范

```
session-YYYY-MM-DD.md
session-YYYY-MM-DD-[brief-description].md

示例:
session-2024-01-15.md
session-2024-01-15-init-project.md
```

### 内容结构

```markdown
# Session 标题

**日期**: YYYY-MM-DD
**主题**: 一句话描述
**状态**: 进行中 | 已完成 | 已暂停

## 会话目标

本次开发要实现的目标。

## 核心决策

### 决策 1: [标题]
**决策内容**: 具体决策
**理由**: 为什么做这个决策
**替代方案**: 考虑过但放弃的方案

## 实施记录

### 已完成
- [x] 任务 1
- [x] 任务 2

### 待办
- [ ] 任务 3
- [ ] 任务 4

## 遇到的问题

### 问题 1: [描述]
**现象**: 具体表现
**原因**: 根本原因
**解决**: 解决方案

## 下一步计划

1. 接下来要做什么
2. 预期的挑战
3. 需要的资源

## 备注

其他需要记录的信息。
```

## 使用流程

### 1. 创建 Session

开发开始前或进行中：

```bash
# 创建 session 文件
cat > .ai-context/session-$(date +%Y-%m-%d).md << 'EOF'
# Session $(date +%Y-%m-%d)

**日期**: $(date +%Y-%m-%d)
**主题**: [待填写]
**状态**: 进行中

## 会话目标
[描述本次开发目标]

## 核心决策
[记录关键决策]

## 下一步
[待办事项]
EOF
```

### 2. 在 AGENTS.md 中引用

```markdown
## AI 助手须知

**进入本项目时，请读取以下文件恢复上下文**：
- `.ai-context/session-YYYY-MM-DD.md` - 最新会话记录

**读取后请确认**：
1. 理解当前开发目标
2. 了解已做出的关键决策
3. 明确下一步任务
```

### 3. 让 AI 读取 Session

开发者告诉 AI：
```
请读取 .ai-context/session-2024-01-15.md 恢复上下文
```

或 AI 自动检测：
```
发现 .ai-context/ 目录，读取最新 session...
```

### 4. 更新 Session

开发过程中持续更新：
- 记录新决策
- 标记完成的任务
- 添加遇到的问题

### 5. 归档 Session

Session 结束后：
- 更新状态为 "已完成"
- 创建新的 session 文件继续后续开发
- 重要决策迁移到正式文档

## .gitignore 配置

必须添加 `.ai-context/` 到 `.gitignore`：

```gitignore
# Vibe Coding Session 记录
.ai-context/
```

原因：
- Session 是临时性的 AI 上下文
- 可能包含未整理的想法
- 正式文档应该放在 docs/

## 最佳实践

### DO（推荐）

- [OK] 每次重要开发前创建 session 文件
- [OK] 在 AGENTS.md 中引用最新 session
- [OK] 使用清晰的标题和日期
- [OK] 记录决策的理由，不只是结果
- [OK] 定期归档，重要内容迁移到 docs/

### DON'T（避免）

- [X] 不要把 session 当作正式文档
- [X] 不要提交 session 到版本控制
- [X] 不要在一个 session 中记录太多不相关的内容
- [X] 不要忘记更新状态（进行中/已完成）

## 示例

### 场景：初始化项目

**开发者**: "我要创建一个 ROS2 导航项目"

**AI**: "请确认项目路径，我将创建 session 记录"

**生成的 session-2024-01-15.md**:
```markdown
# ROS2 导航项目初始化

**日期**: 2024-01-15
**主题**: ROS2 Navigation2 项目脚手架搭建
**状态**: 进行中

## 会话目标

1. 创建 ROS2 工作空间
2. 配置 Navigation2
3. 设置 SLAM 和定位

## 核心决策

### 决策 1: 使用 Nav2 而非自定义
**决策**: 使用 Navigation2 官方框架
**理由**: 减少开发工作量，社区支持好
**替代方案**: 自行实现路径规划（工作量太大）

## 下一步

- [ ] 创建 workspace
- [ ] 配置 nav2_bringup
- [ ] 测试仿真环境
```

## 相关文件

- `patterns/session-template.md` - Session 文件模板
- `patterns/agents-with-session.md` - 引用 session 的 AGENTS.md 模板

## 迭代记录

- 2024-01-15: 初始创建
