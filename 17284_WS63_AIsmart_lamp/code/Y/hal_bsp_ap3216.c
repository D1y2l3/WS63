#include "hal_bsp_ap3216.h"
#include "stdio.h"
#include "pinctrl.h"
#include "gpio.h"
#include "i2c.h"
#include "securec.h"

// AP3216C寄存器地址定义
#define AP3216C_SYSTEM_ADDR 0x00    // 系统控制寄存器
#define AP3216C_IR_L_ADDR 0x0A      // IR数据低位寄存器
#define AP3216C_IR_H_ADDR 0x0B      // IR数据高位寄存器
#define AP3216C_ALS_L_ADDR 0x0C     // 环境光数据低位寄存器
#define AP3216C_ALS_H_ADDR 0x0D     // 环境光数据高位寄存器
#define AP3216C_PS_L_ADDR 0x0E      // 接近传感器数据低位寄存器
#define AP3216C_PS_H_ADDR 0x0F      // 接近传感器数据高位寄存器

// 辅助宏定义
#define AP3216C_RESET_TIME 50       // 复位延时时间(毫秒)
#define LEFT_SHIFT_2 2              // 左移2位
#define LEFT_SHIFT_4 4              // 左移4位
#define LEFT_SHIFT_8 8              // 左移8位

/**
 * @brief 向AP3216C发送单字节数据
 * @param byte 待发送的字节数据
 * @return 操作结果：ERRCODE_SUCC表示成功，其他值表示失败
 */
static uint32_t AP3216C_WiteByteData(uint8_t byte)
{
    uint8_t buffer[] = {byte};
    i2c_data_t i2cData = {0};
    i2cData.send_buf = &byte;      // 设置发送缓冲区指针
    i2cData.send_len = sizeof(buffer);  // 设置发送数据长度
    return uapi_i2c_master_write(AP3216C_I2C_IDX, AP3216C_I2C_ADDR, &i2cData);
}

/**
 * @brief 从AP3216C接收数据
 * @param data 接收数据缓冲区指针
 * @param size 期望接收的数据大小
 * @return 操作结果：ERRCODE_SUCC表示成功，其他值表示失败
 */
static uint32_t AP3216C_RecvData(uint8_t *data, size_t size)
{
    i2c_data_t i2cData = {0};
    i2cData.receive_buf = data;    // 设置接收缓冲区指针
    i2cData.receive_len = size;    // 设置接收数据长度

    return uapi_i2c_master_read(AP3216C_I2C_IDX, AP3216C_I2C_ADDR, &i2cData);
}

/**
 * @brief 向AP3216C的指定寄存器写入数据
 * @param regAddr 目标寄存器地址
 * @param byte 待写入的数据
 * @return 操作结果：ERRCODE_SUCC表示成功，其他值表示失败
 */
static uint32_t AP3216C_WiteCmdByteData(uint8_t regAddr, uint8_t byte)
{
    uint8_t buffer[] = {regAddr, byte};  // 构建写入缓冲区(寄存器地址+数据)
    i2c_data_t i2cData = {0};
    i2cData.send_buf = buffer;           // 设置发送缓冲区指针
    i2cData.send_len = sizeof(buffer);   // 设置发送数据长度
    return uapi_i2c_master_write(AP3216C_I2C_IDX, AP3216C_I2C_ADDR, &i2cData);
}

/**
 * @brief 从AP3216C的指定寄存器读取数据
 * @param regAddr 目标寄存器地址
 * @param byte 读取数据的存储地址
 * @return 操作结果：ERRCODE_SUCC表示成功，其他值表示失败
 */
static uint32_t AP3216C_ReadRegByteData(uint8_t regAddr, uint8_t *byte)
{
    uint32_t result = 0;
    uint8_t buffer[2] = {0};

    // 发送寄存器地址
    result = AP3216C_WiteByteData(regAddr);
    if (result != ERRCODE_SUCC) {
        printf("I2C AP3216C status = 0x%x!!!\r\n", result);  // 打印错误码
        return result;
    }

    // 读取寄存器数据
    result = AP3216C_RecvData(buffer, 1);
    if (result != ERRCODE_SUCC) {
        printf("I2C AP3216C status = 0x%x!!!\r\n", result);  // 打印错误码
        return result;
    }
    
    *byte = buffer[0];  // 保存读取结果

    return ERRCODE_SUCC;
}

/**
 * @brief 从AP3216C读取所有传感器数据
 * @param irData 红外数据存储地址(10位有效数据)
 * @param alsData 环境光数据存储地址(16位有效数据)
 * @param psData 接近传感器数据存储地址(10位有效数据)
 * @return 操作结果：ERRCODE_SUCC表示成功，其他值表示失败
 */
uint32_t AP3216C_ReadData(uint16_t *irData, uint16_t *alsData, uint16_t *psData)
{
    uint32_t result = 0;
    uint8_t data_H = 0;  // 高位数据
    uint8_t data_L = 0;  // 低位数据

    // 读取IR传感器数据(10位分辨率)
    result = AP3216C_ReadRegByteData(AP3216C_IR_L_ADDR, &data_L);
    if (result != ERRCODE_SUCC) {
        return result;
    }

    result = AP3216C_ReadRegByteData(AP3216C_IR_H_ADDR, &data_H);
    if (result != ERRCODE_SUCC) {
        return result;
    }

    if (data_L & 0x80) {  // 检查IR_OF标志(数据溢出标志)
        // IR_OF为1, 则数据无效
        *irData = 0;
    } else {
        // 合并高低位数据(高2位+低8位)
        *irData = ((uint16_t)data_H << LEFT_SHIFT_2) | (data_L & 0x03);
    }

    // 读取ALS传感器数据(16位分辨率)
    result = AP3216C_ReadRegByteData(AP3216C_ALS_L_ADDR, &data_L);
    if (result != ERRCODE_SUCC) {
        return result;
    }

    result = AP3216C_ReadRegByteData(AP3216C_ALS_H_ADDR, &data_H);
    if (result != ERRCODE_SUCC) {
        return result;
    }

    // 合并高低位数据(完整16位)
    *alsData = ((uint16_t)data_H << LEFT_SHIFT_8) | (data_L);

    // 读取PS传感器数据(10位分辨率)
    result = AP3216C_ReadRegByteData(AP3216C_PS_L_ADDR, &data_L);
    if (result != ERRCODE_SUCC) {
        return result;
    }

    result = AP3216C_ReadRegByteData(AP3216C_PS_H_ADDR, &data_H);
    if (result != ERRCODE_SUCC) {
        return result;
    }

    if (data_L & 0x40) {  // 检查PS_OF标志(数据溢出标志)
        // PS_OF为1, 则数据无效
        *psData = 0;
    } else {
        // 合并高低位数据(高6位+低4位)
        *psData = ((uint16_t)(data_H & 0x3F) << LEFT_SHIFT_4) | (data_L & 0x0F);
    }

    return ERRCODE_SUCC;
}

/**
 * @brief 初始化AP3216C传感器
 * @return 操作结果：ERRCODE_SUCC表示成功，其他值表示失败
 */
uint32_t AP3216C_Init(void)
{
    uint32_t result;

    // 复位芯片(写入0x04到系统控制寄存器)
    result = AP3216C_WiteCmdByteData(AP3216C_SYSTEM_ADDR, 0x04);
    if (result != ERRCODE_SUCC) {
        printf("I2C AP3216C AP3216C_SYSTEM_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }

    osDelay(AP3216C_RESET_TIME);  // 等待复位完成

    // 开启ALS(环境光传感器)、PS(接近传感器)和IR(红外传感器)
    result = AP3216C_WiteCmdByteData(AP3216C_SYSTEM_ADDR, 0x03);
    if (result != ERRCODE_SUCC) {
        printf("I2C AP3216C AP3216C_SYSTEM_ADDR status = 0x%x!!!\r\n", result);
        return result;
    }
    
    printf("I2C AP3216C Init is succeeded!!!\r\n");  // 初始化成功提示

    return ERRCODE_SUCC;
}