#include "bsp_init.h"
#include "hal_bsp_aw2013.h"
#include "stdio.h"

// RGB亮度值定义
#define RGB_ON 255    // 全亮状态
#define RGB_OFF 0     // 熄灭状态

// 循环闪烁的节拍值定义
#define BEAT_0 0
#define BEAT_1 1
#define BEAT_2 2
#define BEAT_3 3

// 按键消抖时间(微秒)和亮度调节比例值
#define KEY_DELAY_TIME (100 * 1000) // 100毫秒
#define LIGHT_SCALE_VAL 4           // 光照强度缩放因子

// RGB颜色值结构体定义
typedef struct {
    uint8_t red;    // 红色通道值(0-255)
    uint8_t green;  // 绿色通道值(0-255)
    uint8_t blue;   // 蓝色通道值(0-255)
} ts_rgb_val_t;

// 睡眠模式 RGB灯的PWM值配置(暖色调低亮度)
ts_rgb_val_t sleep_mode_rgb_val = {
    .red = 20,
    .green = 20,
    .blue = 20,
};

// 看书模式 RGB灯的PWM值配置(暖白色高亮度)
ts_rgb_val_t readBook_mode_rgb_val = {
    .red = 226,
    .green = 203,
    .blue = 173,
};

// 灯光模式状态变量
static Lamp_Status_t lamp_mode = OFF_LAMP;  // 初始为关灯状态
static uint8_t t_led_blink_status = 0;      // 闪烁模式状态计数器

/**
 * @brief 初始化用户LED引脚
 * @note 配置LED引脚为输出模式并初始化为高电平(熄灭状态)
 */
void user_led_init(void)
{
    uapi_pin_set_mode(USER_LED, HAL_PIO_FUNC_GPIO);  // 设置引脚为GPIO功能
    uapi_gpio_set_dir(USER_LED, GPIO_DIRECTION_OUTPUT);  // 配置为输出方向
    uapi_gpio_set_val(USER_LED, GPIO_LEVEL_HIGH);  // 初始化为高电平(熄灭)
}

extern char oled_display_buff[30];  // OLED显示缓冲区外部声明

/**
 * @brief 处理RGB灯模式控制
 * @param mode 目标灯光模式
 * @retval None
 */
void switch_rgb_mode(Lamp_Status_t mode)
{
    uint8_t r, g, b;  // RGB值临时存储变量
    
    // 根据不同模式设置RGB值
    switch (mode) {
        case SUN_LIGHT_MODE:  // 白光模式(全亮)
            sys_msg_data.RGB_Value.red = sys_msg_data.RGB_Value.green = sys_msg_data.RGB_Value.blue = RGB_ON;
            break;

        case SLEEP_MODE:  // 睡眠模式(低亮度暖光)
            sys_msg_data.RGB_Value.red = sleep_mode_rgb_val.red;
            sys_msg_data.RGB_Value.green = sleep_mode_rgb_val.green;
            sys_msg_data.RGB_Value.blue = sleep_mode_rgb_val.blue;
            break;

        case READ_BOOK_MODE:  // 看书模式(高亮度暖白)
            sys_msg_data.RGB_Value.red = readBook_mode_rgb_val.red;
            sys_msg_data.RGB_Value.green = readBook_mode_rgb_val.green;
            sys_msg_data.RGB_Value.blue = readBook_mode_rgb_val.blue;
            break;

        case LED_BLINK_MODE:  // 三色闪烁模式
            t_led_blink_status++;  // 更新闪烁状态计数器

            // 根据计数器值切换不同颜色
            if (t_led_blink_status == BEAT_1) {
                sys_msg_data.RGB_Value.red = RGB_ON;
                sys_msg_data.RGB_Value.green = sys_msg_data.RGB_Value.blue = RGB_OFF;
            } else if (t_led_blink_status == BEAT_2) {
                sys_msg_data.RGB_Value.green = RGB_ON;
                sys_msg_data.RGB_Value.red = sys_msg_data.RGB_Value.blue = RGB_OFF;
            } else if (t_led_blink_status == BEAT_3) {
                sys_msg_data.RGB_Value.blue = RGB_ON;
                sys_msg_data.RGB_Value.red = sys_msg_data.RGB_Value.green = RGB_OFF;
            } else {
                t_led_blink_status = BEAT_0;  // 重置计数器
            }
            break;

        case SET_RGB_MODE:  // 调色模式(当前为空，可扩展)
            break;
            
        case AUTO_MODE:  // 自动模式(根据环境光调节)
            sys_msg_data.is_auto_light_mode = LIGHT_AUTO_MODE;
            break;
            
        default:  // 关闭灯光模式
            lamp_mode = OFF_LAMP;
            sys_msg_data.is_auto_light_mode = 0;
            sys_msg_data.Lamp_Status = OFF_LAMP;
            sys_msg_data.RGB_Value.red = RGB_OFF;
            sys_msg_data.RGB_Value.green = RGB_OFF;
            sys_msg_data.RGB_Value.blue = RGB_OFF;
            break;
    }

    // 根据光照强度进行自动调节
    if (sys_msg_data.is_auto_light_mode == LIGHT_AUTO_MODE) {
        // 在OLED显示屏上显示环境光强度信息
        sprintf(oled_display_buff, "light:%04d", 1024 - sys_msg_data.AP3216C_Value.light);
        SSD1306_ShowStr(OLED_TEXT16_COLUMN_0, OLED_TEXT16_LINE_1, oled_display_buff, TEXT_SIZE_16);

        // 计算并显示灯光亮度百分比
        memset(oled_display_buff, 0, sizeof(oled_display_buff));
        sprintf(oled_display_buff, "Lamp:%03d",
                (uint8_t)(((sys_msg_data.AP3216C_Value.light * 100) / LIGHT_SCALE_VAL)) / 255);
        SSD1306_ShowStr(OLED_TEXT16_COLUMN_0, OLED_TEXT16_LINE_2, oled_display_buff, TEXT_SIZE_16);

        // 根据环境光强度控制RGB灯亮度(等比例调节)
        AW2013_Control_RGB((uint8_t)(sys_msg_data.AP3216C_Value.light / LIGHT_SCALE_VAL),
                           (uint8_t)(sys_msg_data.AP3216C_Value.light / LIGHT_SCALE_VAL),
                           (uint8_t)(sys_msg_data.AP3216C_Value.light / LIGHT_SCALE_VAL));
    } else {
        // 手动调节模式，直接使用预设RGB值
        r = sys_msg_data.RGB_Value.red;
        g = sys_msg_data.RGB_Value.green;
        b = sys_msg_data.RGB_Value.blue;
        AW2013_Control_RGB(r, g, b);
    }
}

/**
 * @brief 按键中断回调函数
 * @note 检测到按键按下时，切换灯光模式
 * @param pin 触发中断的引脚
 * @param param 回调函数参数
 */
void user_key_callback_func(pin_t pin, uintptr_t param)
{
    unused(pin);      // 标记未使用的参数
    unused(param);    // 标记未使用的参数
    
    lamp_mode++;      // 切换到下一个灯光模式
    printf("lamp_mode=%d!\r\n", lamp_mode);  // 打印当前灯光模式
    
    // 记录灯的状态到系统消息数据结构
    sys_msg_data.Lamp_Status = lamp_mode;
}

/**
 * @brief 按键初始化函数
 * @note 配置按键引脚并注册上升沿中断回调函数
 * @retval None
 */
void KEY_Init(void)
{
    uapi_pin_set_mode(KEY, PIN_MODE_0);  // 设置按键引脚模式
    
    uapi_pin_set_pull(KEY, PIN_PULL_TYPE_DOWN);  // 设置下拉电阻
    uapi_gpio_set_dir(KEY, GPIO_DIRECTION_INPUT);  // 配置为输入方向
    
    /* 注册指定GPIO上升沿中断，回调函数为user_key_callback_func */
    if (uapi_gpio_register_isr_func(KEY, GPIO_INTERRUPT_RISING_EDGE, user_key_callback_func) != 0) {
        printf("register_isr_func fail!\r\n");  // 中断注册失败处理
        uapi_gpio_unregister_isr_func(KEY);     // 注销中断
    }
    
    uapi_gpio_enable_interrupt(KEY);  // 使能按键中断
}