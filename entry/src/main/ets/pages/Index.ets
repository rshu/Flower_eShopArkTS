import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { Commodity, Store } from '../model/Commodity';
import { MockData } from '../data/MockData';
import { CommodityService } from '../service/CommodityService';
import { CommodityStore } from '../service/CommodityStore';
import { FlowerLocationService } from '../service/FlowerLocationService';
import { SpeechSearchService } from '../service/SpeechSearchService';

@Entry
@Component
struct Index {
  @State commodities: Commodity[] = [];
  @State history: Commodity[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State locationText: string = '';
  @State nearbyStores: Store[] = [];
  @State showNearbyStores: boolean = false;

  aboutToAppear(): void {
    this.loadCommodities();
    this.loadHistory();
  }

  private context(): common.Context {
    return getContext(this) as common.Context;
  }

  private loadCommodities(): void {
    this.isLoading = true;
    CommodityService.fetchCommodities().then((list: Commodity[]) => {
      this.commodities = list;
      this.isLoading = false;
      this.isRefreshing = false;
    }).catch(() => {
      this.commodities = MockData.COMMODITIES;
      this.isLoading = false;
      this.isRefreshing = false;
    });
  }

  private loadHistory(): void {
    CommodityStore.getHistory(this.context()).then((ids: number[]) => {
      const items: Commodity[] = [];
      for (let i = 0; i < ids.length; i++) {
        const found: Commodity | undefined = MockData.getCommodityById(ids[i]);
        if (found !== undefined) {
          items.push(found);
        }
      }
      this.history = items;
    });
  }

  private openDetail(id: number): void {
    CommodityStore.addHistory(this.context(), id).then(() => {
      this.loadHistory();
    });
    router.pushUrl({ url: 'pages/CommodityDetailPage', params: { id: id } });
  }

  private requestLocation(): void {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
    atManager.requestPermissionsFromUser(this.context(), permissions).then(() => {
      this.fetchLocation();
    }).catch(() => {
      this.showToast('Location requires location permission. Enable it in Settings.');
    });
  }

  private fetchLocation(): void {
    if (!FlowerLocationService.isLocationEnabled()) {
      this.showToast('Location service is off. Enable it in Settings.');
      return;
    }
    FlowerLocationService.getCurrentLocation().then((result) => {
      if (result === null) {
        this.showToast('Unable to get current location');
        return;
      }
      this.locationText = `${result.latitude.toFixed(4)}, ${result.longitude.toFixed(4)}`;
      this.nearbyStores = MockData.STORES;
      this.showNearbyStores = true;
      FlowerLocationService.saveLastLocation(this.context(), result);
    });
  }

  private openMap(): void {
    router.pushUrl({ url: 'pages/StoreMapPage' });
  }

  private openScan(): void {
    router.pushUrl({ url: 'pages/ScanPage' });
  }

  @State isListening: boolean = false;
  @State voiceText: string = '';

  private openVoice(): void {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(this.context(), ['ohos.permission.MICROPHONE']).then(() => {
      this.startVoiceSearch();
    }).catch(() => {
      this.showToast('Voice search requires the microphone permission.');
    });
  }

  private startVoiceSearch(): void {
    if (SpeechSearchService.isRunning()) {
      SpeechSearchService.shutdown();
      this.isListening = false;
      return;
    }
    this.isListening = true;
    this.voiceText = '';
    this.showSearchPrompt();
    SpeechSearchService.start({
      onStart: (): void => {
        this.isListening = true;
      },
      onResult: (text: string, isFinal: boolean): void => {
        this.voiceText = text;
        this.searchKeyword = text;
        if (isFinal) {
          this.runSearch();
        }
      },
      onComplete: (finalText: string): void => {
        this.isListening = false;
        if (finalText.length > 0) {
          this.searchKeyword = finalText;
          this.voiceText = finalText;
          this.runSearch();
        }
      },
      onError: (code: number, message: string): void => {
        this.isListening = false;
        this.showToast(`Speech recognition failed (${code}). Type a keyword instead.`);
      }
    }).then((started: boolean) => {
      if (!started) {
        this.isListening = false;
      }
    });
  }

  private showSearchPrompt(): void {
    this.searchKeyword = '';
    this.showSearch = true;
  }

  @State searchKeyword: string = '';
  @State showSearch: boolean = false;
  @State searchResults: Commodity[] = [];

  private runSearch(): void {
    CommodityService.searchCommodities(this.searchKeyword).then((list: Commodity[]) => {
      this.searchResults = list;
    });
  }

  private openPersonal(): void {
    router.pushUrl({ url: 'pages/PersonalPage' });
  }

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  @Builder
  ProductCard(item: Commodity) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Text('🌷')
          .fontSize(48)
        Image(item.image)
          .width('100%')
          .height(150)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 12, topRight: 12 })
      }
      .width('100%')
      .height(150)

      Column() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row() {
          Text('¥')
            .fontSize(14)
            .fontColor('#E64545')
          Text(item.price.toFixed(2))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E64545')
          Blank()
          Text(item.spec)
            .fontSize(11)
            .fontColor('#999999')
        }
        .width('100%')
        .margin({ top: 6 })
      }
      .width('100%')
      .padding(10)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      this.openDetail(item.id);
    })
  }

  @Builder
  HistoryCard(item: Commodity) {
    Column() {
      Text('🌷').fontSize(28)
      Text(item.name)
        .fontSize(12)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(88)
    .padding(8)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .onClick(() => {
      this.openDetail(item.id);
    })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('Flower eShop')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button() { Text('🔍') }
          .width(36).height(36)
          .backgroundColor('#00000000')
          .onClick(() => this.showSearchPrompt())
        Button() { Text('🎤') }
          .width(36).height(36)
          .backgroundColor('#00000000')
          .onClick(() => this.openVoice())
        Button() { Text('📷') }
          .width(36).height(36)
          .backgroundColor('#00000000')
          .onClick(() => this.openScan())
        Button() { Text('📍') }
          .width(36).height(36)
          .backgroundColor('#00000000')
          .onClick(() => this.requestLocation())
        Button() { Text('🗺️') }
          .width(36).height(36)
          .backgroundColor('#00000000')
          .onClick(() => this.openMap())
        Button() { Text('👤') }
          .width(36).height(36)
          .backgroundColor('#00000000')
          .onClick(() => this.openPersonal())
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      if (this.locationText.length > 0) {
        Row() {
          Text(`📍 ${this.locationText}`)
            .fontSize(13)
            .fontColor('#2E7D32')
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#E8F5E9')
      }

      Refresh({ refreshing: this.isRefreshing }) {
        List({ space: 12 }) {
          if (this.isLoading) {
            ListItem() {
              Column() {
                LoadingProgress().width(36).height(36)
                Text('Loading flowers...').fontSize(13).fontColor('#999999')
              }
              .width('100%')
              .height(200)
              .justifyContent(FlexAlign.Center)
            }
          } else {
            ForEach(this.commodities, (item: Commodity) => {
              ListItem() {
                this.ProductCard(item)
              }
            }, (item: Commodity) => item.id.toString())

            if (this.history.length > 0) {
              ListItem() {
                Column() {
                  Row() {
                    Text('Recently viewed')
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                    Blank()
                    Button('Clear')
                      .fontSize(12)
                      .fontColor('#999999')
                      .backgroundColor('#00000000')
                      .onClick(() => {
                        CommodityStore.clearHistory(this.context()).then(() => this.loadHistory());
                      })
                  }
                  .width('100%')

                  Scroll() {
                    Row({ space: 10 }) {
                      ForEach(this.history, (item: Commodity) => {
                        this.HistoryCard(item)
                      }, (item: Commodity) => item.id.toString())
                    }
                  }
                  .scrollable(ScrollDirection.Horizontal)
                  .scrollBar(BarState.Off)
                  .width('100%')
                  .margin({ top: 10 })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(12)
              }
            }
          }
        }
        .width('100%')
        .height('100%')
        .padding({ left: 12, right: 12, bottom: 12 })
        .scrollBar(BarState.Off)
      }
      .layoutWeight(1)
      .onRefreshing(() => {
        this.isRefreshing = true;
        this.loadCommodities();
      })

      if (this.showNearbyStores) {
        Column() {
          Row() {
            Text('Nearby stores')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            Blank()
            Button('Close')
              .fontSize(12)
              .backgroundColor('#00000000')
              .fontColor('#666666')
              .onClick(() => {
                this.showNearbyStores = false;
              })
          }
          .width('100%')

          ForEach(this.nearbyStores, (store: Store) => {
            Row() {
              Column() {
                Text(store.name).fontSize(15).fontWeight(FontWeight.Medium)
                Text(store.address).fontSize(12).fontColor('#666666').margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('📞')
                .fontSize(20)
                .onClick(() => this.showToast(store.phone))
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          }, (store: Store) => store.id.toString())
        }
        .width('90%')
        .padding(14)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .position({ x: '5%', y: '20%' })
        .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 4 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')

    if (this.showSearch) {
      Column() {
        Row() {
          TextInput({ placeholder: 'Search flower name', text: this.searchKeyword })
            .layoutWeight(1)
            .height(44)
            .onChange((value: string) => {
              this.searchKeyword = value;
            })
          Button('Search')
            .height(44)
            .margin({ left: 8 })
            .onClick(() => {
              this.runSearch();
              this.showSearch = false;
            })
        }
        .width('100%')
        .padding(12)

        if (this.isListening || this.voiceText.length > 0) {
          Row() {
            Text(this.isListening ? '🎙️ Listening...' : `🎙️ ${this.voiceText}`)
              .fontSize(13)
              .fontColor(this.isListening ? '#E64545' : '#2E7D32')
            if (this.isListening) {
              Blank()
              Button('Stop')
                .fontSize(12)
                .height(28)
                .backgroundColor('#E64545')
                .fontColor(Color.White)
                .onClick(() => {
                  SpeechSearchService.shutdown();
                  this.isListening = false;
                })
            }
          }
          .width('100%')
          .padding(10)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ bottom: 8 })
        }

        ForEach(this.searchResults, (item: Commodity) => {
          Row() {
            Text(item.name).fontSize(15)
            Blank()
            Text(`¥${item.price.toFixed(2)}`).fontSize(14).fontColor('#E64545')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onClick(() => {
            this.showSearch = false;
            this.openDetail(item.id);
          })
        }, (item: Commodity) => item.id.toString())
      }
      .width('90%')
      .padding(14)
      .backgroundColor('#F1F3F5')
      .borderRadius(14)
      .position({ x: '5%', y: '15%' })
      .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 4 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
