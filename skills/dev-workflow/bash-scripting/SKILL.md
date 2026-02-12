---
name: bash-scripting
description: Bash 脚本编写最佳实践。涵盖 set -e 陷阱、数组使用、文件名空格处理、错误处理等实用技巧。
created: 2026-02-12
status: stable
---

# Bash 脚本编写指南

> 实用的 Bash 脚本编写技巧和常见陷阱

## 快速参考

| 问题 | 解决方案 |
|------|---------|
| `set -e` 导致算术运算退出 | 使用 `set -o pipefail` 或避免 `((0))` |
| 变量递增失败 | 使用 `var=$((var + 1))` 代替 `((var++))` |
| 文件名含空格处理 | 使用数组 `"${array[@]}"` 存储文件列表 |
| 通配符无匹配时返回原字符串 | 使用 `shopt -s nullglob` |

---

## 1. set -e 的陷阱

### 问题
`set -e` 会让脚本在任何命令返回非零退出码时立即退出，包括算术运算。

```bash
#!/bin/bash
set -e

total=0
for f in *.mp4; do
    ((total++))  # 当 total=0 时，((0)) 返回 false，脚本退出！
done
echo "Total: $total"  # 永远不会执行
```

### 解决方案

**方案 1: 使用 `set -o pipefail`（推荐）**
```bash
#!/bin/bash
set -o pipefail  # 只检查管道错误，不检查算术运算

total=0
for f in *.mp4; do
    total=$((total + 1))  # 安全
done
```

**方案 2: 使用兼容的算术语法**
```bash
#!/bin/bash
set -e

total=0
for f in *.mp4; do
    total=$((total + 1))  # 总是返回 0
    # 或者: let "total+=1"
done
```

**方案 3: 临时禁用 exit-on-error**
```bash
#!/bin/bash
set -e

set +e  # 临时禁用
total=0
for f in *.mp4; do
    ((total++))
done
set -e  # 重新启用
```

---

## 2. 变量递增的正确方式

| 方式 | 兼容性 | 返回值 | 适用场景 |
|------|--------|--------|---------|
| `((var++))` | Bash 4+ | 递增前的值 | 简单递增，无 set -e |
| `((++var))` | Bash 4+ | 递增后的值 | 简单递增，无 set -e |
| `var=$((var + 1))` | POSIX | 0 | **set -e 环境推荐** |
| `let "var+=1"` | Bash | 0 | 复杂表达式 |
| `((var+=1))` | Bash 4+ | 递增后的值 | 简单递增 |

**推荐写法（兼容 set -e）:**
```bash
# 递增
count=$((count + 1))

# 递减
count=$((count - 1))

# 累加
sum=$((sum + value))
```

---

## 3. 处理文件名（含空格）

### 问题
文件名含空格时使用字符串变量会导致分割错误。

```bash
# 错误！文件名含空格会被分割
files=""
for f in *.mp4; do
    files="$files $f"  # 空格分隔，后续无法正确处理
done

for f in $files; do  # file1 file2.mp4 被当成两个文件
    echo "$f"
done
```

### 解决方案

**使用数组（推荐）**
```bash
#!/bin/bash

# 收集文件到数组
files=()
for f in *.mp4; do
    [ -f "$f" ] && files+=("$f")
done

echo "找到 ${#files[@]} 个文件"

# 遍历数组
for f in "${files[@]}"; do
    echo "处理: $f"
done
```

**使用数组时避免通配符问题**
```bash
# 如果没有匹配文件，*.mp4 会返回字面量 "*.mp4"
shopt -s nullglob  # 无匹配时返回空

files=()
for f in *.mp4; do
    files+=("$f")
done

if [ ${#files[@]} -eq 0 ]; then
    echo "未找到视频文件"
    exit 1
fi
```

---

## 4. 遍历文件的健壮模式

```bash
#!/bin/bash
set -o pipefail

VIDEO_DIR="testdata/videos"

# 1. 检查目录存在
if [ ! -d "$VIDEO_DIR" ]; then
    echo "错误: 目录不存在: $VIDEO_DIR"
    exit 1
fi

# 2. 收集文件到数组（处理空格、特殊字符）
shopt -s nullglob
video_list=()
for video in "$VIDEO_DIR"/*.mp4; do
    [ -f "$video" ] && video_list+=("$video")
done

# 3. 检查是否有文件
if [ ${#video_list[@]} -eq 0 ]; then
    echo "错误: 未找到视频文件"
    exit 1
fi

echo "找到 ${#video_list[@]} 个视频"

# 4. 遍历处理
idx=0
for video_path in "${video_list[@]}"; do
    idx=$((idx + 1))
    video_name=$(basename "$video_path")
    
    echo "[$idx/${#video_list[@]}] 处理: $video_name"
    
    # 处理逻辑...
done
```

---

## 5. 条件判断最佳实践

```bash
# 检查命令存在
if command -v uv &> /dev/null; then
    echo "uv 已安装"
fi

# 检查文件存在
if [ -f "$file" ]; then
    echo "文件存在"
fi

# 检查目录存在
if [ -d "$dir" ]; then
    echo "目录存在"
fi

# 检查非空
if [ -n "$var" ]; then  # 字符串非空
    echo "变量有值"
fi

if [ ${#array[@]} -gt 0 ]; then  # 数组非空
    echo "数组有元素"
fi
```

---

## 6. 调试技巧

```bash
#!/bin/bash

# 开启调试（显示执行的每条命令）
set -x

# 你的脚本...

# 关闭调试
set +x

# 或者在 shebang 中开启
#!/bin/bash -x

# 或者运行时开启
bash -x script.sh
```

---

## 7. 错误处理模板

```bash
#!/bin/bash
set -o pipefail

# 错误处理函数
error_exit() {
    echo -e "\033[0;31m错误: $1\033[0m" >&2
    exit 1
}

# 检查依赖
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        error_exit "未找到依赖: $1"
    fi
}

# 使用示例
check_dependency "python3"
check_dependency "ffmpeg"

# 检查文件
[ -f "$input" ] || error_exit "输入文件不存在: $input"
```

---

## 8. 实际案例对比

### 修改前（有问题）
```bash
#!/bin/bash
set -e  # 问题根源

total=0
for video in *.mp4; do
    [ -f "$video" ] || continue
    ((total++))  # 当 total=0 时退出
done
echo "总计: $total"  # 不会执行
```

### 修改后（健壮）
```bash
#!/bin/bash
set -o pipefail  # 解决方案 1

# 检查目录
[ -d "videos" ] || { echo "目录不存在"; exit 1; }

# 收集文件
videos=()
for v in videos/*.mp4; do
    [ -f "$v" ] && videos+=("$v")
done

# 检查数量
[ ${#videos[@]} -eq 0 ] && { echo "无视频文件"; exit 1; }

# 处理
count=0
for v in "${videos[@]}"; do
    count=$((count + 1))  # 解决方案 2
    echo "[$count/${#videos[@]}] $v"
done
```

---

## 参考

- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)
- [ShellCheck](https://www.shellcheck.net/) - 静态分析工具
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
