# Python CLI 开发最佳实践

## 概述

基于 Click 框架的 Python 命令行应用开发最佳实践。

## 适用场景

- 命令行工具开发
- 带参数和选项的脚本
- 子命令结构

## 核心技术栈

- **click**: 命令行框架
- **pydantic**: 配置验证
- **tqdm**: 进度条

## 项目结构
```
src/mycli/
├── __init__.py
├── cli.py          # 主入口和命令定义
├── config.py       # 配置管理
├── commands/       # 子命令模块 (可选)
│   ├── __init__.py
│   ├── cmd1.py
│   └── cmd2.py
└── core/           # 核心逻辑
    └── __init__.py
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

## 待完善
- [ ] 添加完整 CLI 示例
- [ ] 补充错误处理
- [ ] 补充测试方法
- [ ] 补充打包发布指南
