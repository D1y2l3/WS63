import http from '@ohos.net.http';
import common from '@ohos.app.ability.common';

// 定义UserInfo接口替代any类型
interface UserInfo {
  id?: string;
  name?: string;
  // 其他用户信息字段
}

export class GlobalContext {
  private static instance: GlobalContext | null = null;
  private context: common.UIAbilityContext | null = null;


  public userInfo: UserInfo | null = null;
  public iamEndpoint: string = "";
  public userName: string = "";
  public iamUserName: string = "";
  public iamUserPassword: string = "";
  public productName: string = "";
  public iotDAEndpoint: string = "";
  public projectId: string = "";
  public productId: string = "";
  public deviceId: string = "";
  public color: string = 'rgb(0,0,0)';

  private constructor(context?: common.UIAbilityContext) {
    if (context) {
      this.context = context;
    }
  }

  // 获取单例实例
  public static getInstance(context?: common.UIAbilityContext): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext(context);
    }
    return GlobalContext.instance;
  }

  // 获取应用上下文（添加空值检查）
  public getAppContext(): common.UIAbilityContext | null {
    return this.context;
  }
}

