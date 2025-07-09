
#ifndef HAL_BSP_SSD1306_BMPS_H
#define HAL_BSP_SSD1306_BMPS_H

#include <stdint.h>

#define smartTemp 0            // 智能温度计
#define smartFarm 0            // 智慧农业项目
#define smartSecurityDefense 0 // 智慧安防报警
#define ReversingRadar 0       // 倒车雷达

extern unsigned char bmp_16X32_number[10][64];
extern unsigned char bmp_8X16_number[10][16];
extern unsigned char bmp_16X16_dian[32];

#if (smartTemp)
extern unsigned char bmp_16X16_sheShiDu[32];
extern unsigned char bmp_16X16_baifenhao[32];
extern unsigned char bmp_48X48_1_mi_yan_xiao[288];
extern unsigned char bmp_48X48_2_wei_xiao[288];
extern unsigned char bmp_48X48_3_wu_biao_qing[288];
extern unsigned char bmp_48X48_4_nan_guo[288];
extern unsigned char bmp_48X48_5_ku_qi[288];
#endif

#if (smartDistance || ReversingRadar)
extern unsigned char bmp_32X32_cm[128];
#endif

#if (smartSecurityDefense)
extern unsigned char bmp_32X32_BaoJing[128];
extern unsigned char bmp_32X32_No_BaoJing[128];
extern unsigned char bmp_32X32_Body[128];
extern unsigned char bmp_32X32_No_Body[128];
extern unsigned char bmp_16X16_baifenhao[32];
#endif

#if (smartFarm)
extern unsigned char bmp_48X48_fan_gif[4][288];
extern unsigned char bmp_16X16_baifenhao[32];
#endif
void show_page(void);
#endif
