import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { Commodity, MOCK_COMMODITIES } from '../model/Commodity';
import { AppState } from '../model/AppState';
import { CommodityStore } from '../store/CommodityStore';
import { PromotionNotifier } from '../service/PromotionNotifier';

@Entry
@Component
struct CommodityDetailPage {
  @State commodity: Commodity | undefined = undefined;
  @State isFavorite: boolean = false;

  aboutToAppear(): void {
    let id = AppState.selectedCommodityId;
    this.commodity = this.findById(id);
    this.loadFavorite(id);
  }

  findById(id: number): Commodity | undefined {
    for (let i = 0; i < MOCK_COMMODITIES.length; i++) {
      if (MOCK_COMMODITIES[i].id === id) {
        return MOCK_COMMODITIES[i];
      }
    }
    return undefined;
  }

  loadFavorite(id: number): void {
    CommodityStore.isFavorite(this.abilityCtx(), id).then((fav: boolean) => {
      this.isFavorite = fav;
    });
  }

  abilityCtx(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  toast(msg: string): void {
    promptAction.showToast({ message: msg });
  }

  toggleFavorite(): void {
    if (this.commodity === undefined) {
      return;
    }
    CommodityStore.toggleFavorite(this.abilityCtx(), this.commodity.id).then((fav: boolean) => {
      this.isFavorite = fav;
      this.toast(fav ? '已收藏' : '已取消收藏');
    });
  }

  buy(): void {
    if (this.commodity === undefined) {
      return;
    }
    let ctx = this.abilityCtx();
    let orderNo = 'ORD' + Date.now().toString();
    PromotionNotifier.requestEnable(ctx).catch(() => {
      // 用户拒绝或已关闭通知，继续尝试发布，失败时给出提示
    });
    PromotionNotifier.publishOrderConfirmation(ctx, this.commodity.name, orderNo).then(() => {
      this.toast('下单成功，已发送订单通知');
    }).catch(() => {
      this.toast('通知已关闭，可在系统设置中开启');
    });
  }

  build() {
    Column() {
      this.topBar()
      this.content()
      this.buyBar()
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
      Text('商品详情')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      Text(this.isFavorite ? '♥' : '♡')
        .fontSize(24)
        .fontColor(this.isFavorite ? '#E53935' : '#999999')
        .accessibilityText(this.isFavorite ? '已收藏' : '未收藏')
        .onClick(() => this.toggleFavorite())
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder
  content() {
    Scroll() {
      Column() {
        if (this.commodity !== undefined) {
          Column() {
            Text(this.commodity.emoji).fontSize(84)
          }
          .width('100%')
          .height(220)
          .backgroundColor(this.commodity.color)
          .justifyContent(FlexAlign.Center)

          Column() {
            Text(this.commodity.name)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
            Text(`¥${this.commodity.price}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#E53935')
              .margin({ top: 8 })
              .accessibilityText(`售价 ${this.commodity.price} 元`)
            Text(`花语：${this.commodity.flowerLanguage}`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 8 })
            Text(`规格：${this.commodity.spec}`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(Color.White)

          Column() {
            Text('优惠与服务')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .width('100%')
            this.serviceItem('📅', '配送日历提醒')
            this.serviceItem('📤', '分享给好友')
            this.serviceItem('👥', '添加收货人')
            this.serviceItem('🏺', '智能花瓶')
            this.serviceItem('🖼️', '晒图评价')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(Color.White)
          .margin({ top: 8 })
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  serviceItem(emoji: string, label: string) {
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
    .padding({ top: 12, bottom: 12 })
    .onClick(() => this.toast(`${label}：功能预留，暂未接入`))
  }

  @Builder
  buyBar() {
    Row() {
      Button('立即购买')
        .width('100%')
        .height(46)
        .fontSize(16)
        .backgroundColor('#E53935')
        .onClick(() => this.buy())
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
  }
}
