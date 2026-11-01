import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct PersonalPage {
  toast(msg: string): void {
    promptAction.showToast({ message: msg });
  }

  onEntryClick(label: string): void {
    if (label === '支付安全') {
      router.pushUrl({ url: 'pages/PaySecurityPage' });
    } else {
      this.toast(`${label}：功能预留，暂未接入`);
    }
  }

  build() {
    Column() {
      this.topBar()

      Column() {
        Text('👤').fontSize(64)
        Text('未登录').fontSize(16).fontColor('#666666').margin({ top: 8 })
        Button('华为账号登录')
          .width(160)
          .height(40)
          .fontSize(14)
          .margin({ top: 16 })
          .backgroundColor('#E53935')
          .onClick(() => this.toast('华为账号登录需 Account Kit 与 AGC 配置，暂未接入'))
      }
      .width('100%')
      .padding({ top: 32, bottom: 32 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        this.entryRow('🔒', '支付安全')
        this.entryRow('📦', '订单管理')
        this.entryRow('⚙️', '设置')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  topBar() {
    Row() {
      Text('←')
        .fontSize(22)
        .padding({ right: 8 })
        .onClick(() => router.back())
      Text('我的')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  entryRow(emoji: string, label: string) {
    Row() {
      Text(emoji).fontSize(20)
      Text(label)
        .fontSize(14)
        .margin({ left: 10 })
        .layoutWeight(1)
      Text('›')
        .fontSize(18)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding({ top: 14, bottom: 14 })
    .onClick(() => this.onEntryClick(label))
  }
}
