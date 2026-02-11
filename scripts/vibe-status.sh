#!/bin/bash
# 查看当前项目的 Vibe Coding 状态

set -e

echo "=== Vibe Coding 状态 ==="
echo ""

# 检查是否初始化
if [ ! -d ".vibe" ]; then
    echo "❌ 未初始化"
    echo "运行: init-vibe.sh"
    exit 1
fi

echo "✅ 已初始化"
echo ""

# 显示技能库路径
if [ -n "$SKILLS_REGISTRY" ]; then
    echo "技能库: $SKILLS_REGISTRY"
else
    echo "技能库: $HOME/skills-registry (默认)"
fi
echo ""

# 显示启用的技能
if [ -f ".skill-set" ]; then
    echo "启用的技能:"
    grep -v "^#" .skill-set | grep -v "^$" | while read -r line; do
        echo "  • $line"
    done
else
    echo "未找到 .skill-set"
fi
echo ""

# 显示链接的技能
if [ -d ".vibe/skills" ]; then
    echo "已链接的技能:"
    ls -la .vibe/skills/ | grep "^l" | awk '{print "  → " $9 " -> " $11}'
fi
echo ""

# 检查 gitignore
if [ -f ".gitignore" ]; then
    if grep -q ".vibe" .gitignore; then
        echo "✅ .gitignore 已配置"
    else
        echo "⚠️  .gitignore 未配置 .vibe"
    fi
else
    if [ -f ".vibeignore" ]; then
        echo "ℹ️  使用 .vibeignore（非 git 仓库）"
    fi
fi
