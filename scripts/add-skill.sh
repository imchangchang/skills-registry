#!/bin/bash
# 添加技能到当前项目

set -e

SKILLS_REGISTRY="${SKILLS_REGISTRY:-$HOME/skills-registry}"

usage() {
    echo "Usage: add-skill.sh <skill-path>"
    echo ""
    echo "Example:"
    echo "  add-skill.sh embedded/mcu/st-stm32"
    echo "  add-skill.sh dev-workflow/git-commits"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

SKILL_PATH="$1"
SKILL_NAME=$(basename "$SKILL_PATH")

# 检查当前目录是否已初始化
if [ ! -f ".skill-set" ]; then
    echo "错误: 当前目录未初始化 Vibe Coding"
    echo "请先运行: init-vibe.sh"
    exit 1
fi

# 检查技能是否存在
if [ ! -d "$SKILLS_REGISTRY/skills/$SKILL_PATH" ]; then
    echo "错误: 技能不存在: $SKILL_PATH"
    echo "可用技能:"
    find "$SKILLS_REGISTRY/skills" -name "SKILL.md" -exec dirname {} \; | sed "s|$SKILLS_REGISTRY/skills/||"
    exit 1
fi

# 检查是否已添加
if grep -q "^$SKILL_PATH$" .skill-set 2>/dev/null; then
    echo "技能已存在: $SKILL_PATH"
    exit 0
fi

# 添加到 .skill-set
echo "$SKILL_PATH" >> .skill-set
echo "[OK] 已添加技能到 .skill-set: $SKILL_NAME"
