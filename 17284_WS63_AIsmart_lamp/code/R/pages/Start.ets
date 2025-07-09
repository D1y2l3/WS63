// 跳转页面入口函数
@Builder
export function StartBuilder() {
  Start();
}


@Component
struct Start {
  pathStack: NavPathStack = new NavPathStack();
aboutToAppear(): void {
  setTimeout(()=>{
    this.pathStack.replacePathByName("Layout", null, false);

  },3000)
}

  build() {
    NavDestination() {
      // Button('点击跳到布局页')
      //   .onClick(()=>{
      //     this.pathStack.pushPathByName("Layout", null, false);
      //   })

      Stack({alignContent:Alignment.TopEnd}){
        Image($r('app.media.guanggao'))
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
         Button('跳过')
           .backgroundColor(Color.Grey)
           .margin(15)
           .onClick(()=>{
                 this.pathStack.replacePathByName("Layout", null, false);
                })
      }



    }
    // .title('广告页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}