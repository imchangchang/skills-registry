---
name: git-commits
description: Git 提交规范和分支管理。统一提交信息格式，确保提交历史清晰可读。
created: 2026-02-12
status: stable
---

# Git 提交规范

> 统一提交信息格式，确保提交历史清晰可读

## 提交格式

```
type(scope): subject

body

footer
```

## Type（必填）

| 类型 | 说明 |
|-----|------|
| feat | 新功能 |
| fix | 修复问题 |
| docs | 文档修改 |
| style | 代码格式（不影响功能） |
| refactor | 重构 |
| test | 测试相关 |
| chore | 构建/工具/依赖 |

## Scope（可选）

- `skill-*`：技能相关
- `core`：核心功能
- `scripts`：脚本工具
- `docs`：文档

## 示例

```bash
feat(skill-python): 添加虚拟环境管理最佳实践

- 包含 pyvenv 和 venv 的使用建议
- 添加 requirements.txt 管理规范

docs(skill-bash): 补充信号处理章节

fix(core): 修复 skill-import 空目录问题
```

## 禁止行为

- ❌ `git add .`
- ❌ `git commit -am "message"`
- ❌ `git stash`
- ❌ 未经明确指令执行 `git push`

## 迭代记录

- 2026-02-12: 初始创建，统一提交规范
