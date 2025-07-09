#include "bsp_init.h"
#include "mqtt.h"
#include "hal_bsp_ssd1306.h"
#include "oled_show_log.h"
#include "cJSON.h"

#ifdef IOT
char *g_username = ""; // IoT平台认证用户名
char *g_password = ""; // IoT平台认证密码
#endif

uint8_t g_cmdFlag;                          // 命令标志位（接收到新命令时置1）
msg_data_t sys_msg_data = {0};              // 系统消息数据结构（存储传感器和灯状态）
uint8_t mqtt_conn;                          // MQTT连接状态标志
char g_send_buffer[512] = {0};              // 数据发布缓冲区（最大512字节）
char g_response_id[100] = {0};              // 命令ID保存缓冲区（用于响应消息）

MQTTClient client;                          // MQTT客户端句柄
volatile MQTTClient_deliveryToken deliveredToken; // 消息投递令牌
extern int MQTTClient_init(void);           // MQTT客户端初始化函数声明


/**
 * @brief 连接丢失回调函数
 * @note 当MQTT连接断开时触发
 * @param context 上下文参数（未使用）
 * @param cause 断开原因字符串
 */
void connlost(void *context, char *cause)
{
    unused(context);
    printf("Connection lost: %s\n", cause); // 打印连接丢失原因
}


/**
 * @brief 订阅MQTT主题
 * @param topic 要订阅的主题字符串
 * @return 0表示成功
 */
int mqtt_subscribe(const char *topic)
{
    printf("subscribe start\r\n");
    MQTTClient_subscribe(client, topic, 1); // 订阅主题，QoS级别为1
    return 0;
}


/**
 * @brief 发布MQTT消息
 * @param topic 发布主题
 * @param msg 要发布的消息内容
 * @return MQTTClient返回码（MQTTCLIENT_SUCCESS表示成功）
 */
int mqtt_publish(const char *topic, char *msg)
{
    MQTTClient_message pubmsg = MQTTClient_message_initializer; // 消息结构初始化
    MQTTClient_deliveryToken token;
    int ret = 0;
    
    pubmsg.payload = msg;                  // 设置消息负载
    pubmsg.payloadlen = (int)strlen(msg);  // 设置消息长度
    pubmsg.qos = 1;                        // 设置QoS级别为1
    pubmsg.retained = 0;                   // 不保留消息
    
    printf("[payload]:  %s, [topic]: %s\r\n", msg, topic); // 打印发布内容和主题
    
    ret = MQTTClient_publishMessage(client, topic, &pubmsg, &token); // 发布消息
    if (ret != MQTTCLIENT_SUCCESS) {
        printf("mqtt publish failed\r\n"); // 发布失败提示
        return ret;
    }

    return ret;
}


/**
 * @brief 消息投递确认回调函数
 * @note 当消息成功投递到服务器时触发
 * @param context 上下文参数（未使用）
 * @param dt 投递令牌
 */
void delivered(void *context, MQTTClient_deliveryToken dt)
{
    unused(context);
    printf("Message with token value %d delivery confirmed\n", dt); // 打印确认信息
    deliveredToken = dt;                                            // 保存令牌
}


/**
 * @brief 解析等号后的字符串
 * @note 用于从主题字符串中提取命令ID（如"cmd/123"提取"123"）
 * @param input 输入字符串
 * @param output 输出缓冲区（保存等号后的内容）
 */
void parse_after_equal(const char *input, char *output)
{
    const char *equalsign = strchr(input, '='); // 查找等号位置
    if (equalsign != NULL) {
        strcpy(output, equalsign + 1); // 复制等号后的内容
    }
}


/**
 * @brief 消息到达回调函数
 * @note 当接收到新的MQTT消息时触发
 * @param context 上下文参数（未使用）
 * @param topic_name 主题名称
 * @param topic_len 主题长度（未使用）
 * @param message 消息指针
 * @return 1表示消息已处理
 */
int messageArrived(void *context, char *topic_name, int topic_len, MQTTClient_message *message)
{
    unused(context);
    unused(topic_len);
    unused(topic_name);
    
    cJSON *root = cJSON_Parse((char *)message->payload); // 解析JSON消息
    cJSON *paras = cJSON_GetObjectItem(root, "paras");    // 获取参数对象
    
    printf("[Message]: %s\n", (char *)message->payload);  // 打印接收到的消息
    
    // 处理灯光模式控制命令
    if (strstr((char *)message->payload, "lamp_mode") != NULL) {
        sys_msg_data.is_auto_light_mode = LIGHT_MANUAL_MODE; // 设置为手动模式
        
        // 根据消息内容设置不同灯光模式
        if (strstr((char *)message->payload, "SUN_LIGHT_MODE_ON") != NULL) {
            sys_msg_data.Lamp_Status = SUN_LIGHT_MODE;
        } else if (strstr((char *)message->payload, "SLEEP_MODE_ON") != NULL) {
            sys_msg_data.Lamp_Status = SLEEP_MODE;
        } else if (strstr((char *)message->payload, "READ_BOOK_MODE_ON") != NULL) {
            sys_msg_data.Lamp_Status = READ_BOOK_MODE;
        } else if (strstr((char *)message->payload, "LED_BLINK_MODE_ON") != NULL) {
            sys_msg_data.Lamp_Status = LED_BLINK_MODE;
        } else {
            sys_msg_data.Lamp_Status = OFF_LAMP; // 关闭灯光
        }
    } 
    // 处理自动模式开关命令
    else if (strstr((char *)message->payload, "auto_mode") != NULL) {
        if (strstr((char *)message->payload, "ON") != NULL) {
            sys_msg_data.is_auto_light_mode = LIGHT_AUTO_MODE; // 开启自动模式
        } else if (strstr((char *)message->payload, "OFF") != NULL) {
            sys_msg_data.is_auto_light_mode = LIGHT_MANUAL_MODE; // 关闭自动模式
        }
    } 
    // 处理RGB颜色自定义命令
    else if (strstr((char *)message->payload, "RGB") != NULL) {
        if (sys_msg_data.is_auto_light_mode == LIGHT_MANUAL_MODE) {
            // 从JSON中提取RGB值
            cJSON *red = cJSON_GetObjectItem(paras, "red");
            cJSON *green = cJSON_GetObjectItem(paras, "green");
            cJSON *blue = cJSON_GetObjectItem(paras, "blue");
            
            sys_msg_data.RGB_Value.red = red->valueint;
            sys_msg_data.RGB_Value.green = green->valueint;
            sys_msg_data.RGB_Value.blue = blue->valueint;
            sys_msg_data.Lamp_Status = SET_RGB_MODE; // 设置为调色模式
            
            red = green = blue = NULL; // 清空指针
        }
    }
    
    // 解析命令ID（用于响应消息）
    parse_after_equal(topic_name, g_response_id);
    g_cmdFlag = 1; // 标记接收到新命令
    memset((char *)message->payload, 0, message->payloadlen); // 清空消息缓冲区

    return 1; // 消息已处理
}


/**
 * @brief MQTT连接函数
 * @note 初始化MQTT客户端并连接到服务器，成功后循环上报设备状态
 * @return ERRCODE_SUCC表示成功，其他值表示失败
 */
errcode_t mqtt_connect(void)
{
    int ret;
    MQTTClient_connectOptions conn_opts = MQTTClient_connectOptions_initializer; // 连接参数初始化
    
    oled_consle_log("===mqtt init==="); // OLED显示初始化日志
    MQTTClient_init(); // 初始化MQTT客户端库
    
    // 创建MQTT客户端
    ret = MQTTClient_create(&client, SERVER_IP_ADDR, CLIENT_ID, MQTTCLIENT_PERSISTENCE_NONE, NULL);
    if (ret != MQTTCLIENT_SUCCESS) {
        printf("Failed to create MQTT client, return code %d\n", ret);
        oled_consle_log("=mqtt cre fail=");
        return ERRCODE_FAIL;
    }
    oled_consle_log("= mqtt cre ok ="); // 创建成功日志
    
    // 配置连接参数
    conn_opts.keepAliveInterval = KEEP_ALIVE_INTERVAL; // 心跳间隔
    conn_opts.cleansession = 1;                        // 清除会话
    
#ifdef IOT
    conn_opts.username = g_username; // 设置IoT平台用户名
    conn_opts.password = g_password; // 设置IoT平台密码
#endif
    
    // 绑定回调函数
    MQTTClient_setCallbacks(client, NULL, connlost, messageArrived, delivered);
    oled_consle_log("=mqtt set  cbk="); // 回调设置日志
    
    // 连接到MQTT服务器
    if ((ret = MQTTClient_connect(client, &conn_opts)) != MQTTCLIENT_SUCCESS) {
        oled_consle_log("mqtt conn fail");
        printf("Failed to connect, return code %d\n", ret);
        MQTTClient_destroy(&client); // 连接失败时销毁客户端
        return ERRCODE_FAIL;
    }
    oled_consle_log("=mqtt conn  ok="); // 连接成功日志
    printf("Connected to MQTT broker!\n");
    
    osDelay(DELAY_TIME_MS); // 延时等待连接稳定
    SSD1306_CLS(); // 清屏OLED显示
    
    mqtt_conn = 1; // 标记连接成功
    osDelay(100); // 延时防止发布失败
    
    // 循环上报设备状态
    while (1) {
        osDelay(DELAY_TIME_MS);
        memset(g_send_buffer, 0, sizeof(g_send_buffer) / sizeof(g_send_buffer[0]));
        
        // 构建上报消息（包含环境光、灯光状态、RGB值、自动模式状态）
        sprintf(g_send_buffer, MQTT_DATA_SEND, 1024 - sys_msg_data.AP3216C_Value.light,
                sys_msg_data.Lamp_Status ? "ON" : "OFF", sys_msg_data.RGB_Value.red, 
                sys_msg_data.RGB_Value.green, sys_msg_data.RGB_Value.blue,
                sys_msg_data.is_auto_light_mode ? "ON" : "OFF");
        
        mqtt_publish(MQTT_DATATOPIC_PUB, g_send_buffer); // 发布状态消息
        memset(g_send_buffer, 0, sizeof(g_send_buffer) / sizeof(g_send_buffer[0]));
        osDelay(DELAY_TIME_MS); // 延时防止发布失败
    }
    
    return ERRCODE_SUCC;
}