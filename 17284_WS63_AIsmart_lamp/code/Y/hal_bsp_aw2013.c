#include "hal_bsp_aw2013.h"
#include "stdio.h"
#include "pinctrl.h"
#include "gpio.h"
#include "i2c.h"
#include "securec.h"

// AW2013寄存器地址定义（按功能分组）
#define RSTR_REG_ADDR 0x00     // 复位寄存器（用于芯片复位）
#define GCR_REG_ADDR 0x01      // 全局控制寄存器（控制芯片工作模式）
#define ISR_REG_ADDR 0x02      // 中断状态寄存器（读取中断标志）
#define LCTR_REG_ADDR 0x30     // LED通道控制寄存器（启用/禁用LED通道）
#define LCFG0_REG_ADDR 0x31    // LED0配置寄存器（设置PWM模式等）
#define LCFG1_REG_ADDR 0x32    // LED1配置寄存器
#define LCFG2_REG_ADDR 0x33    // LED2配置寄存器
#define PWM0_REG_ADDR 0x34     // LED0 PWM值寄存器（控制红色通道亮度）
#define PWM1_REG_ADDR 0x35     // LED1 PWM值寄存器（控制绿色通道亮度）
#define PWM2_REG_ADDR 0x36     // LED2 PWM值寄存器（控制蓝色通道亮度）
#define LED0T0_REG_ADDR 0x37   // LED0 时间参数寄存器0
#define LED0T1_REG_ADDR 0x38   // LED0 时间参数寄存器1
#define LED0T2_REG_ADDR 0x39   // LED0 时间参数寄存器2
#define LED1T0_REG_ADDR 0x3A   // LED1 时间参数寄存器0
#define LED1T1_REG_ADDR 0x3B   // LED1 时间参数寄存器1
#define LED1T2_REG_ADDR 0x3C   // LED1 时间参数寄存器2
#define LED2T0_REG_ADDR 0x3D   // LED2 时间参数寄存器0
#define LED2T1_REG_ADDR 0x3E   // LED2 时间参数寄存器1
#define LED2T2_REG_ADDR 0x3F   // LED2 时间参数寄存器2
#define IADR_REG_ADDR 0x77     // I2C地址寄存器（可配置从机地址）

#define DELAY_TIME_MS 1        // 操作延时（毫秒），用于I2C通信稳定


/**
 * @brief 向AW2013指定寄存器写入单字节数据
 * @param regAddr 目标寄存器地址
 * @param byte 待写入的数据
 * @return 操作结果：ERRCODE_SUCC(0)表示成功，非0表示I2C通信失败
 */
static uint32_t aw2013_WiteByte(uint8_t regAddr, uint8_t byte)
{
    uint32_t result = 0;
    uint8_t buffer[] = {regAddr, byte};  // 构建写入数据帧（寄存器地址+数据）
    i2c_data_t i2c_data = {0};
    i2c_data.send_buf = buffer;          // 设置发送缓冲区
    i2c_data.send_len = sizeof(buffer);  // 设置发送数据长度

    // 通过I2C发送数据
    result = uapi_i2c_master_write(AW2013_I2C_IDX, AW2013_I2C_ADDR, &i2c_data);
    if (result != ERRCODE_SUCC) {
        printf("I2C AW2013 Write result is 0x%x!!!\r\n", result);
        return result;  // 通信失败时返回错误码
    }
    return result;
}


/**
 * @brief 控制RGB灯红色通道的亮度（通过PWM调节）
 * @param PWM_Data PWM值（0-255，0为熄灭，255为最大亮度）
 * @return 操作结果：ERRCODE_SUCC表示成功
 */
uint32_t AW2013_Control_Red(uint8_t PWM_Data)
{
    uint32_t result = 0;
    // 向PWM0寄存器写入红色通道PWM值（对应LED0通道）
    result = aw2013_WiteByte(PWM0_REG_ADDR, PWM_Data);
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 Red PWM1_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    return result;
}


/**
 * @brief 控制RGB灯绿色通道的亮度（通过PWM调节）
 * @param PWM_Data PWM值（0-255）
 * @return 操作结果：ERRCODE_SUCC表示成功
 */
uint32_t AW2013_Control_Green(uint8_t PWM_Data)
{
    uint32_t result = 0;
    // 向PWM1寄存器写入绿色通道PWM值（对应LED1通道）
    result = aw2013_WiteByte(PWM1_REG_ADDR, PWM_Data);
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 Green PWM0_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    return result;
}


/**
 * @brief 控制RGB灯蓝色通道的亮度（通过PWM调节）
 * @param PWM_Data PWM值（0-255）
 * @return 操作结果：ERRCODE_SUCC表示成功
 */
uint32_t AW2013_Control_Blue(uint8_t PWM_Data)
{
    uint32_t result = 0;
    // 向PWM2寄存器写入蓝色通道PWM值（对应LED2通道）
    result = aw2013_WiteByte(PWM2_REG_ADDR, PWM_Data);
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 Blue PWM2_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    return result;
}


/**
 * @brief 同时控制RGB三个通道的亮度
 * @param R_Value 红色PWM值
 * @param G_Value 绿色PWM值
 * @param B_Value 蓝色PWM值
 * @return 操作结果：ERRCODE_SUCC表示成功
 */
uint32_t AW2013_Control_RGB(uint8_t R_Value, uint8_t G_Value, uint8_t B_Value)
{
    uint32_t result = 0;

    // 依次写入三个通道的PWM值
    result = aw2013_WiteByte(PWM0_REG_ADDR, R_Value);  // 红色通道（LED0）
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 Green PWM0_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    result = aw2013_WiteByte(PWM1_REG_ADDR, G_Value);  // 绿色通道（LED1）
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 Red PWM1_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    result = aw2013_WiteByte(PWM2_REG_ADDR, B_Value);  // 蓝色通道（LED2）
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 Blue PWM2_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    return result;
}


/**
 * @brief 初始化AW2013 RGB控制器
 * @return 操作结果：ERRCODE_SUCC表示成功
 */
uint32_t AW2013_Init(void)
{
    uint32_t result;

    // 1. 复位芯片（向复位寄存器写入0x55）
    result = aw2013_WiteByte(RSTR_REG_ADDR, 0x55);
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 RSTR_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    // 2. 使能全局控制器并设置为RUN模式（GCR寄存器写入0x01）
    //    bit0=1表示启用芯片，其他位默认0（正常工作模式）
    result = aw2013_WiteByte(GCR_REG_ADDR, 0x01);
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 GCR_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    // 3. 启用RGB三个通道（LCTR寄存器写入0x07）
    //    bit0=1: 启用LED0（红色），bit1=1: 启用LED1（绿色），bit2=1: 启用LED2（蓝色）
    result = aw2013_WiteByte(LCTR_REG_ADDR, 0x07);
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 LCTR_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    // 4. 配置RGB通道工作模式（LCFG0~2寄存器写入0x63）
    //    0x63二进制为01100011，含义：
    //    bit7-6=01: PWM模式（非呼吸灯模式）
    //    bit5-4=11: 保留位（默认）
    //    bit3-0=0011: LED驱动电流设置（0x03对应最大电流）
    result = aw2013_WiteByte(LCFG0_REG_ADDR, 0x63);  // 红色通道配置
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 LCFG0_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    result = aw2013_WiteByte(LCFG1_REG_ADDR, 0x63);  // 绿色通道配置
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 LCFG1_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    result = aw2013_WiteByte(LCFG2_REG_ADDR, 0x63);  // 蓝色通道配置
    if (result != ERRCODE_SUCC) {
        printf("I2C aw2013 LCFG2_REG_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    printf("I2C aw2013 Init is succeeded!!!\r\n");  // 初始化成功提示
    return ERRCODE_SUCC;
}