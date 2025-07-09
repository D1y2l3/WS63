import { router } from "@kit.ArkUI";
import { GlobalUserState } from "./baocun"; // 引入全局状态管理
@Component
export struct Mine {
  private globalUserState: GlobalUserState = GlobalUserState.getInstance(); // 获取全局状态实例
  @State selectTime: Date | null = null;
  gender: string[] = ['男', '女'];
  @State selectedIndex: number = 0;
  @State selectedDate: Date = new Date("2000-12-1");
  @State date: string = '出生日期';
  // 生命周期钩子：页面显示时恢复登录状态
  // aboutToAppear() {
  //   this.globalUserState.restoreState(); // 从本地存储恢复状态
  // }
  build() {
    // 使用Stack布局实现顶部固定定位
    Stack() {
      // 顶部导航栏容器
      Column() {
        // 头像、登录、注册横向排列
        Row({ space: 12 }) { // space控制元素间距
          // 头像
          Image($r('app.media.touxiang'))
            .width(32)
            .height(32)
            .margin({ left: 5 }) // 左侧边距
          // 根据登录状态显示内容
          if (this.globalUserState.isLoggedIn) {
            // 已登录：显示手机号和登出按钮
            Text(this.globalUserState.phoneNumber)
              .fontColor(Color.Black)
              .fontSize(18)
              .margin({ left: 5 });

            Text('退出')
              .fontColor(Color.Blue)
              .fontSize(16)
              .margin({ left: 10 })
              .onClick(() => {
                this.globalUserState.logout(); // 调用登出方法
                router.pushUrl({ url: "pages/Loginpages" }); // 登出后跳转登录页
              });
          } else {


            // 登录按钮
            Text('登录')
              .fontColor(Color.Black)
              .fontSize(18)
              .onClick(() => {
                router.pushUrl({ url: "pages/Loginpages" });
              })

            // 分隔符
            Text('/')
              .fontColor(Color.Black)
              .fontSize(18)
              .margin({ left: 2, right: 2 })

            // 注册按钮
            Text('注册')
              .fontColor(Color.Black)
              .fontSize(18)
              .margin({ left: 2 })// 与分隔符的间距
              .onClick(() => {
                router.pushUrl({ url: "pages/Registrationpage" });
              })
          }
         }
        .width('100%') // 确保Row占满父容器宽度
        .justifyContent(FlexAlign.Start) // 明确设置左对齐
        .padding({ top: 24, bottom: 12 }) // 导航栏内边距
        .backgroundColor(Color.White) // 背景色

        // 下方内容区域
        Text('AI灯光助手个人信息')
          .fontSize(25)
          .margin({ top: 16 })

        // 名称和出生日期输入框区域
        Column() {
          // 名称输入框
          TextInput({ placeholder: '个性名称' })
            .width('80%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })

          TextInput({ placeholder: '个性签名' })
            .width('80%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })
          TextInput({ placeholder: '绑定设备' })
            .width('80%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .placeholderColor('#99182431')
            .margin({ top: 12 })
            .padding({ left: 0 })
          // 出生日期选择框
          TextInput({
            placeholder: '出生日期',
            text: this.date
          })
            .width('80%') // 与名称输入框宽度一致
            .height(45)  // 与名称输入框高度一致
            .backgroundColor('#F1F3F5') // 保持相同的背景色
            .fontSize(20) // 与名称输入框字体大小一致
            .fontColor(Color.Black) // 添加字体颜色，与名称输入框一致
            .placeholderColor('#99182431')
            .margin({ top: 12 }) // 保持相同的上边距
            .padding({ left: 0 })
            .onClick(() => {
              this.getUIContext().showDatePickerDialog({
                start: new Date("2000-1-1"),
                end: new Date("2100-12-31"),
                selected: this.selectTime,
                textStyle: { color: '#2787d9', font: { size: '14fp', weight: FontWeight.Normal } },
                selectedTextStyle: { color: '#004aaf', font: { size: '18fp', weight: FontWeight.Regular } },
                acceptButtonStyle: {
                  fontColor: '#2787d9',
                  fontSize: '16fp',
                  backgroundColor: '#f7f7f7',
                  borderRadius: 10
                },
                cancelButtonStyle: {
                  fontColor: Color.Red,
                  fontSize: '16fp',
                  backgroundColor: '#f7f7f7',
                  borderRadius: 10
                },
                // 添加日期选择回调处理
                onAccept: (value: DatePickerResult) => {
                  // 添加空值检查
                  if (value.year !== undefined && value.month !== undefined && value.day !== undefined) {
                    this.selectTime = new Date(value.year, value.month - 1, value.day);
                    this.date = `${value.year}-${value.month}-${value.day}`;
                  } else {
                    // 处理属性缺失的情况
                    console.error('日期选择器返回值缺少必要属性');
                  }
                }
              })
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)

        // 性别选择区域
        Row({ space: 20 }) {
          // 性别标签
          Text( '性别' )
            .width('30%')
            .height(45)
            .backgroundColor('#F1F3F5')
            .fontSize(20)
            .borderRadius(24) // 圆角半径
            .textAlign(TextAlign.Center) // 文本水平居中
            .alignSelf(ItemAlign.Auto) // 修改为ItemAlign类型

          // 性别选项
          Text(this.gender[this.selectedIndex])
            .fontSize(20)
            .fontWeight(FontWeight.Normal) // 加粗文本
            .padding({ left: 20, right: 20, top: 8, bottom: 8 }) // 调整内边距
            .backgroundColor('#F1F3F5') // 设置背景色
            .borderRadius(24) // 圆角半径（高度的一半，实现胶囊形）
            .textAlign(TextAlign.Center) // 文本水平居中

            .onClick(() => {
              TextPickerDialog.show({
                range: this.gender,
                selected: this.selectedIndex,
                onAccept: (value: TextPickerResult) => {
                  this.selectedIndex = value.index as number;
                },
                onCancel: () => {
                  console.info('取消选择')
                },
                onChange: (value: TextPickerResult) => {
                  console.info('当前文本:${JSON.stringify(value)}')
                }
              })
            })
        }
        .width('80%')
        .justifyContent(FlexAlign.Start)
        .margin({ top: 12 })
      }
    }
    .width('100%') // 占满屏幕宽度
    .position({ // 固定在顶部
      top: 0
    })
  }
}
