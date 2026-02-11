---
name: git-commits
description: Git 提交规范与工具使用。包含精确提交、commit message 规范、多代理安全规则。
created: 2024-01-15
status: draft
---

# Git 提交规范

## 核心原则

### 精确提交（强制）
**禁止**使用 `git add -A` 或 `git commit -a`

**必须**使用精确文件指定：
```bash
# 正确
git add src/main.c src/utils.c
git commit -m "fix: resolve timing issue"

# 错误
git add .
git commit -am "update"  # 禁止！
```

### Commit Message 格式
```
<type>(<scope>): <subject>

<body>
```

**Type 类型**：
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式（不影响代码逻辑）
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

**示例**：
```
feat(gpio): add interrupt debounce support

fix(stm32): correct RCC clock configuration for H7 series

docs: update API usage examples
```

## 多代理安全规则

### 禁止操作
- ❌ 创建 `git stash`
- ❌ 切换分支（除非明确要求）
- ❌ 修改 `.worktrees/`
- ❌ 使用 `git add -A`

### 允许操作
- ✅ 精确添加指定文件
- ✅ 在当前分支创建 commit
- ✅ 查看状态/日志/diff

## 提交脚本模板

见 patterns/commit.sh

## 提交前检查清单

- [ ] 只提交了相关文件
- [ ] Commit message 清晰描述变更
- [ ] 没有提交临时文件/密钥
- [ ] 代码可以编译/运行

## 迭代记录
- 2024-01-15: 初始创建，基于 OpenClaw 实践
