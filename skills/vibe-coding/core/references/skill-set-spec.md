# Skill-Set 格式规范

> 定义 `.skill-set` 文件格式

## 基本格式

`.skill-set` 是纯文本文件，每行一个 Skill 路径：

```
vibe-coding/core
dev-workflow/git-commits
embedded/mcu/st-stm32
```

## 通配符支持

使用 `*` 引入整个分类下的所有 Skill：

```
# 引入 vibe-coding 下所有 Skill
vibe-coding/*

# 引入 software 下所有 Skill
software/*
```

**展开示例**：
```
# 输入
vibe-coding/*

# 实际展开为
vibe-coding/core
vibe-coding/multi-agent-safety
vibe-coding/session-management
vibe-coding/skill-evolution
```

## 完整示例

```
# Vibe Coding 核心（引入全部）
vibe-coding/*

# 开发工作流
dev-workflow/git-commits
dev-workflow/quality-gates

# 嵌入式
embedded/mcu/st-stm32

# 软件技能（引入全部）
software/*

# 设计模式
design-patterns/pipeline-architecture
```

## AI 解析规则

1. 逐行读取
2. `#` 开头为注释，跳过
3. 空行跳过
4. `/*` 结尾的行：展开为该目录下所有子目录（需包含 SKILL.md）
5. 其他行：作为具体 Skill 路径

## 向后兼容

旧格式（无通配符）完全兼容。
