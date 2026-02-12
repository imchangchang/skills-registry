# Skill Evolution 迭代记录

## 2026-02-12: 初始创建

**变更**: 创建 Skill 演化与提炼工具

**核心内容**:
- extract-skill.sh: 从项目提取 Skill 更新，生成导入包
- merge-skill.sh: 将导入包融合到 Skill 仓库
- 定义导入包格式规范（manifest.json + delta/）
- 支持三种融合策略：append、patch、replace
- 提供完整的工作流指南

**目标**: 实现从项目实践中自动提炼知识，让 Skill 持续进化

**设计决策**:
- 导入包使用 tar.gz 格式，便于传输和版本控制
- 人工编辑中间步骤，确保内容质量
- 备份机制防止数据丢失
