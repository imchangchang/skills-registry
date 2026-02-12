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
├── vibe-coding/           # Vibe Coding 核心方法论
│   ├── core/             # 全局约定（三种约定层次）
│   ├── multi-agent-safety/ # 多代理安全规则
│   └── session-management/ # 会话管理规范
│
├── dev-workflow/          # 开发工作流技能
│   ├── git-commits/      # Git 提交规范
│   ├── quality-gates/    # 质量门禁
│   └── pr-workflow/      # PR 工作流
│
├── embedded/              # 嵌入式开发技能
│   ├── common/           # 通用概念
│   │   └── c-embedded/   # 嵌入式 C 开发规范
│   ├── mcu/              # MCU 相关
│   │   └── st-stm32/     # STM32 具体实现（含示例）
│   └── rtos/             # RTOS 相关
│       └── freertos/     # FreeRTOS
│
└── software/              # 软件开发技能
    ├── docker-best-practices/
    └── python-cli/

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
vibe init -s embedded/mcu/st-stm32,dev-workflow/git-commits
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
vibe skill embedded/rtos/freertos

# 更新所有技能链接
vibe update
```

### 手动方式（不使用 vibe 命令）

```bash
# 直接运行初始化脚本
~/skills-registry/scripts/init-vibe.sh

# 添加技能
~/skills-registry/scripts/add-skill.sh embedded/mcu/gd32
```

### 创建新技能

```bash
./scripts/new-skill.sh <category>/<skill-name>

# 示例
./scripts/new-skill.sh embedded/mcu/gd32
./scripts/new-skill.sh software/ros2
```

## Skill 格式规范

每个技能目录包含：

```
skill-name/
├── SKILL.md              # 核心指导（<500 行，中文）
├── HISTORY.md            # 变更记录
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

## 参考资料
- references/quick-ref.md - 速查表

## 迭代记录
- 2026-02-11: 初始创建
```

## 核心技能说明

### vibe-coding/core
Vibe Coding 全局约定，包含：
- 三种核心理念（约定优于配置、渐进式披露、学习中演进）
- 三种约定层次（全局/能力/项目）
- 能力层与交付层双层结构
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

### dev-workflow/git-commits
Git 提交规范，包含：
- Commit message 格式
- 精确提交流程

### dev-workflow/quality-gates
质量门禁，包含：
- C 项目检查（编译、静态分析）
- Python 项目检查（格式、类型、测试）
- 可扩展的 gate.sh 脚本

### embedded/mcu/st-stm32
STM32 开发技能，示例技能，包含：
- GPIO 初始化模板
- 中断处理模板
- 常见问题

## 使用原则

1. **选择性加载**：根据项目需要选择技能，不要加载全部
2. **持续迭代**：开发中发现问题立即更新技能
3. **保持精简**：SKILL.md 精简，详细内容放 references/
4. **中文编写**：所有技能文档使用中文

## 模板文件

`templates/` 目录包含创建新项目的模板：

| 文件 | 用途 |
|------|------|
| `AGENTS.md` | 项目开发指南模板 |
| `init-project.sh` | 一键初始化新项目 |

### 快速创建新项目

```bash
# 使用初始化脚本
./templates/init-project.sh my-project --skills embedded/mcu/st-stm32,dev-workflow/git-commits

# 或手动复制模板
cp templates/AGENTS.md ~/projects/my-project/AGENTS.md
```

## 迭代记录

- 2026-02-11: 初始创建，添加 embedded 和 dev-workflow 基础技能
- 2026-02-11: 添加 docker-best-practices 技能
- 2026-02-11: 添加模板文件和项目初始化脚本
- 2026-02-11: 添加安装脚本 `install.sh` 和 `vibe` 命令工具

---

*基于 OpenClaw Vibe Coding 方法论*
