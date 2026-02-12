# Python Dev Skill 迭代记录

## 2026-02-12

**重大更新**: 全面迁移到 uv 工具链

**变更内容**:
- 完全基于 [uv](https://docs.astral.sh/uv/) 重写
- 放弃 pip + venv + pip-tools 组合
- 统一使用 uv 进行环境管理、依赖管理和工具运行
- 添加 uv 工作流、配置示例和迁移指南

**理由**:
- uv 速度比 pip 快 10-100 倍
- 统一工具链，学习成本更低
- 原生支持 pyproject.toml 标准
- 替代 pipx 进行工具管理

**破坏性变更**:
- 不再推荐使用 pip 和 venv
- 原有 pip 工作流标记为过时

---

## 2026-02-11

**创建**: 初始版本

**内容**: Python 开发基础规范
- 项目结构
- 代码规范（black, ruff, mypy）
- pyproject.toml 配置
- 命名规范
