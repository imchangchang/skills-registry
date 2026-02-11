#!/bin/bash
# 从项目中移除 Vibe Coding
# 非侵入式清理，保留原项目文件

set -e

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
    echo "Usage: remove-vibe.sh [options] [path]"
    echo ""
    echo "Options:"
    echo "  -y, --yes      自动确认，不询问"
    echo "  -k, --keep     保留备份，不移除 .vibe 目录"
    echo "  -h, --help     显示帮助"
    echo ""
    echo "说明:"
    echo "  从指定目录（默认当前目录）移除 Vibe Coding 配置"
    echo "  可以选择保留备份或完全删除"
}

# 解析参数
TARGET_DIR="."
AUTO_CONFIRM=false
KEEP_BACKUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        -k|--keep)
            KEEP_BACKUP=true
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
if [ ! -d "$TARGET_DIR" ]; then
    log_error "目录不存在: $TARGET_DIR"
    exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
VIBE_DIR="$TARGET_DIR/.vibe"

echo "目标目录: $TARGET_DIR"

# 检查是否已初始化
if [ ! -d "$VIBE_DIR" ]; then
    log_error "该目录未初始化 Vibe Coding"
    echo "未找到 .vibe 目录"
    exit 1
fi

# 显示将要删除的内容
echo ""
log_step "将要移除的内容:"
echo "  目录: $VIBE_DIR"

if [ -d "$TARGET_DIR/.ai-context" ]; then
    echo "  目录: .ai-context/"
fi

if [ -f "$TARGET_DIR/.skill-set" ]; then
    echo "  文件: .skill-set"
fi

if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    echo "  文件: AGENTS.md"
fi

if [ -f "$TARGET_DIR/.vibeignore" ]; then
    echo "  文件: .vibeignore"
fi

# 从 .gitignore 中移除的配置
if [ -f "$TARGET_DIR/.gitignore" ]; then
    if grep -q "Vibe Coding" "$TARGET_DIR/.gitignore" 2>/dev/null; then
        echo "  配置: 从 .gitignore 移除 Vibe 相关行"
    fi
fi

echo ""

# 确认
if [ "$AUTO_CONFIRM" != true ]; then
    log_warn "确认移除上述内容?"
    read -p "确认? [y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消操作"
        exit 0
    fi
fi

# 备份（如果需要）
if [ "$KEEP_BACKUP" = true ]; then
    BACKUP_DIR="$TARGET_DIR/.vibe-backup.$(date +%Y%m%d%H%M%S)"
    log_step "创建备份: $BACKUP_DIR"
    cp -r "$VIBE_DIR" "$BACKUP_DIR"
    
    if [ -f "$TARGET_DIR/.skill-set" ]; then
        cp "$TARGET_DIR/.skill-set" "$BACKUP_DIR/"
    fi
    
    if [ -f "$TARGET_DIR/AGENTS.md" ]; then
        cp "$TARGET_DIR/AGENTS.md" "$BACKUP_DIR/"
    fi
    
    log_info "备份完成"
fi

# 开始移除
log_step "移除 Vibe Coding 配置"

# 1. 删除 .vibe 目录
if [ -d "$VIBE_DIR" ]; then
    rm -rf "$VIBE_DIR"
    log_info "已删除: .vibe/"
fi

# 2. 删除 .ai-context 目录
if [ -d "$TARGET_DIR/.ai-context" ]; then
    rm -rf "$TARGET_DIR/.ai-context"
    log_info "已删除: .ai-context/"
fi

# 3. 删除 .skill-set
if [ -f "$TARGET_DIR/.skill-set" ]; then
    rm "$TARGET_DIR/.skill-set"
    log_info "已删除: .skill-set"
fi

# 4. 删除 AGENTS.md
if [ -f "$TARGET_DIR/AGENTS.md" ]; then
    rm "$TARGET_DIR/AGENTS.md"
    log_info "已删除: AGENTS.md"
fi

# 5. 删除 .vibeignore
if [ -f "$TARGET_DIR/.vibeignore" ]; then
    rm "$TARGET_DIR/.vibeignore"
    log_info "已删除: .vibeignore"
fi

# 6. 清理 .gitignore
if [ -f "$TARGET_DIR/.gitignore" ]; then
    if grep -q "Vibe Coding" "$TARGET_DIR/.gitignore" 2>/dev/null; then
        log_step "清理 .gitignore"
        
        # 创建临时文件
        tmp_file=$(mktemp)
        
        # 移除 Vibe Coding 相关行（兼容新旧两种格式）
        grep -v "# Vibe Coding" "$TARGET_DIR/.gitignore" | \
        grep -v "\.ai-context/" | \
        grep -v "\.skill-set" | \
        grep -v "\.vibe/" | \
        grep -v "AGENTS\.md" | \
        grep -v "\.vibe/skills/" | \
        grep -v "\.vibe/backups/" | \
        grep -v "\.skill-updates-todo\.md" | \
        grep -v "\.ai-context/\*" | \
        grep -v "!\.ai-context/\.gitkeep" > "$tmp_file" || true
        
        # 检查是否有变化
        if ! diff -q "$TARGET_DIR/.gitignore" "$tmp_file" > /dev/null 2>&1; then
            # 备份原文件
            cp "$TARGET_DIR/.gitignore" "$TARGET_DIR/.gitignore.backup.$(date +%Y%m%d%H%M%S)"
            mv "$tmp_file" "$TARGET_DIR/.gitignore"
            log_info "已清理 .gitignore"
        else
            rm "$tmp_file"
        fi
    fi
fi

# 完成
log_step "移除完成！"
echo ""

if [ "$KEEP_BACKUP" = true ]; then
    echo "备份位置: $BACKUP_DIR"
    echo "如需恢复，手动复制备份文件"
fi

echo ""
echo "项目已恢复为普通项目"
