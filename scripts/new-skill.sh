#!/bin/bash
# 创建新技能脚本

set -e

SKILL_PATH="$1"

if [ -z "$SKILL_PATH" ]; then
    echo "Usage: $0 <category>/<skill-name>"
    echo "Example: $0 embedded/mcu/st-stm32"
    exit 1
fi

SKILL_ROOT="$(dirname "$(dirname "$(realpath "$0")")")/skills"
FULL_PATH="$SKILL_ROOT/$SKILL_PATH"

if [ -d "$FULL_PATH" ]; then
    echo "Error: Skill already exists at $FULL_PATH"
    exit 1
fi

mkdir -p "$FULL_PATH"/{patterns/{templates,examples},references}

# 提取技能名称
SKILL_NAME=$(basename "$SKILL_PATH")

# 创建 SKILL.md
cat > "$FULL_PATH/SKILL.md" << EOF
---
name: ${SKILL_NAME}
description: TODO: 添加技能描述
created: $(date +%Y-%m-%d)
status: draft
---

# ${SKILL_NAME}

## 适用场景
TODO: 描述在什么情况下使用此技能

## 核心概念
TODO: 列出关键概念（3-5 个）

## 快速开始
TODO: 最简示例，让 AI 快速理解

## 代码模式

### 模式 1：TODO
\`\`\`
// TODO: 添加核心代码模板
\`\`\`

## 常见问题

### 问题 1：TODO
**现象**：TODO
**原因**：TODO
**解决**：TODO

## 参考资料
- references/quick-ref.md - 速查表
- references/detailed/ - 详细文档

## 迭代记录
- $(date +%Y-%m-%d): 初始创建
EOF

# 创建 HISTORY.md
cat > "$FULL_PATH/HISTORY.md" << EOF
# ${SKILL_NAME} 变更记录

## $(date +%Y-%m-%d)
- 初始创建
EOF

# 创建 quick-ref.md
cat > "$FULL_PATH/references/quick-ref.md" << EOF
# ${SKILL_NAME} 速查表

TODO: 添加一页纸速查内容
EOF

# 创建 metadata.json
CATEGORY=$(dirname "$SKILL_PATH" | tr '/' '-')
cat > "$FULL_PATH/metadata.json" << EOF
{
  "name": "${SKILL_NAME}",
  "description": "TODO: 添加技能描述",
  "type": "${CATEGORY}",
  "created": "$(date +%Y-%m-%d)",
  "status": "draft",
  "tags": []
}
EOF

echo "[OK] Created skill: $FULL_PATH"
echo ""
echo "Next steps:"
echo "  1. Edit SKILL.md to add core content"
echo "  2. Add patterns to patterns/"
echo "  3. Add references to references/"
