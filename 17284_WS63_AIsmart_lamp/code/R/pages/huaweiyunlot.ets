import common from '@ohos.app.ability.common';

// 定义全局状态的类型
type GlobalStateValue = string | number | boolean | object | null;
type GlobalState = Record<string, GlobalStateValue>;

export class GlobalContext {
  private static instance: GlobalContext | null = null;
  private context: common.UIAbilityContext | null = null;

  // 全局状态存储
  private globalState: GlobalState = {};

  // 华为云认证参数
  public iamEndpoint: string = "";
  public userName: string = "";
  public iamUserName: string = "";
  public iamUserPassword: string = "";
  public productName: string = "";

  // 华为云IoT参数
  public iotDAEndpoint: string = "";
  public projectId: string = "";
  public productId: string = "";
  public deviceId: string = "";

  // 全局状态
  public color: string = 'rgb(0,0,0)';

  private constructor(context?: common.UIAbilityContext) {
    if (context) {
      this.context = context;
    }
  }

  public static getInstance(context?: common.UIAbilityContext): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext(context);
    }
    return GlobalContext.instance;
  }

  public getAppContext(): common.UIAbilityContext | null {
    return this.context;
  }

  // 使用明确的类型定义，避免索引访问类型
  public getGlobalState(key: string): GlobalStateValue {
    return this.globalState[key];
  }

  public setGlobalState(key: string, value: GlobalStateValue): void {
    this.globalState[key] = value;
  }
}