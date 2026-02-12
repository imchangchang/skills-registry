---
name: bash-scripting
description: Bash 脚本编写规范。包含严格模式、错误处理、日志记录和可维护性最佳实践。
created: 2026-02-12
status: stable
---

# Bash 脚本规范

> 编写健壮、可维护 Bash 脚本的完整指南

## 适用场景

- 系统管理脚本
- 自动化工作流
- 构建/部署脚本

## [强制] 脚本模板

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

## 严格模式详解

| 选项 | 作用 |
|-----|------|
| `-e` | 命令失败时立即退出 |
| `-u` | 使用未定义变量时报错 |
| `-o pipefail` | 管道中任意命令失败即整体失败 |

## 最佳实践

### 变量引用

```bash
# 总是引用变量
name="John"
echo "Hello, $name"

# 默认值
port="${PORT:-8080}"

# 必需变量检查
: "${REQUIRED_VAR:?REQUIRED_VAR is required}"
```

### 函数定义

```bash
# 使用 local 限定变量作用域
process_file() {
    local file="$1"
    local output_dir="${2:-/tmp/output}"
    
    local filename
    filename=$(basename "$file")
    
    # 处理逻辑
}
```

### 错误处理

```bash
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/temp_*
}
trap cleanup EXIT

# 特定信号处理
trap 'echo "Interrupted"; exit 1' INT TERM
```

## 迭代记录

- 2026-02-12: 初始创建，沉淀 Bash 脚本最佳实践
