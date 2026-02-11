#!/bin/bash
# 更新项目中的技能链接

set -e

if [ ! -f ".skill-set" ]; then
    echo "错误: 当前目录未初始化 Vibe Coding"
    echo "请先运行: init-vibe.sh"
    exit 1
fi

if [ ! -x ".vibe/scripts/link-skills.sh" ]; then
    echo "错误: 未找到 link-skills.sh 脚本"
    exit 1
fi

echo "更新技能链接..."
.vibe/scripts/link-skills.sh

echo ""
echo "✅ 技能已更新"
