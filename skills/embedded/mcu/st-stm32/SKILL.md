---
name: st-stm32
description: STM32 MCU development using HAL/LL drivers. Covers STM32F4/F7/H7 series clock, GPIO, interrupt, DMA, and timer configuration.
created: 2026-02-11
status: draft
---

# STM32 MCU 开发

## 适用场景
- 使用 STM32 HAL/LL 库进行裸机或 RTOS 开发
- STM32F4/F7/H7 系列为主
- 需要寄存器级调试时参考

## 核心概念

### 1. 时钟树（RCC）
**必须先配置时钟，否则外设无法工作！**

- HSI：内部高速时钟（16MHz），启动默认
- HSE：外部高速时钟（4-26MHz），需晶振
- PLL：锁相环倍频，系统时钟来源
- AHB/APB 分频：总线时钟

### 2. GPIO 工作模式
- Input：浮空、上拉、下拉、模拟
- Output：推挽、开漏
- Alternate Function：复用功能（USART/SPI/I2C/TIM）
- Analog：ADC/DAC 使用

### 3. 中断优先级（NVIC）
- 抢占优先级（Preemption）：可打断其他中断
- 子优先级（Sub）：同抢占级时排队
- **注意**：优先级数值越小优先级越高

## 快速开始

### GPIO 初始化（最简）
```c
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

### 中断配置（EXTI）
```c
// 关键：必须清除中断标志！
void HAL_GPIO_EXTI_IRQHandler(uint16_t GPIO_Pin) {
    if(__HAL_GPIO_EXTI_GET_IT(GPIO_Pin) != RESET) {
        __HAL_GPIO_EXTI_CLEAR_IT(GPIO_Pin);  // 必须！
        // 用户代码
    }
}
```

## 代码模式

### 模式 1：定时器 PWM 输出
见 patterns/templates/timer-pwm.c

### 模式 2：DMA 传输
见 patterns/templates/dma-transfer.c

### 模式 3：低功耗模式进入
见 patterns/templates/low-power.c

## 常见问题

### 问题 1：GPIO 不工作
**现象**：设置输出高电平，但引脚无变化
**原因**：忘记使能 GPIO 时钟
**解决**：确认调用了 `__HAL_RCC_GPIOx_CLK_ENABLE()`

### 问题 2：中断持续触发，程序卡死
**现象**：进入中断后无法退出，或频繁进入
**原因**：没有清除中断标志位
**解决**：在 ISR 中调用 `__HAL_GPIO_EXTI_CLEAR_IT()`

### 问题 3：时钟配置后死机
**现象**：修改 PLL 后程序卡死
**原因**：PLL 配置错误导致系统时钟失效
**解决**：使用 HAL_RCC_OscConfig() 的返回值检查，配置失败时回退到 HSI

## 参考资料

- **速查表**：references/quick-ref.md - 寄存器地址、常用 API
- **时钟配置**：references/clock-configuration.md - 详细时钟树说明
- **系列差异**：references/series-differences.md - F4 vs F7 vs H7

## 迭代记录
- 2026-02-11: 初始创建，包含 GPIO、中断基础
