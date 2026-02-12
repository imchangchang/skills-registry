#!/bin/bash
#
# merge-skill.sh - 将 Skill 导入包融合到 Skill 仓库
#
# 用法:
#   merge-skill.sh --package <package.pkg> --strategy <append|patch|replace>
#

set -euo pipefail

# 默认配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REGISTRY="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
PACKAGE_PATH=""
STRATEGY="append"
BACKUP_DIR=".backup"
DRY_RUN=false
FORCE=false

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 使用说明
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

将 Skill 导入包融合到 Skill 仓库

Options:
    --package <path>      Skill 导入包路径（.pkg 文件，必须）
    --strategy <name>     融合策略: append|patch|replace（默认: append）
    --backup-dir <path>   备份目录（默认: .backup/）
    --force               强制融合，不提示确认
    --dry-run             预览模式，不实际修改文件
    --help                显示此帮助

Strategies:
    append    追加新内容（推荐，不修改现有内容）
    patch     应用补丁（修改特定段落）
    replace   完全替换（谨慎使用）

Examples:
    # 融合导入包（追加模式）
    $(basename "$0") --package ~/stm32-update.pkg

    # 预览融合结果
    $(basename "$0") --package ~/stm32-update.pkg --dry-run

    # 使用补丁模式
    $(basename "$0") --package ~/stm32-update.pkg --strategy patch
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 解析参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --package)
                PACKAGE_PATH="$2"
                shift 2
                ;;
            --strategy)
                STRATEGY="$2"
                shift 2
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
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
    if [[ -z "$PACKAGE_PATH" ]]; then
        log_error "--package is required"
        exit 1
    fi

    if [[ ! -f "$PACKAGE_PATH" ]]; then
        log_error "Package file does not exist: $PACKAGE_PATH"
        exit 1
    fi

    if [[ "$STRATEGY" != "append" && "$STRATEGY" != "patch" && "$STRATEGY" != "replace" ]]; then
        log_error "Invalid strategy: $STRATEGY (must be append|patch|replace)"
        exit 1
    fi
}

# 解压导入包
extract_package() {
    local package_path="$1"
    local extract_dir="$2"

    tar -xzf "$package_path" -C "$extract_dir"
}

# 读取 manifest
read_manifest() {
    local extract_dir="$1"
    cat "$extract_dir/manifest.json"
}

# 获取 manifest 字段
get_manifest_field() {
    local manifest="$1"
    local field="$2"
    echo "$manifest" | grep -oP "\"$field\":\s*\"[^\"]+\"" | cut -d'"' -f4
}

# 验证目标 Skill 存在
validate_target_skill() {
    local target_skill="$1"
    local skill_path="$SKILLS_REGISTRY/skills/$target_skill"

    if [[ ! -d "$skill_path" ]]; then
        log_error "Target skill does not exist: $target_skill"
        log_info "Expected path: $skill_path"
        return 1
    fi

    if [[ ! -f "$skill_path/SKILL.md" ]]; then
        log_error "Target skill is missing SKILL.md: $target_skill"
        return 1
    fi

    echo "$skill_path"
}

# 创建备份
create_backup() {
    local skill_path="$1"
    local backup_dir="$2"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    local backup_path="$backup_dir/$(basename "$skill_path").$timestamp"
    mkdir -p "$backup_path"

    # 备份关键文件
    cp -r "$skill_path" "$backup_path/"

    echo "$backup_path"
}

# 追加内容到 SKILL.md
append_to_skill() {
    local skill_path="$1"
    local delta_dir="$2"

    local skill_md="$skill_path/SKILL.md"
    local patch_file="$delta_dir/SKILL.md.patch"

    if [[ ! -f "$patch_file" ]]; then
        log_warn "No SKILL.md.patch found in package"
        return 0
    fi

    # 读取补丁内容（跳过注释行）
    local content=$(grep -v '^#' "$patch_file" | grep -v '^$' || true)

    if [[ -z "$content" ]]; then
        log_warn "SKILL.md.patch is empty (only comments)"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would append to $skill_md:"
        echo "$content" | head -20
        [[ $(echo "$content" | wc -l) -gt 20 ]] && echo "... ($(echo "$content" | wc -l) lines total)"
        return 0
    fi

    # 在 "## 迭代记录" 之前插入新内容
    if grep -q "## 迭代记录" "$skill_md"; then
        # 使用临时文件进行安全替换
        local tmp_file=$(mktemp)
        awk '
            /^## 迭代记录/ {
                print "## 新增内容（来自导入包）"
                print ""
                while ((getline line < patch_file) > 0) {
                    if (line !~ /^#/ && line != "") {
                        print line
                    }
                }
                print ""
            }
            { print }
        ' patch_file="$patch_file" "$skill_md" > "$tmp_file"
        mv "$tmp_file" "$skill_md"
    else
        # 直接追加到文件末尾
        echo "" >> "$skill_md"
        echo "## 新增内容（来自导入包）" >> "$skill_md"
        echo "" >> "$skill_md"
        grep -v '^#' "$patch_file" | grep -v '^$' >> "$skill_md"
    fi

    log_info "Appended content to SKILL.md"
}

# 复制 patterns
merge_patterns() {
    local skill_path="$1"
    local delta_dir="$2"

    local patterns_dir="$delta_dir/patterns"

    if [[ ! -d "$patterns_dir" ]] || [[ -z "$(ls -A "$patterns_dir" 2>/dev/null)" ]]; then
        log_info "No patterns to merge"
        return 0
    fi

    mkdir -p "$skill_path/patterns"

    for file in "$patterns_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local target="$skill_path/patterns/$filename"

            if [[ -f "$target" && "$FORCE" != true ]]; then
                log_warn "Pattern already exists: $filename (use --force to overwrite)"
                continue
            fi

            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY RUN] Would copy pattern: $filename"
            else
                cp "$file" "$target"
                log_info "Copied pattern: $filename"
            fi
        fi
    done
}

# 复制 references
merge_references() {
    local skill_path="$1"
    local delta_dir="$2"

    local refs_dir="$delta_dir/references"

    if [[ ! -d "$refs_dir" ]] || [[ -z "$(ls -A "$refs_dir" 2>/dev/null)" ]]; then
        log_info "No references to merge"
        return 0
    fi

    mkdir -p "$skill_path/references"

    for file in "$refs_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local target="$skill_path/references/$filename"

            if [[ -f "$target" && "$FORCE" != true ]]; then
                log_warn "Reference already exists: $filename (use --force to overwrite)"
                continue
            fi

            if [[ "$DRY_RUN" == true ]]; then
                log_info "[DRY RUN] Would copy reference: $filename"
            else
                cp "$file" "$target"
                log_info "Copied reference: $filename"
            fi
        fi
    done
}

# 更新 HISTORY.md
update_history() {
    local skill_path="$1"
    local delta_dir="$2"

    local history_entry="$delta_dir/HISTORY.md.entry"
    local history_file="$skill_path/HISTORY.md"

    if [[ ! -f "$history_entry" ]]; then
        log_warn "No HISTORY.md.entry found in package"
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would append to HISTORY.md:"
        head -10 "$history_entry"
        return 0
    fi

    # 在文件开头添加新条目（在标题之后）
    if [[ -f "$history_file" ]]; then
        local tmp_file=$(mktemp)
        # 读取原文件内容
        local content=$(cat "$history_file")
        # 找到第一个空行后的位置插入
        echo "$content" | awk '
            NR==1 { print; next }
            NR==2 && /^$/ { print; next }
            NR==2 { print ""; print; next }
            { print }
        ' > "$tmp_file"

        # 在第三行插入新条目
        head -2 "$tmp_file" > "$history_file"
        echo "" >> "$history_file"
        cat "$history_entry" >> "$history_file"
        echo "" >> "$history_file"
        tail -n +3 "$tmp_file" >> "$history_file"
        rm "$tmp_file"
    else
        # 创建新的 HISTORY.md
        echo "# 迭代记录" > "$history_file"
        echo "" >> "$history_file"
        cat "$history_entry" >> "$history_file"
    fi

    log_info "Updated HISTORY.md"
}

# 验证融合结果
validate_merge() {
    local skill_path="$1"
    local errors=0

    log_step "Validating merge result..."

    # 检查 SKILL.md 是否存在
    if [[ ! -f "$skill_path/SKILL.md" ]]; then
        log_error "SKILL.md is missing!"
        ((errors++))
    fi

    # 检查 frontmatter
    if ! head -5 "$skill_path/SKILL.md" | grep -q "^---"; then
        log_warn "SKILL.md might be missing frontmatter"
    fi

    # 检查 metadata.json
    if [[ ! -f "$skill_path/metadata.json" ]]; then
        log_warn "metadata.json is missing"
    fi

    # 检查 HISTORY.md
    if [[ ! -f "$skill_path/HISTORY.md" ]]; then
        log_warn "HISTORY.md is missing"
    fi

    if [[ $errors -eq 0 ]]; then
        log_info "Validation passed"
        return 0
    else
        log_error "Validation failed with $errors errors"
        return 1
    fi
}

# 显示融合摘要
show_summary() {
    local manifest="$1"
    local strategy="$2"

    echo ""
    echo "========================================"
    echo "Skill 融合摘要"
    echo "========================================"
    echo "目标 Skill: $(echo "$manifest" | grep -oP '"target_skill":\s*"[^"]+"' | cut -d'"' -f4)"
    echo "来源项目: $(echo "$manifest" | grep -oP '"source_project":\s*"[^"]+"' | cut -d'"' -f4)"
    echo "融合策略: $strategy"
    echo "创建时间: $(echo "$manifest" | grep -oP '"created_at":\s*"[^"]+"' | cut -d'"' -f4)"
    echo "========================================"
}

# 确认融合
confirm_merge() {
    if [[ "$FORCE" == true ]]; then
        return 0
    fi

    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi

    echo ""
    read -p "确认执行融合? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Merge cancelled"
        exit 0
    fi
}

# 主函数
main() {
    parse_args "$@"
    validate_args

    log_step "Extracting package..."

    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # 解压包
    extract_package "$PACKAGE_PATH" "$tmp_dir"

    # 读取 manifest
    local manifest
    manifest=$(read_manifest "$tmp_dir")

    local target_skill
    target_skill=$(get_manifest_field "$manifest" "target_skill")

    show_summary "$manifest" "$STRATEGY"

    # 验证目标 Skill
    local skill_path
    if ! skill_path=$(validate_target_skill "$target_skill"); then
        exit 1
    fi

    log_info "Target skill path: $skill_path"

    # 创建备份
    if [[ "$DRY_RUN" != true ]]; then
        log_step "Creating backup..."
        local backup_path
        backup_path=$(create_backup "$skill_path" "$BACKUP_DIR")
        log_info "Backup created: $backup_path"
    fi

    # 确认融合
    confirm_merge

    # 执行融合
    log_step "Merging content..."

    case "$STRATEGY" in
        append)
            append_to_skill "$skill_path" "$tmp_dir/delta"
            merge_patterns "$skill_path" "$tmp_dir/delta"
            merge_references "$skill_path" "$tmp_dir/delta"
            update_history "$skill_path" "$tmp_dir"
            ;;
        patch)
            log_warn "Patch strategy not fully implemented, using append"
            append_to_skill "$skill_path" "$tmp_dir/delta"
            merge_patterns "$skill_path" "$tmp_dir/delta"
            merge_references "$skill_path" "$tmp_dir/delta"
            update_history "$skill_path" "$tmp_dir"
            ;;
        replace)
            log_error "Replace strategy not implemented (too dangerous)"
            exit 1
            ;;
    esac

    # 验证
    if [[ "$DRY_RUN" != true ]]; then
        validate_merge "$skill_path"
        log_info "Merge completed successfully!"
        log_info "Backup available at: $backup_path"
    else
        log_info "[DRY RUN] Merge preview completed"
    fi
}

main "$@"
