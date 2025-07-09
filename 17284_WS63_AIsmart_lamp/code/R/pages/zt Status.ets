import promptAction from '@ohos.promptAction';
import { GlobalContext } from './huaweiyunlot';
import http from '@ohos.net.http';
import router from '@ohos.router';

interface DeviceProperties {
  light?: number;
  lamp_mode?: string;
  RGB?: RGBColor;
}

interface RGBColor {
  red: number;
  green: number;
  blue: number;
}

interface CommandParams {
  value?: string | number | boolean;
  red?: number;
  green?: number;
  blue?: number;
}

interface HttpRequestOptions {
  method: http.RequestMethod;
  header: Record<string, string>;
  readTimeout: number;
  connectTimeout: number;
}


interface GeneratedTypeLiteralInterface_2 {
  properties: DeviceProperties;
}

interface GeneratedTypeLiteralInterface_1 {
  reported: GeneratedTypeLiteralInterface_2;
}

@Entry
@Component
struct Status {
  private globalContext: GlobalContext = GlobalContext.getInstance();
  private httpClient: http.HttpRequest | null = null; // 明确类型为HttpRequest或null

  @State isLightOn: boolean = false;
  @State lightBrightness: number = 100;
  @State autoDimming: boolean = false;
  @State sleepMode: boolean = false;
  @State readingMode: boolean = false;
  @State transformMode: boolean = false;
  @State lightValue: number = 0;
  @State deviceOnline: boolean = false;

  aboutToAppear() {
    this.deviceOnline = this.globalContext.getGlobalState('deviceOnline') as boolean || false;
    this.checkGlobalStatus();
    this.pollLocalStatus();
  }

  aboutToDisappear() {
    clearInterval(this.pollingTimer);
  }

  private pollingTimer: number | null = null;

  checkGlobalStatus() {
    this.deviceOnline = this.globalContext.getGlobalState('deviceOnline') as boolean || false;
    this.fetchDeviceShadow();
  }

  pollLocalStatus() {
    this.pollingTimer = setInterval((): void => this.checkGlobalStatus(), 1000);
  }

  // 明确返回类型
  async fetchDeviceShadow(): Promise<void> {
    if (!this.deviceOnline) return;
    try {
      const url = `https://${this.globalContext.iotDAEndpoint}/v5/iot/${this.globalContext.projectId}/devices/${this.globalContext.deviceId}/shadow`;
      const authToken = this.globalContext.getGlobalState('X_Auth_Token') as string;
      const header: Record<string, string> = { 'X-Auth-Token': authToken };
      this.httpClient = http.createHttp();
      const options: HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header,
        readTimeout: 10000,
        connectTimeout: 10000
      };
      const result = await this.httpClient.request(url, options);

      if (result.responseCode === 200) {
        // 定义完整响应接口
        interface ShadowResponse {
          shadow: Array<GeneratedTypeLiteralInterface_1>;
        }

        const responseData = JSON.parse(result.result as string) as ShadowResponse;
        const properties = responseData.shadow[0]?.reported?.properties || {};
        this.lightValue = properties.light || 0;
        this.isLightOn = properties.lamp_mode?.includes('ON') || false;
        this.syncDeviceMode(properties);
        this.httpClient.destroy();
      }
    } catch (error) {
      console.error('获取设备影子失败:', (error as Error).message);
    }
  }

  syncDeviceMode(properties: DeviceProperties) {
    const lampMode = properties.lamp_mode || '';
    this.autoDimming = lampMode.includes('AUTO_MODE_ON');
    this.sleepMode = lampMode.includes('SLEEP_MODE_ON');
    this.readingMode = lampMode.includes('READ_BOOK_MODE_ON');
    this.transformMode = lampMode.includes('LED_BLINK_MODE_ON');

    if (properties.RGB) {
      const rgb = properties.RGB;
      this.lightBrightness = Math.round((rgb.red + rgb.green + rgb.blue) / 3 / 255 * 100);
    }
  }

  // 明确参数类型
  async sendDeviceCommand(command: string, params: CommandParams): Promise<void> {
    if (!this.deviceOnline) {
      promptAction.showToast({ message: '设备离线，无法操作', duration: 2000 });
      return;
    }
    try {
      // 假设sendDeviceCommandFunc已正确定义
      const sendDeviceCommandFunc = this.globalContext.getGlobalState('sendDeviceCommand') as Function;
      await sendDeviceCommandFunc(command, params);
      promptAction.showToast({ message: '操作成功', duration: 1500 });
    } catch (error) {
      console.error('命令下发失败:', (error as Error).message);
      promptAction.showToast({
        message: (error as Error).message || '操作失败，请重试',
        duration: 2000
      });
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button('云连接')
          .width(80)
          .onClick(() => router.pushUrl({ url: 'pages/lotpage' }));
        Text('智能灯控制')
          .fontSize(18)
          .fontWeight(FontWeight.Bold);
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundColor('#E0E0E0');

      // 设备状态
      Text(`设备: ${this.globalContext.deviceId}`)
        .fontSize(12)
        .margin({ bottom: 5 })
        .fontColor('#666666');
      Text(this.deviceOnline ? '设备在线' : '设备离线')
        .fontSize(14)
        .margin({ top: 5, bottom: 10 })
        .fontColor(this.deviceOnline ? '#00B42A' : '#F53F3F');

      // 灯泡图标
      Image(this.isLightOn ? $r('app.media.lampon') : $r('app.media.lampoff'))
        .width(80)
        .height(80)
        .margin({ top: 10, bottom: 10 })
        .objectFit(ImageFit.Contain)
        .align(Alignment.Center);

      // 光照值显示
      Text(`当前光照: ${this.lightValue}Lux`)
        .fontSize(14)
        .margin({ bottom: 15 });

      // 灯开关控制
      Row({ space: 10 }) {
        Text('灯:')
          .fontSize(16);
        Toggle({ type: ToggleType.Switch, isOn: this.isLightOn })
          .onChange((isChecked: boolean) => {
            this.isLightOn = isChecked;
            this.sendDeviceCommand('lamp_mode', {
              value: isChecked ? 'SUN_LIGHT_MODE_ON' : 'SUN_LIGHT_MODE_OFF'
            });
            if (!isChecked) {
              this.autoDimming = this.sleepMode = this.readingMode = this.transformMode = false;
            }
          });
        Text(this.isLightOn ? '开' : '关')
          .fontSize(16);
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding(10)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .shadow({ radius: 2, color: '#E0E0E0' });

      // 亮度调节
      Column({ space: 10 }) {
        Text('亮度调节')
          .fontSize(16)
          .margin({ left: 10 });
        Row() {
          Text(`${this.lightBrightness}%`)
            .fontSize(14)
            .fontColor('#666666')
            .width(40);
          Slider({
            value: this.lightBrightness,
            min: 0,
            max: 100,
            step: 1
          })
            .width('80%')
            .onChange((value: number) => {
              this.lightBrightness = value;
              if (this.autoDimming) this.autoDimming = false;
              const rgb = Math.round((value / 100) * 255);
              this.sendDeviceCommand('RGB', {
                red: rgb, green: rgb, blue: rgb
              });
            });
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center);
      }
      .width('100%')
      .padding(10)
      .margin({ top: 15 })
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .shadow({ radius: 2, color: '#E0E0E0' });

      // 场景模式
      Text('场景模式')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 });

      // 模式开关
      Column({ space: 12 }) {
        // 自动调光模式
        Row({ space: 10 }) {
          Image($r('app.media.autolight'))
            .width(24)
            .height(24);
          Text('自动调光')
            .fontSize(16);
          Toggle({ type: ToggleType.Switch, isOn: this.autoDimming })
            .onChange((isChecked: boolean) => {
              this.autoDimming = isChecked;
              if (isChecked) {
                this.sleepMode = this.readingMode = this.transformMode = false;
                this.lightBrightness = 60;
                this.sendDeviceCommand('auto_mode', { value: 'ON' });
                this.sendDeviceCommand('RGB', { red: 153, green: 153, blue: 255 });
              } else {
                this.sendDeviceCommand('auto_mode', { value: 'OFF' });
              }
            });
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding(10)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#E0E0E0' });

        // 睡眠模式
        Row({ space: 10 }) {
          Image($r('app.media.sleep'))
            .width(24)
            .height(24);
          Text('睡眠模式')
            .fontSize(16);
          Toggle({ type: ToggleType.Switch, isOn: this.sleepMode })
            .onChange((isChecked: boolean) => {
              this.sleepMode = isChecked;
              if (isChecked) {
                this.autoDimming = this.readingMode = this.transformMode = false;
                this.lightBrightness = 20;
                this.sendDeviceCommand('lamp_mode', { value: 'SLEEP_MODE_ON' });
                this.sendDeviceCommand('RGB', { red: 255, green: 153, blue: 255 });
              } else {
                this.sendDeviceCommand('lamp_mode', { value: 'SLEEP_MODE_OFF' });
              }
            });
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding(10)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#E0E0E0' });

        // 阅读模式
        Row({ space: 10 }) {
          Image($r('app.media.readbook'))
            .width(24)
            .height(24);
          Text('阅读模式')
            .fontSize(16);
          Toggle({ type: ToggleType.Switch, isOn: this.readingMode })
            .onChange((isChecked: boolean) => {
              this.readingMode = isChecked;
              if (isChecked) {
                this.autoDimming = this.sleepMode = this.transformMode = false;
                this.lightBrightness = 85;
                this.sendDeviceCommand('lamp_mode', { value: 'READ_BOOK_MODE_ON' });
                this.sendDeviceCommand('RGB', { red: 255, green: 255, blue: 204 });
              } else {
                this.sendDeviceCommand('lamp_mode', { value: 'READ_BOOK_MODE_OFF' });
              }
            });
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding(10)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#E0E0E0' });

        // 变幻模式
        Row({ space: 10 }) {
          Image($r('app.media.ledblink'))
            .width(24)
            .height(24);
          Text('变幻模式')
            .fontSize(16);
          Toggle({ type: ToggleType.Switch, isOn: this.transformMode })
            .onChange((isChecked: boolean) => {
              this.transformMode = isChecked;
              if (isChecked) {
                this.autoDimming = this.sleepMode = this.readingMode = false;
                this.lightBrightness = 85;
                this.sendDeviceCommand('lamp_mode', { value: 'LED_BLINK_MODE_ON' });
              } else {
                this.sendDeviceCommand('lamp_mode', { value: 'LED_BLINK_MODE_OFF' });
              }
            });
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .padding(10)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .shadow({ radius: 2, color: '#E0E0E0' });
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F5F5F5');
  }
}

export { Status };