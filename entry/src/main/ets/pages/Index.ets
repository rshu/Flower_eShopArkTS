import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { Commodity, MOCK_COMMODITIES } from '../model/Commodity';
import { AppState } from '../model/AppState';
import { CommodityService } from '../service/CommodityService';
import { CommodityStore } from '../store/CommodityStore';

@Entry
@Component
struct Index {
  @State commodities: Commodity[] = [];
  @State historyIds: number[] = [];
  @State isRefreshing: boolean = false;
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.loadCommodities();
    this.loadHistory();
  }

  loadCommodities(): void {
    this.loading = true;
    CommodityService.fetchCommodities().then((list: Commodity[]) => {
      this.commodities = list;
      this.loading = false;
      this.isRefreshing = false;
    }).catch(() => {
      this.commodities = MOCK_COMMODITIES;
      this.loading = false;
      this.isRefreshing = false;
    });
  }

  loadHistory(): void {
    CommodityStore.getHistory(this.abilityCtx()).then((ids: number[]) => {
      this.historyIds = ids;
    });
  }

  onRefresh(): void {
    this.isRefreshing = true;
    this.loadCommodities();
  }

  abilityCtx(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  toast(msg: string): void {
    promptAction.showToast({ message: msg });
  }

  historyName(id: number): string {
    for (let i = 0; i < this.commodities.length; i++) {
      if (this.commodities[i].id === id) {
        return this.commodities[i].name;
      }
    }
    return '';
  }

  openDetail(item: Commodity): void {
    CommodityStore.addHistory(this.abilityCtx(), item.id);
    AppState.selectedCommodityId = item.id;
    router.pushUrl({ url: 'pages/CommodityDetailPage' });
  }

  openDetailById(id: number): void {
    AppState.selectedCommodityId = id;
    router.pushUrl({ url: 'pages/CommodityDetailPage' });
  }

  clearHistory(): void {
    CommodityStore.clearHistory(this.abilityCtx()).then(() => {
      this.historyIds = [];
      this.toast('已清空浏览历史');
    });
  }

  build() {
    Column() {
      this.header()
      this.listArea()
      this.historySection()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  header() {
    Row() {
      Text('花店')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Blank()

      Column() {
        Text('📷').fontSize(20)
        Text('扫一扫').fontSize(9).fontColor('#666666')
      }
      .margin({ left: 8 })
      .onClick(() => this.toast('扫一扫需 Scan Kit 与 AGC 配置，暂未接入'))

      Column() {
        Text('🎤').fontSize(20)
        Text('语音').fontSize(9).fontColor('#666666')
      }
      .margin({ left: 8 })
      .onClick(() => this.toast('语音搜索需 Speech Kit 与 AGC 配置，暂未接入'))

      Column() {
        Text('📍').fontSize(20)
        Text('定位').fontSize(9).fontColor('#666666')
      }
      .margin({ left: 8 })
      .onClick(() => this.toast('定位需位置权限，暂未接入'))

      Column() {
        Text('🗺️').fontSize(20)
        Text('地图').fontSize(9).fontColor('#666666')
      }
      .margin({ left: 8 })
      .onClick(() => router.pushUrl({ url: 'pages/StoreMapPage' }))

      Column() {
        Text('👤').fontSize(20)
        Text('我的').fontSize(9).fontColor('#666666')
      }
      .margin({ left: 8 })
      .onClick(() => router.pushUrl({ url: 'pages/PersonalPage' }))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  listArea() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      List({ space: 10 }) {
        if (this.loading) {
          ListItem() {
            this.loadingView()
          }
        } else {
          ForEach(this.commodities, (item: Commodity) => {
            ListItem() {
              this.commodityCard(item)
            }
          }, (item: Commodity) => item.id.toString())
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12, top: 12 })
      .scrollBar(BarState.Off)
    }
    .onRefreshing(() => this.onRefresh())
    .layoutWeight(1)
  }

  @Builder
  loadingView() {
    Column() {
      LoadingProgress()
        .width(40)
        .height(40)
        .color('#E53935')
      Text('加载中…')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .height(200)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  commodityCard(item: Commodity) {
    Row() {
      Column() {
        Text(item.emoji).fontSize(40)
      }
      .width(72)
      .height(72)
      .backgroundColor(item.color)
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)

      Column() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text(item.flowerLanguage)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
        Text(`¥${item.price}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#E53935')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Text('›')
        .fontSize(22)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => this.openDetail(item))
  }

  @Builder
  historySection() {
    Column() {
      Row() {
        Text('浏览历史')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('清空')
          .fontSize(12)
          .fontColor('#999999')
          .onClick(() => this.clearHistory())
      }
      .width('100%')

      if (this.historyIds.length === 0) {
        Text('暂无浏览记录')
          .fontSize(12)
          .fontColor('#BBBBBB')
          .margin({ top: 10 })
      } else {
        Scroll() {
          Row() {
            ForEach(this.historyIds, (id: number) => {
              Text(this.historyName(id))
                .fontSize(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('#F5F5F5')
                .borderRadius(15)
                .margin({ right: 8 })
                .onClick(() => this.openDetailById(id))
            }, (id: number) => id.toString())
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }
}
