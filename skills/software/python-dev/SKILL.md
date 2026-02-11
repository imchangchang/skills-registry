# Python 开发最佳实践

## 概述

Python 项目开发的标准规范、工具链配置和最佳实践。

## 适用场景

- Python 3.10+ 项目开发
- 代码质量和风格统一
- 项目结构标准化

## 核心规范

### 项目结构
```
project/
├── src/package/        # 源代码
│   ├── __init__.py
│   ├── module.py
│   └── cli.py
├── tests/              # 测试代码
├── docs/               # 文档
├── pyproject.toml      # 项目配置
├── .env.example        # 环境变量示例
└── README.md
```

### 代码规范
- **缩进**: 4 空格
- **行长度**: 100 字符
- **格式化**: black
- **静态检查**: ruff
- **类型检查**: mypy (可选)

### 工具链
```bash
# 格式化
black src/ tests/

# 静态检查
ruff check src/ tests/
ruff check --fix src/ tests/

# 测试
pytest tests/ -v
```

### pyproject.toml 配置
```toml
[tool.black]
line-length = 100
target-version = ['py310']

[tool.ruff]
line-length = 100
select = ["E", "F", "W", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

## 命名规范
- **文件**: 小写下划线 (snake_case)
- **类**: 大驼峰 (PascalCase)
- **函数/变量**: 小写下划线 (snake_case)
- **常量**: 全大写下划线 (UPPER_SNAKE_CASE)
- **私有**: 单下划线前缀

## 依赖管理
- 使用 `uv` 或 `pip` + `pyproject.toml`
- 开发依赖放 `[project.optional-dependencies]` 或 `[dependency-groups]`

## 待完善
- [ ] 添加更多代码示例
- [ ] 补充类型注解最佳实践
- [ ] 补充错误处理模式
- [ ] 补充日志配置指南
