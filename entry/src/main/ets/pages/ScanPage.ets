import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { Commodity } from '../model/Commodity';
import { MockData } from '../data/MockData';
import { FlowerScanService } from '../service/FlowerScanService';

@Entry
@Component
struct ScanPage {
  @State codeInput: string = '';
  @State lastResult: string = '';
  @State isScanning: boolean = false;

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  private handleCode(code: string): void {
    this.codeInput = code;
    const id: number | null = FlowerScanService.parseCommodityCode(code);
    if (id === null) {
      this.lastResult = `Invalid code: ${code}`;
      this.showToast('Invalid code');
      return;
    }
    const commodity: Commodity | undefined = MockData.getCommodityById(id);
    if (commodity === undefined) {
      this.lastResult = `No flower found for code ${id}`;
      this.showToast('No flower found');
      return;
    }
    this.lastResult = `Found: ${commodity.name}`;
    this.showToast(`Found: ${commodity.name}`);
    router.pushUrl({ url: 'pages/CommodityDetailPage', params: { id: id } });
  }

  private scanManual(): void {
    if (this.codeInput.trim().length === 0) {
      this.showToast('Enter a flower code');
      return;
    }
    this.handleCode(this.codeInput);
  }

  private startCameraScan(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE, scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };
    this.isScanning = true;
    try {
      scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options)
        .then((data: scanBarcode.ScanResult) => {
          this.isScanning = false;
          this.handleCode(data.originalValue);
        })
        .catch((err: BusinessError) => {
          this.isScanning = false;
          if (err.code === 1000500002) {
            this.lastResult = 'Scan canceled';
            return;
          }
          this.lastResult = `Scan failed: ${err.code} ${err.message}`;
          this.showToast('Camera scan failed. Enter a code below.');
        });
    } catch (err) {
      this.isScanning = false;
      const e = err as BusinessError;
      this.lastResult = `Scan error: ${e.code} ${e.message}`;
      this.showToast('Camera scan unavailable. Enter a code below.');
    }
  }

  private fillDemo(code: string): void {
    this.codeInput = code;
    this.lastResult = '';
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .fontSize(22)
          .backgroundColor('#00000000')
          .onClick(() => router.back())
        Text('Find flower')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Column() {
            Text('📷')
              .fontSize(56)
            Text('Scan a QR code on the flower tag')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ top: 8 })
            Text('Uses the built-in Huawei Scan Kit camera with album support.')
              .fontSize(11)
              .fontColor('#888888')
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
            Button(this.isScanning ? 'Opening scanner...' : 'Open camera scanner')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 14 })
              .width('100%')
              .height(46)
              .backgroundColor('#1565C0')
              .fontColor(Color.White)
              .enabled(!this.isScanning)
              .onClick(() => this.startCameraScan())
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#E3F2FD')
          .borderRadius(12)

          TextInput({ placeholder: 'Enter flower code (e.g. flower://3 or 3)', text: $$this.codeInput })
            .width('100%')
            .height(48)
            .margin({ top: 16 })

          Button('Open by code')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .height(48)
            .margin({ top: 12 })
            .backgroundColor('#E64545')
            .fontColor(Color.White)
            .onClick(() => this.scanManual())

          Text('Demo codes')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 20 })

          Row({ space: 10 }) {
            ForEach([1, 2, 3, 5], (id: number) => {
              Button(`flower://${id}`)
                .fontSize(12)
                .backgroundColor('#E3F2FD')
                .fontColor('#1565C0')
                .onClick(() => this.fillDemo(FlowerScanService.buildDemoCode(id)))
            }, (id: number) => id.toString())
          }
          .width('100%')
          .margin({ top: 8 })

          if (this.lastResult.length > 0) {
            Text(this.lastResult)
              .fontSize(14)
              .fontColor('#333333')
              .width('100%')
              .margin({ top: 16 })
          }
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
