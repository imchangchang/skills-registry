---
name: quality-gates
description: 代码质量门禁与检查流程。定义提交前必须通过的质量检查。
created: 2024-01-15
status: draft
---

# 质量门禁

## 核心理念

**质量门禁是强制性的**。未通过质量门禁的代码不得提交。

## 标准质量门流程

```bash
# 1. 静态检查
lint-check

# 2. 类型检查（如适用）
type-check

# 3. 构建检查
build-check

# 4. 测试检查
test-check
```

## 嵌入式 C 项目质量门

### Gate 1: 编译检查
```bash
# 零警告编译
make clean
make 2>&1 | tee build.log

# 检查是否有警告
if grep -i "warning" build.log; then
    echo "[X] 存在编译警告"
    exit 1
fi
```

### Gate 2: 静态分析
```bash
# 使用 cppcheck
cppcheck --enable=all --error-exitcode=1 \
    --suppress=missingIncludeSystem \
    src/

# 或使用 clang-static-analyzer
scan-build make
```

### Gate 3: 代码格式
```bash
# 使用 clang-format
find src/ -name "*.c" -o -name "*.h" | \
    xargs clang-format --dry-run --Werror
```

### Gate 4: 测试运行
```bash
# 单元测试
make test

# 硬件在环测试（如适用）
make hw-test
```

## Python 项目质量门

```bash
# Gate 1: 格式
ruff check .
black --check .

# Gate 2: 类型
mypy src/

# Gate 3: 测试
pytest --cov=src --cov-report=term-missing
```

## 质量门脚本模板

见 patterns/gate.sh

## 项目特定配置

每个项目应在 `scripts/gate.sh` 中定义自己的质量门。

## 迭代记录
- 2024-01-15: 初始创建
