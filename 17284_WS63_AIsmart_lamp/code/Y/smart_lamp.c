#include "stdio.h"
#include "string.h"
#include "soc_osal.h"
#include "securec.h"
#include "osal_debug.h"
#include "cmsis_os2.h" 
#include "bsp/hal_bsp_ssd1306.h"
#include "bsp/bsp_init.h"
#include "bsp/hal_bsp_bmps.h"
#include "bsp/wifi_connect.h"
#include "bsp/mqtt.h"
#include "bsp/oled_show_log.h"
#include "bsp/hal_bsp_ap3216.h"
#include "bsp/hal_bsp_aw2013.h"
#include "app_init.h"
#include "osal_task.h"
#include "watchdog.h"

// 任务执行延时参数定义
#define TASK_DELAY_TIME (1000)       // 任务延时1000微秒
#define KEY_COUNT_TIEMS (10)          // 按键计数项数
#define SENSOR_COUNT_TIMES (50)       // 传感器采集周期（50次循环）
#define CHANGE_MODE_COUNT_TIMES (100) // 模式切换周期（100次循环）

// OLED显示缓冲区与MQTT响应数据
char oled_display_buff[30] = {0};                 // OLED显示缓冲区
char g_response_buf[] =                           // MQTT响应JSON数据
    "{\"result_code\": 0,\"response_name\": \"beep\",\"paras\": {\"result\": \"success\"}}";
char g_buffer[512] = {0};                         // MQTT发布数据缓冲区

// 全局数据结构与标志位
msg_data_t sys_msg_data = {0};                    // 系统消息数据（存储传感器和灯状态）
uint8_t mqtt_conn = 0;                            // MQTT连接状态标志
uint8_t g_cmdFlag = 0;                            // MQTT命令标志位
char g_response_id[100] = {0};                    // 保存命令ID的缓冲区


/**
 * @brief 传感器数据采集与灯光控制函数
 * @note 循环采集环境光数据并控制RGB灯模式
 */
void sensor_collect_function(void)
{
    uint16_t times = 0;             // 循环计数变量
    uint8_t last_mode = 0;           // 记录上一次灯光模式
    
    // 初始化传感器与灯光控制芯片
    AP3216C_Init();                 // 初始化环境光传感器
    AW2013_Init();                  // 初始化RGB灯控制芯片
    AW2013_Control_RGB(0, 0, 0);    // 初始关闭RGB灯
    
    // 主循环：持续采集数据并控制灯光
    while (1) {
        // 手动模式下处理灯光模式切换
        if (sys_msg_data.is_auto_light_mode == LIGHT_MANUAL_MODE) {
            if (last_mode != sys_msg_data.Lamp_Status) {
                switch_rgb_mode(sys_msg_data.Lamp_Status);  // 切换灯光模式
            }
            last_mode = sys_msg_data.Lamp_Status;           // 更新模式记录
        }

        // 周期性采集传感器数据（每50次循环）
        if (!(times % SENSOR_COUNT_TIMES)) {
            // 读取AP3216C传感器数据（红外、接近、环境光）
            AP3216C_ReadData(&sys_msg_data.AP3216C_Value.infrared, 
                             &sys_msg_data.AP3216C_Value.proximity,
                             &sys_msg_data.AP3216C_Value.light);
            
            // 手动模式下更新OLED显示
            if (sys_msg_data.is_auto_light_mode == LIGHT_MANUAL_MODE) {
                memset(oled_display_buff, 0, sizeof(oled_display_buff));
                sprintf(oled_display_buff, "light:%04d", sys_msg_data.AP3216C_Value.light);
                SSD1306_ShowStr(OLED_TEXT16_COLUMN_0, OLED_TEXT16_LINE_1, oled_display_buff, TEXT_SIZE_16);
                
                memset(oled_display_buff, 0, sizeof(oled_display_buff));
                sprintf(oled_display_buff, "Lamp:%s", 
                        (sys_msg_data.Lamp_Status == OFF_LAMP) ? "OFF" : " ON");
                SSD1306_ShowStr(OLED_TEXT16_COLUMN_0, OLED_TEXT16_LINE_2, oled_display_buff, TEXT_SIZE_16);
            }
            times = 0;  // 重置计数器
        }

        // 周期性更新灯光模式显示（每100次循环）
        if (!(times % CHANGE_MODE_COUNT_TIMES)) {
            memset(oled_display_buff, 0, sizeof(oled_display_buff));
            sprintf(oled_display_buff, "auto control:%s", 
                    (sys_msg_data.is_auto_light_mode == 1) ? " ON" : "OFF");
            SSD1306_ShowStr(OLED_TEXT16_COLUMN_0, OLED_TEXT16_LINE_0, oled_display_buff, TEXT_SIZE_16);
            switch_rgb_mode(sys_msg_data.Lamp_Status);  // 刷新灯光模式
        }

        times++;                // 循环计数递增
        osal_udelay(TASK_DELAY_TIME);  // 延时1000微秒
    }
}


/**
 * @brief MQTT命令响应处理函数
 * @note 检测命令标志位并发送响应消息
 */
void mqtt_report_function(void)
{
    while (1) {
        if (g_cmdFlag) {                          // 检测到命令标志位
            sprintf(g_buffer, MQTT_CLIENT_RESPONSE, g_response_id);  // 构建响应主题
            mqtt_publish(g_buffer, g_response_buf);  // 发布响应消息
            g_cmdFlag = 0;                          // 清除命令标志
            memset(g_response_id, 0, sizeof(g_response_id));  // 清空命令ID
        }
        osDelay(20);  // 延时20毫秒（降低CPU占用）
    }
}


// /**
//  * @brief 主功能初始化函数
//  * @note 执行NFC配网和MQTT连接
//  */
// void main_function(void)
// {
//     // 执行NFC配网
//     if (nfc_connect_wifi_init() == -1) {
//         printf("NFC配网失败\n");
//         return;
//     }
    
//     // 连接MQTT服务器
//     mqtt_connect();
// }


/**
 * @brief 外设初始化函数
 * @note 初始化LED、按键、OLED等外设
 */
void my_peripheral_init(void)
{
    user_led_init();          // 初始化用户LED
    KEY_Init();               // 初始化按键
    SSD1306_Init();           // 初始化OLED显示屏
    SSD1306_CLS();            // 清屏OLED
    sys_msg_data.led_light_value = 100;  // 设置默认亮度为100%
    uapi_watchdog_disable();  // 禁用看门狗（调试模式）
}


/**
 * @brief 标准C程序入口函数
 * @note 程序执行起点，按顺序初始化并启动各功能模块
 */
int main(void)
{
    printf("Smart Lamp System Starting...\n");  // 系统启动提示
    
    // 初始化外设硬件
    my_peripheral_init();
    
    // 主功能流程：先进行网络连接
    main_function();
    
    // 启动传感器采集与灯光控制
    sensor_collect_function();
    
    // MQTT命令响应
    mqtt_report_function();
    
    // 程序主循环
    while (1) {
        osDelay(100);  // 主循环延时
    }
    
    return 0;
}



void smart_farm_demo(void)
{
    printf("Enter smart_farm_demo()!\n");
    my_peripheral_init();
   
}