// import http from '@ohos.net.http';
// import { JSON } from "@kit.ArkTS";
//
// // 定义API请求选项接口
// interface ApiRequestOptions {
//   method: http.RequestMethod; // 请求方法（GET, POST等）
//   header: Record<string, string>; // 请求头，包含内容类型和授权信息
//   readTimeout: number; // 读取超时时间（毫秒）
//   expectDataType: http.HttpDataType; // 预期的数据类型（字符串、字节数组等）
//   extraData: string; // 请求体数据，通常是JSON字符串
// }
//
// // 定义API响应中的message接口
// interface GeneratedTypeLiteralInterface_2 {
//   content: string; // 消息内容
// }
//
// // 定义API响应中的choices接口
// interface GeneratedTypeLiteralInterface_1 {
//   message: GeneratedTypeLiteralInterface_2[]; // 消息数组
// }
//
// // 定义完整的API响应接口
// interface ApiResponse {
//   choices: GeneratedTypeLiteralInterface_1; // 包含消息的选择项
//   // 可以根据实际API响应添加更多属性
// }
//
// export class GetMessage {
//   // 豆包API的基础URL
//   private apiUrl = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
//   // 您的API密钥，实际使用时应从安全存储中获取
//   private apiKey = '562b905b-3485-47fa-8a9e-7402e794072a';
//
//   async receive(prompt: string): Promise<string> {
//     try {
//       // 创建HTTP请求对象
//       const httpRequest = http.createHttp();
//
//       // 准备请求参数
//       const requestOptions: ApiRequestOptions = {
//         method: http.RequestMethod.POST, // 使用POST方法发送请求
//         header: {
//           'Content-Type': 'application/json', // 设置内容类型为JSON
//           'Authorization': `Bearer ${this.apiKey}` // 添加授权头，使用Bearer Token认证
//         },
//         readTimeout: 60000, // 设置读取超时时间为60秒
//         expectDataType: http.HttpDataType.STRING, // 预期响应数据类型为字符串
//         extraData: JSON.stringify({
//           model: "ep-20250607223644-26zsm", // 豆包模型名称，根据实际可用模型调整
//           messages: [
//             {
//               role: "user",
//               content: prompt // 用户输入的提示信息
//             }
//           ],
//           temperature: 0.7, // 控制生成文本的随机性，值越大越随机
//           max_tokens: 800 // 最大生成令牌数
//         })
//       };
//
//       // 发送请求到豆包API并等待响应
//       const result = await httpRequest.request(
//         this.apiUrl,
//         requestOptions
//       );
//
//       // 检查响应状态码是否为200（成功）
//       if (result.responseCode === 200) {
//         console.log('API响应成功');
//
//         // 解析响应数据，确保结果不为空
//         if (result.result) {
//           const responseData = JSON.parse(result.result.toString()) as ApiResponse;
//
//           // 从响应中提取模型生成的内容
//           if (responseData.choices && responseData.choices.message && responseData.choices.message.length > 0) {
//             return responseData.choices.message[0].content; // 返回第一个消息的内容
//           } else {
//             return '无法解析API响应'; // 如果没有找到消息内容，返回错误信息
//           }
//         } else {
//           return 'API响应为空'; // 如果响应结果为空，返回错误信息
//         }
//       } else {
//         console.error(`API请求失败，状态码: ${result.responseCode}`);
//         console.error(`错误信息: ${result.result?.toString() || '无响应内容'}`);
//         return '请求失败，请稍后重试'; // 返回请求失败的错误信息
//       }
//     } catch (error) {
//       console.error(`发生异常: ${JSON.stringify(error)}`);
//       return '发生错误，请检查网络连接'; // 返回捕获到的异常信息
//     } finally {
//       // 释放HTTP请求资源
//       if (typeof http.createHttp().destroy === 'function') {
//         http.createHttp().destroy();
//       }
//     }
//   }
// }
//
// let messageUtil = new GetMessage(); // 创建GetMessage实例
//
// export default messageUtil as GetMessage; // 导出GetMessage实例作为默认导出
//
//
//
