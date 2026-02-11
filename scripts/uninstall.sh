#!/bin/bash
# Skills Registry 卸载脚本
# 完全卸载技能库和相关配置

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

# 检测 shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# 获取 shell 配置文件
get_shell_rc() {
    local shell_type=$1
    case "$shell_type" in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# 从 shell 配置文件移除环境变量
remove_from_shell_rc() {
    local shell_rc=$1
    
    if [ ! -f "$shell_rc" ]; then
        return
    fi
    
    log_step "清理 shell 配置: $shell_rc"
    
    # 创建临时文件
    local tmp_file=$(mktemp)
    
    # 移除 Skills Registry 相关行
    grep -v "# Skills Registry" "$shell_rc" | \
    grep -v "SKILLS_REGISTRY=" | \
    grep -v 'PATH="\$SKILLS_REGISTRY/scripts:' > "$tmp_file" || true
    
    # 检查是否有实质性变化
    if diff -q "$shell_rc" "$tmp_file" > /dev/null 2>&1; then
        log_info "无需清理 $shell_rc"
        rm "$tmp_file"
    else
        # 备份原文件
        cp "$shell_rc" "$shell_rc.backup.$(date +%Y%m%d%H%M%S)"
        mv "$tmp_file" "$shell_rc"
        log_info "已清理 $shell_rc"
        log_info "备份文件: $shell_rc.backup.*"
    fi
}

# 卸载主函数
uninstall_skills_registry() {
    log_step "开始卸载 Skills Registry"
    
    # 1. 查找技能库位置
    local skills_registry=""
    
    if [ -n "${SKILLS_REGISTRY:-}" ] && [ -d "$SKILLS_REGISTRY" ]; then
        skills_registry="$SKILLS_REGISTRY"
    elif [ -d "$HOME/skills-registry" ]; then
        skills_registry="$HOME/skills-registry"
    else
        log_error "无法找到技能库安装位置"
        log_info "请手动删除技能库目录"
        exit 1
    fi
    
    log_info "技能库位置: $skills_registry"
    
    # 2. 确认卸载
    echo ""
    log_warn "即将卸载 Skills Registry"
    echo "  - 删除目录: $skills_registry"
    echo "  - 清理 shell 环境变量"
    echo "  - 移除 vibe 命令"
    echo ""
    read -p "确认卸载? [y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        exit 0
    fi
    
    # 3. 清理 shell 配置
    local shell_type=$(detect_shell)
    local shell_rc=$(get_shell_rc "$shell_type")
    
    if [ -n "$shell_rc" ]; then
        remove_from_shell_rc "$shell_rc"
    fi
    
    # 也检查并清理其他可能的 shell 配置
    for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
        if [ -f "$rc" ] && [ "$rc" != "$shell_rc" ]; then
            if grep -q "SKILLS_REGISTRY" "$rc" 2>/dev/null; then
                remove_from_shell_rc "$rc"
            fi
        fi
    done
    
    # 4. 删除技能库目录
    log_step "删除技能库"
    if [ -d "$skills_registry" ]; then
        # 先备份配置（如果用户需要）
        local backup_dir="$HOME/.skills-registry-backup.$(date +%Y%m%d%H%M%S)"
        echo "创建备份: $backup_dir"
        cp -r "$skills_registry" "$backup_dir"
        
        # 删除原目录
        rm -rf "$skills_registry"
        log_info "已删除: $skills_registry"
        log_info "备份保留在: $backup_dir"
    fi
    
    # 5. 删除 vibe 命令（如果在 PATH 中的其他位置）
    if command -v vibe >/dev/null 2>&1; then
        local vibe_path=$(which vibe)
        if [[ "$vibe_path" == *"skills-registry"* ]]; then
            log_info "vibe 命令将被移除（通过环境变量）"
        fi
    fi
    
    # 6. 检查并列出已初始化的项目
    log_step "检查已初始化的项目"
    echo "以下项目可能包含 .vibe 目录，请手动处理:"
    find ~ -type d -name ".vibe" 2>/dev/null | while read -r vibe_dir; do
        local project_dir=$(dirname "$vibe_dir")
        echo "  - $project_dir"
    done
    
    echo ""
    log_step "卸载完成！"
    echo ""
    echo "后续操作:"
    echo "  1. 重新加载 shell: source $shell_rc"
    echo "  2. 如需恢复，从备份还原: $backup_dir"
    echo "  3. 如需清理项目中的 .vibe 目录，请手动删除"
    echo ""
    echo "项目清理命令（如需）:"
    echo "  find ~ -type d -name '.vibe' -exec rm -rf {} + 2>/dev/null"
}

# 显示帮助
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     显示帮助"
    echo "  -y, --yes      自动确认（危险！）"
    echo ""
    echo "卸载内容:"
    echo "  - 删除技能库目录"
    echo "  - 清理 shell 环境变量"
    echo "  - 移除 vibe 命令"
    echo ""
    echo "注意: 不会删除项目中的 .vibe 目录"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
        -y|--yes)
            # 自动确认模式
            REPLY="y"
            uninstall_skills_registry
            ;;
        "")
            uninstall_skills_registry
            ;;
        *)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
