import { http } from '@kit.NetworkKit';
import { Commodity } from '../model/Commodity';
import { MockData } from '../data/MockData';
import { Constants } from '../common/Constants';

export class CommodityService {
  static async fetchCommodities(): Promise<Commodity[]> {
    const remote: Commodity[] | null = await CommodityService.tryFetchRemote();
    if (remote !== null && remote.length > 0) {
      return remote;
    }
    return MockData.COMMODITIES;
  }

  static async fetchCommodityById(id: number): Promise<Commodity | undefined> {
    const list: Commodity[] = await CommodityService.fetchCommodities();
    return list.find((item: Commodity): boolean => item.id === id);
  }

  static async searchCommodities(keyword: string): Promise<Commodity[]> {
    const list: Commodity[] = await CommodityService.fetchCommodities();
    const normalized: string = keyword.trim().toLowerCase();
    if (normalized.length === 0) {
      return list;
    }
    return list.filter((item: Commodity): boolean => {
      return item.name.toLowerCase().includes(normalized) ||
        item.flowerLanguage.toLowerCase().includes(normalized) ||
        item.description.toLowerCase().includes(normalized);
    });
  }

  private static async tryFetchRemote(): Promise<Commodity[] | null> {
    try {
      const client: http.HttpRequest = http.createHttp();
      const response: http.HttpResponse = await client.request(
        `${Constants.API_BASE_URL}/commodities`,
        {
          method: http.RequestMethod.GET,
          connectTimeout: 3000,
          readTimeout: 3000,
          header: { 'Content-Type': 'application/json' }
        }
      );
      if (response.responseCode === 200) {
        const body: string = response.result.toString();
        const parsed: Commodity[] = JSON.parse(body) as Commodity[];
        return parsed;
      }
      return null;
    } catch (error) {
      return null;
    }
  }
}
