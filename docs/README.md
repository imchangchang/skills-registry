# Vibe Coding 文档

本文档提供 Vibe Coding 方法论的原则性指导。具体操作细节请参考对应 Skill。

## 快速导航

| 文档 | 内容 | 对应 Skill |
|------|------|-----------|
| [overview.md](overview.md) | 什么是 Vibe Coding | - |
| [methodology.md](methodology.md) | 三大理念、双层结构、三种约定 | `vibe-coding/core` |
| [architecture.md](architecture.md) | 四层架构设计 | `vibe-coding/core` |
| [workflow.md](workflow.md) | 四阶段实施流程 | `vibe-coding/skill-evolution` |
| [skill-design.md](skill-design.md) | Skill 设计原则 | `skill-creator` |
| [glossary.md](glossary.md) | 术语表 | - |

## 核心理念

Vibe Coding 的核心是：**开发者通过自然语言描述需求，AI 工具负责具体的代码实现**。

### 三大原则

1. **约定优于配置** - SKILL 是强制执行的工作约定
2. **渐进式披露** - AI 按需加载信息
3. **学习中演进** - 被动式经验沉淀

### 双层结构

- **能力层**：知识积累（主动学习 + 实践沉淀）
- **交付层**：项目迭代（需求 → 方案 → 实现 → 验收）

## 开始使用

1. **了解概念**：阅读 [overview.md](overview.md) 和 [methodology.md](methodology.md)
2. **查看架构**：阅读 [architecture.md](architecture.md)
3. **实施项目**：参考 [workflow.md](workflow.md) 和 `vibe-coding/skill-evolution`
4. **创建 Skill**：参考 [skill-design.md](skill-design.md) 和 `skill-creator`

## 重要 Skill 索引

| Skill | 用途 |
|-------|------|
| `vibe-coding/core` | 全局约定、核心概念、Skill-Set 机制 |
| `vibe-coding/multi-agent-safety` | Git 安全规则、推送确认流程 |
| `vibe-coding/session-management` | 会话管理、上下文恢复 |
| `vibe-coding/skill-evolution` | Skill 沉淀流程、项目与中央仓库关系 |
| `vibe-coding/skill-testing` | Skill 测试验证、质量保障 |
| `dev-workflow/git-commits` | 提交规范、Commit Message 格式 |
| `dev-workflow/quality-gates` | 质量门禁、检查流程 |

## 原则声明

本文档只包含**原则性内容**，所有**具体操作细节**都在对应 Skill 中定义。

这种设计确保：
- 原则稳定，不轻易变更
- 操作流程可迭代优化
- 实际执行由 Skill 指导
