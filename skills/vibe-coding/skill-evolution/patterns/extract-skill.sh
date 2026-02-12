#!/bin/bash
#
# extract-skill.sh - 从项目中提取 Skill 更新，生成导入包
#
# 用法:
#   extract-skill.sh --source <project_path> --target-skill <skill_name> --output <package_path>
#   extract-skill.sh --source <project_path> --batch-mode --output-dir <dir>
#

set -euo pipefail

# 默认配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR=""
TARGET_SKILL=""
OUTPUT_PATH=""
OUTPUT_DIR=""
BATCH_MODE=false
DRY_RUN=false
VERBOSE=false

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 使用说明
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

从项目中提取 Skill 更新，生成导入包

Options:
    --source <path>       项目源代码目录（必须）
    --target-skill <name> 目标 Skill 名称（如 embedded/mcu/stm32）
    --output <path>       输出导入包路径（.pkg 文件）
    --output-dir <path>   批量模式输出目录
    --batch-mode          批量提取所有待办
    --dry-run             预览模式，不实际生成文件
    --verbose             详细输出
    --help                显示此帮助

Examples:
    # 提取单个 Skill 更新
    $(basename "$0") --source ~/projects/my-project --target-skill embedded/mcu/stm32 --output ~/stm32-update.pkg

    # 批量提取所有待办
    $(basename "$0") --source ~/projects/my-project --batch-mode --output-dir ~/skill-packages/

    # 预览模式
    $(basename "$0") --source ~/projects/my-project --target-skill embedded/mcu/stm32 --dry-run
EOF
}

# 日志输出
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --target-skill)
                TARGET_SKILL="$2"
                shift 2
                ;;
            --output)
                OUTPUT_PATH="$2"
                shift 2
                ;;
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --batch-mode)
                BATCH_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# 验证参数
validate_args() {
    if [[ -z "$SOURCE_DIR" ]]; then
        log_error "--source is required"
        exit 1
    fi

    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "Source directory does not exist: $SOURCE_DIR"
        exit 1
    fi

    if [[ "$BATCH_MODE" == false ]]; then
        if [[ -z "$TARGET_SKILL" ]]; then
            log_error "--target-skill is required (or use --batch-mode)"
            exit 1
        fi
        if [[ -z "$OUTPUT_PATH" ]]; then
            log_error "--output is required (or use --batch-mode)"
            exit 1
        fi
    else
        if [[ -z "$OUTPUT_DIR" ]]; then
            log_error "--output-dir is required in batch mode"
            exit 1
        fi
    fi
}

# 扫描 Skill 待办文件
scan_skill_todos() {
    local source_dir="$1"
    local todo_file="$source_dir/.vibe/.skill-updates-todo.md"

    if [[ ! -f "$todo_file" ]]; then
        log_warn "No .skill-updates-todo.md found in $source_dir/.vibe/"
        return 1
    fi

    if [[ "$VERBOSE" == true ]]; then
        log_info "Found skill updates todo file: $todo_file"
    fi

    echo "$todo_file"
    return 0
}

# 解析待办项
parse_todos() {
    local todo_file="$1"
    local target_skill="${2:-}"

    # 读取待办项，格式如下：
    # ## 待办
    # - [ ] skill-name: 描述
    #   发现时间：2026-02-12
    #   项目：my-project
    #   问题描述：...

    local in_todo=false
    local current_item=""
    local items=()

    while IFS= read -r line; do
        # 检测待办列表开始
        if [[ "$line" =~ ^##[[:space:]]*待办 ]]; then
            in_todo=true
            continue
        fi

        # 检测新的待办项
        if [[ "$in_todo" == true && "$line" =~ ^-\ \[[\ \x]\][[:space:]]*(.+):[[:space:]]*(.+) ]]; then
            # 保存上一个待办项
            if [[ -n "$current_item" ]]; then
                items+=("$current_item")
            fi
            # 开始新的待办项
            local skill_name="${BASH_REMATCH[1]}"
            local description="${BASH_REMATCH[2]}"

            # 如果指定了目标 skill，过滤
            if [[ -n "$target_skill" && "$skill_name" != "$target_skill" && "$skill_name" != *"$target_skill"* ]]; then
                current_item=""
                continue
            fi

            current_item="SKILL:$skill_name|DESC:$description"
            continue
        fi

        # 收集待办项的详细信息
        if [[ -n "$current_item" && "$line" =~ ^[[:space:]]+(.+):[[:space:]]*(.+) ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            current_item="$current_item|${key}:${value}"
        fi
    done < "$todo_file"

    # 保存最后一个待办项
    if [[ -n "$current_item" ]]; then
        items+=("$current_item")
    fi

    # 输出所有待办项
    for item in "${items[@]}"; do
        echo "$item"
    done
}

# 提取 AGENTS.md 中的 Skill 引用
extract_agents_skill_refs() {
    local source_dir="$1"
    local agents_file="$source_dir/AGENTS.md"

    if [[ ! -f "$agents_file" ]]; then
        return 0
    fi

    # 提取引用的 skills
    grep -oE '\bskills/[a-zA-Z0-9_-]+(/[a-zA-Z0-9_-]+)*' "$agents_file" 2>/dev/null || true
}

# 生成 manifest.json
generate_manifest() {
    local target_skill="$1"
    local source_project="$2"
    local change_type="$3"
    local strategy="$4"

    cat << EOF
{
  "package_version": "1.0.0",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source_project": "$source_project",
  "target_skill": "$target_skill",
  "change_type": "$change_type",
  "strategy": "$strategy",
  "changes": {
    "SKILL.md": {
      "type": "patch",
      "sections": [],
      "lines_added": 0
    },
    "patterns/": {
      "type": "add",
      "files": []
    },
    "HISTORY.md": {
      "type": "append"
    }
  },
  "validation": {
    "tested": false,
    "test_project": "$source_project"
  }
}
EOF
}

# 生成 HISTORY.md 条目
generate_history_entry() {
    local target_skill="$1"
    local source_project="$2"
    local description="$3"

    cat << EOF
## $(date +"%Y-%m-%d"): $description（来自 $source_project）

**变更**: $description

**来源项目**: $source_project
**提取工具**: skill-evolution v1.0.0

**具体内容**:
- 待补充

**验证**: 在 $source_project 中实际应用
EOF
}

# 创建导入包
create_package() {
    local target_skill="$1"
    local output_path="$2"
    local todo_item="$3"
    local source_dir="$4"

    # 解析待办项
    local skill_name=$(echo "$todo_item" | grep -oP '(?<=SKILL:)[^|]+')
    local description=$(echo "$todo_item" | grep -oP '(?<=DESC:)[^|]+')

    # 获取项目名称
    local source_project=$(basename "$source_dir")

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would create package: $output_path"
        log_info "  Target Skill: $skill_name"
        log_info "  Description: $description"
        return 0
    fi

    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # 创建包结构
    mkdir -p "$tmp_dir/delta/patterns"
    mkdir -p "$tmp_dir/delta/references"

    # 生成 manifest.json
    generate_manifest "$skill_name" "$source_project" "incremental" "append" > "$tmp_dir/manifest.json"

    # 生成 HISTORY.md 条目
    generate_history_entry "$skill_name" "$source_project" "$description" > "$tmp_dir/HISTORY.md.entry"

    # 创建 SKILL.md.patch（占位符，实际内容需要人工编辑）
    cat << 'EOF' > "$tmp_dir/delta/SKILL.md.patch"
# SKILL.md 增量补丁
# 请在此编辑实际要追加到 SKILL.md 的内容

## 新增内容

### 新增模式

### 新增常见问题

EOF

    # 打包为 .pkg 文件（实际为 tar.gz）
    local output_dir=$(dirname "$output_path")
    mkdir -p "$output_dir"

    tar -czf "$output_path" -C "$tmp_dir" .

    log_info "Created skill package: $output_path"
    log_info "  Target Skill: $skill_name"
    log_info "  Source: $source_project"
}

# 批量模式
run_batch_mode() {
    local source_dir="$1"
    local output_dir="$2"

    log_info "Running in batch mode..."

    # 扫描待办文件
    local todo_file
    todo_file=$(scan_skill_todos "$source_dir") || return 1

    # 解析所有待办项
    local items=()
    while IFS= read -r line; do
        items+=("$line")
    done < <(parse_todos "$todo_file")

    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "No skill update items found"
        return 1
    fi

    log_info "Found ${#items[@]} skill update items"

    # 为每个待办项创建导入包
    mkdir -p "$output_dir"

    local count=0
    for item in "${items[@]}"; do
        local skill_name=$(echo "$item" | grep -oP '(?<=SKILL:)[^|]+' | tr '/' '-')
        local timestamp=$(date +"%Y-%m-%d")
        local package_name="${timestamp}-${skill_name}.pkg"
        local package_path="$output_dir/$package_name"

        create_package "" "$package_path" "$item" "$source_dir"
        ((count++))
    done

    log_info "Created $count skill packages in $output_dir"
}

# 主函数
main() {
    parse_args "$@"
    validate_args

    if [[ "$BATCH_MODE" == true ]]; then
        run_batch_mode "$SOURCE_DIR" "$OUTPUT_DIR"
    else
        # 单个模式
        local todo_file
        if ! todo_file=$(scan_skill_todos "$SOURCE_DIR"); then
            log_error "Cannot find skill updates to extract"
            exit 1
        fi

        local items=()
        while IFS= read -r line; do
            items+=("$line")
        done < <(parse_todos "$todo_file" "$TARGET_SKILL")

        if [[ ${#items[@]} -eq 0 ]]; then
            log_warn "No items found for skill: $TARGET_SKILL"
            exit 1
        fi

        # 使用第一个匹配的待办项
        create_package "$TARGET_SKILL" "$OUTPUT_PATH" "${items[0]}" "$SOURCE_DIR"
    fi
}

main "$@"
