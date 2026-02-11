#!/usr/bin/env bash
# Docker 环境自动设置脚本
# 基于 OpenClaw docker-setup.sh 简化版

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# 配置默认值
export APP_NAME="${APP_NAME:-myapp}"
export APP_IMAGE="${APP_IMAGE:-$APP_NAME:local}"
export APP_PORT="${APP_PORT:-8080}"
export CONFIG_DIR="${CONFIG_DIR:-$HOME/.$APP_NAME}"
export WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/.$APP_NAME/workspace}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "未安装 Docker"
        exit 1
    fi
    
    if ! docker compose version >/dev/null 2>&1; then
        log_error "未安装 Docker Compose"
        exit 1
    fi
    
    log_info "依赖检查通过"
}

# 创建必要目录
setup_directories() {
    log_info "设置目录..."
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$WORKSPACE_DIR"
    log_info "配置目录: $CONFIG_DIR"
    log_info "工作目录: $WORKSPACE_DIR"
}

# 生成随机 Token
generate_token() {
    if [[ -z "${APP_TOKEN:-}" ]]; then
        if command -v openssl >/dev/null 2>&1; then
            APP_TOKEN="$(openssl rand -hex 32)"
        else
            APP_TOKEN="$(python3 -c "import secrets; print(secrets.token_hex(32))")"
        fi
        export APP_TOKEN
    fi
}

# 创建 .env 文件
create_env_file() {
    local env_file="$PROJECT_ROOT/.env"
    
    log_info "创建环境配置: $env_file"
    
    cat > "$env_file" << EOF
# 自动生成于 $(date)
# 可手动修改

APP_NAME=$APP_NAME
APP_IMAGE=$APP_IMAGE
APP_PORT=$APP_PORT
APP_TOKEN=$APP_TOKEN

CONFIG_DIR=$CONFIG_DIR
WORKSPACE_DIR=$WORKSPACE_DIR
EOF
    
    log_info "配置已保存"
}

# 构建镜像
build_image() {
    log_info "构建 Docker 镜像: $APP_IMAGE"
    
    docker build \
        -t "$APP_IMAGE" \
        -f "$PROJECT_ROOT/Dockerfile" \
        "$PROJECT_ROOT"
    
    log_info "镜像构建完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    cd "$PROJECT_ROOT"
    docker compose up -d app-gateway
    
    log_info "服务已启动"
    log_info "访问: http://localhost:$APP_PORT"
}

# 显示帮助信息
show_help() {
    cat << EOF
Docker 环境设置脚本

用法: $0 [命令]

命令:
    setup       完整设置（构建 + 启动）
    build       仅构建镜像
    start       仅启动服务
    stop        停止服务
    restart     重启服务
    logs        查看日志
    cli         运行 CLI 容器
    clean       清理容器和镜像

环境变量:
    APP_NAME        应用名称 (默认: myapp)
    APP_PORT        服务端口 (默认: 8080)
    CONFIG_DIR      配置目录 (默认: ~/.myapp)
    WORKSPACE_DIR   工作目录 (默认: ~/.myapp/workspace)

示例:
    APP_NAME=myproject APP_PORT=3000 $0 setup
EOF
}

# 主函数
main() {
    case "${1:-setup}" in
        setup)
            check_dependencies
            setup_directories
            generate_token
            create_env_file
            build_image
            start_services
            log_info "设置完成！"
            echo ""
            echo "常用命令:"
            echo "  查看日志: $0 logs"
            echo "  运行 CLI: $0 cli"
            echo "  停止服务: $0 stop"
            ;;
        build)
            build_image
            ;;
        start)
            start_services
            ;;
        stop)
            cd "$PROJECT_ROOT"
            docker compose down
            log_info "服务已停止"
            ;;
        restart)
            cd "$PROJECT_ROOT"
            docker compose restart
            log_info "服务已重启"
            ;;
        logs)
            cd "$PROJECT_ROOT"
            docker compose logs -f app-gateway
            ;;
        cli)
            cd "$PROJECT_ROOT"
            docker compose run --rm app-cli
            ;;
        clean)
            cd "$PROJECT_ROOT"
            docker compose down --rmi local --volumes
            log_info "已清理"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
