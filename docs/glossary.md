# 术语表

Vibe Coding 方法论中的核心术语解释。

## A

### AGENTS.md
项目级 AI 开发指南文件，包含：
- 项目技术栈和规范
- 启用的 Skill 列表
- 多代理安全规则
- 开发工作流程

### AI Agent（AI 代理）
指使用 Vibe Coding 方法论的 AI 助手，如 Claude、GPT 等。Agent 通过读取 AGENTS.md 和 Skill 来理解项目上下文。

### AI Assistant Convention（AI 助手约定）
SKILL.md 或 AGENTS.md 中的特殊章节，定义 AI 必须遵循的规则。通常标记为 `## AI 助手约定（强制执行）`，包含：
- `[强制]` 必须执行的操作
- `[禁止]` 绝不能做的操作  
- `[OK]` 推荐的做法

AI 助手读取到此类章节时，必须严格遵守其中的规定。

## C

### Capability Convention（能力约定）
三种约定层次之一，指领域内做事的方法，类似个人知识习惯。

**载体**：各 `SKILL.md` 文件
**演进**：项目经验沉淀，HISTORY.md 记录演进

示例：`git-commits`, `stm32`, `docker-best-practices`

### Convention over Configuration（约定优于配置）
三种核心理念之一，SKILL 不是可选的参考资料，而是**强制执行的工作约定**。

通过 SKILL 固化流程，让 AI 遵循规则做事情，而不是每次依赖用户说明。

## D

### Dev-Workflow（开发工作流）
Skill 分类之一，包含通用开发流程的规范：
- git-commits: Git 提交规范
- quality-gates: 质量门禁
- pr-workflow: PR 流程

## G

### Global Convention（全局约定）
三种约定层次之一，指 AI 的"本性"原则，跨领域通用。

**载体**：`vibe-coding/core` 等核心 Skill
**演进**：多次项目经验升华，变更需慎重

示例：禁止擅自扩展、推送确认流程、渐进式披露原则

### Gateway Protocol（网关协议）
Vibe Coding 架构的 Layer 4，用于 IDE 集成和 AI 工具连接。可选层，小型项目可不使用。

### Git Commits
开发工作流 Skill，规范 Git 提交行为：
- 精确提交（禁止 `git add -A`）
- Commit message 格式
- 多代理安全规则

## H

### HISTORY.md
Skill 的变更记录文件，记录技能的演进过程。不同于版本号，只记录变更历史供参考。

## K

### Knowledge Base（知识库）
原始资料的存储库，包含：
- PDF 文档
- 视频教程
- 参考代码

知识库是 Skill 的原材料来源，通过提取和精炼转化为 Skill。

## L

### Layer 1-5（五层架构）
Vibe Coding 的分层架构：
- Layer 1: AI Agent Context（上下文）
- Layer 2: Skill Registry（技能注册表）
- Layer 3: Workflow Engine（工作流引擎）
- Layer 4: Gateway Protocol（网关协议，可选）
- Layer 5: Project Core（项目核心）

## M

### Mermaid
用于绘制图表的标记语言，Vibe Coding 推荐使用 Mermaid 绘制架构图和流程图。

### Multi-Agent Safety（多代理安全）
允许多个 AI 同时工作时的安全规则：
- 禁止 `git stash`
- 禁止切换分支
- 精确文件提交

## P

### Patterns（模式）
Skill 的子目录，包含可复用的代码模板和示例：
- `patterns/templates/`: 可直接使用的代码模板
- `patterns/examples/`: 参考示例代码

### Progressive Disclosure（渐进式披露）
三种核心理念之一，AI 只加载需要的信息：
- Level 1: Metadata（元数据）
- Level 2: SKILL.md Body
- Level 3: References

避免上下文爆炸，按需加载知识。

### PR Workflow
开发工作流 Skill，规范 Pull Request 流程：
- review-pr: 审查
- prepare-pr: 准备
- merge-pr: 合并

### Project Core（项目核心）
Vibe Coding 架构的 Layer 5，实际的源代码实现。

## Q

### Quality Gates（质量门禁）
五阶段流程之一，AI 生成的代码必须通过预定义的检查：
- 代码规范检查
- 编译/运行验证
- 测试覆盖检查

## R

### References（参考资料）
Skill 的子目录，包含详细的参考资料：
- `references/quick-ref.md`: 速查表
- `references/detailed/`: 详细文档

按需加载，不占用 AI 上下文窗口。

## S

### Session Persistence（会话持久化）
上下文管理机制，保持开发会话的连续性：
- `.ai-context/` 目录存储关键决策
- 支持上下文恢复
- 可选全量对话日志

### Skill（技能）
Vibe Coding 的核心知识单元，包含：
- SKILL.md: 核心指导
- patterns/: 代码模式
- references/: 参考资料

### Skill Activation（技能激活）
AI 根据任务自动识别并激活相关 Skill 的机制。

**触发方式**：
- 显式声明：`.skill-set` 文件
- 关键词匹配：description 中的关键词
- 文件模式：触发文件类型

### Skill Registry（技能注册表）
Vibe Coding 架构的 Layer 2，存储和管理所有 Skill 的中央仓库。

### Skill Set（技能集）
项目通过 `.skill-set` 文件声明引用的 Skill 列表。

### Symbolic Link（符号链接）
项目引用 Skill 的方式，通过软链接指向 Skill Registry，节省空间且保持同步。

## T

### Templates（模板）
Skill 中 `patterns/templates/` 目录下的文件，提供可直接使用的代码模板。

## V

### Vibe Coding
AI 协作开发方法论，核心公式：
> **AI 代理 + 结构化上下文 + 质量门控 + 多代理协作**

### Vibe Directory（.vibe/）
项目中的 Vibe Coding 配置目录，包含：
- `skills/`: 链接的 Skill
- `scripts/`: 辅助脚本
- `backups/`: 备份文件

### Vibe Init
初始化命令 `vibe init`，将任意目录转换为 Vibe Coding 项目。

## W

### Workflow Engine（工作流引擎）
Vibe Coding 架构的 Layer 3，标准化开发流程，确保质量。

## 常用缩写

| 缩写 | 全称 | 说明 |
|------|------|------|
| skill | - | 技能，知识单元 |
| registry | - | 注册表，中央存储库 |
| pattern | - | 模式，可复用的代码模板 |
| ref | reference | 参考资料 |
| gate | quality gate | 质量门禁 |
| ctx | context | 上下文 |

## 相关概念对比

### Skill vs 原始资料
| Skill | 原始资料 |
|-------|---------|
| 精炼后，AI 可用 | 原始格式，人阅读 |
| 结构化 | 非结构化 |
| 中文编写 | 多为英文 |
| < 500 行核心 | 可能数千页 |

### Skill vs 项目配置
| Skill | 项目配置 |
|-------|---------|
| 跨项目复用 | 项目专属 |
| 存储在 Registry | 存储在项目 |
| 符号链接引用 | 直接文件 |
| 多人维护 | 项目开发者维护 |

### AGENTS.md vs SKILL.md
| AGENTS.md | SKILL.md |
|-----------|----------|
| 项目级 | Skill 级 |
| 引用 Skill | 被项目引用 |
| 定制项目规范 | 提供领域知识 |
| 每个项目一个 | 每个 Skill 一个 |

---

*持续更新中...*
