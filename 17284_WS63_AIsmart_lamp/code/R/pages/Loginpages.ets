import { router } from "@kit.ArkUI"
import { DBConsole } from "./DBConsole"
import { DBTable } from "./enrollmentArtDate"
import { IUserRegistration } from "./enrollmentArtDate"
import promptAction from "@ohos.promptAction"
import ArrayList from "@ohos.util.ArrayList"
 import { GlobalUserState } from "./baocun"
@Entry
@Component
struct Loginpages {
  // 数据库控制台实例
  private dbConsole: DBConsole = new DBConsole()

  // 表单数据
  @State username: string = ''
  @State password: string = ''
  @State isLoading: boolean = false
  private globalUserState: GlobalUserState = GlobalUserState.getInstance(); // 获取全局状态实例

  // 初始化
  aboutToAppear() {
    // 创建用户注册表实例
    const userTable = DBTable.GetUSERREGISTERDBTableInstance()

    // 添加表到数据库控制台
    const tables: ArrayList<DBTable> = new ArrayList<DBTable>()
    tables.add(userTable)
    this.dbConsole.DBTables = tables

    // 初始化数据库连接
    this.initDatabase()
  }

  // 初始化数据库连接
  private initDatabase() {
    this.dbConsole.GetDBStore(() => {
      console.info('登录页面数据库初始化成功')
    })
  }

  // 处理登录逻辑
  private handleLogin() {
    if (!this.username || !this.password) {
      promptAction.showToast({ message: '用户名和密码不能为空' })
      return
    }

    this.isLoading = true

    // 验证用户
    this.validateUser(this.username, this.password)
  }

  // 验证用户
  private validateUser(username: string, password: string) {
    if (!this.dbConsole.RDBStore) {
      promptAction.showToast({ message: '数据库连接失败，请重试' })
      this.isLoading = false
      return
    }

    // 注意：实际应用中应该使用参数化查询防止SQL注入
    // 这里使用手机号作为用户名进行查询
    const sql = `SELECT * FROM UserRegistrationTable WHERE PhoneNumber = ? AND Password = ?`

    this.dbConsole.RDBStore.querySql(
      sql,
      [username, password],
      (err, resultSet) => {
        this.isLoading = false

        if (err) {
          console.error('查询用户数据失败:', err)
          promptAction.showToast({ message: '登录失败，请重试' })
          return
        }

        if (resultSet.rowCount > 0) {

           this.globalUserState.login(username);
          // 用户验证成功
          promptAction.showToast({ message: '登录成功' })
          // 这里可以添加用户信息存储到全局状态的逻辑
          router.pushUrl({ url: "pages/Index" }) // 跳转到主页面
        } else {
          // 用户不存在或密码错误
          promptAction.showToast({ message: '用户名或密码错误' })
        }
      }
    )
  }

  build() {
    Column({space:10}){
      Image($r("app.media.zhuomlogo"))
        .width(80)
        .height(80)
        .borderRadius(50)
        .margin({
          top:"120vp"
        })

      Text("欢迎登录AI灯光助手")
        .fontColor(Color.Black)
        .fontSize(20)
        .margin({
          top:"15vp"
        })

      TextInput({placeholder:"手机号码"})
        .margin({bottom:"10vp"})
        .onChange((value) => this.username = value)
        .maxLength(11)

      TextInput({placeholder:"请输入密码"})

        .type(InputType.Password)
        .onChange((value) => this.password = value)
        .maxLength(8)

      Row(){
        Text("短信验证码登录").fontColor(Color.Blue).fontSize(12)
          .margin({left:5})
        Text("忘记密码").fontColor(Color.Blue).fontSize(12)
      }.width("100%").justifyContent(FlexAlign.SpaceBetween)

      Button("登录")
        .width("100%")
        .type(ButtonType.Capsule)
        .enabled(!this.isLoading)
        .onClick(() => this.handleLogin())

      Text("注册账号").fontColor(Color.Blue).fontSize(14)
        .onClick(() => {
          router.pushUrl({url:"pages/Registrationpage"})
        })

      if (this.isLoading) {
        LoadingProgress().width(50).height(50).color(Color.Blue)
      } else {
        Blank()
      }
    }
    .backgroundImage($r("app.media.wdbeijing"))
    .backgroundImageSize({
      height:"100%"
    })
    .padding({
      left:"10vp",right:"10vp",bottom:"10vp"
    })
    .border({width:1})
    .width("100%")
    .height("100%")
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
  }
}
