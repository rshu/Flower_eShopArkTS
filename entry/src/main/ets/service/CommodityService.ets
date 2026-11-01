import { Commodity, MOCK_COMMODITIES } from '../model/Commodity';

export class CommodityService {
  static async fetchCommodities(): Promise<Commodity[]> {
    try {
      return await CommodityService.requestFromNetwork();
    } catch (e) {
      return CommodityService.getLocalCache();
    }
  }

  static async fetchCommodityDetail(id: number): Promise<Commodity | undefined> {
    let list = await CommodityService.fetchCommodities();
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === id) {
        return list[i];
      }
    }
    return undefined;
  }

  static getLocalCache(): Commodity[] {
    return MOCK_COMMODITIES;
  }

  private static async requestFromNetwork(): Promise<Commodity[]> {
    // 真实实现应使用 @ohos.net.http 请求 GET /api/commodities。
    // 此处模拟网络请求失败，以触发本地 mock 降级，保证应用可用性。
    await CommodityService.delay(400);
    throw new Error('network unavailable, fallback to local mock');
  }

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, ms);
    });
  }
}
