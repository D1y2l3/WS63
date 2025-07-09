import { MessageRoleEnum, MessageVO } from './Ali chatMessage';
import ALiYunHttpUtils from './ALiYun';
import { TextTest } from './1111';

@Component
export struct Intelligent {
  @State submitMsg: string = '';
  @State messageArr: MessageVO[] = TextTest.Text;

  private scroller: Scroller = new Scroller();

  build() {
    Row() {
      Column() {
        // headerText("AI桌宠助手");
        headerText("AI助手");
        // 传递 Scroller 实例和消息数组
        chatList(this.scroller, this.messageArr);
        // 传递状态更新函数和发送逻辑
        inputBox(
          this.submitMsg,
          (text: string) => {
            console.log('Input changed:', text); // 调试信息
            this.submitMsg = text;
          },
          (): void => this.handleSendMessage()
        );
      }
      .width('100%');
    }
    .height('100%');
  }

  // 独立处理消息发送的成员函数（避免在独立函数中使用 this）
  handleSendMessage() {
    console.log('Sending message:', this.submitMsg); // 调试信息
    if (this.submitMsg.trim() === '') return;

    // 添加我方消息
    this.messageArr.push(new MessageVO(MessageRoleEnum.Mine, this.submitMsg));
    this.scroller.scrollEdge(Edge.Bottom);

    // 发送请求
    ALiYunHttpUtils.request(this.submitMsg, (responseText: string) => {
      console.log('Received response:', responseText); // 调试信息
      this.messageArr.push(new MessageVO(MessageRoleEnum.Other, responseText));
      this.scroller.scrollEdge(Edge.Bottom);
    });

    // 清空输入
    this.submitMsg = '';
    console.log('Cleared input'); // 调试信息
  }
}

@Builder function headerText(title: string) {
  Text(title)
    .minFontSize(20).maxFontSize(40).maxLines(1)
    .fontWeight(FontWeight.Bold)
    .height('10%');
}

@Builder function chatList(scroller: Scroller, messageArr: MessageVO[]) {
  List({ space: 15, scroller: scroller }) {
    ForEach(messageArr, (item: MessageVO) => {
      if (item.role === MessageRoleEnum.Mine) {
        chatLine_mine(item.message);
      } else {
        chatLine_other(item.message);
      }
    });
  }
  .alignListItem(ListItemAlign.Center)
  .height('80%');
}

@Builder function chatLine_mine(msg: string) {
  Row({ space: 5 }) {
    Text(msg).chatLine_text_style();
    Image($r("app.media.zhuomlogo")).chatLine_image_style();
  }
  .alignItems(VerticalAlign.Top)
  .justifyContent(FlexAlign.End);
}

@Builder function chatLine_other(msg: string) {
  Row({ space: 5 }) {
    Image($r("app.media.qianwen")).chatLine_image_style();
    Text(msg).chatLine_text_style();
  }
  .alignItems(VerticalAlign.Top)
  .justifyContent(FlexAlign.Start);
}

@Extend(Image) function chatLine_image_style() {
  .width(50)
  .aspectRatio(1)
  .borderRadius(25);
}

@Extend(Text) function chatLine_text_style() {
  .fontSize(20)
  .fontColor(Color.White)
  .width('70%')
  .lineHeight(25)
  .backgroundColor('rgb(64,64,64)')
  .padding(12)
  .borderRadius(10)
  .wordBreak(WordBreak.NORMAL);
}

@Builder function inputBox(
  currentValue: string,
  onInputChange: (text: string) => void,
  onSend: () => void
) {
  Row() {
    // 使用Row而不是Stack，让输入框和发送按钮并排排列
    TextInput({
      placeholder: '有问题尽管问我~',
      text: currentValue
    })
      .height(50)
      .width('80%')  // 调整宽度，为发送按钮留出空间
      .enterKeyType(EnterKeyType.Send)
      .onChange(onInputChange)
      .onSubmit(() => onSend());

    // 发送按钮 - 使用更可靠的实现
    Button('发送')
      .width(70)
      .height(50)
      .backgroundColor('#007DFF')
      .fontColor(Color.White)
      .fontSize(16)
      .borderRadius(25)
      .margin({ left: 5 })
      .onClick(() => {
        console.log('Button clicked'); // 添加调试信息
        onSend();
      });
  }
  .width('90%')
  .padding({ bottom: 10 });
}
