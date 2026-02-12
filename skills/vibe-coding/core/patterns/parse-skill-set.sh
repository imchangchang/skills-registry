#!/bin/bash
#
# parse-skill-set.sh - 解析 .skill-set 文件（支持通配符）
#
# 用法: parse-skill-set.sh [.skill-set文件]
#

SKILLS_REGISTRY="$(cd "$(dirname "$0")/../../../.." && pwd)"
SKILL_SET_FILE="${1:-./.skill-set}"

if [[ ! -f "$SKILL_SET_FILE" ]]; then
    echo "Error: File not found: $SKILL_SET_FILE" >&2
    exit 1
fi

# 读取并处理每一行
while IFS= read -r line; do
    # 去除前后空格
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # 跳过空行和注释
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    # 处理通配符
    if [[ "$line" =~ /\*$ ]]; then
        category="${line%/*}"
        category_path="$SKILLS_REGISTRY/skills/$category"
        
        if [[ -d "$category_path" ]]; then
            # 遍历目录下所有子目录
            for skill_dir in "$category_path"/*; do
                if [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]]; then
                    skill_name=$(basename "$skill_dir")
                    echo "$category/$skill_name"
                fi
            done | sort
        fi
    else
        # 普通 skill 路径
        echo "$line"
    fi
done < "$SKILL_SET_FILE" | awk '!seen[$0]++'  # 去重
