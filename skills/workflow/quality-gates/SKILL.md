---
name: quality-gates
description: 代码质量门禁检查。提交前的质量检查清单，确保代码质量。
created: 2026-02-12
status: stable
---

# 质量门禁

> 提交前的质量检查清单

## 检查清单

### 代码层面

- [ ] 代码通过语法检查（`bash -n`、`python -m py_compile`）
- [ ] 关键路径有注释
- [ ] 变量命名清晰有意义
- [ ] 没有硬编码的敏感信息

### 文档层面

- [ ] SKILL.md 格式正确
- [ ] 新增 skill 有对应的 HISTORY.md
- [ ] 更新 SKILL.md 时同步更新 HISTORY.md
- [ ] 中文文档无乱码

### 结构层面

- [ ] 文件放置在正确的目录
- [ ] 命名符合规范
- [ ] 没有遗留的临时文件

### 验证层面

- [ ] 关键逻辑经过测试
- [ ] 示例代码可运行

## 自动化检查脚本

```bash
#!/bin/bash
# pre-commit-check.sh

echo "=== 代码检查 ==="

# Bash 语法检查
for f in $(find skills -name "*.sh"); do
    bash -n "$f" || exit 1
done

# Python 语法检查
for f in $(find skills -name "*.py"); do
    python3 -m py_compile "$f" || exit 1
done

echo "=== 结构检查 ==="

# 检查 SKILL.md 是否存在
for dir in skills/*/*/; do
    if [ ! -f "$dir/SKILL.md" ]; then
        echo "[X] 缺少 SKILL.md: $dir"
        exit 1
    fi
done

echo "[OK] 所有检查通过"
```

## 迭代记录

- 2026-02-12: 初始创建，建立质量门禁检查清单
