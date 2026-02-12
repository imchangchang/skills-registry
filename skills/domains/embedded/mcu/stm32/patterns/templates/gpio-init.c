/**
 * STM32 GPIO 初始化模板
 * 
 * 使用说明：
 * 1. 修改 GPIOx 为实际端口（GPIOA/GPIOB/...）
 * 2. 修改 GPIO_PIN_x 为实际引脚
 * 3. 根据需求修改 Mode/Pull/Speed
 */

#include "stm32f4xx_hal.h"

void GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    
    /* 1. 使能 GPIO 时钟 - 必须先做！ */
    __HAL_RCC_GPIOA_CLK_ENABLE();
    
    /* 2. 配置 GPIO 参数 */
    GPIO_InitStruct.Pin = GPIO_PIN_5;                    // LED 引脚
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;          // 推挽输出
    GPIO_InitStruct.Pull = GPIO_NOPULL;                  // 无上下拉
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;         // 低速（2MHz）
    
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
    
    /* 3. 初始状态 */
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
}

/* 使用示例 */
void LED_Toggle(void)
{
    HAL_GPIO_TogglePin(GPIOA, GPIO_PIN_5);
}

void LED_On(void)
{
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_SET);
}

void LED_Off(void)
{
    HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, GPIO_PIN_RESET);
}
