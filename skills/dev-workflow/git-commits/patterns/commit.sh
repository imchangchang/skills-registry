#!/bin/bash
# commit.sh - 精确提交脚本
# 用法: ./commit.sh "<message>" <file1> [file2 ...]

set -euo pipefail

usage() {
    echo "Usage: $0 <commit-message> <file1> [file2 ...]"
    echo "Example: $0 \"feat: add gpio interrupt\" src/gpio.c src/gpio.h"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

MESSAGE="$1"
shift

# 检查是否误用 "git add -A" 模式
if [[ "$*" == *"."* ]] || [[ "$*" == *"*"* ]]; then
    echo "[X] Error: 不要使用通配符或 '.' 提交所有文件"
    echo "请明确指定要提交的文件"
    exit 1
fi

# 验证文件存在
for file in "$@"; do
    if [ ! -f "$file" ] && [ ! -d "$file" ]; then
        # 检查是否已追踪
        if ! git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            echo "[X] Error: 文件不存在: $file"
            exit 1
        fi
    fi
done

# 取消所有暂存，确保只提交指定文件
git reset HEAD >/dev/null 2>&1 || true

# 添加指定文件
git add "$@"

# 检查是否有变更
git diff --cached --quiet && {
    echo "[WARN] Warning: 没有要提交的变更"
    exit 1
}

# 提交
git commit -m "$MESSAGE"

echo "[OK] 提交成功: $MESSAGE"
echo "文件数: $#"
