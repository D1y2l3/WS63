// import { chatMessage } from "./chatMessage";
//
// import messageUtil from "./GetMessage"
//
// // 定义一个名为 Intelligent 的组件类
// @Component
//  export struct Intelligent {
//   // 定义状态变量 isReceive，用于表示是否正在接收消息
//   @State isReceive: boolean = false;
//   // 定义状态变量 chatList，用于存储聊天记录
//   @State chatList: Array<chatMessage> = [];
//   // 定义状态变量 sendMessage，用于存储用户输入的消息
//   @State sendMessage: string = "";
//   // 定义状态变量 isPanelShow，用于控制常用语面板的显示与隐藏
//   @State isPanelShow: boolean = false;
//   @State inputText: string = ""; //
//   @State isLoading: boolean = false; //
//   @State responseText: string = ""; //
//
//   // 定义一个构建器方法 usuallyTake，用于创建常用的文本按钮
//   @Builder
//   usuallyTake(message: string) {
//     Text(message)
//       .fontSize(20)// 设置文本字体大小为20
//       .onClick(() => {
//         this.sendMessage = message; // 将点击的文本设置为要发送的消息
//         this.isPanelShow = false; // 关闭常用语面板
//
//         this.SendMessage(); // 调用 SendMessage 方法发送消息
//       })
//       .width("100%")// 设置文本宽度为100%
//       .textAlign(TextAlign.Start)// 文本左对齐
//       .padding({
//         left: 15,
//         right: 15,
//         top: 5,
//         bottom: 5
//       })// 设置内边距
//       .borderRadius(10)// 设置圆角半径
//       .margin({ top: 5, bottom: 5 }); // 设置外边距
//
//     Divider().strokeWidth(2).width("80%"); // 添加分隔线
//   }
//
//   // 组件即将出现时调用的方法
//   aboutToAppear() {
//     let chat = new chatMessage("AI", "你好，我是聊天机器人");
//     this.chatList.push(chat); // 初始化聊天记录，添加一条欢迎消息
//   }
//
//   // 发送消息的方法
//   async SendMessage() {
//     this.isReceive = true; // 标记为正在接收消息
//     let userChat = new chatMessage("User", this.sendMessage);
//
//     this.chatList.push(userChat); // 将用户消息添加到聊天记录中
//
//     this.sendMessage = ""; // 清空输入框
//     let receiveMessage = await messageUtil.receive(userChat.message); // 调用工具获取AI回复
//     let AIChat = new chatMessage("AI", receiveMessage);
//     this.chatList.push(AIChat); // 将AI回复添加到聊天记录中
//     this.isReceive = false; // 标记为不再接收消息
//   }
//
//   // 获取响应的方法（未在build方法中使用）
//   async getResponse() {
//     if (!this.inputText.trim()) {
//       return;
//     }
//
//     this.isLoading = true;
//
//     try {
//       // 调用API获取响应
//       this.responseText = await messageUtil.receive(this.inputText);
//     } catch (error) {
//       console.error('获取响应失败:', error);
//       this.responseText = '获取响应失败，请稍后重试';
//     } finally {
//       this.isLoading = false;
//     }
//   }
//
//   // 构建UI的方法
//   build() {
//     Stack() {
//       Column() {
//         Row() {
//           Text(this.isReceive ? "AI桌宠助手正在输入" : "AI桌宠助手")
//             .fontSize(28)// 设置标题字体大小
//             .width("100%")// 设置标题宽度
//             .textAlign(TextAlign.Center); // 文本居中对齐
//         }
//         .width("90%") // 设置行宽度
//         .height("5%"); // 设置行高度
//
//         Column() {
//           List() {
//             ForEach(this.chatList, (chat: chatMessage) => {
//               ListItem() {
//                 if (chat.sender == "AI") {
//                   Row() {
//                     Text(chat.sender)
//                       .fontSize(28)// 设置发件人字体大小
//                       .width("25%")// 设置发件人区域宽度
//                       .alignSelf(ItemAlign.Start); // 左对齐
//                     Text(chat.message)
//                       .fontSize(28)// 设置消息字体大小
//                       .backgroundColor(Color.Green)// 设置背景颜色
//                       .width("70%")// 设置消息区域宽度
//                       .margin(10); // 设置外边距
//                   }
//                   .width("100%") // 设置行宽度
//                   .margin({ top: 8 }); // 设置上边距
//                 } else {
//                   Row() {
//                     Text(chat.message)
//                       .fontSize(28)// 设置消息字体大小
//                       .backgroundColor(Color.Green)// 设置背景颜色
//                       .width("70%")// 设置消息区域宽度
//                       .margin(10); // 设置外边距
//                     Text(chat.sender)
//                       .fontSize(28)// 设置发件人字体大小
//                       .width("25%")// 设置发件人区域宽度
//                       .alignSelf(ItemAlign.Start); // 左对齐
//                   }
//                   .width("100%") // 设置行宽度
//                   .margin({ top: 8 }); // 设置上边距
//                 }
//               }
//             });
//           }
//         }
//         .width("90%") // 设置列宽度
//         .height("85%") // 设置列高度
//         .backgroundColor("#F0FFFF") // 设置背景颜色
//         .opacity(0.5); // 设置透明度
//
//         Row() {
//           TextInput({ text: this.sendMessage })
//             .width("60%")// 设置输入框宽度
//             .onChange((value: string) => {
//               this.sendMessage = value; // 更新发送消息的状态
//             });
//           Text("常用语")
//             .fontSize(18)// 设置文本字体大小
//             .onClick(() => {
//               this.isPanelShow = true; // 显示常用语面板
//             });
//
//           Button("发送")
//             .fontSize(18)// 设置按钮字体大小
//             .onClick(() => {
//               this.SendMessage(); // 调用 SendMessage 方法发送消息
//             });
//         }
//         .width("90%") // 设置行宽度
//         .height("10%") // 设置行高度
//         .justifyContent(FlexAlign.SpaceAround); // 内容两端对齐
//       }
//       .width("100%") // 设置列宽度
//       .height("100%") // 设置列高度
//       .backgroundColor("#ADD8E6"); // 设置背景颜色
//
//       Panel(this.isPanelShow) {
//         Column() {
//           Row() {
//             Button("返回")
//               .fontSize(28)// 设置按钮字体大小
//               .fontColor(Color.Black)// 设置按钮文字颜色
//               .onClick(() => {
//                 this.isPanelShow = false; // 隐藏常用语面板
//               });
//           }
//           .justifyContent(FlexAlign.Start) // 内容左对齐
//           .width("100%"); // 设置行宽度
//
//           Text("常用语")
//             .fontSize(28)// 设置文本字体大小
//             .width("50%")// 设置文本宽度
//             .textAlign(TextAlign.Center); // 文本居中对齐
//
//           Blank(); // 空白占位符
//         }
//         .width("90%") // 设置列宽度
//         .justifyContent(FlexAlign.SpaceAround); // 内容两端对齐
//
//         this.usuallyTake("你叫什么名字"); // 创建“你叫什么名字”按钮
//         this.usuallyTake("今天天气怎么样"); // 创建“今天天气怎么样”按钮
//         this.usuallyTake("你讲个故事吧"); // 创建“你讲个故事吧”按钮
//         this.usuallyTake("今天的热点新闻"); // 创建“今天的热点新闻”按钮
//       }
//       .width("100%"); // 设置面板宽度
//     }
//     .backgroundColor("#F0F8FF"); // 设置背景颜色
//   }
// }