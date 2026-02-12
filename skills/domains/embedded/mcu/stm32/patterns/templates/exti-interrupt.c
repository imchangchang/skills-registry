/**
 * STM32 外部中断（EXTI）配置模板
 * 
 * 关键要点：
 * - 必须清除中断标志，否则会持续触发
 * - 注意 NVIC 优先级配置
 */

#include "stm32f4xx_hal.h"

/* 中断回调函数（弱定义，用户实现） */
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
    if(GPIO_Pin == GPIO_PIN_0) {
        // 按键中断处理
        // 建议：设置标志位，在主循环处理，不要在中断中做耗时操作
    }
}

void EXTI_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    
    /* 1. 使能时钟 */
    __HAL_RCC_GPIOA_CLK_ENABLE();
    
    /* 2. 配置引脚为中断输入 */
    GPIO_InitStruct.Pin = GPIO_PIN_0;
    GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;  // 下降沿触发
    GPIO_InitStruct.Pull = GPIO_PULLUP;            // 上拉（按键常用）
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
    
    /* 3. 配置 NVIC */
    HAL_NVIC_SetPriority(EXTI0_IRQn, 2, 0);  // 抢占优先级2，子优先级0
    HAL_NVIC_EnableIRQ(EXTI0_IRQn);
}

/* 4. 中断服务函数（在 startup 文件中定义） */
void EXTI0_IRQHandler(void)
{
    /* 关键：HAL_GPIO_EXTI_IRQHandler 会清除中断标志 */
    HAL_GPIO_EXTI_IRQHandler(GPIO_PIN_0);
}

/* 注意事项：
 * 1. 如果手动操作寄存器，必须清除 PR 寄存器对应位
 *    __HAL_GPIO_EXTI_CLEAR_IT(GPIO_PIN_0);
 * 
 * 2.  EXTI0-EXTI4 有独立中断线
 *     EXTI5-EXTI9 共用 EXTI9_5_IRQn
 *     EXTI10-EXTI15 共用 EXTI15_10_IRQn
 */
