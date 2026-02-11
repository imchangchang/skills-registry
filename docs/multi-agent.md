# 多代理安全规则

Vibe Coding 默认假设多个 AI 代理可能同时操作同一个仓库，因此需要严格的安全规则。

## 核心原则

> **保持工作区干净，避免冲突，精确控制**

## 禁止操作清单

### [X] 绝对禁止

| 操作 | 原因 | 替代方案 |
|------|------|---------|
| `git stash` | 可能与其他代理的 stash 冲突 | 直接提交或丢弃变更 |
| `git checkout <branch>` | 可能中断其他代理的工作 | 在当前分支创建 commit |
| `git add -A` | 可能提交不相关文件 | 精确添加指定文件 |
| 修改 `.worktrees/` | 可能破坏其他代理的工作区 | 不碰 worktree 目录 |
| `git pull --rebase --autostash` | autostash 可能产生冲突 | 手动处理变更后再 pull |

### [WARN] 需要确认的操作

| 操作 | 场景 | 确认方式 |
|------|------|---------|
| `git push` | 可能覆盖其他代理的提交 | 确保已通过质量门 |
| `git rebase` | 可能产生冲突 | 仅限当前分支 |
| `git reset --hard` | 会丢失变更 | 必须确认无重要变更 |

## 安全操作模式

### [OK] 推荐的 Git 工作流

```bash
# 1. 检查状态（始终先检查）
git status

# 2. 精确添加文件
git add src/file1.c src/file2.h

# 3. 规范提交
git commit -m "feat(gpio): add interrupt debounce"

# 4. 获取最新变更
git pull --rebase

# 5. 推送
git push
```

### 精确提交脚本

```bash
#!/bin/bash
# commit.sh - 精确提交脚本

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <message> <file1> [file2 ...]"
    exit 1
fi

MESSAGE="$1"
shift

# 禁止通配符
if [[ "$*" == *"."* ]] || [[ "$*" == *"*"* ]]; then
    echo "[X] Error: 不要使用通配符或 '.'"
    exit 1
fi

# 取消所有暂存
git reset HEAD >/dev/null 2>&1 || true

# 精确添加
git add "$@"

# 检查有变更
if git diff --cached --quiet; then
    echo "[WARN] Warning: 没有要提交的变更"
    exit 1
fi

# 提交
git commit -m "$MESSAGE"
echo "[OK] 提交成功: $MESSAGE"
```

## 多代理协作模式

### 场景 1：多个 AI 同时工作

```
AI A: 开发功能 A
  ↓ 在分支 feature-a 工作
AI B: 开发功能 B
  ↓ 在分支 feature-b 工作
Human: 审查并合并
```

### 场景 2：AI 与人协作

```
AI: 生成初始代码
  ↓
Human: 审查并提出修改意见
  ↓
AI: 根据反馈修改
  ↓
Human: 确认并提交
```

### 场景 3：Skill 库维护

```
AI A: 在项目中开发，发现 Skill 问题
  ↓ 记录到 .skill-updates-todo.md
Human: 审查待办列表
  ↓
AI B: 修改 Skill 库
  ↓
AI A: 更新项目中的 Skill 链接
```

## 冲突避免策略

### 1. 文件级隔离

每个代理只修改分配给它的文件：
```
AI A: src/module-a/*
AI B: src/module-b/*
```

### 2. 时间片分配

如果必须修改同一文件，按时间片分配：
```
时间段 1: AI A 修改，AI B 等待
时间段 2: AI B 修改，AI A 等待
```

### 3. 快速提交

小步快跑，频繁提交：
```
修改文件 A → 提交
修改文件 B → 提交
修改文件 C → 提交
```

## 安全边界

### 项目边界

```
project-a/
  └── .vibe/          # AI A 的工作区

project-b/
  └── .vibe/          # AI B 的工作区
```

每个项目的 `.vibe/` 目录相互隔离。

### 技能库边界

```
skills-registry/       # 独立的技能库
  └── skills/         # 所有项目共享

project/
  └── .vibe/skills/   # 符号链接（只读）
```

项目通过符号链接引用技能库，不直接修改。

## 异常情况处理

### 发现冲突

```bash
# 1. 立即停止操作
# 2. 报告给用户
echo "[WARN] 发现其他代理的变更:"
git status

# 3. 等待用户确认如何处理
```

### 意外的 stash

```bash
# 如果发现 stash 不是自己创建的
# 不应用它，直接报告给用户
git stash list
echo "[WARN] 发现未授权的 stash，请人工处理"
```

### worktree 冲突

```bash
# 如果发现 .worktrees/ 有其他代理的工作区
# 不修改它，使用独立目录
ls -la .worktrees/
echo "[WARN] 发现其他工作区，创建新的独立目录"
```

## 检查清单

开始工作前检查：
- [ ] `git status` 确认工作区干净
- [ ] 确认当前分支正确
- [ ] 检查是否有其他代理的 `.worktrees/`

提交前检查：
- [ ] 只提交了相关文件（没有 `git add .`）
- [ ] commit message 清晰
- [ ] 通过质量门禁

完成后检查：
- [ ] 推送成功
- [ ] 没有遗留的 stash
- [ ] 没有修改其他代理的文件

## 下一步

- 学习 [技能设计原则](skill-design.md)
- 了解 [实施流程](workflow.md)
