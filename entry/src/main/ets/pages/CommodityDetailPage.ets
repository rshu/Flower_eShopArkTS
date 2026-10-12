import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { userAuth } from '@kit.UserAuthenticationKit';
import { Commodity, DeliveryAddress } from '../model/Commodity';
import { MockData } from '../data/MockData';
import { CommodityService } from '../service/CommodityService';
import { CommodityStore } from '../service/CommodityStore';
import { PromotionNotifier } from '../service/PromotionNotifier';
import { DeliveryCalendarService } from '../service/DeliveryCalendarService';
import { ShareAndContactsService } from '../service/ShareAndContactsService';
import { PhotoPickerHelper } from '../service/PhotoPickerHelper';
import { BackgroundRefreshService } from '../service/BackgroundRefreshService';
import { SecurePayService } from '../service/SecurePayService';
import { SmartVaseService, VaseScanDevice } from '../service/SmartVaseService';
import { Constants } from '../common/Constants';

class DetailParams {
  id: number = 0;
}

@Entry
@Component
struct CommodityDetailPage {
  @State commodity: Commodity | undefined = undefined;
  @State isFavorite: boolean = false;
  @State photos: string[] = [];
  @State recipient: DeliveryAddress | null = null;
  @State deliveryDate: string = '';
  @State isBuying: boolean = false;
  @State vaseResult: string = '';

  private context(): common.Context {
    return getContext(this) as common.Context;
  }

  aboutToAppear(): void {
    const params: DetailParams = router.getParams() as DetailParams;
    const id: number = params.id;
    CommodityService.fetchCommodityById(id).then((item: Commodity | undefined) => {
      this.commodity = item;
      CommodityStore.addHistory(this.context(), id).then(() => {});
    });
    CommodityStore.isFavorite(this.context(), id).then((value: boolean) => {
      this.isFavorite = value;
    });
  }

  private toggleFavorite(): void {
    if (this.commodity === undefined) {
      return;
    }
    CommodityStore.toggleFavorite(this.context(), this.commodity.id).then((nowFavorite: boolean) => {
      this.isFavorite = nowFavorite;
      this.showToast(nowFavorite ? 'Added to favorites' : 'Removed from favorites');
    });
  }

  private pickRecipient(): void {
    ShareAndContactsService.pickRecipient().then((address: DeliveryAddress | null) => {
      if (address === null) {
        this.showToast('No recipient selected');
        return;
      }
      this.recipient = address;
      this.showToast(`Recipient: ${address.name}`);
    }).catch(() => {
      this.showToast('Contact picker failed');
    });
  }

  private pickPhotos(): void {
    PhotoPickerHelper.pickPhotos(3).then((uris: string[]) => {
      if (uris.length === 0) {
        this.showToast('No photo selected');
        return;
      }
      this.photos = this.photos.concat(uris);
    }).catch(() => {
      this.showToast('Photo picker failed');
    });
  }

  private removePhoto(uri: string): void {
    const next: string[] = [];
    for (let i = 0; i < this.photos.length; i++) {
      if (this.photos[i] !== uri) {
        next.push(this.photos[i]);
      }
    }
    this.photos = next;
  }

  private smartVase(): void {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = ['ohos.permission.ACCESS_BLUETOOTH'];
    atManager.requestPermissionsFromUser(this.context(), permissions).then(() => {
      this.runVaseScan();
    }).catch(() => {
      this.vaseResult = 'Bluetooth permission denied. Enable it in Settings.';
      this.showToast('Bluetooth permission denied');
    });
  }

  private runVaseScan(): void {
    this.vaseResult = 'Scanning for nearby BLE devices...';
    SmartVaseService.scan(5000).then((devices: VaseScanDevice[]) => {
      const target: VaseScanDevice | null = SmartVaseService.findLikelyVase(devices);
      if (target === null) {
        this.vaseResult = 'No BLE device found nearby';
        this.showToast('No BLE device found');
        return;
      }
      this.vaseResult = `Found ${devices.length} device(s); connecting to ${target.name}...`;
      SmartVaseService.sendWaterCommand(target.deviceId).then((message: string) => {
        this.vaseResult = message;
        this.showToast(message);
      }).catch(() => {
        this.vaseResult = 'Could not connect to the vase';
        this.showToast('Vase connection failed');
      });
    });
  }

  private share(): void {
    if (this.commodity === undefined) {
      return;
    }
    const context: common.UIAbilityContext = this.context() as common.UIAbilityContext;
    ShareAndContactsService.shareCommodity(
      context,
      this.commodity.name,
      `${this.commodity.name} · ¥${this.commodity.price.toFixed(2)} · ${this.commodity.flowerLanguage}`
    ).catch(() => {
      this.showToast('Share failed');
    });
  }

  private addDeliveryReminder(): void {
    if (this.commodity === undefined) {
      return;
    }
    const recipientName: string = this.recipient === null ? 'Recipient' : this.recipient.name;
    const deliveryTime: number = Date.now() + 24 * 3600 * 1000;
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'];
    atManager.requestPermissionsFromUser(this.context(), permissions).then(() => {
      DeliveryCalendarService.addDeliveryEvent(this.context(), this.commodity!.name, recipientName, deliveryTime).then(() => {
        this.showToast('Delivery added to calendar');
      }).catch(() => {
        this.showToast('Calendar add failed');
      });
    }).catch(() => {
      this.showToast('Calendar permission denied. Enable it in Settings.');
    });

    BackgroundRefreshService.schedulePromotionReminder(
      this.context(),
      'Flower delivery',
      `${this.commodity.name} · ${recipientName}`,
      deliveryTime
    ).then(() => {}).catch(() => {
      this.showToast('Reminder scheduling failed');
    });
  }

  private buy(): void {
    if (this.commodity === undefined) {
      return;
    }
    this.isBuying = true;
    PromotionNotifier.isEnabled().then((enabled: boolean) => {
      if (enabled) {
        this.finishBuy();
        return;
      }
      PromotionNotifier.requestEnable().then((granted: boolean) => {
        if (granted) {
          this.finishBuy();
        } else {
          this.isBuying = false;
          this.showToast('Notifications are disabled. Enable them in Settings.');
        }
      });
    });
  }

  private finishBuy(): void {
    if (this.commodity === undefined) {
      return;
    }
    const orderId: string = this.generateOrderId();
    PromotionNotifier.sendOrderConfirmation({
      commodityName: this.commodity.name,
      orderId: orderId
    }).then(() => {
      this.isBuying = false;
      router.pushUrl({
        url: 'pages/PaySecurityPage',
        params: {
          mode: 'pay',
          commodityName: this.commodity!.name,
          price: this.commodity!.price,
          orderId: orderId
        }
      });
    }).catch(() => {
      this.isBuying = false;
      this.showToast('Notification failed');
    });
  }

  private generateOrderId(): string {
    const now: number = Date.now();
    const random: number = Math.floor(Math.random() * 9000) + 1000;
    return `FL${now}${random}`;
  }

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  private testBiometric(): void {
    const authParam: userAuth.AuthParam = {
      challenge: new Uint8Array([]),
      authType: [userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.FACE, userAuth.UserAuthType.PIN],
      authTrustLevel: userAuth.AuthTrustLevel.ATL1
    };
    const widgetParam: userAuth.WidgetParam = {
      title: 'Verify your identity'
    };
    const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
    instance.on('result', {
      onResult: (result: userAuth.UserAuthResult) => {
        if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
          this.showToast('Identity verified');
        } else if (result.result === userAuth.UserAuthResultCode.NOT_ENROLLED) {
          this.showToast('No biometric or PIN enrolled on this device');
        } else {
          this.showToast('Verification failed');
        }
      }
    });
    instance.start();
  }

  @Builder
  SectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .margin({ top: 16, bottom: 8 })
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .fontSize(22)
          .backgroundColor('#00000000')
          .onClick(() => router.back())
        Text('Flower detail')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
        Blank()
        Button(this.isFavorite ? '♥' : '♡')
          .fontSize(26)
          .fontColor('#E64545')
          .backgroundColor('#00000000')
          .onClick(() => this.toggleFavorite())
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Stack({ alignContent: Alignment.Center }) {
            Text('🌷').fontSize(80)
            if (this.commodity !== undefined) {
              Image(this.commodity.image)
                .width('100%')
                .height(240)
                .objectFit(ImageFit.Cover)
            }
          }
          .width('100%')
          .height(240)

          Column() {
            Row() {
              Text('¥')
                .fontSize(18)
                .fontColor('#E64545')
              Text(this.commodity === undefined ? '--' : this.commodity.price.toFixed(2))
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E64545')
                .accessibilityText(`Price ${this.commodity === undefined ? 'unknown' : this.commodity.price.toFixed(2)} yuan`)
              Blank()
              Text(this.commodity === undefined ? '' : `Stock ${this.commodity.stock}`)
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')

            Text(this.commodity === undefined ? '' : this.commodity.name)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 8 })
              .accessibilityText(`Product ${this.commodity === undefined ? '' : this.commodity.name}`)

            Text(this.commodity === undefined ? '' : this.commodity.spec)
              .fontSize(13)
              .fontColor('#666666')
              .margin({ top: 4 })

            this.SectionTitle('Description')
            Text(this.commodity === undefined ? '' : this.commodity.description)
              .fontSize(14)
              .fontColor('#333333')
              .lineHeight(22)

            this.SectionTitle('Flower language')
            Text(this.commodity === undefined ? '' : this.commodity.flowerLanguage)
              .fontSize(14)
              .fontColor('#7B1FA2')

            this.SectionTitle('Gift & delivery')
            Row() {
              Button('📅 Delivery date')
                .fontSize(13)
                .layoutWeight(1)
                .backgroundColor('#E8F5E9')
                .fontColor('#2E7D32')
                .onClick(() => this.addDeliveryReminder())
              Button('📤 Share')
                .fontSize(13)
                .layoutWeight(1)
                .backgroundColor('#E3F2FD')
                .fontColor('#1565C0')
                .onClick(() => this.share())
            }
            .width('100%')
            .margin({ top: 4 })

            Row() {
              Button('👤 Recipient')
                .fontSize(13)
                .layoutWeight(1)
                .backgroundColor('#FFF3E0')
                .fontColor('#E65100')
                .onClick(() => this.pickRecipient())
              Button('📡 Smart vase')
                .fontSize(13)
                .layoutWeight(1)
                .backgroundColor('#F3E5F5')
                .fontColor('#6A1B9A')
                .onClick(() => this.smartVase())
            }
            .width('100%')
            .margin({ top: 10 })

            if (this.vaseResult.length > 0) {
              Text(this.vaseResult)
                .fontSize(13)
                .fontColor('#6A1B9A')
                .width('100%')
                .margin({ top: 8 })
            }

            if (this.recipient !== null) {
              Row() {
                Text(`Recipient: ${this.recipient!.name}${this.recipient!.phone.length > 0 ? ' · ' + this.recipient!.phone : ''}`)
                  .fontSize(13)
                  .fontColor('#E65100')
              }
              .width('100%')
              .margin({ top: 8 })
            }

            this.SectionTitle('Photo reviews')
            Row() {
              Button('+ Add photo')
                .fontSize(13)
                .backgroundColor('#ECEFF1')
                .fontColor('#333333')
                .onClick(() => this.pickPhotos())
              Button('🖊 Verify')
                .fontSize(13)
                .backgroundColor('#ECEFF1')
                .fontColor('#333333')
                .margin({ left: 10 })
                .onClick(() => this.testBiometric())
            }
            .width('100%')

            if (this.photos.length > 0) {
              Scroll() {
                Row({ space: 10 }) {
                  ForEach(this.photos, (uri: string) => {
                    Column() {
                      Stack({ alignContent: Alignment.TopEnd }) {
                        Image(uri)
                          .width(90)
                          .height(90)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(8)
                        Button('×')
                          .fontSize(14)
                          .width(22)
                          .height(22)
                          .backgroundColor('#CC000000')
                          .fontColor(Color.White)
                          .borderRadius(11)
                          .onClick(() => this.removePhoto(uri))
                      }
                    }
                  }, (uri: string) => uri)
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
              .margin({ top: 10 })
            }
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Row() {
        Button(this.isBuying ? 'Processing...' : 'Buy now')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#E64545')
          .fontColor(Color.White)
          .enabled(!this.isBuying)
          .onClick(() => this.buy())
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
