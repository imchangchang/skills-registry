# Skill 设计原则

## 什么是 Skill

> **Skill = 领域知识包 = 指导 + 模板 + 参考资料**

Skill 将特定领域的知识结构化封装，让 AI 能够快速获取并使用。

## 三大设计理念

### 1. 知识无版本

**原则**：只有当前最佳实践，不强制版本号

- 使用 HISTORY.md 记录演进过程
- Git 历史作为真正的版本控制
- 错误就改，补充就加

### 2. 渐进式披露

**原则**：AI 只加载需要的信息

```
Level 1: SKILL.md frontmatter（元数据）
    ↓ 触发匹配
Level 2: SKILL.md body（核心流程）
    ↓ AI 判断需要
Level 3: references/（详细资料）
```

- SKILL.md < 500 行
- 详细内容放 references/
- 明确说明何时加载 reference

### 3. 从实践中来

**原则**：只记录验证过的知识

- 从实际项目提取 Skill
- 记录踩过的坑
- 持续迭代优化

---

## Skill 结构

```
skill-name/
├── SKILL.md           # 核心指导（必须）
├── HISTORY.md         # 变更记录
├── patterns/          # 代码模式（可选）
└── references/        # 参考资料（可选）
```

### SKILL.md 基本结构

```markdown
---
name: skill-name
description: 详细描述，包含触发关键词
created: 2026-02-11
status: draft | stable
---

# 技能名称

## 适用场景
- 场景 1
- 场景 2

## 核心概念
- 概念 1：简要说明
- 概念 2：简要说明

## 快速开始
```代码示例```

## 代码模式
### 模式 1
说明 + 代码

## 常见问题
### 问题 1
**现象**：...
**原因**：...
**解决**：...

## 参考资料
- references/quick-ref.md

## 迭代记录
- 2026-02-11: 初始创建
```

---

## 组织原则

### 1. 技能粒度

| 粒度 | 示例 | 说明 |
|------|------|------|
| 太小 | `stm32-gpio-pin-a5` | 过于具体，难以复用 |
| 合适 | `stm32-gpio` | 覆盖整体，包含各引脚 |
| 太大 | `stm32-all` | 过于庞大，信息过载 |

### 2. 分类策略

```
skills/
├── dev-workflow/      # 通用开发工作流
├── embedded/          # 嵌入式领域
│   ├── common/        # 通用概念
│   ├── mcu/           # MCU 具体实现
│   └── rtos/          # RTOS
└── software/          # 软件领域
```

### 3. 引用关系

```
项目
  ↓ 引用
具体实现 Skill
  ↓ 引用
通用概念 Skill
  ↓ 引用
开发规范 Skill
```

---

## 创建检查清单

- [ ] frontmatter 完整（name/description/created/status）
- [ ] 适用场景清晰
- [ ] 核心概念不超过 5 个
- [ ] 有快速开始示例
- [ ] 常见问题来自实践
- [ ] HISTORY.md 记录创建
- [ ] 所有内容使用中文

---

## 参考

具体编写技巧参考：
- `skill-creator`（系统自带）- 详细编写指南
- `skills/embedded/mcu/st-stm32/` - 完整示例
