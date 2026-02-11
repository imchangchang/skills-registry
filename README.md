# Skills Registry

个人技能知识库，用于 AI 协作开发。

## 设计理念

- **知识无版本**：只有当前最佳实践，不强制版本号
- **渐进式披露**：AI 按需加载，避免上下文爆炸
- **从实践中来**：每个技能都经过实际项目验证

## 目录结构

```
skills/
├── embedded/           # 嵌入式开发技能
│   ├── common/        # 通用概念
│   ├── mcu/           # MCU 相关
│   │   └── st-stm32/  # STM32 具体实现
│   ├── rtos/          # RTOS 相关
│   │   ├── freertos/
│   │   └── rt-thread/
│   └── soc-linux/     # Linux SoC
│       └── rockchip/
│
├── software/          # 软件开发技能
│   ├── git/
│   ├── docker/
│   └── ros/
│       ├── ros1/
│       └── ros2/
│
└── README.md          # 本文件
```

## 使用方式

在项目中创建 `.skill-set` 文件声明所需技能：

```
embedded/mcu/st-stm32
embedded/rtos/freertos
software/ros/ros2
```

然后通过符号链接引用：

```bash
ln -sf ~/skills-registry/skills/embedded/mcu/st-stm32 ./skills/st-stm32
```

## 创建新技能

```bash
./scripts/new-skill.sh <category>/<skill-name>
```

## Skill 格式

每个技能目录包含：

```
skill-name/
├── SKILL.md           # 核心指导（<500 行）
├── patterns/          # 代码模式
│   ├── templates/     # 可直接使用的模板
│   └── examples/      # 示例代码
├── references/        # 参考资料（按需加载）
│   ├── quick-ref.md   # 速查表
│   └── detailed/      # 详细文档
└── HISTORY.md         # 变更记录（非版本号）
```

## 贡献原则

1. **来自实践**：只记录验证过的知识
2. **精简核心**：SKILL.md 保持精简，详细内容放 references/
3. **持续迭代**：开发中发现问题立即更新

---

*最后更新：2024-01*
