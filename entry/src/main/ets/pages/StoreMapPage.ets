import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { MapComponent, mapCommon, map } from '@kit.MapKit';
import { Store } from '../model/Commodity';
import { MockData } from '../data/MockData';
import { FlowerLocationService, LocationResult } from '../service/FlowerLocationService';

class StoreDistance {
  store: Store;
  distanceKm: number;

  constructor(store: Store, distanceKm: number) {
    this.store = store;
    this.distanceKm = distanceKm;
  }
}

const TILE_MAP_TIMEOUT_MS: number = 8000;
const DEMO_LOCATION: LocationResult = { latitude: 22.4243, longitude: 114.2125, time: 0 };

@Entry
@Component
struct StoreMapPage {
  @State locationText: string = '';
  @State stores: StoreDistance[] = [];
  @State selectedStore: Store | undefined = undefined;
  @State currentLocation: LocationResult | null = null;
  @State mapReady: boolean = false;
  @State useTileMap: boolean = true;
  private mapController: map.MapComponentController | undefined = undefined;
  private mapOptions: mapCommon.MapOptions = {
    position: {
      target: {
        latitude: MockData.STORES.length > 0 ? MockData.STORES[0].latitude : 22.4243,
        longitude: MockData.STORES.length > 0 ? MockData.STORES[0].longitude : 114.2125
      },
      zoom: 14
    },
    zoomControlsEnabled: true
  };
  private mapCallback: (err: BusinessError, controller: map.MapComponentController) => void =
    (err: BusinessError, controller: map.MapComponentController): void => {
      if (err) {
        console.error(`Map init failed: ${err.code} ${err.message}`);
        this.useTileMap = false;
        return;
      }
      this.mapController = controller;
      const eventManager: map.MapEventManager = controller.getEventManager();
      eventManager.on('mapLoad', (): void => {
        this.addMarkersToMap();
      });
      eventManager.on('error', (): void => {
        this.useTileMap = false;
      });
      this.addMarkersToMap();
    };
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private context(): common.Context {
    return getContext(this) as common.Context;
  }

  aboutToAppear(): void {
    this.requestLocationAndLoad();
    this.scheduleTileMapFallback();
  }

  private scheduleTileMapFallback(): void {
    setTimeout((): void => {
      if (this.useTileMap && this.mapController === undefined) {
        console.warn('Tile map did not initialize; falling back to canvas map.');
        this.useTileMap = false;
      }
    }, TILE_MAP_TIMEOUT_MS);
  }

  private addMarkersToMap(): void {
    if (this.mapController === undefined) {
      return;
    }
    for (let i = 0; i < MockData.STORES.length; i++) {
      const store: Store = MockData.STORES[i];
      const options: mapCommon.MarkerOptions = {
        position: {
          latitude: store.latitude,
          longitude: store.longitude
        },
        title: store.name,
        snippet: store.address,
        clickable: true
      };
      this.mapController.addMarker(options).catch((err: BusinessError) => {
        console.error(`addMarker failed: ${err.code} ${err.message}`);
      });
    }
  }

  private requestLocationAndLoad(): void {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
    atManager.requestPermissionsFromUser(this.context(), permissions).then(() => {
      this.loadStores();
    }).catch(() => {
      this.showToast('Location permission denied. Showing store list without distance.');
      this.loadStores();
    });
  }

  private loadStores(): void {
    FlowerLocationService.getCurrentLocation().then((current: LocationResult | null) => {
      if (current === null) {
        this.locationText = 'Demo location (22.4243, 114.2125)';
        current = DEMO_LOCATION;
      } else {
        this.locationText = `${current.latitude.toFixed(4)}, ${current.longitude.toFixed(4)}`;
      }
      this.mapOptions = {
        position: {
          target: {
            latitude: current.latitude,
            longitude: current.longitude
          },
          zoom: 14
        },
        zoomControlsEnabled: true
      };
      this.currentLocation = current;
      this.buildStoreList(current);
    });
  }

  private buildStoreList(location: LocationResult | null): void {
    const result: StoreDistance[] = [];
    for (let i = 0; i < MockData.STORES.length; i++) {
      const store: Store = MockData.STORES[i];
      let distanceKm: number = -1;
      if (location !== null) {
        distanceKm = this.haversineKm(location.latitude, location.longitude, store.latitude, store.longitude);
      }
      result.push(new StoreDistance(store, distanceKm));
    }
    result.sort((a: StoreDistance, b: StoreDistance): number => {
      return a.distanceKm - b.distanceKm;
    });
    this.stores = result;
    if (this.mapReady) {
      this.drawMap();
    }
  }

  private drawMap(): void {
    const width: number = this.ctx.width;
    const height: number = this.ctx.height;
    this.ctx.clearRect(0, 0, width, height);

    this.ctx.fillStyle = '#EAF2EF';
    this.ctx.fillRect(0, 0, width, height);

    this.ctx.strokeStyle = '#C9DBD4';
    this.ctx.lineWidth = 1;
    const step: number = 40;
    for (let x = 0; x <= width; x += step) {
      this.ctx.beginPath();
      this.ctx.moveTo(x, 0);
      this.ctx.lineTo(x, height);
      this.ctx.stroke();
    }
    for (let y = 0; y <= height; y += step) {
      this.ctx.beginPath();
      this.ctx.moveTo(0, y);
      this.ctx.lineTo(width, y);
      this.ctx.stroke();
    }

    if (MockData.STORES.length === 0) {
      return;
    }

    let minLat: number = MockData.STORES[0].latitude;
    let maxLat: number = MockData.STORES[0].latitude;
    let minLon: number = MockData.STORES[0].longitude;
    let maxLon: number = MockData.STORES[0].longitude;
    for (let i = 0; i < MockData.STORES.length; i++) {
      const s: Store = MockData.STORES[i];
      if (s.latitude < minLat) {
        minLat = s.latitude;
      }
      if (s.latitude > maxLat) {
        maxLat = s.latitude;
      }
      if (s.longitude < minLon) {
        minLon = s.longitude;
      }
      if (s.longitude > maxLon) {
        maxLon = s.longitude;
      }
    }
    const padLat: number = (maxLat - minLat) * 0.1 + 0.0005;
    const padLon: number = (maxLon - minLon) * 0.1 + 0.0005;
    minLat -= padLat;
    maxLat += padLat;
    minLon -= padLon;
    maxLon += padLon;

    const toX = (lon: number): number => ((lon - minLon) / (maxLon - minLon)) * (width - 40) + 20;
    const toY = (lat: number): number => height - (((lat - minLat) / (maxLat - minLat)) * (height - 40) + 20);

    if (this.currentLocation !== null) {
      this.ctx.fillStyle = '#1E88E5';
      this.ctx.beginPath();
      this.ctx.arc(toX(this.currentLocation.longitude), toY(this.currentLocation.latitude), 6, 0, Math.PI * 2);
      this.ctx.fill();
      this.ctx.fillStyle = '#0D47A1';
      this.ctx.font = '10px sans-serif';
      this.ctx.fillText('You', toX(this.currentLocation.longitude) + 8, toY(this.currentLocation.latitude) - 8);
    }

    for (let i = 0; i < MockData.STORES.length; i++) {
      const s: Store = MockData.STORES[i];
      const x: number = toX(s.longitude);
      const y: number = toY(s.latitude);
      this.ctx.fillStyle = '#E64545';
      this.ctx.beginPath();
      this.ctx.arc(x, y, 7, 0, Math.PI * 2);
      this.ctx.fill();
      this.ctx.fillStyle = '#333333';
      this.ctx.font = '11px sans-serif';
      this.ctx.fillText(s.name, x + 10, y + 4);
    }
  }

  private haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const rad = Math.PI / 180;
    const dLat = (lat2 - lat1) * rad;
    const dLon = (lon2 - lon1) * rad;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return 6371 * c;
  }

  private distanceLabel(store: StoreDistance): string {
    if (store.distanceKm < 0) {
      return 'distance unknown';
    }
    if (store.distanceKm < 1) {
      return `${Math.round(store.distanceKm * 1000)} m`;
    }
    return `${store.distanceKm.toFixed(1)} km`;
  }

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration:2000 });
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button('←')
            .fontSize(22)
            .backgroundColor('#00000000')
            .onClick(() => router.back())
          Text('Nearby stores')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(52)
        .padding({ left: 8, right: 16 })
        .backgroundColor(Color.White)

        Column() {
          Row() {
            Text('📍')
              .fontSize(18)
            Text(this.locationText.length > 0 ? this.locationText : 'Locating...')
              .fontSize(14)
              .fontColor('#2E7D32')
              .margin({ left: 6 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#E8F5E9')
          .borderRadius(10)

          if (this.useTileMap) {
            MapComponent({
              mapOptions: this.mapOptions,
              mapCallback: this.mapCallback
            })
              .width('100%')
              .height(240)
              .borderRadius(10)
              .margin({ top: 8 })
          } else {
            Canvas(this.ctx)
              .width('100%')
              .height(240)
              .backgroundColor('#EAF2EF')
              .borderRadius(10)
              .margin({ top: 8 })
              .onReady(() => {
                this.mapReady = true;
                this.drawMap();
              })
          }

          Text(this.useTileMap
            ? 'Live map tiles (falls back to a local map if the Map service is unavailable).'
            : 'Local store map. Tap a store below for details.')
            .fontSize(11)
            .fontColor('#888888')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding(12)

        List({ space: 12 }) {
          ForEach(this.stores, (item: StoreDistance) => {
            ListItem() {
              Column() {
                Row() {
                  Text('🏪').fontSize(28)
                  Column() {
                    Text(item.store.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                    Text(item.store.address)
                      .fontSize(13)
                      .fontColor('#666666')
                      .margin({ top: 4 })
                    Text(`📞 ${item.store.phone}`)
                      .fontSize(13)
                      .fontColor('#1565C0')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: 10 })

                  Text(this.distanceLabel(item))
                    .fontSize(13)
                    .fontColor('#E65100')
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }
              .width('100%')
              .padding(14)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onClick(() => {
                this.selectedStore = item.store;
              })
            }
          }, (item: StoreDistance) => item.store.id.toString())
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 12 })
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F1F3F5')

      if (this.selectedStore !== undefined) {
        Column() {
          Text(this.selectedStore!.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text(this.selectedStore!.address)
            .fontSize(14)
            .fontColor('#333333')
            .margin({ top: 8 })
          Text(`Phone: ${this.selectedStore!.phone}`)
            .fontSize(14)
            .fontColor('#1565C0')
            .margin({ top: 8 })
          Button('Close')
            .margin({ top: 16 })
            .width('100%')
            .onClick(() => {
              this.selectedStore = undefined;
            })
        }
        .width('80%')
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .position({ x: '10%', y: '30%' })
        .shadow({ radius: 20, color: '#33000000', offsetX: 0, offsetY: 4 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
