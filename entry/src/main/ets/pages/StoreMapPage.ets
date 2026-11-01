import router from '@ohos.router';

@Entry
@Component
struct StoreMapPage {
  build() {
    Column() {
      this.topBar()

      Column() {
        Text('🗺️').fontSize(64)
        Text('门店地图').fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 8 })
        Text('需要 Map Kit 与 AGC 配置的 API Key').fontSize(12).fontColor('#999999').margin({ top: 8 })
        Text('当前为功能预留，暂未展示真实地图').fontSize(12).fontColor('#999999').margin({ top: 4 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
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
      Text('门店地图')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }
}
