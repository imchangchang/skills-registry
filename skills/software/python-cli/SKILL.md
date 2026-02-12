# Python CLI 开发最佳实践（uv 版）

## 概述

基于 Click 框架和 uv 工具链的 Python 命令行应用开发最佳实践。

## 适用场景

- 命令行工具开发
- 带参数和选项的脚本
- 子命令结构

## 核心技术栈

- **uv**: 开发工具链（环境、依赖、运行）
- **click**: 命令行框架
- **pydantic**: 配置验证
- **tqdm**: 进度条

## 快速开始

```bash
# 1. 创建项目
uv init mycli --python 3.11
cd mycli

# 2. 添加 CLI 依赖
uv add click pydantic pydantic-settings tqdm

# 3. 添加开发依赖
uv add --dev pytest

# 4. 运行
uv run python -m mycli
```

## 项目结构

```
mycli/
├── pyproject.toml
├── uv.lock
├── README.md
└── src/
    └── mycli/
        ├── __init__.py
        ├── __main__.py      # 入口: python -m mycli
        ├── cli.py           # 主入口和命令定义
        ├── config.py        # 配置管理
        ├── commands/        # 子命令模块 (可选)
        │   ├── __init__.py
        │   ├── cmd1.py
        │   └── cmd2.py
        └── core/            # 核心逻辑
            └── __init__.py
```

## 开发工作流

### 日常开发

```bash
# 运行 CLI（无需激活环境）
uv run python -m mycli --help

# 带参数运行
uv run python -m mycli process input.txt --output result.txt

# 运行测试
uv run pytest tests/

# 代码格式化
uv run ruff format src/

# 静态检查
uv run ruff check src/
```

### 打包为可执行工具

```bash
# 构建包
uv build

# 本地安装测试
uv tool install --editable .

# 现在可以直接运行
mycli --help

# 卸载
uv tool uninstall mycli
```

### 发布到 PyPI

```bash
# 构建并发布
uv build
uv publish

# 发布后用户可以直接安装
# uv tool install mycli
```

## Click 最佳实践

### 基础命令

```python
import click

@click.command()
@click.argument('input')
@click.option('-o', '--output', help='输出文件')
@click.option('--verbose', is_flag=True, help='详细输出')
def main(input, output, verbose):
    """命令说明"""
    pass

if __name__ == '__main__':
    main()
```

### 子命令结构

```python
@click.group()
def cli():
    """CLI 工具说明"""
    pass

@cli.command()
@click.argument('file')
def process(file):
    """处理文件"""
    pass

@cli.command()
def batch():
    """批量处理"""
    pass
```

### 进度条

```python
from tqdm import tqdm

for item in tqdm(items, desc="处理中"):
    process(item)
```

## 配置管理

使用 pydantic-settings 管理配置：

```python
from pydantic_settings import BaseSettings

class Config(BaseSettings):
    api_key: str
    model: str = "default"
    
    class Config:
        env_file = ".env"
```

## pyproject.toml 配置

```toml
[project]
name = "mycli"
version = "0.1.0"
description = "My CLI tool"
requires-python = ">=3.10"
dependencies = [
    "click>=8.0",
    "pydantic>=2.0",
    "pydantic-settings>=2.0",
    "tqdm>=4.65",
]

[project.optional-dependencies]
dev = ["pytest>=7.0", "ruff>=0.1.0"]

# 命令行入口点
[project.scripts]
mycli = "mycli.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = ["pytest>=7.0", "ruff>=0.1.0"]

[tool.ruff]
target-version = "py310"
line-length = 100
```

## 用户安装方式

构建发布后，用户可以通过多种方式安装：

```bash
# 方式1：作为 uv 工具安装（推荐，隔离环境）
uv tool install mycli

# 方式2：添加到项目依赖
uv add mycli

# 方式3：临时运行（不安装）
uvx mycli --help
```

## 检查清单

CLI 项目开发检查：

- [ ] 使用 `uv init` 创建项目
- [ ] 添加 click 作为依赖
- [ ] 配置 `pyproject.toml` 的 `[project.scripts]`
- [ ] 使用 `uv run` 进行开发和测试
- [ ] 使用 `uv build` 打包
- [ ] 使用 `uv tool install` 本地测试
- [ ] 使用 `uv publish` 发布
