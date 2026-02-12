# Python CLI 开发最佳实践

## 概述

基于 Click 框架的 Python 命令行应用开发最佳实践。

**继承关系**：本 Skill 继承 [python-dev](../python-dev/) 的所有约定，在此基础上添加 CLI 特定的扩展。

## 继承的约定（来自 python-dev）

使用本 Skill 时，AI 助手必须同时遵循 [python-dev](../python-dev/SKILL.md) 的所有约定：

- **工具链**：使用 uv 进行环境管理、依赖管理、代码运行
- **代码规范**：ruff 格式化，mypy 类型检查
- **项目结构**：src/ 布局，pyproject.toml 配置
- **开发工作流**：uv add / uv run / uv sync

## CLI 特定扩展

本 Skill 在 python-dev 基础上添加：

- **框架**：Click 命令行框架
- **项目结构**：CLI 特定的目录组织
- **入口配置**：pyproject.toml 中的 [project.scripts]
- **发布流程**：CLI 工具的安装方式

## 核心技术栈

- **python-dev**: 基础开发约定（uv, ruff, mypy）
- **click**: 命令行框架
- **pydantic**: 配置验证
- **tqdm**: 进度条

## 快速开始

```bash
# 1. 创建项目（继承 python-dev 工作流）
uv init mycli --python 3.11
cd mycli

# 2. 添加 CLI 依赖
uv add click pydantic pydantic-settings tqdm

# 3. 添加开发依赖（继承 python-dev 推荐）
uv add --dev pytest ruff mypy

# 4. 配置入口点（CLI 特定）
# 编辑 pyproject.toml 添加 [project.scripts]
```

## 项目结构（扩展）

在 [python-dev 标准结构](../python-dev/SKILL.md#项目结构) 基础上，CLI 项目添加：

```
mycli/
├── pyproject.toml          # 继承 python-dev 配置 + CLI 入口
├── uv.lock
├── README.md
└── src/
    └── mycli/
        ├── __init__.py
        ├── __main__.py      # 新增：支持 python -m mycli
        ├── cli.py           # 新增：主入口和命令定义
        ├── config.py        # 新增：配置管理
        ├── commands/        # 新增：子命令模块
        │   ├── __init__.py
        │   ├── cmd1.py
        │   └── cmd2.py
        └── core/            # 核心逻辑
            └── __init__.py
```

**注意**：`__main__.py` 和 `cli.py` 是 CLI 特有的，其他遵循 python-dev 标准。

## pyproject.toml（继承 + 扩展）

继承 [python-dev 的完整配置](../python-dev/SKILL.md#pyprojecttoml-完整配置)，添加 CLI 特定部分：

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

# CLI 特定：命令行入口点
[project.scripts]
mycli = "mycli.cli:main"

# 继承 python-dev 的其余配置
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = ["pytest>=7.0", "ruff>=0.1.0", "mypy>=1.0"]

[tool.ruff]
target-version = "py310"
line-length = 100

[tool.mypy]
python_version = "3.10"
warn_return_any = true
disallow_untyped_defs = true
```

## 开发工作流（继承）

完全继承 [python-dev 的工作流](../python-dev/SKILL.md#核心工作流)：

```bash
# 运行 CLI（使用 uv run，无需激活环境）
uv run python -m mycli --help

# 代码格式化（继承 python-dev）
uv run ruff format src/

# 静态检查（继承 python-dev）
uv run ruff check src/
uv run mypy src/

# 运行测试（继承 python-dev）
uv run pytest
```

## CLI 特定工作流

### 本地安装测试

```bash
# 构建包
uv build

# 本地安装为工具
uv tool install --editable .

# 现在可以直接运行
mycli --help

# 卸载
uv tool uninstall mycli
```

### 发布

```bash
# 构建并发布
uv build
uv publish
```

### 用户安装

发布后，用户通过以下方式安装：

```bash
# 方式1：作为 uv 工具安装（隔离环境，推荐）
uv tool install mycli

# 方式2：临时运行（不安装）
uvx mycli --help
```

## Click 最佳实践（CLI 特定）

### 基础命令

```python
# src/mycli/cli.py
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
```

### 进度条

```python
from tqdm import tqdm

for item in tqdm(items, desc="处理中"):
    process(item)
```

## 配置管理（CLI 特定）

使用 pydantic-settings：

```python
# src/mycli/config.py
from pydantic_settings import BaseSettings

class Config(BaseSettings):
    api_key: str
    model: str = "default"
    
    class Config:
        env_file = ".env"
```

## 与 python-dev 的关系

```
python-dev（父 Skill）
├── 工具链：uv
├── 代码规范：ruff, mypy
├── 项目结构：src/ 布局
└── 工作流：uv add/run/sync
        │
        └── 被 python-cli 继承
                │
                ▼
        python-cli（子 Skill）
        ├── 框架：Click
        ├── 结构：CLI 特定目录
        ├── 配置：[project.scripts]
        └── 发布：uv tool
```

## 检查清单

使用本 Skill 时检查：

**继承自 python-dev**：
- [ ] 使用 `uv init` 创建项目
- [ ] 使用 `uv add` 管理依赖
- [ ] 使用 `uv run` 运行代码
- [ ] 配置 ruff/mypy 代码检查
- [ ] 提交 `uv.lock` 到版本控制

**CLI 特定**：
- [ ] 添加 click 依赖
- [ ] 创建 `src/mycli/cli.py`
- [ ] 配置 `[project.scripts]` 入口点
- [ ] 创建 `__main__.py` 支持 `python -m`
- [ ] 使用 `uv tool install` 本地测试
- [ ] 发布到 PyPI 后可用 `uv tool install` 安装

## 参考

- [python-dev](../python-dev/) - 父 Skill，包含基础 Python 开发约定
- [Click 文档](https://click.palletsprojects.com/)
