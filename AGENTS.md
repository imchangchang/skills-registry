# Skills Registry 开发指南

本仓库是 Vibe Coding 技能库，用于存储和管理 AI 协作开发的知识技能。

---

## AI 助手须知

### 进入本项目时

**必读文件**：
1. `.ai-context/session-*.md` - 恢复会话上下文（如有）
2. 本文件（AGENTS.md）- 了解项目特定规则

**必引用的 Skill**：
- `vibe-coding/core` - Vibe Coding 全局约定
- `vibe-coding/multi-agent-safety` - 多代理安全规则
- `vibe-coding/session-management` - 会话管理规范

### 会话恢复流程

```
1. 检查 .ai-context/*.md
   ├─ 存在 → 读取最新 session，向用户确认是否恢复
   └─ 不存在 → 询问用户是否创建新 session

2. 确认理解
   - 当前开发目标
   - 已做关键决策
   - 下一步任务
```

---

## 项目概述

| 项目 | 内容 |
|------|------|
| 名称 | Skills Registry |
| 类型 | Vibe Coding 技能库 |
| 用途 | 存储和管理 AI 协作开发的知识技能 |

## 技术栈

- **脚本**：Bash（兼容 POSIX）
- **文档**：Markdown
- **编码**：UTF-8

## 引用的 Skill

```
dev-workflow/
├── vibe-coding              # 全局约定（必读）
├── multi-agent-safety       # 安全规则（必读）
├── session-management       # 会话管理（必读）
├── git-commits              # 提交规范
├── quality-gates            # 质量门禁
└── pr-workflow              # PR 流程

software/
└── python-cli               # Python CLI 开发
```

---

## 项目特定规则

### 1. 语言与格式

- [强制] 所有文档使用**中文**
- [强制] **不使用 emoji**（使用 [OK], [X], [!] 等纯文本标记）
- [强制] 文件使用 **UTF-8** 编码
- [强制] 框图采用 **Mermaid** 绘制

### 2. 文档规范

**SKILL.md 结构**：
```markdown
---
name: skill-name
description: 描述，包含触发关键词
---

# Skill 名称

## 适用场景
## AI 助手约定（强制执行）
## 核心概念
## 快速开始
## 常见问题
## 迭代记录
```

**长度限制**：
- SKILL.md < 500 行
- 详细内容放入 references/

### 3. 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 技能目录 | 小写，连字符分隔 | `st-stm32`, `git-commits` |
| 脚本 | kebab-case，`.sh` 后缀 | `init-vibe.sh` |
| 文档 | 描述性名称 | `SKILL.md`, `HISTORY.md` |

### 4. 提交规范

**提交前检查清单**：
- [ ] 脚本可执行权限正确 (`chmod +x`)
- [ ] 脚本语法检查通过 (`bash -n`)
- [ ] 中文文档无乱码
- [ ] 帮助信息完整

**提交格式**：
```
type(scope): subject

type:
  - feat: 新功能
  - fix: 修复
  - docs: 文档
  - refactor: 重构
  - test: 测试
  - chore: 构建/工具

scope:
  - install: 安装脚本
  - init: 初始化
  - skill: 技能相关
  - template: 模板
```

---

## 多代理安全规则

本仓库遵循 `dev-workflow/multi-agent-safety` skill 的安全规则。

### 绝对禁止

- [X] `git add .` 或 `git add -A`
- [X] `git commit -am "message"`
- [X] `git stash`
- [X] `git checkout`（除非明确要求）
- [X] 未经明确指令执行 `git push`

### 推送确认流程

```
1. 检查用户是否在本轮对话中明确说"推送"/"push"
   ├─ 否 → 必须询问用户
   └─ 是 → 二次确认

2. 询问："是否推送到远程仓库？"

3. 等待用户明确回复
   ├─ "是"/"确认"/"推送" → 执行 push
   └─ 其他 → 不执行
```

### 禁止擅自扩展

- [X] 不要擅自创建用户未要求的文件、脚本、配置
- [X] 不要添加超出用户明确指令范围的功能
- [X] 不要以"优化"、"完善"等理由添加额外内容

---

## 开发工作流

### 开发新技能

```bash
# 使用脚本创建框架
./scripts/new-skill.sh <category>/<skill-name>

# 示例
./scripts/new-skill.sh embedded/mcu/gd32
./scripts/new-skill.sh software/ros2-nav
```

### 修改现有技能

直接编辑对应 skill 目录下的文件：
- `SKILL.md` - 核心指导
- `patterns/` - 代码模板
- `references/` - 参考资料

### 修改管理脚本

编辑 `scripts/` 目录下的脚本：
- 保持向后兼容
- 添加错误处理
- 更新帮助信息

---

## 技能设计原则

### 1. 渐进式披露

```
SKILL.md（精简核心）
  ↓ 按需加载
references/（详细资料）
  ↓ 按需加载
patterns/（代码模板）
```

### 2. 知识无版本

- 不强制版本号
- 用 HISTORY.md 记录演进
- 错误就改，补充就加

### 3. 实践导向

- 只记录验证过的知识
- 从实际项目提取
- 持续迭代优化

---

## 新增技能检查清单

创建新技能时检查：

- [ ] `SKILL.md` 包含完整的 frontmatter
- [ ] 有清晰的适用场景说明
- [ ] 核心概念不超过 5 个
- [ ] 包含快速开始示例
- [ ] 有常见问题章节
- [ ] `HISTORY.md` 记录创建
- [ ] 如需要，添加 `patterns/` 模板
- [ ] 如需要，添加 `references/` 参考

---

## 脚本开发规范

### Bash 脚本模板

```bash
#!/bin/bash
# 脚本名称 - 一句话描述

set -euo pipefail

# 使用说明
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help    显示帮助"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            usage
            ;;
        *)
            # 默认行为
            ;;
    esac
}

main "$@"
```

### 必须遵循

1. **Shebang**: `#!/bin/bash`
2. **严格模式**: `set -euo pipefail`
3. **帮助信息**: 提供 `--help`
4. **错误处理**: 检查文件/目录存在
5. **中文输出**: 用户可见信息使用中文

---

## 迭代记录

- 2026-02-12: 重构 AGENTS.md，改为项目/任务约定定位，引用全局约定 skill
