import { Commodity } from '../model/Commodity';
import { CommodityService } from './CommodityService';

export class VoiceSearchService {
  static async searchByKeyword(keyword: string): Promise<Commodity[]> {
    return await CommodityService.searchCommodities(keyword);
  }
}
