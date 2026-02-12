# STM32 F4 vs F7 vs H7 系列差异

> 本文档对比 STM32 三个主流系列的差异。
>
> 状态：待完善（由 SKILL.md 引用创建）

## 概览对比

| 特性 | F4 系列 | F7 系列 | H7 系列 |
|------|---------|---------|---------|
| **Cortex-M** | M4 | M7 | M7 |
| **主频** | 最高 180MHz | 最高 216MHz | 最高 480MHz |
| **FPU** | 单精度 | 双精度 | 双精度 |
| **Cache** | 无 | 4KB D-Cache | 16KB D/I-Cache |
| **ART 加速器** | 无 | 有 | 有 |
| **供电电压** | 1.8V - 3.6V | 1.8V - 3.6V | 1.62V - 3.6V |

## 核心差异

### 1. 浮点运算单元 (FPU)

**F4**: 单精度浮点（float）
```c
// 需要启用 FPU
SCB->CPACR |= ((3UL << 10*2) | (3UL << 11*2));  // 设置 CP10 和 CP11 全访问
```

**F7/H7**: 双精度浮点（double）
```c
// 同样需要启用 FPU，但支持 double
```

### 2. 缓存 (Cache)

**F4**: 无缓存

**F7**: 4KB 数据缓存

**H7**: 16KB 数据缓存 + 16KB 指令缓存

```c
// H7 需要使能缓存
SCB_EnableICache();
SCB_EnableDCache();
```

### 3. 时钟配置

**F4/F7**: 标准时钟树

**H7**: 需要额外 PWR 配置
```c
// H7 特有
__HAL_RCC_PWR_CLK_ENABLE();
__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE0);
```

## HAL 库差异

### GPIO 配置

三个系列基本相同，但 H7 有更多速度选项：

```c
// F4/F7
GPIO_SPEED_FREQ_LOW
GPIO_SPEED_FREQ_MEDIUM
GPIO_SPEED_FREQ_HIGH
GPIO_SPEED_FREQ_VERY_HIGH

// H7 额外增加
GPIO_SPEED_FREQ_ULTRA_HIGH
```

### DMA 配置

**F4**: DMA1, DMA2

**F7**: DMA1, DMA2

**H7**: DMA1, DMA2 + MDMA（高级 DMA）

## 选型建议

| 应用场景 | 推荐系列 | 理由 |
|----------|----------|------|
| 成本敏感 | F4 | 性价比高，生态成熟 |
| 中等性能 | F7 | 双精度 FPU，带 Cache |
| 高性能 | H7 | 480MHz，大容量 Cache |
| 低功耗 | L4/L5 | 专为低功耗设计 |

## 待完善内容

- [ ] 各系列 Flash 等待周期配置
- [ ] 外设差异详细列表
- [ ] 启动文件差异
- [ ] 调试接口差异
