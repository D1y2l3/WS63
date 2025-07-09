

#ifndef WIFI_CONNECT_H
#define WIFI_CONNECT_H
#include "lwip/netifapi.h"
#include "wifi_hotspot.h"
#include "wifi_hotspot_config.h"
#include "stdlib.h"
#include "uart.h"
#include "lwip/nettool/misc.h"
#include "soc_osal.h"
#include "app_init.h"
#include "cmsis_os2.h"

#define CONFIG_WIFI_SSID "HISI"       // 要连接的WiFi 热点账号
#define CONFIG_WIFI_PWD "123456789" // 要连接的WiFi 热点密码




errcode_t wifi_connect(char *ssid, char *psk);
#endif