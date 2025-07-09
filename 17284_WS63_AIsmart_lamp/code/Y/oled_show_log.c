#include <string.h>
#include <stdio.h>
#include <stdbool.h>
#include "hal_bsp_ssd1306.h"
#include "oled_show_log.h"

#define INIT_LINE 1     // 初始显示行号（从第1行开始）
#define MAX_LINE 4      // 最大显示行数（总共4行）
#define MAX_ROW 16      // 每行最大显示字符数（16个字符）

// 定义显示行号枚举（方便代码可读性）
typedef enum {
    LINE_1 = 1,
    LINE_2,
    LINE_3,
    LINE_4,
    LINE_5,
} te_Line_t;


/**
 * @brief 在OLED指定行显示字符串
 * @note 使用8*16字体，每行最多显示16个字符
 * @param line 显示行号（1-4）
 * @param string 要显示的字符串
 * @return true表示显示成功，false表示参数错误
 */
uint8_t oled_show_line_string(uint8_t line, char *string)
{
    // 行号有效性检查
    if (line > MAX_LINE) {
        printf("line is > 4\r\n");
        return false;
    } else if (line <= 0) {
        printf("line is <= 0\r\n");
        return false;
    }
    
    // 字符串有效性检查
    if (string == NULL) {
        printf("string is NULL\r\n");
        return false;
    } else if (strlen(string) > MAX_ROW) {
        printf("string of length is > 16\r\n");
        return false;
    }

    // 调用底层函数显示字符串（列0，行号-1，字体大小16）
    SSD1306_ShowStr(0, line - 1, string, TEXT_SIZE_16);
    return true;
}


static uint8_t current_line = INIT_LINE; // 当前显示行号（静态变量，保存状态）

/**
 * @brief OLED控制台日志显示（带滚动效果）
 * @note 日志从第1行开始显示，超过4行会自动滚动
 * @param string 要显示的日志字符串
 * @return 0表示成功，1表示参数错误
 */
uint8_t oled_consle_log(char *string)
{
    // 字符串有效性检查
    if (string == NULL) {
        printf("string is NULL\r\n");
        return 1;
    }

    // 行号循环处理（超过4行则回到第1行，实现滚动效果）
    if (current_line > MAX_LINE) {
        current_line = INIT_LINE;
    }

    // 先清除当前行原有内容（16个空格）
    oled_show_line_string(current_line, "               ");
    
    // 首行显示特殊处理（清除下方所有行）
    if (current_line == INIT_LINE) {
        oled_show_line_string(current_line, string);  // 显示当前日志
        // 清除下方3行内容
        oled_show_line_string(LINE_2, "               ");
        oled_show_line_string(LINE_3, "               ");
        oled_show_line_string(LINE_4, "               ");
    } else {
        oled_show_line_string(current_line, string);  // 非首行直接显示
    }

    current_line++;  // 指向下一行
    return 0;
}