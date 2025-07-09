import { Intelligent } from "./Aichat";
import { Rich } from "./fw rich";
import { Mine } from "./wd Mine";
import { Status } from "./zt Status";
// import {Intelligent}from'./ai Intelligent'


interface TabClass{
  text:string
  icon:ResourceStr
}


// 跳转页面入口函数
@Builder
export function LayoutBuilder() {
  Layout();
}


@ComponentV2
struct Layout{
  @Local currentIndex:number=0
  pathStack: NavPathStack = new NavPathStack();
  tabData:TabClass[]=[

    {text:"状态",icon:$r('app.media.zt') },
    {text:"服务",icon:$r('app.media.fw') },
    {text:"AI",icon:$r('app.media.AI') },
    {text:"我的",icon:$r('app.media.wd') }



  ]

  @Builder  tabBuilder(item:TabClass,index:number) {
    Column({space:5}) {
      Image(item.icon)
        .width(24)
        .fillColor(this.currentIndex=== index ? '#E85A88' :'#63AAAA')
      Text(item.text)
        .fontSize(14)
        .fontColor(this.currentIndex === index ? '#E85A88 ':'#63AAAA')
    }
  }

  build() {
    NavDestination() {
      Tabs({ barPosition:BarPosition.End}){
        ForEach(this.tabData,(item:TabClass,index:number)=>{
          TabContent(){
            if (this.currentIndex===0) {
              Status()
            }else if (this.currentIndex===1){
             Rich()
            }else if(this.currentIndex===2){
              Intelligent()
            }else  if(this.currentIndex===3){
              Mine()
            }




          }
          .tabBar(this.tabBuilder(item,index))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])


        })

      }

      .onChange((index:number)=>{
        this.currentIndex=index
      })
.expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])

    }
    // .title('内容页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}