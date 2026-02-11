# 技能设计原则

Skill（技能）是 Vibe Coding 的核心知识单元，良好的 Skill 设计直接影响 AI 协作效率。

## 什么是 Skill？

> **Skill = 领域知识包 = 指导 + 模板 + 参考资料**

Skill 将特定领域的知识结构化封装，让 AI 能够快速获取并使用。

## 设计理念

### 1. 知识无版本

**原则**：只有当前最佳实践，不强制版本号

```
昨天：GPIO 初始化要先使能时钟
今天：发现还需要配置 PWR 寄存器（H7 系列）

不需要：stm32-gpio@v1.0 → stm32-gpio@v1.1
只需要：更新 SKILL.md，添加 PWR 注意事项
```

**实现**：
- 使用 HISTORY.md 记录演进过程
- Git 历史作为真正的版本控制
- 错误就改，补充就加

### 2. 渐进式披露

**原则**：AI 只加载需要的信息

```
Level 1: SKILL.md frontmatter（~100 tokens）
    ↓ 触发匹配
Level 2: SKILL.md body（~2k tokens）
    ↓ AI 判断需要
Level 3: references/（无限制）
```

**实现**：
- SKILL.md < 500 行
- 详细内容放 references/
- 明确说明何时加载 reference

### 3. 从实践中来

**原则**：只记录验证过的知识

```
[X] 不要：复制官方文档全文
[OK] 要：提取实战中常用的 20% 内容

[X] 不要：假设性的最佳实践
[OK] 要：解决过实际问题的方案
```

**实现**：
- 从实际项目提取 Skill
- 记录踩过的坑
- 持续迭代优化

## Skill 结构

```
skill-name/
├── SKILL.md              # 核心指导（必须）
├── HISTORY.md            # 变更记录
├── patterns/             # 代码模式
│   ├── templates/        # 可直接使用的模板
│   └── examples/         # 示例代码
└── references/           # 参考资料
    ├── quick-ref.md      # 速查表
    └── detailed/         # 详细文档
```

### SKILL.md 结构

```markdown
---
name: skill-name                   # 技能标识
description: 详细描述，包含触发关键词  # AI 判断是否使用
created: 2026-02-11              # 创建日期
status: draft | stable            # 状态
---

# 技能名称

## 适用场景                    # 何时使用
- 场景 1
- 场景 2

## 核心概念                    # 关键知识点（3-5个）
- 概念 1：简要说明
- 概念 2：简要说明

## 快速开始                    # 最简示例
```代码```

## 代码模式                    # 常用模式
### 模式 1
说明 + 代码

## 常见问题                    # 踩坑记录
### 问题 1
**现象**：...
**原因**：...
**解决**：...

## 参考资料                    # 按需加载
- references/quick-ref.md
- references/detailed-guide.md

## 迭代记录
- 2026-02-11: 初始创建
```

## 内容组织原则

### 1. 技能粒度

| 粒度 | 示例 | 说明 |
|------|------|------|
| 太小 | `stm32-gpio-pin-a5` | 过于具体，难以复用 |
| 合适 | `stm32-gpio` | 覆盖 GPIO 整体，包含各引脚 |
| 太大 | `stm32-all` | 过于庞大，信息过载 |

### 2. 分类策略

```
skills/
├── dev-workflow/          # 通用开发工作流
│   ├── git-commits/       # Git 提交
│   ├── quality-gates/     # 质量门禁
│   └── pr-workflow/       # PR 流程
│
├── embedded/              # 嵌入式领域
│   ├── common/            # 通用概念
│   ├── mcu/               # MCU 具体实现
│   │   ├── st-stm32/
│   │   └── gd32/
│   └── rtos/              # RTOS
│       ├── freertos/
│       └── rt-thread/
│
└── software/              # 软件领域
    ├── docker/
    ├── python/
    └── ros/
```

### 3. 引用关系

```
项目
  ↓ 引用
st-stm32/               # 具体实现
  ↓ 引用
embedded-common/        # 通用概念
  ↓ 引用
dev-workflow/           # 开发规范
```

## 编写技巧

### 1. 描述要精准

**好的 description**：
```yaml
description: STM32 MCU development using HAL/LL drivers. 
  Covers STM32F4/F7/H7 series clock, GPIO, interrupt, DMA, 
  and timer configuration. Use when developing bare-metal 
  or RTOS-based firmware for STM32.
```

包含：
- 技术栈（HAL/LL）
- 覆盖范围（F4/F7/H7）
- 主题（clock/GPIO/interrupt）
- 使用场景（bare-metal/RTOS）

### 2. 示例要完整

**好的模板**：
```c
// stm32-gpio/patterns/templates/gpio-init.c

/**
 * GPIO 初始化模板
 * 
 * 修改点：
 * 1. GPIOx: 修改为实际端口（GPIOA/GPIOB/...）
 * 2. GPIO_PIN_x: 修改为实际引脚
 * 3. Mode/Pull/Speed: 根据需求调整
 */

// 1. 使能时钟（必须先做！）
__HAL_RCC_GPIOA_CLK_ENABLE();

// 2. 配置引脚
GPIO_InitTypeDef GPIO_InitStruct = {0};
GPIO_InitStruct.Pin = GPIO_PIN_5;
GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
GPIO_InitStruct.Pull = GPIO_NOPULL;
GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

// 3. 使用
HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
```

### 3. 问题要具体

**好的 troubleshooting**：
```markdown
### 问题：GPIO 不工作
**现象**：设置输出高电平，但引脚无变化
**原因**：忘记使能 GPIO 时钟
**解决**：确认调用了 `__HAL_RCC_GPIOx_CLK_ENABLE()`
**检查点**：
1. 确认时钟使能代码已执行
2. 确认引脚号正确
3. 确认没有复用冲突
```

## 迭代流程

```mermaid
graph LR
    A[项目开发] --> B[发现问题]
    B --> C[记录到 todo]
    C --> D[修改 Skill]
    D --> E[提交到 Registry]
    E --> F[其他项目受益]
```

### 快速记录模板

```markdown
## 待办

- [ ] stm32-gpio: 补充 H7 时钟配置说明
  来源：项目 X 开发中发现
  问题：H7 系列需要额外配置 PWR 寄存器
  
- [ ] git-commits: 添加 amend 场景
  来源：PR 审查时用到
  场景：提交后发现小错误需要修正
```

## 检查清单

创建新 Skill 时检查：

- [ ] frontmatter 完整（name/description/created/status）
- [ ] 适用场景清晰
- [ ] 核心概念不超过 5 个
- [ ] 有快速开始示例
- [ ] 常见问题真实（来自实践）
- [ ] HISTORY.md 记录创建
- [ ] 如需要，添加 patterns/
- [ ] 如需要，添加 references/
- [ ] 所有内容使用中文

## 示例 Skill

参考 `skills/embedded/mcu/st-stm32/`：
- 完整的 SKILL.md
- 实用的代码模板
- 真实的踩坑记录

## 下一步

- 了解 [实施流程](workflow.md)
- 阅读 [术语表](glossary.md)
