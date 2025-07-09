#include "wifi_connect.h"

#define WIFI_SCAN_AP_LIMIT 64                         // 最大扫描AP数量（64个）
#define WIFI_CONN_STATUS_MAX_GET_TIMES 5             // 连接状态检查最大尝试次数
#define DHCP_BOUND_STATUS_MAX_GET_TIMES 20           // DHCP绑定状态检查最大尝试次数
#define WIFI_STA_IP_MAX_GET_TIMES 5                  // IP地址获取检查最大尝试次数

/*****************************************************************************
  STA 扫描-关联示例函数
*****************************************************************************/
static errcode_t example_get_match_network(const char *expected_ssid,
                                           const char *key,
                                           wifi_sta_config_stru *expected_bss)
{
    uint32_t num = WIFI_SCAN_AP_LIMIT;            // 存储扫描到的AP数量
    uint32_t bss_index = 0;                       // AP索引

    /* 分配扫描结果缓冲区 */
    uint32_t scan_len = sizeof(wifi_scan_info_stru) * WIFI_SCAN_AP_LIMIT;
    wifi_scan_info_stru *result = osal_kmalloc(scan_len, OSAL_GFP_ATOMIC);
    if (result == NULL) {
        return ERRCODE_MALLOC;                    // 内存分配失败返回错误码
    }

    memset_s(result, scan_len, 0, scan_len);      // 清空缓冲区
    if (wifi_sta_get_scan_info(result, &num) != ERRCODE_SUCC) {
        osal_kfree(result);                       // 释放内存
        return ERRCODE_FAIL;                      // 扫描信息获取失败
    }

    /* 遍历扫描结果，查找匹配的AP */
    for (bss_index = 0; bss_index < num; bss_index++) {
        if (strlen(expected_ssid) == strlen(result[bss_index].ssid)) {
            if (memcmp(expected_ssid, result[bss_index].ssid, strlen(expected_ssid)) == 0) {
                break;                              // 找到匹配的SSID，退出循环
            }
        }
    }

    /* 未找到目标AP */
    if (bss_index >= num) {
        osal_kfree(result);
        return ERRCODE_FAIL;
    }
    
    /* 复制AP配置信息 */
    if (memcpy_s(expected_bss->ssid, WIFI_MAX_SSID_LEN, result[bss_index].ssid, WIFI_MAX_SSID_LEN) != EOK) {
        osal_kfree(result);
        return ERRCODE_MEMCPY;
    }
    if (memcpy_s(expected_bss->bssid, WIFI_MAC_LEN, result[bss_index].bssid, WIFI_MAC_LEN) != EOK) {
        osal_kfree(result);
        return ERRCODE_MEMCPY;
    }
    expected_bss->security_type = result[bss_index].security_type; // 设置安全类型
    if (memcpy_s(expected_bss->pre_shared_key, WIFI_MAX_KEY_LEN, key, strlen(key)) != EOK) {
        osal_kfree(result);
        return ERRCODE_MEMCPY;
    }
    expected_bss->ip_type = DHCP;                  // 设置IP获取方式为DHCP
    osal_kfree(result);                           // 释放临时缓冲区
    return ERRCODE_SUCC;
}

/**
 * @brief WiFi连接主函数（STA模式）
 * @param ssid WiFi名称（NULL时使用默认配置）
 * @param psk WiFi密码（NULL时使用默认配置）
 * @return ERRCODE_SUCC表示成功，其他值表示失败
 */
errcode_t wifi_connect(char *ssid, char *psk)
{
    char ifname[WIFI_IFNAME_MAX_SIZE + 1] = "wlan0";  // WiFi设备名称
    wifi_sta_config_stru expected_bss = {0};          // 连接配置结构体
    
    // 处理默认值（参数为NULL时使用预定义配置）
    const char *expected_ssid = ssid ? ssid : CONFIG_WIFI_SSID;
    const char *key = psk ? psk : CONFIG_WIFI_PWD;
     
    if (!expected_ssid || !key) {
        PRINT("Error: Invalid SSID or password!\r\n");
        return ERRCODE_INVALID_PARAM;                // 参数无效返回错误
    }
    
    struct netif *netif_p = NULL;                    // 网络接口指针
    wifi_linked_info_stru wifi_status;               // 连接状态结构体
    uint8_t index = 0;                               // 循环索引
    uint8_t retry_num = 0;                           // 重试次数

    /* 等待WiFi初始化完成 */
    while (wifi_is_wifi_inited() == 0) {
        (void)osDelay(10);                           // 延时100ms（10*10ms）
    }
    
    /* 启用STA模式 */
    if (wifi_sta_enable() != ERRCODE_SUCC) {
        PRINT("STA enable fail !\r\n");
        return ERRCODE_FAIL;
    }
    
    /* 循环扫描-连接（直到成功或密码错误超过限制） */
    do {
        PRINT("Start Scan !\r\n");
        (void)osDelay(100);                          // 延时1s（100*10ms）
        
        /* 启动WiFi扫描 */
        if (wifi_sta_scan() != ERRCODE_SUCC) {
            PRINT("STA scan fail, try again !\r\n");
            continue;
        }

        (void)osDelay(300);                          // 延时3s（300*10ms）

        /* 获取匹配的AP配置 */
        if (example_get_match_network(expected_ssid, key, &expected_bss) != ERRCODE_SUCC) {
            PRINT("Can not find AP, try again !\r\n");
            continue;
        }

        PRINT("STA start connect.\r\n");
        /* 启动连接过程 */
        if (wifi_sta_connect(&expected_bss) != ERRCODE_SUCC) {
            continue;
        }

        /* 检查连接状态（最多尝试5次） */
        for (index = 0; index < WIFI_CONN_STATUS_MAX_GET_TIMES; index++) {
            (void)osDelay(50);                       // 延时5s（50*100ms）
            memset_s(&wifi_status, sizeof(wifi_linked_info_stru), 0, sizeof(wifi_linked_info_stru));
            if (wifi_sta_get_ap_info(&wifi_status) != ERRCODE_SUCC) {
                continue;
            }
            if (wifi_status.conn_state == WIFI_CONNECTED) {
                break;                                // 连接成功，退出检查
            }
        }
        
        if (wifi_status.conn_state == WIFI_CONNECTED) {
            break;                                    // 连接成功，退出循环
        } else {
            retry_num++;
            if (retry_num > 2) {
                PRINT("password err!\r\n");           // 密码错误超过限制
                return ERRCODE_FAIL;
            }
        }

    } while (1);

    /* DHCP获取IP地址 */
    netif_p = netifapi_netif_find(ifname);
    if (netif_p == NULL) {
        return ERRCODE_FAIL;
    }

    if (netifapi_dhcp_start(netif_p) != ERR_OK) {
        PRINT("STA DHCP Fail.\r\n");
        return ERRCODE_FAIL;
    }

    /* 等待DHCP绑定（最多20次检查） */
    for (uint8_t i = 0; i < DHCP_BOUND_STATUS_MAX_GET_TIMES; i++) {
        (void)osDelay(50);                           // 延时500ms（50*10ms）
        if (netifapi_dhcp_is_bound(netif_p) == ERR_OK) {
            PRINT("STA DHCP bound success.\r\n");
            break;
        }
    }

    /* 等待获取IP地址（最多5次检查） */
    for (uint8_t i = 0; i < WIFI_STA_IP_MAX_GET_TIMES; i++) {
        osDelay(1);                                 // 延时10ms
        if (netif_p->ip_addr.u_addr.ip4.addr != 0) {
            /* 打印获取到的IP地址 */
            PRINT("STA IP %u.%u.%u.%u\r\n", (netif_p->ip_addr.u_addr.ip4.addr & 0x000000ff),
                  (netif_p->ip_addr.u_addr.ip4.addr & 0x0000ff00) >> 8,
                  (netif_p->ip_addr.u_addr.ip4.addr & 0x00ff0000) >> 16,
                  (netif_p->ip_addr.u_addr.ip4.addr & 0xff000000) >> 24);

            PRINT("STA connect success.\r\n");
            return ERRCODE_SUCC;
        }
    }
    PRINT("STA connect fail.\r\n");
    return ERRCODE_FAIL;
}