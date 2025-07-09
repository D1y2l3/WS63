import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { GlobalContext } from './huaweiyunlot';
import router from '@ohos.router';

// 类型定义
interface GeneratedTypeLiteralInterface_3 {
  name: string;
}

interface GeneratedTypeLiteralInterface_2 {
  domain: GeneratedTypeLiteralInterface_3;
  name: string;
  password: string;
}

interface GeneratedTypeLiteralInterface_1 {
  user: GeneratedTypeLiteralInterface_2;
}

interface AuthIdentity {
  methods: string[];
  password: GeneratedTypeLiteralInterface_1;
}

interface GeneratedTypeLiteralInterface_4 {
  name: string;
}

interface AuthScope {
  project: GeneratedTypeLiteralInterface_4;
}

interface GeneratedTypeLiteralInterface_5 {
  identity: AuthIdentity;
  scope: AuthScope;
}

interface AuthRequest {
  auth: GeneratedTypeLiteralInterface_5
}

interface DeviceResponse {
  status: string;
  device_id: string;
  name: string;
}

interface CommandParams {
  value?: string | number | boolean;
  red?: number;
  green?: number;
  blue?: number;
}

interface CommandRequest {
  service_id: string;
  command_name: string;
  paras: CommandParams;
}

@Entry
@Component
  // 修复1：移除export，@Entry组件不应导出
struct HuaweiCloud {
  private globalContext: GlobalContext = GlobalContext.getInstance();
  private httpClient: http.HttpRequest | null = null;

  @State isInitialized: boolean = false;
  @State isConnecting: boolean = false;
  @State tokenStatus: string = '未获取Token';
  @State deviceStatus: string = '设备未连接';
  private pollingTimer: number | null = null;

  aboutToAppear() {
    this.initCloudConnection();
  }

  aboutToDisappear() {
    this.httpClient?.destroy();
    this.pollingTimer && clearInterval(this.pollingTimer);
  }

  async initCloudConnection(): Promise<void> {
    this.isConnecting = true;
    try {
      await this.requestToken();
      this.tokenStatus = 'Token已获取';
      this.startPollingDeviceStatus();
      this.isInitialized = true;
    } catch (error) {
      console.error('初始化失败:', (error as Error).message);
      this.tokenStatus = 'Token获取失败';
      this.deviceStatus = '连接失败';
      promptAction.showToast({
        message: `连接失败: ${(error as Error).message}`,
        duration: 2000
      });
    } finally {
      this.isConnecting = false;
    }
  }

  async requestToken(): Promise<void> {
    const url = `https://${this.globalContext.iamEndpoint}/v3/auth/tokens?nocatalog=true`;
    const requestData: AuthRequest = {
      auth: {
        identity: {
          methods: ["password"],
          password: {
            user: {
              domain: { name: this.globalContext.userName },
              name: this.globalContext.iamUserName,
              password: this.globalContext.iamUserPassword
            }
          }
        },
        scope: { project: { name: this.globalContext.productName } }
      }
    };

    this.httpClient = http.createHttp();
    const response: http.HttpResponse = await this.httpClient.request(url, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify(requestData),
      readTimeout: 10000,
      connectTimeout: 10000
    });

    if (response.responseCode === 201) {

      const token: string = response.header['X-Subject-Token'] as string || '';
      this.globalContext.setGlobalState('X_Auth_Token', token);
    } else {
      throw new Error(`状态码: ${response.responseCode}`);
    }
  }

  startPollingDeviceStatus(): void {
    this.pollingTimer = setInterval(async () => {
      const token = this.globalContext.getGlobalState('X_Auth_Token') as string;
      if (!token) return;

      try {
        const url = `https://${this.globalContext.iotDAEndpoint}/v5/iot/${this.globalContext.projectId}/devices/${this.globalContext.deviceId}`;
        this.httpClient = http.createHttp();
        const result = await this.httpClient.request(url, {
          method: http.RequestMethod.GET,
          header: { 'X-Auth-Token': token },
          readTimeout: 10000,
          connectTimeout: 10000
        });

        if (result.responseCode === 200) {
          const data = JSON.parse(result.result as string) as DeviceResponse;
          const isOnline = data.status === "ONLINE";
          this.globalContext.setGlobalState('deviceOnline', isOnline);
          this.deviceStatus = isOnline ? '设备在线' : '设备离线';
        }
      } catch (error) {
        console.error('设备查询失败:', (error as Error).message);
      } finally {
        this.httpClient?.destroy();
      }
    }, 5000);
  }

  async sendDeviceCommand(command: string, params: CommandParams): Promise<boolean> {
    const token = this.globalContext.getGlobalState('X_Auth_Token') as string;
    const isOnline = this.globalContext.getGlobalState('deviceOnline') as boolean;

    if (!token || !isOnline) {
      throw new Error('设备离线或无Token');
    }

    const url = `https://${this.globalContext.iotDAEndpoint}/v5/iot/${this.globalContext.projectId}/devices/${this.globalContext.deviceId}/commands`;
    const requestData: CommandRequest = {
      service_id: 'control',
      command_name: command,
      paras: params
    };

    this.httpClient = http.createHttp();

    const result = await this.httpClient.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'X-Auth-Token': token,
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify(requestData), // 替换data为extraData
      readTimeout: 10000,
      connectTimeout: 10000
    });

    if (result.responseCode !== 200) {
      throw new Error(`状态码: ${result.responseCode}`);
    }
    return true;
  }

  build() {
    Column() {
      Text('华为云物联网连接')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 });

      Text(`连接状态: ${this.isInitialized ? '已初始化' : '未初始化'}`)
        .fontSize(14)
        .margin({ bottom: 5 });

      Text(`Token状态: ${this.tokenStatus}`)
        .fontSize(14)
        .margin({ bottom: 5 });

      Text(`设备状态: ${this.deviceStatus}`)
        .fontSize(14)
        .margin({ bottom: 20 })
        .fontColor(this.globalContext.getGlobalState('deviceOnline') as boolean ? '#00B42A' : '#F53F3F');

      // 修复4：使用if-else替代三元表达式，符合UI组件语法
      if (this.isInitialized) {
        Button('重新连接')
          .onClick(() => {
            this.isInitialized = false;
            this.initCloudConnection();
          })
          .width('80%'); // 确保属性在组件内链式调用
      } else {
        Button('初始化连接')
          .onClick(() => this.initCloudConnection())
          .width('80%'); // 确保属性在组件内链式调用
      }

      Text('API调试区')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 10 });

      Button('测试Token获取')
        .width('80%')
        .onClick(async () => {
          try {
            await this.requestToken();
            this.tokenStatus = 'Token已获取';
            promptAction.showToast({ message: 'Token获取成功' });
          } catch (error) {
            promptAction.showToast({ message: (error as Error).message });
          }
        });

      Button('跳转控制页')
        .width('80%')
        .margin({ top: 10 })
        .onClick(() => router.pushUrl({ url: 'pages/ztStatus' }));
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F9F9F9');
  }
}