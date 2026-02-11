---
name: pr-workflow
description: Pull Request 工作流，包括创建、审查、合并的规范流程。
created: 2026-02-11
status: draft
---

# PR 工作流

## 流程概览

```
开发 → 本地检查 → 推送分支 → 创建 PR → 审查 → 合并 → 清理
```

## 创建 PR

### 准备工作
```bash
# 1. 确保本地干净
git status  # 应该是干净的

# 2. 基于最新 main
git checkout main
git pull --rebase

# 3. 创建功能分支
git checkout -b feature/xxx
```

### 开发流程
```bash
# 开发...
# 提交（使用精确提交）
./scripts/commit.sh "feat: add xxx" src/xxx.c src/xxx.h

# 质量门
./scripts/gate.sh

# 推送
git push -u origin feature/xxx
```

### PR 描述模板

```markdown
## 变更内容
[清晰描述变更]

## 类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档
- [ ] 重构

## 检查清单
- [ ] 通过本地质量门
- [ ] 添加/更新测试
- [ ] 更新文档（如需要）
```

## 审查规范

### 审查者检查项
- [ ] 代码逻辑正确
- [ ] 符合项目规范
- [ ] 有适当注释
- [ ] 测试覆盖
- [ ] 无安全风险

### 审查意见分级
- **BLOCKER**: 必须修复才能合并
- **IMPORTANT**: 应该修复，可以后续
- **NIT**: 风格问题，可选

## 合并规范

```bash
# 1. 确保 PR 是最新的
git checkout feature/xxx
git rebase main

# 2. 解决冲突（如有）
# ...

# 3. 强制推送（因为 rebase）
git push --force-with-lease

# 4. 在 GitHub/GitLab 合并
# 推荐使用 "Squash and merge"

# 5. 清理本地分支
git checkout main
git pull
git branch -d feature/xxx
```

## 多代理安全（重要）

- **不要**直接 push 到 main
- **不要**在审查前合并自己的 PR
- **不要** force push 他人的分支

## 迭代记录
- 2026-02-11: 初始创建
