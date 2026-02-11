#!/bin/bash
# Skills Registry 安装脚本
# 将技能库安装到本地环境

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REGISTRY="$(dirname "$SCRIPT_DIR")"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 安装主函数
install_skills_registry() {
    log_step "开始安装 Skills Registry"
    
    # 1. 检查技能库路径
    if [ ! -f "$SKILLS_REGISTRY/README.md" ]; then
        log_error "无法找到技能库: $SKILLS_REGISTRY"
        exit 1
    fi
    
    log_info "技能库路径: $SKILLS_REGISTRY"
    
    # 2. 设置环境变量
    local shell_type=$(detect_shell)
    local shell_rc=$(get_shell_rc "$shell_type")
    
    log_step "配置环境变量 ($shell_type)"
    
    if [ -z "$shell_rc" ]; then
        log_warn "无法检测 shell 配置文件，请手动添加环境变量"
        echo "请添加以下内容到您的 shell 配置文件："
        echo "export SKILLS_REGISTRY=\"$SKILLS_REGISTRY\""
        echo "export PATH=\"\$SKILLS_REGISTRY/scripts:\$PATH\""
    else
        # 检查是否已安装
        if grep -q "SKILLS_REGISTRY" "$shell_rc" 2>/dev/null; then
            log_warn "SKILLS_REGISTRY 已配置在 $shell_rc"
            read -p "是否更新? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "跳过环境变量配置"
            else
                # 删除旧配置
                sed -i '/# Skills Registry/d' "$shell_rc" 2>/dev/null || true
                sed -i '/SKILLS_REGISTRY/d' "$shell_rc" 2>/dev/null || true
                
                # 添加新配置
                cat >> "$shell_rc" << EOF

# Skills Registry
export SKILLS_REGISTRY="$SKILLS_REGISTRY"
export PATH="\$SKILLS_REGISTRY/scripts:\$PATH"
EOF
                log_info "已更新 $shell_rc"
            fi
        else
            # 添加配置
            cat >> "$shell_rc" << EOF

# Skills Registry
export SKILLS_REGISTRY="$SKILLS_REGISTRY"
export PATH="\$SKILLS_REGISTRY/scripts:\$PATH"
EOF
            log_info "已添加环境变量到 $shell_rc"
        fi
        
        log_info "请运行: source $shell_rc"
    fi
    
    # 3. 创建全局可用命令
    log_step "创建 vibe 命令"
    
    local vibe_cmd="$SKILLS_REGISTRY/scripts/vibe"
    cat > "$vibe_cmd" << 'SCRIPT_EOF'
#!/bin/bash
# vibe - Vibe Coding 工具入口

SKILLS_REGISTRY="${SKILLS_REGISTRY:-$HOME/skills-registry}"

usage() {
    echo "Usage: vibe <command> [options]"
    echo ""
    echo "Commands:"
    echo "  init [path]     初始化当前目录（或指定路径）为 Vibe Coding 项目"
    echo "  skill <name>    添加技能到当前项目"
    echo "  update          更新所有技能链接"
    echo "  status          查看当前项目 Vibe 状态"
    echo ""
    echo "Examples:"
    echo "  vibe init                    # 初始化当前目录"
    echo "  vibe init ~/projects/myapp   # 初始化指定目录"
    echo "  vibe skill docker            # 添加 docker 技能"
    echo "  vibe update                  # 更新技能链接"
}

case "${1:-}" in
    init)
        shift
        "$SKILLS_REGISTRY/scripts/init-vibe.sh" "$@"
        ;;
    skill)
        shift
        "$SKILLS_REGISTRY/scripts/add-skill.sh" "$@"
        ;;
    update)
        "$SKILLS_REGISTRY/scripts/update-skills.sh"
        ;;
    status)
        "$SKILLS_REGISTRY/scripts/vibe-status.sh"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "错误: 未知命令: ${1:-}"
        usage
        exit 1
        ;;
esac
SCRIPT_EOF
    chmod +x "$vibe_cmd"
    log_info "已创建 vibe 命令"
    
    # 4. 创建辅助脚本
    create_helper_scripts
    
    log_step "安装完成！"
    echo ""
    echo "使用方法:"
    echo "  1. 重新加载 shell 配置: source $shell_rc"
    echo "  2. 在任意项目目录运行: vibe init"
    echo "  3. 或运行: $SKILLS_REGISTRY/scripts/init-vibe.sh"
    echo ""
    echo "项目位置: $SKILLS_REGISTRY"
}

# 创建辅助脚本
create_helper_scripts() {
    log_step "创建辅助脚本"
    
    # init-vibe.sh 将在下一步创建
    # 这里确保目录存在即可
    mkdir -p "$SKILLS_REGISTRY/scripts"
}

# 主函数
main() {
    case "${1:-install}" in
        install)
            install_skills_registry
            ;;
        uninstall)
            log_warn "卸载功能尚未实现"
            log_info "手动卸载方法:"
            echo "  1. 从 shell 配置文件 (~/.bashrc 或 ~/.zshrc) 删除 SKILLS_REGISTRY 相关行"
            echo "  2. 删除 $SKILLS_REGISTRY 目录"
            ;;
        *)
            echo "Usage: $0 [install|uninstall]"
            exit 1
            ;;
    esac
}

main "$@"
