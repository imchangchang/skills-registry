#!/bin/bash
# gate.sh - 质量门禁脚本模板
# 根据项目类型选择合适的检查

set -e

echo "[SEARCH] 运行质量门禁..."

# 根据项目类型自动检测
if [ -f "CMakeLists.txt" ] || [ -f "Makefile" ]; then
    PROJECT_TYPE="c"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    PROJECT_TYPE="python"
elif [ -f "package.json" ]; then
    PROJECT_TYPE="node"
else
    echo "[WARN] 未知项目类型，请手动配置检查"
    exit 1
fi

echo "项目类型: $PROJECT_TYPE"

case $PROJECT_TYPE in
    c)
        echo "=== C 项目检查 ==="
        
        # 1. 编译
        echo "[PACKAGE] 编译检查..."
        make clean >/dev/null 2>&1 || true
        if ! make 2>&1 | tee /tmp/build.log; then
            echo "[X] 编译失败"
            exit 1
        fi
        
        # 2. 警告检查
        if grep -i "warning" /tmp/build.log >/dev/null 2>&1; then
            echo "[WARN] 发现编译警告:"
            grep -i "warning" /tmp/build.log
        fi
        
        # 3. 静态分析（如果安装了 cppcheck）
        if command -v cppcheck >/dev/null 2>&1; then
            echo "[SEARCH] 静态分析..."
            cppcheck --enable=all --error-exitcode=1 \
                --suppress=missingIncludeSystem \
                src/ 2>&1 | head -50 || {
                echo "[X] 静态分析发现问题"
                exit 1
            }
        fi
        
        echo "[OK] C 项目检查通过"
        ;;
        
    python)
        echo "=== Python 项目检查 ==="
        
        # 1. 格式检查
        if command -v ruff >/dev/null 2>&1; then
            echo "🎨 代码格式..."
            ruff check . || exit 1
        fi
        
        # 2. 类型检查
        if command -v mypy >/dev/null 2>&1; then
            echo "[SEARCH] 类型检查..."
            mypy src/ || exit 1
        fi
        
        # 3. 测试
        if [ -f "pytest.ini" ] || [ -d "tests" ]; then
            echo "🧪 运行测试..."
            pytest || exit 1
        fi
        
        echo "[OK] Python 项目检查通过"
        ;;
        
    *)
        echo "[X] 未实现的项目类型: $PROJECT_TYPE"
        exit 1
        ;;
esac

echo ""
echo "[PARTY] 所有质量门禁通过！"
