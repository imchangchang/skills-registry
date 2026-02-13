# Skill 分析 Prompt 模板

## 使用场景

完成四层过滤后，将过滤结果发给 AI 进行 Skill 提炼分析。

## Prompt 内容

```markdown
请基于以下行为审计的过滤结果，分析并生成 Skill 建议。

## 项目背景
- 项目名称：{project_name}
- 功能名称：{feature_name}
- 开发时长：{duration}

## 过滤数据

### 第一层：时间范围
{粘贴 layer1 摘要}

### 第二层：场景分布
- 规划阶段：{planning_count} 轮对话
- 实现阶段：{implementation_count} 轮对话
- 调试阶段：{debugging_count} 轮对话
- 审查阶段：{review_count} 轮对话

### 第三层：提取的信息
{粘贴 layer3 内容}

### 第四层：频率统计
{粘贴 layer4 stats.json}

## 请分析并输出

### 1. 高频指令（出现 ≥3 次）
列出重复的指令，说明使用场景。

### 2. 约束条件
列出明确的边界限制，说明适用条件。

### 3. 常见误解
AI 经常理解错的点，以及正确的理解方式。

### 4. 决策模式
我在什么情况下会选择什么方案，优先考虑什么因素。

### 5. Skill 更新建议
具体建议更新哪个 Skill 文件，在哪个章节添加什么内容。

格式：
- 目标 Skill：{skill_path}
- 变更类型：append | modify | new
- 建议内容：{具体文字}
- 理由：{为什么需要这个更新}
```
