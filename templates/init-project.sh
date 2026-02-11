#!/bin/bash
# 初始化 Vibe Coding 项目脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REGISTRY="$(dirname "$SCRIPT_DIR")"

usage() {
    echo "Usage: $0 <project-name> [options]"
    echo ""
    echo "Options:"
    echo "  -s, --skills <skill1,skill2,...>  要启用的技能"
    echo "  -d, --dir <directory>             项目目录（默认：~/projects/）"
    echo "  -h, --help                        显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 my-robot --skills embedded/mcu/st-stm32,dev-workflow/git-commits"
    exit 1
}

# 解析参数
PROJECT_NAME=""
SKILLS=""
BASE_DIR="$HOME/projects"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skills)
            SKILLS="$2"
            shift 2
            ;;
        -d|--dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "未知选项: $1"
            usage
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                echo "错误: 只能指定一个项目名称"
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    echo "错误: 请指定项目名称"
    usage
fi

PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

# 检查目录是否存在
if [ -d "$PROJECT_DIR" ]; then
    echo "错误: 目录已存在: $PROJECT_DIR"
    exit 1
fi

echo "创建项目: $PROJECT_NAME"
echo "位置: $PROJECT_DIR"
echo ""

# 创建目录结构
mkdir -p "$PROJECT_DIR"/{src,docs,scripts}

# 复制 AGENTS.md 模板
cp "$SCRIPT_DIR/AGENTS.md" "$PROJECT_DIR/AGENTS.md"

# 创建 .skill-set
if [ -n "$SKILLS" ]; then
    echo "$SKILLS" | tr ',' '\n' > "$PROJECT_DIR/.skill-set"
else
    cat > "$PROJECT_DIR/.skill-set" << 'EOF'
# 声明本项目使用的技能
# 每行一个技能路径（相对于 skill registry 的 skills/ 目录）
#
# 示例：
# embedded/mcu/st-stm32
# embedded/rtos/freertos
# dev-workflow/git-commits
# dev-workflow/quality-gates
EOF
fi

# 创建 .skill-updates-todo.md
cat > "$PROJECT_DIR/.skill-updates-todo.md" << 'EOF'
# Skill 更新待办

开发过程中如发现技能问题，记录在此处，定期更新到 skill 库。

## 待办

## 已完成

EOF

# 创建 README.md
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

## 简介

[项目简介]

## 技术栈

- 语言：
- 平台：
- 构建工具：

## 快速开始

### 环境准备

1. 克隆技能库（如未安装）
   \`\`\`bash
   git clone <your-skills-repo> ~/skills-registry
   \`\`\`

2. 链接技能
   \`\`\`bash
   cd $PROJECT_DIR
   ./scripts/link-skills.sh
   \`\`\`

### 构建

\`\`\`bash
./scripts/build.sh
\`\`\`

### 开发

根据 \`AGENTS.md\` 中的指南与 AI 协作开发。

## 目录结构

\`\`\`
.
├── src/              # 源代码
├── docs/             # 文档
├── scripts/          # 项目脚本
├── skills/           # 链接的技能（自动生成）
├── AGENTS.md         # AI 开发指南
└── README.md         # 本文件
\`\`\`

## 贡献

使用 Vibe Coding 方法论开发。

---

*创建时间：$(date +%Y-%m-%d)*
EOF

# 创建 link-skills.sh
cat > "$PROJECT_DIR/scripts/link-skills.sh" << 'EOF'
#!/bin/bash
# 链接技能脚本

SKILL_REGISTRY="${SKILL_REGISTRY:-$HOME/skills-registry}"
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"
SKILL_SET="$PROJECT_ROOT/.skill-set"
SKILLS_DIR="$PROJECT_ROOT/skills"

echo "Skill Registry: $SKILL_REGISTRY"
echo ""

if [ ! -f "$SKILL_SET" ]; then
    echo "错误: 未找到 .skill-set 文件"
    exit 1
fi

if [ ! -d "$SKILL_REGISTRY" ]; then
    echo "错误: 未找到技能库: $SKILL_REGISTRY"
    echo "请克隆技能库: git clone <your-skills-repo> ~/skills-registry"
    exit 1
fi

mkdir -p "$SKILLS_DIR"

echo "链接技能..."
while IFS= read -r line || [ -n "$line" ]; do
    # 跳过空行和注释
    line=$(echo "$line" | sed 's/#.*//')
    [ -z "$(echo "$line" | tr -d '[:space:]')" ] && continue
    
    skill_path=$(echo "$line" | tr -d '[:space:]')
    skill_name=$(basename "$skill_path")
    source_path="$SKILL_REGISTRY/skills/$skill_path"
    target_path="$SKILLS_DIR/$skill_name"
    
    if [ ! -d "$source_path" ]; then
        echo "  [WARN]  未找到技能: $skill_path"
        continue
    fi
    
    if [ -L "$target_path" ]; then
        rm "$target_path"
    fi
    
    ln -sf "$source_path" "$target_path"
    echo "  [OK] $skill_name"
done < "$SKILL_SET"

echo ""
echo "完成！技能链接在: $SKILLS_DIR"
EOF

chmod +x "$PROJECT_DIR/scripts/link-skills.sh"

# 创建 gate.sh（质量门禁模板）
cat > "$PROJECT_DIR/scripts/gate.sh" << 'EOF'
#!/bin/bash
# 质量门禁脚本
# 根据项目需求修改

set -e

echo "[SEARCH] 运行质量门禁..."

# TODO: 添加项目特定的检查
# 示例：
# - 编译检查
# - 代码格式检查
# - 测试运行

echo "[OK] 质量门禁通过"
EOF

chmod +x "$PROJECT_DIR/scripts/gate.sh"

echo "项目创建完成！"
echo ""
echo "目录结构:"
find "$PROJECT_DIR" -type f | head -15
echo ""
echo "下一步:"
echo "  1. cd $PROJECT_DIR"
echo "  2. 编辑 .skill-set 声明所需技能"
echo "  3. ./scripts/link-skills.sh"
echo "  4. 编辑 AGENTS.md 填写项目信息"
echo "  5. 开始开发！"
