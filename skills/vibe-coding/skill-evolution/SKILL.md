---
name: skill-evolution
description: Skill 演化与沉淀指南。定义从项目实践中提取知识、更新 Skill 的完整流程。回答"如何沉淀 skill"的唯一入口。
created: 2026-02-12
status: stable
tags: [vibe-coding, skill-management, evolution]
---

# Skill 演化指南

> 回答"如何沉淀 skill"的唯一入口
> 
> **核心原则**：简单直接，根据场景选择合适的方式

## 快速决策

```
用户问：怎么沉淀 skill？
    │
    ├── 已有 Skill，发现需要补充/修正？
    │       └── Yes → 方式 1：直接编辑（推荐）
    │
    ├── 想从当前项目提炼新知识？
    │       └── Yes → 方式 2：项目提取
    │
    └── 要创建全新的 Skill？
            └── Yes → 方式 3：新建 Skill
```

---

## 方式 1：直接编辑（已有 Skill，快速修复）

**适用场景**：
- 发现现有 Skill 有错误
- 需要补充一个小细节
- 修正代码示例

**执行步骤**：

```bash
# 1. 进入技能仓库
cd ~/skills-registry

# 2. 直接编辑对应 skill
vim skills/<category>/<skill-name>/SKILL.md

# 3. 更新 HISTORY.md
echo "- $(date +%Y-%m-%d): 修正 xxx" >> skills/<category>/<skill-name>/HISTORY.md

# 4. 提交
git add .
git commit -m "fix(<skill-name>): 修正 xxx"
```

**示例**：
```bash
# 修正 stm32 skill 的 GPIO 示例
cd ~/skills-registry
vim skills/embedded/mcu/st-stm32/SKILL.md
git commit -m "fix(stm32): 修正 GPIO 时钟使能顺序"
```

---

## 方式 2：项目提取（从实践提炼）

**适用场景**：
- 项目中积累了新经验
- 发现现有 Skill 缺失重要内容
- 想系统性地贡献改进

**执行步骤**：

### 步骤 1：项目内记录

在 `.vibe/.skill-updates-todo.md` 记录：

```markdown
## 待办

- [ ] stm32: 补充 DMA 双缓冲配置
  发现时间：2026-02-12
  项目：my-robot
  问题描述：H7 DMA 双缓冲需要特殊配置
  建议方案：在常见问题中添加 H7 DMA 章节
```

### 步骤 2：提取到技能仓库

```bash
# 1. 进入技能仓库
cd ~/skills-registry

# 2. 编辑对应 skill
vim skills/<category>/<skill-name>/SKILL.md

# 3. 在 HISTORY.md 记录来源
cat >> skills/<category>/<skill-name>/HISTORY.md << 'EOF'
## 2026-02-12: 补充 DMA 双缓冲（来自 my-robot 项目）

**变更**: 添加 H7 DMA 双缓冲配置说明

**来源项目**: my-robot
**问题**: H7 DMA 双缓冲需要特殊配置
**解决**: 添加配置示例和常见问题
EOF

# 4. 提交
git add .
git commit -m "feat(stm32): 补充 H7 DMA 双缓冲配置

- 添加 DMA 配置示例代码
- 添加常见问题章节
- 来自 my-robot 项目实践经验"
```

---

## 方式 3：新建 Skill（全新领域）

**适用场景**：
- 现有技能库没有覆盖的领域
- 需要创建全新的知识模块
- 项目特定的复杂工作流

**执行步骤**：

### 步骤 1：确定分类

```
skills/
├── vibe-coding/     # Vibe Coding 核心
├── dev-workflow/    # 开发工作流
├── embedded/        # 嵌入式
├── software/        # 软件
└── design-patterns/ # 设计模式
```

### 步骤 2：创建目录结构

```bash
# 进入技能仓库
cd ~/skills-registry

# 创建新 skill 目录
mkdir -p skills/<category>/<skill-name>
cd skills/<category>/<skill-name>

# 创建基本文件
touch SKILL.md HISTORY.md metadata.json
mkdir -p patterns references
```

### 步骤 3：编写 SKILL.md

```markdown
---
name: <skill-name>
description: |
  清晰的描述，说明：
  1. 这是什么 skill
  2. 在什么场景下使用
  3. 核心解决什么问题
  关键词：xxx, yyy, zzz
created: 2026-02-12
status: draft
---

# <Skill 标题>

## 适用场景
描述在什么情况下使用此 skill

## 核心概念
- 概念 1：简要说明
- 概念 2：简要说明

## 快速开始
最简示例，让 AI 快速理解如何使用

## 详细流程
### 步骤 1：xxx
...

## 常见问题
### 问题 1：xxx
**现象**：...
**原因**：...
**解决**：...

## 迭代记录
- 2026-02-12: 初始创建
```

### 步骤 4：编写 metadata.json

```json
{
  "name": "<skill-name>",
  "description": "简短描述",
  "type": "<category>",
  "created": "2026-02-12",
  "status": "draft",
  "tags": ["tag1", "tag2"]
}
```

### 步骤 5：提交

```bash
cd ~/skills-registry
git add skills/<category>/<skill-name>/
git commit -m "feat(<category>): add <skill-name> skill

- 添加 <描述> 的完整指南
- 包含核心概念、快速开始、常见问题
- 初始版本，待实践验证"
```

---

## 关键原则

### DO（推荐）

- [OK] **简单问题直接改**：发现错误，直接编辑提交
- [OK] **项目经验要记录**：在 `.skill-updates-todo.md` 先记录
- [OK] **保持小而精**：一个 Skill 解决一类问题
- [OK] **更新 HISTORY.md**：每次变更都记录

### DON'T（避免）

- [X] **不要为了形式而形式**：简单修正不需要走完整提取流程
- [X] **不要创建空壳 Skill**：没有实践验证的知识不要写
- [X] **不要复制粘贴**：从项目中提炼，而非照搬代码

---

## 与 skill-creator 的关系

**skill-creator**（系统自带）提供创建 skill 的**详细技术指南**。

**本 SKILL** 提供沉淀 skill 的**场景决策和工作流程**。

**分工**：
- 不知道怎么做？→ 看本 SKILL（场景决策）
- 不知道怎么写？→ 看 skill-creator（技术细节）

---

## 迭代记录

- 2026-02-12: 初始创建，统一三种沉淀方式
