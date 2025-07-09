import promptAction from '@ohos.promptAction';
import imageModule from '@ohos.multimedia.image';
import { BusinessError } from '@ohos.base';

// 定义Stage模式下的PositionArea接口
interface PositionArea {
  pixels: Uint8Array;
  offset: number;
  stride: number;
  region: imageModule.Region;
}

// 定义图片加载完成事件接口
interface ImageCompleteEvent {
  width: number;
  height: number;
}

// 定义布局矩形接口
interface BoundingClientRect {
  width: number;
  height: number;
  left: number;
  top: number;
}

// 定义Element接口
interface Element {
  getBoundingClientRect(callback: (rect: BoundingClientRect) => void): void;
}

// 定义用于getElementById的返回类型
interface ElementWithRect extends Element {
  getBoundingClientRect: (callback: (rect: BoundingClientRect) => void) => void;
}

@Entry
@Component
struct PhotoColorSelector {
  // 图片资源路径
  private imageResource: ResourceStr = $r('app.media.tiaosepan');
  // 选中的颜色
  @State selectedColor: string = '#0000FF';
  // 图片加载状态
  @State isImageLoaded: boolean = false;
  // 图片尺寸（明确类型）
  @State imgNaturalWidth: number = 0;
  @State imgNaturalHeight: number = 0;
  // 缩放比例和偏移（明确类型）
  @State scaleRatio: number = 1;
  @State imageOffsetX: number = 0;
  @State imageOffsetY: number = 0;
  // 像素数据（明确类型）
  @State pixelData: Uint8Array | null = null;
  // 容器宽度（默认值兼容初始渲染）
  @State containerWidth: number = 720;
  @State containerHeight: number = 1280;

  build() {
    Column() {
      // 标题区域
      Text('灯光颜色选择器')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
        .foregroundColor('#333333');

      Text('点击图片中的颜色进行选择')
        .fontSize(16)
        .margin({ bottom: 20 })
        .opacity(0.8);

      // 图片容器
      Image(this.imageResource)
        .width('80%')
        .height(400)
        .objectFit(ImageFit.Contain)
        .onComplete((event: ImageCompleteEvent) => {
          this.isImageLoaded = true;
          this.imgNaturalWidth = event.width;
          this.imgNaturalHeight = event.height;
          this.calculateImagePosition();
          this.loadImagePixelData();
        })
        .onError(() => {
          promptAction.showToast({ message: '图片加载失败，请检查资源路径' });
        })
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .onClick((event: ClickEvent) => {
          if (event.x !== undefined && event.y !== undefined) {
            this.handleImageClick(event);
          }
        })
        .margin({ bottom: 20 })
        .border({ width: 1, color: '#DDDDDD' })
        .borderRadius(8);

      // 颜色预览区域
      Row() {
        Text('选中颜色：')
          .fontSize(18)
          .margin({ right: 10 })
          .fontWeight(FontWeight.Medium);

        Text(this.selectedColor)
          .width(200)
          .height(40)
          .backgroundColor(this.selectedColor)
          .borderRadius(4)
          .textAlign(TextAlign.Center)
          .foregroundColor(this.isDarkColor(this.selectedColor) ? '#FFFFFF' : '#000000');
      }
      .margin({ top: 10 })
      .padding(10)
      .backgroundColor('#EEEEEE')
      .borderRadius(8);
    }
    .id('container') // 添加组件ID用于获取布局
    .padding(20)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F9F9F9');
  }

  // 页面即将显示时获取布局
  aboutToAppear() {
    this.updateContainerSize();
  }

  // 获取容器尺寸
  private updateContainerSize(): void {
    const element: Element = getElementById('container') as Element;
    if (element) {
      element.getBoundingClientRect((rect: BoundingClientRect) => {
        if (rect && rect.width > 0) {
          this.containerWidth = rect.width;
          this.containerHeight = rect.height;
        }
      });
    }
  }

  // 计算图片位置和缩放
  private calculateImagePosition(): void {
    if (!this.imgNaturalWidth || !this.imgNaturalHeight) return;

    const containerWidth = this.containerWidth * 0.8;
    const containerHeight = 400;

    this.scaleRatio = Math.min(
      containerWidth / this.imgNaturalWidth,
      containerHeight / this.imgNaturalHeight
    );
    this.imageOffsetX = (containerWidth - this.imgNaturalWidth * this.scaleRatio) / 2;
    this.imageOffsetY = (containerHeight - this.imgNaturalHeight * this.scaleRatio) / 2;
  }

  // 加载图片像素数据
  private async loadImagePixelData(): Promise<void> {
    if (!this.imgNaturalWidth || !this.imgNaturalHeight) return;

    try {
      const imageSource = imageModule.createImageSource(this.imageResource.toString());
      const pixelMap = await imageSource.createPixelMap();

      const bufferSize = this.imgNaturalWidth * this.imgNaturalHeight * 4;
      const uint8Array = new Uint8Array(bufferSize);

      const region: imageModule.Region = {
        x: 0,
        y: 0,
        size: { width: this.imgNaturalWidth, height: this.imgNaturalHeight }
      };

      const positionArea: PositionArea = {
        pixels: uint8Array,
        offset: 0,
        stride: this.imgNaturalWidth * 4,
        region: region
      };

      await pixelMap.readPixels(positionArea, (err: BusinessError | null) => {
        if (err) {
          console.error('读取像素失败:', err.message);
        }
      });

      this.pixelData = uint8Array;
    } catch (error) {
      const err = error as Error;
      console.error('像素数据加载失败:', err.message);
      // promptAction.showToast({ message: '颜色选择功能异常，请重试' });
    }
  }

  // 处理点击事件并提取颜色
  private handleImageClick(event: ClickEvent): void {
    if (!this.isImageLoaded || !this.pixelData) {
      // promptAction.showToast({ message: '图片未加载完成，请稍候' });
      return;
    }

    const x = event.x;
    const y = event.y;
    const imgX = Math.floor((x - this.imageOffsetX) / this.scaleRatio);
    const imgY = Math.floor((y - this.imageOffsetY) / this.scaleRatio);

    if (imgX >= 0 && imgX < this.imgNaturalWidth && imgY >= 0 && imgY < this.imgNaturalHeight) {
      const pixelIndex = (imgY * this.imgNaturalWidth + imgX) * 4;
      if (pixelIndex + 3 < this.pixelData.length) {
        const r = this.pixelData[pixelIndex];
        const g = this.pixelData[pixelIndex + 1];
        const b = this.pixelData[pixelIndex + 2];
        this.selectedColor = `#${((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1)}`;
      } else {
        promptAction.showToast({ message: '颜色数据读取失败' });
      }
    } else {
      promptAction.showToast({ message: '请点击图片区域' });
    }
  }

  // 判断颜色深浅
  private isDarkColor(color: string): boolean {
    const hex = color.replace('#', '').padEnd(6, '0').substring(0, 6);
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    return brightness < 128;
  }
}

// 实现getElementById函数，为返回对象添加明确类型
function getElementById(elementId: string): ElementWithRect {
  // 实际项目中应使用鸿蒙提供的API获取元素
  // 此处为模拟实现，返回带有类型定义的对象
  return {
    getBoundingClientRect: (callback: (rect: BoundingClientRect) => void) => {
      // 模拟布局数据，实际需根据API实现
      callback({
        width: 720,
        height: 1280,
        left: 0,
        top: 0
      });
    }
  };
}