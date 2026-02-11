#!/bin/bash
# 初始化 Vibe Coding 环境（非侵入式）
# 在任意目录运行，将该目录改造为 Vibe Coding 风格

set -e

SKILLS_REGISTRY="${SKILLS_REGISTRY:-$HOME/skills-registry}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 如果 SKILLS_REGISTRY 未设置，尝试从脚本位置推断
if [ ! -d "$SKILLS_REGISTRY" ]; then
    SKILLS_REGISTRY="$(dirname "$SCRIPT_DIR")"
fi

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 显示帮助
usage() {
    echo "Usage: init-vibe.sh [options] [path]"
    echo ""
    echo "Options:"
    echo "  -s, --skills <list>    初始技能列表，逗号分隔"
    echo "  -f, --force            强制重新初始化"
    echo "  -h, --help             显示帮助"
    echo ""
    echo "Examples:"
    echo "  init-vibe.sh                          # 初始化当前目录"
    echo "  init-vibe.sh ~/projects/myapp         # 初始化指定目录"
    echo "  init-vibe.sh -s stm32,git,docker      # 初始化并添加技能"
}

# 解析参数
TARGET_DIR="."
INITIAL_SKILLS=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skills)
            INITIAL_SKILLS="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# 解析目标目录
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
VIBE_DIR="$TARGET_DIR/.vibe"

echo "目标目录: $TARGET_DIR"

# 检查是否已初始化
if [ -d "$VIBE_DIR" ] && [ "$FORCE" != true ]; then
    log_warn "该目录已初始化 Vibe Coding"
    echo "运行 'vibe update' 更新技能链接"
    echo "或使用 --force 强制重新初始化"
    exit 1
fi

# 检查技能库
if [ ! -d "$SKILLS_REGISTRY/skills" ]; then
    log_error "无法找到技能库: $SKILLS_REGISTRY"
    echo "请设置 SKILLS_REGISTRY 环境变量"
    exit 1
fi

log_info "使用技能库: $SKILLS_REGISTRY"

# 创建 .vibe 目录结构
log_step "创建 .vibe 目录"
mkdir -p "$VIBE_DIR"/{skills,scripts,backups}

# 1. 创建 .skill-set
log_step "创建技能声明文件"
if [ ! -f "$TARGET_DIR/.skill-set" ] || [ "$FORCE" = true ]; then
    cat > "$TARGET_DIR/.skill-set" << 'EOF'
# Vibe Coding 技能声明
# 每行一个技能路径（相对于技能库的 skills/ 目录）
#
# 格式: <category>/<skill-name>
# 示例:
#   dev-workflow/git-commits
#   dev-workflow/quality-gates
#   embedded/mcu/st-stm32

EOF
    
    # 如果指定了初始技能，添加进去
    if [ -n "$INITIAL_SKILLS" ]; then
        echo "$INITIAL_SKILLS" | tr ',' '\n' | while read -r skill; do
            [ -n "$skill" ] && echo "$skill" >> "$TARGET_DIR/.skill-set"
        done
        log_info "已添加初始技能: $INITIAL_SKILLS"
    fi
else
    log_warn ".skill-set 已存在，保留原文件"
    # 备份到 .vibe/backups
    cp "$TARGET_DIR/.skill-set" "$VIBE_DIR/backups/.skill-set.bak.$(date +%Y%m%d%H%M%S)"
fi

# 2. 创建 AGENTS.md（如果不存在）
log_step "创建 AGENTS.md"
if [ ! -f "$TARGET_DIR/AGENTS.md" ] || [ "$FORCE" = true ]; then
    if [ -f "$SKILLS_REGISTRY/templates/AGENTS.md" ]; then
        cp "$SKILLS_REGISTRY/templates/AGENTS.md" "$TARGET_DIR/AGENTS.md"
        log_info "已从模板复制 AGENTS.md"
    else
        # 创建简化版
        cat > "$TARGET_DIR/AGENTS.md" << 'EOF'
# 项目开发指南

本项目使用 Vibe Coding（AI 协作开发）方法论。

## 启用的 Skills

技能通过 `.skill-set` 声明，链接在 `.vibe/skills/` 目录。

## 多代理安全规则（强制）

- [X] 不要创建 `git stash`
- [X] 不要切换分支（除非明确要求）
- [X] 不要修改 `.worktrees/`
- [X] 不要使用 `git add -A`
- [OK] 使用精确文件提交

## 技能迭代

开发中发现 skill 问题：
1. 记录到 `.vibe/.skill-updates-todo.md`
2. 或修改 `$SKILLS_REGISTRY` 中的 skill

---
*Vibe Coding 项目*
EOF
        log_info "已创建简化版 AGENTS.md"
    fi
else
    log_warn "AGENTS.md 已存在，保留原文件"
fi

# 3. 创建技能更新待办
if [ ! -f "$VIBE_DIR/.skill-updates-todo.md" ]; then
    cat > "$VIBE_DIR/.skill-updates-todo.md" << 'EOF'
# Skill 更新待办

开发过程中发现的技能问题或改进点：

## 待办

## 已完成

EOF
fi

# 4. 创建脚本
log_step "创建辅助脚本"

# link-skills.sh
cat > "$VIBE_DIR/scripts/link-skills.sh" << EOF
#!/bin/bash
# 链接技能脚本

SKILLS_REGISTRY="${SKILLS_REGISTRY:-$HOME/skills-registry}"
PROJECT_ROOT="\$(dirname "\$(dirname "\$(dirname "\$(realpath "\$0")")")")"
SKILL_SET="\$PROJECT_ROOT/.skill-set"
SKILLS_DIR="\$PROJECT_ROOT/.vibe/skills"

echo "技能库: \$SKILLS_REGISTRY"
echo ""

if [ ! -f "\$SKILL_SET" ]; then
    echo "错误: 未找到 .skill-set 文件"
    exit 1
fi

if [ ! -d "\$SKILLS_REGISTRY" ]; then
    echo "错误: 未找到技能库"
    echo "请设置 SKILLS_REGISTRY 环境变量"
    exit 1
fi

mkdir -p "\$SKILLS_DIR"

echo "链接技能..."
while IFS= read -r line || [ -n "\$line" ]; do
    line=\$(echo "\$line" | sed 's/#.*//')
    [ -z "\$(echo "\$line" | tr -d '[:space:]')" ] && continue
    
    skill_path=\$(echo "\$line" | tr -d '[:space:]')
    skill_name=\$(basename "\$skill_path")
    source_path="\$SKILLS_REGISTRY/skills/\$skill_path"
    target_path="\$SKILLS_DIR/\$skill_name"
    
    if [ ! -d "\$source_path" ]; then
        echo "  [WARN]  未找到: \$skill_path"
        continue
    fi
    
    if [ -L "\$target_path" ]; then
        rm "\$target_path"
    fi
    
    ln -sf "\$source_path" "\$target_path"
    echo "  [OK] \$skill_name"
done < "\$SKILL_SET"

echo ""
echo "完成！"
EOF
chmod +x "$VIBE_DIR/scripts/link-skills.sh"

# 5. 链接技能
log_step "链接技能"
"$VIBE_DIR/scripts/link-skills.sh"

# 6. 处理 gitignore
log_step "配置忽略文件"

# 检查是否是 git 仓库
if [ -d "$TARGET_DIR/.git" ]; then
    GITIGNORE="$TARGET_DIR/.gitignore"
    IS_GIT_REPO=true
else
    # 不是 git 仓库，创建 .vibeignore
    GITIGNORE="$TARGET_DIR/.vibeignore"
    IS_GIT_REPO=false
fi

# 创建或更新忽略文件
VIBE_IGNORE_PATTERNS="# Vibe Coding (auto-generated)
.vibe/skills/
.vibe/backups/
.skill-updates-todo.md
"

if [ -f "$GITIGNORE" ]; then
    # 检查是否已有 vibe 相关配置
    if ! grep -q "Vibe Coding" "$GITIGNORE"; then
        echo "" >> "$GITIGNORE"
        echo "$VIBE_IGNORE_PATTERNS" >> "$GITIGNORE"
        log_info "已追加到 $(basename "$GITIGNORE")"
    else
        log_info "$(basename "$GITIGNORE") 已配置"
    fi
else
    echo "$VIBE_IGNORE_PATTERNS" > "$GITIGNORE"
    if [ "$IS_GIT_REPO" = true ]; then
        log_info "已创建 .gitignore"
    else
        log_info "已创建 .vibeignore（当前不是 git 仓库）"
        log_info "如以后转为 git 仓库，可将 .vibeignore 内容复制到 .gitignore"
    fi
fi

# 7. 创建 README.vibe.md（如果不存在项目 README）
if [ ! -f "$TARGET_DIR/README.md" ]; then
    log_step "创建项目 README"
    project_name=$(basename "$TARGET_DIR")
    cat > "$TARGET_DIR/README.md" << EOF
# $project_name

## 简介

[项目简介]

## 开发方法

本项目使用 Vibe Coding（AI 协作开发）方法论。

- 技能库: \`$SKILLS_REGISTRY\`
- 技能链接: \`.vibe/skills/\`
- 开发指南: \`AGENTS.md\`

## 快速开始

\`\`\`bash
# 更新技能链接
.vibe/scripts/link-skills.sh

# 查看开发指南
cat AGENTS.md
\`\`\`

## 目录结构

\`\`\`
.
├── .vibe/              # Vibe Coding 配置（自动生成）
│   ├── skills/         # 链接的技能
│   └── scripts/        # 辅助脚本
├── AGENTS.md           # AI 开发指南
└── README.md           # 本文件
\`\`\`
EOF
    log_info "已创建 README.md"
fi

# 完成
log_step "初始化完成！"
echo ""
echo "项目结构:"
find "$TARGET_DIR/.vibe" -type f 2>/dev/null | head -10
echo ""
echo "生成文件:"
ls -la "$TARGET_DIR/AGENTS.md" "$TARGET_DIR/.skill-set" 2>/dev/null || true
echo ""
echo "下一步:"
echo "  1. 编辑 .skill-set 声明所需技能"
echo "  2. 运行 .vibe/scripts/link-skills.sh 更新链接"
echo "  3. 编辑 AGENTS.md 填写项目信息"
echo "  4. 开始开发！"
echo ""
echo "注意:"
if [ "$IS_GIT_REPO" = true ]; then
    echo "  - .vibe/skills/ 已添加到 .gitignore（不会提交到版本控制）"
else
    echo "  - 当前不是 git 仓库，如需要请自行初始化"
    echo "  - .vibeignore 已创建，可作为 .gitignore 参考"
fi
echo "  - 所有 Vibe Coding 文件都在 .vibe/ 目录，保持工作区整洁"
