# Skills Registry

个人技能知识库，用于 AI 协作开发。

## 设计理念

- **知识无版本**：只有当前最佳实践，不强制版本号
- **渐进式披露**：AI 按需加载，避免上下文爆炸
- **从实践中来**：每个技能都经过实际项目验证
- **中文优先**：所有技能文档使用中文编写

## 目录结构

```
skills/
├── vibe-coding/          # Vibe Coding 核心方法论
│   ├── core/             # 全局约定（三种约定层次）
│   ├── multi-agent-safety/ # 多代理安全规则
│   ├── session-management/ # 会话管理规范
│   ├── skill-evolution/  # Skill 演化流程
│   └── skill-testing/    # Skill 测试规范
│
├── languages/            # 编程语言
│   ├── python/
│   │   ├── core/         # Python 核心实践
│   │   ├── cli/          # Python CLI 开发
│   │   └── pipeline/     # Python 管道编程
│   └── bash/             # Bash 脚本编写
│
├── domains/              # 领域技能
│   ├── embedded/         # 嵌入式开发
│   │   ├── common/       # 通用概念
│   │   ├── mcu/stm32/    # STM32 开发
│   │   └── rtos/freertos/ # FreeRTOS
│   ├── ai/               # AI 相关
│   │   ├── api-integration/  # AI API 集成
│   │   ├── prompt-engineering/ # Prompt 工程
│   │   └── whisper-asr/  # Whisper 语音识别
│   └── multimedia/       # 多媒体处理
│       ├── video-processing/
│       └── opencv/
│
├── patterns/             # 架构模式
│   └── pipeline/architecture/  # 管道架构模式
│
└── workflow/             # 开发工作流
    ├── git/              # Git 提交规范
    ├── quality-gates/    # 质量门禁
    └── docker/           # Docker 基础实践

scripts/
├── install.sh            # 安装技能库到本地
├── init-vibe.sh          # 在任意目录初始化 Vibe Coding
├── add-skill.sh          # 为项目添加技能
├── update-skills.sh      # 更新技能链接
├── vibe-status.sh        # 查看项目 Vibe 状态
└── new-skill.sh          # 创建新技能脚本
```

## 快速开始

### 安装技能库

```bash
# 1. 克隆技能库
git clone <your-repo-url> ~/skills-registry
cd ~/skills-registry

# 2. 安装到本地（创建 vibe 命令）
./scripts/install.sh

# 3. 重新加载 shell 配置
source ~/.bashrc  # 或 ~/.zshrc
```

### 在项目中使用（推荐）

使用 `vibe` 命令快速初始化：

```bash
# 进入任意项目目录
cd ~/projects/my-project

# 初始化 Vibe Coding
vibe init

# 或指定初始技能
vibe init -s domains/embedded/mcu/stm32,workflow/git
```

**生成的文件结构**：
```
my-project/
├── .vibe/                # Vibe Coding 配置（自动生成）
│   ├── skills/           # 链接的技能（符号链接）
│   ├── scripts/          # 辅助脚本
│   └── backups/          # 备份文件
├── .skill-set            # 技能声明
├── AGENTS.md             # AI 开发指南
└── .gitignore            # 已配置忽略 .vibe/
```

**非侵入式设计**：
- 所有 Vibe 文件都在 `.vibe/` 目录
- 自动配置 `.gitignore`，不会污染版本控制
- 使用符号链接引用技能库，节省空间

### 管理技能

```bash
# 查看项目状态
vibe status

# 添加技能
vibe skill domains/embedded/rtos/freertos

# 更新所有技能链接
vibe update
```

### 手动方式（不使用 vibe 命令）

```bash
# 直接运行初始化脚本
~/skills-registry/scripts/init-vibe.sh

# 添加技能
~/skills-registry/scripts/add-skill.sh domains/embedded/mcu/gd32
```

### 创建新技能

```bash
./scripts/new-skill.sh <category>/<skill-name>

# 示例
./scripts/new-skill.sh domains/embedded/mcu/gd32
./scripts/new-skill.sh languages/rust/core
```

## Skill 格式规范

每个技能目录包含：

```
skill-name/
├── SKILL.md              # 核心指导（<500 行，中文）
├── HISTORY.md            # 变更记录
├── metadata.json         # 元数据
├── patterns/             # 代码模式
│   ├── templates/        # 可直接使用的模板
│   └── examples/         # 示例代码
├── references/           # 参考资料（按需加载）
│   ├── quick-ref.md      # 速查表
│   └── detailed/         # 详细文档
└── scripts/              # 工具脚本（可选）
```

### SKILL.md 结构

```markdown
---
name: skill-name
description: 简短描述，让 AI 知道何时使用此技能
created: 2026-02-11
status: draft  # draft → stable
---

# 技能标题

## 适用场景
描述在什么情况下使用此技能

## 核心概念
- 概念 1：简要说明
- 概念 2：简要说明

## 快速开始
最简单的入门示例

## 代码模式
### 模式 1：描述
代码示例

## 常见问题
### 问题 1
**现象**：...
**原因**：...
**解决**：...

## 迭代记录
- 2026-02-11: 初始创建
```

## 核心技能说明

### vibe-coding/core
Vibe Coding 全局约定，包含：
- 三种约定层次（全局/能力/项目）
- 双层架构（能力层与交付层）
- 主动学习与实践沉淀两条路径

### vibe-coding/multi-agent-safety
多代理安全规则，包含：
- 绝对禁止操作清单（git stash, git add . 等）
- 推送确认流程
- 精确提交规范

### vibe-coding/session-management
会话管理规范，包含：
- .ai-context/ 目录使用
- Session 记录格式
- 上下文恢复流程

### vibe-coding/skill-evolution
Skill 演化指南，包含：
- [强制] NEVER delete 原则：从项目中提取的 Skill 一律保留
- 三种沉淀方式：直接编辑、项目提取、新建 Skill
- 场景决策树

### vibe-coding/skill-testing
Skill 测试验证规范，包含：
- Skill 测试三步法
- 测试检查清单
- 冲突检查

### patterns/pipeline/architecture
管道架构模式，通用设计思想

### languages/python/core
Python 核心开发实践

### languages/bash
Bash 脚本编写规范

### domains/embedded/mcu/stm32
STM32 开发技能

### workflow/git
Git 提交规范

### workflow/quality-gates
代码质量门禁检查

## 使用原则

1. **选择性加载**：根据项目需要选择技能，不要加载全部
2. **持续迭代**：开发中发现问题立即更新技能
3. **保持精简**：SKILL.md 精简，详细内容放 references/
4. **中文编写**：所有技能文档使用中文
5. **项目经验全保留**：从项目实践中提取的技能一律保留，分类存放

## 模板文件

`templates/` 目录包含创建新项目的模板：

| 文件 | 用途 |
|------|------|
| `AGENTS.md` | 项目开发指南模板 |
| `init-project.sh` | 一键初始化新项目 |

### 快速创建新项目

```bash
# 使用初始化脚本
./templates/init-project.sh my-project --skills domains/embedded/mcu/stm32,workflow/git

# 或手动复制模板
cp templates/AGENTS.md ~/projects/my-project/AGENTS.md
```

## 迭代记录

- 2026-02-12: 重构目录结构（languages/, domains/, patterns/, workflow/）
- 2026-02-12: 恢复并创建 project-specific 技能（prompt-engineering, whisper-asr, opencv）
- 2026-02-12: 添加 [强制] NEVER delete 原则：项目经验技能一律保留
- 2026-02-12: 添加 skill-testing 测试验证规范
- 2026-02-12: 添加 skill-evolution Skill 演化流程
- 2026-02-12: 添加 pipeline-architecture 架构模式
- 2026-02-11: 初始创建

---

*基于 OpenClaw Vibe Coding 方法论*
