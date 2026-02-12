---
name: skill-evolution
description: Skill 演化与提炼规范。定义从项目实践中提取知识、生成 Skill 导入包、融合到 Skill 仓库的标准流程。所有 Vibe Coding 项目都应该遵循此约定进行知识沉淀。
created: 2026-02-12
status: stable
tags: [vibe-coding, skill-management, evolution, knowledge-extraction, convention]
---

# Skill 演化规范

> 从项目实践中提炼知识，让 Skill 持续进化
> 
> **核心原则**：约定优于脚本，AI 按照规范执行，而非依赖自动化工具

## 适用场景

- 项目开发中积累了新的最佳实践，需要沉淀到 Skill
- 发现现有 Skill 的不足，需要增量更新
- 跨项目复用新提炼的知识模式
- 批量管理和更新 Skill 仓库

## AI 助手约定（强制执行）

### [强制] 知识提取流程

当用户要求"提取 Skill"或"更新 Skill"时，AI 必须按照以下流程执行：

#### 步骤 1：扫描项目中的知识来源

**必须检查的位置**（按优先级）：
1. `.vibe/.skill-updates-todo.md` - Skill 更新待办清单
2. `AGENTS.md` 变更历史 - 项目特定的约定
3. `.ai-context/session-*.md` - 会话中的关键决策
4. 代码中的 `TODO(SKILL)` 注释

#### 步骤 2：分析并归类变更

对于每个发现的知识点，确定：
- **目标 Skill**：变更应该归属哪个 Skill（如 `embedded/mcu/stm32`）
- **变更类型**：`add`（新增）| `update`（更新）| `fix`（修正）
- **内容类别**：`pattern`（代码模式）| `faq`（常见问题）| `concept`（核心概念）
- **验证状态**：是否在项目中实际验证过

#### 步骤 3：生成 Skill 导入包

按照【导入包格式规范】创建标准化的导入包：

```
skill-package/
├── manifest.json          # 包元数据
├── delta/
│   ├── SKILL.md.patch     # SKILL.md 增量内容
│   ├── patterns/          # 新增代码模式
│   └── references/        # 新增参考资料
└── HISTORY.md.entry       # 历史记录条目
```

#### 步骤 4：生成导入包文件

**操作命令**：
```bash
# 创建导入包目录结构
mkdir -p ~/skill-packages/YYYYMMDD-<skill-name>-<brief-desc>
cd ~/skill-packages/YYYYMMDD-<skill-name>-<brief-desc>

# 创建子目录
mkdir -p delta/patterns delta/references

# 生成 manifest.json（AI 按照模板填写）
# 生成 HISTORY.md.entry（AI 按照模板填写）
# 编辑 delta/SKILL.md.patch（AI 编写实际内容）

# 打包（可选，便于传输）
tar -czf ../YYYYMMDD-<skill-name>-<brief-desc>.pkg .
```

#### 步骤 5：验证导入包完整性

**验证清单**：
- [ ] manifest.json 包含所有必需字段
- [ ] SKILL.md.patch 内容格式正确（Markdown）
- [ ] 新增的 patterns 文件可读取
- [ ] HISTORY.md.entry 包含来源项目和验证信息

### [强制] 融合到 Skill 仓库流程

当用户要求"融合导入包"时，AI 必须按照以下流程执行：

#### 步骤 1：读取导入包

```bash
# 解压导入包（如果是 .pkg 格式）
mkdir -p /tmp/skill-import-XXX
tar -xzf <package.pkg> -C /tmp/skill-import-XXX

# 读取 manifest.json
cat /tmp/skill-import-XXX/manifest.json
```

#### 步骤 2：验证目标 Skill

**必须检查**：
- 目标 Skill 目录存在：`skills/<target_skill>/`
- 目标 Skill 包含 SKILL.md
- 备份原文件（复制到 `.backup/YYYYMMDD-HHMMSS/`）

#### 步骤 3：执行融合（按策略）

**策略 A：append（追加，推荐）**
1. 在 SKILL.md 的"## 迭代记录"之前插入新内容
2. 复制 patterns/ 下的新文件到目标 skill
3. 复制 references/ 下的新文件到目标 skill
4. 在 HISTORY.md 开头添加新条目

**策略 B：patch（补丁）**
1. 定位 SKILL.md 中需要修改的段落
2. 精确替换或修改内容
3. 保留原有结构和格式

**禁止**：
- [X] 不允许使用 `replace` 策略（完全替换 SKILL.md 太危险）
- [X] 不允许直接修改没有备份的文件
- [X] 不允许跳过验证步骤

#### 步骤 4：验证融合结果

**验证清单**：
- [ ] SKILL.md 语法正确（Markdown 格式）
- [ ] SKILL.md 包含 frontmatter
- [ ] 所有引用的文件存在
- [ ] HISTORY.md 格式正确

#### 步骤 5：提交变更

**提交信息格式**：
```
feat(<skill-scope>): <brief description>

- <change detail 1>
- <change detail 2>

Source: <project-name>
Extracted by: skill-evolution convention
```

## 导入包格式规范

### manifest.json（必需）

```json
{
  "package_version": "1.0.0",
  "created_at": "2026-02-12T10:00:00Z",
  "source_project": "项目名称",
  "target_skill": "category/skill-name",
  "change_type": "incremental",
  "strategy": "append",
  "changes": {
    "SKILL.md": {
      "type": "patch",
      "sections": ["新增章节名"],
      "lines_added": 20
    },
    "patterns/": {
      "type": "add",
      "files": ["pattern-name.c"]
    }
  },
  "validation": {
    "tested": true,
    "test_project": "项目名称"
  }
}
```

### delta/SKILL.md.patch（必需）

```markdown
## 新增章节标题

正文内容，支持完整的 Markdown 格式。

### 子章节

- 要点 1
- 要点 2

```c
// 代码示例
void example() {
    // ...
}
```

## 新增常见问题

### 问题：描述问题
**现象**：具体表现
**原因**：根本原因
**解决**：解决方案
```

### HISTORY.md.entry（必需）

```markdown
## YYYY-MM-DD: 变更描述（来自项目名称）

**变更**: 简短描述变更内容

**来源项目**: 项目名称
**提取方式**: skill-evolution 规范

**具体内容**:
- 新增内容 1
- 新增内容 2

**验证**: 在项目名称中实际应用
```

## 项目中的知识记录规范

### .vibe/.skill-updates-todo.md

项目开发中记录 Skill 更新的标准格式：

```markdown
## 待办

- [ ] target-skill/name: 简短描述
  发现时间：YYYY-MM-DD
  项目：project-name
  问题描述：详细描述问题或新发现
  建议方案：如何更新 Skill
  参考代码：src/xxx/yyy.c

- [ ] embedded/mcu/stm32: H7 DMA 双缓冲配置
  发现时间：2026-02-12
  项目：my-robot
  问题描述：H7 系列 DMA 双缓冲需要特殊配置
  建议方案：在常见问题中添加 H7 DMA 章节
  参考代码：src/drivers/dma_h7.c
```

## 快速开始

### 场景 1：从项目提取 Skill 更新

**用户指令**："从这个项目提取 Skill 更新"

**AI 执行**：
1. 扫描 `.vibe/.skill-updates-todo.md`
2. 为每个待办项生成导入包
3. 输出导入包路径和摘要

### 场景 2：融合导入包到 Skill 仓库

**用户指令**："把这个导入包融合到 skill 仓库"

**AI 执行**：
1. 读取导入包内容
2. 验证目标 Skill
3. 备份原文件
4. 执行融合（append 策略）
5. 验证结果
6. 准备提交信息

### 场景 3：批量更新多个 Skill

**用户指令**："批量融合所有导入包"

**AI 执行**：
1. 列出所有导入包
2. 按 Skill 分组
3. 逐个融合（每个 Skill 一个 commit）
4. 输出融合摘要

## 与 vibe-coding/core 的关系

本 SKILL 遵循 `vibe-coding/core` 中的 **[强制] SKILL 指导执行，脚本只是辅助** 原则：

> **本质**：SKILL 是 AI 的执行规范，脚本只是可选的辅助工具

**AI 执行原则**：
- ✅ **SKILL 定义完整流程**：本 SKILL 详细定义了提取和融合的 5 个步骤
- ✅ **AI 按 SKILL 执行**：无论是否有 extract-skill.sh/merge-skill.sh
- ✅ **脚本仅作辅助**：脚本加速重复操作，但不改变 SKILL 约定的流程
- ✅ **没有脚本时 AI 手动执行**：按照本 SKILL 的步骤逐步完成

**检查清单**：
- [ ] 是否可以不运行任何脚本而完成提取？（按照步骤 1-5 手动执行）
- [ ] 是否可以不运行任何脚本而完成融合？（按照步骤 1-5 手动执行）
- [ ] 脚本是否只做 SKILL 约定的事？（没有额外逻辑）

如果以上任何一项为否，说明脚本过度设计，需要调整。

## 迭代记录

- 2026-02-12: 初始创建，定义知识提取和融合的标准流程
