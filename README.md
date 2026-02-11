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
├── embedded/              # 嵌入式开发技能
│   ├── common/           # 通用概念
│   │   └── c-embedded/   # 嵌入式 C 开发规范
│   ├── mcu/              # MCU 相关
│   │   └── st-stm32/     # STM32 具体实现（含示例）
│   └── rtos/             # RTOS 相关
│       └── freertos/     # FreeRTOS
│
├── dev-workflow/          # 开发工作流技能
│   ├── git-commits/      # Git 提交规范与多代理安全
│   ├── quality-gates/    # 质量门禁
│   └── pr-workflow/      # PR 工作流
│
└── software/             # 软件开发技能（待添加）
    ├── python/
    ├── docker/
    └── ros/

scripts/
└── new-skill.sh          # 创建新技能脚本
```

## 快速开始

### 创建新技能

```bash
./scripts/new-skill.sh <category>/<skill-name>

# 示例
./scripts/new-skill.sh embedded/mcu/gd32
./scripts/new-skill.sh software/docker
```

### 在项目中使用

1. 在项目根目录创建 `.skill-set` 文件：
```
embedded/mcu/st-stm32
embedded/rtos/freertos
dev-workflow/git-commits
dev-workflow/quality-gates
```

2. 运行链接脚本：
```bash
./scripts/link-skills.sh
```

3. 技能将被链接到 `./skills/` 目录

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
created: 2024-01-15
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
- 2024-01-15: 初始创建
```

## 核心技能说明

### dev-workflow/git-commits
Git 提交规范，包含：
- 精确提交（禁止 `git add -A`）
- Commit message 规范
- 多代理安全规则

### dev-workflow/quality-gates
质量门禁，包含：
- C 项目检查（编译、静态分析）
- Python 项目检查（格式、类型、测试）
- 可扩展的 gate.sh 脚本

### dev-workflow/pr-workflow
PR 工作流，包含：
- PR 创建流程
- 审查规范
- 合并流程

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

- 2024-01-15: 初始创建，添加 embedded 和 dev-workflow 基础技能
- 2024-01-15: 添加 docker-best-practices 技能
- 2024-01-15: 添加模板文件和项目初始化脚本

---

*基于 OpenClaw Vibe Coding 方法论*
