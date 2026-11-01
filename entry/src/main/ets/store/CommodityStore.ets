import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

const STORE_NAME = 'flower_eshop_store';
const KEY_FAVORITES = 'favorites';
const KEY_HISTORY = 'browse_history';

export class CommodityStore {
  private static async getPrefs(context: common.Context): Promise<dataPreferences.Preferences> {
    return await dataPreferences.getPreferences(context, STORE_NAME);
  }

  static async getFavorites(context: common.Context): Promise<number[]> {
    let prefs = await CommodityStore.getPrefs(context);
    return prefs.getSync(KEY_FAVORITES, [] as number[]) as number[];
  }

  static async isFavorite(context: common.Context, id: number): Promise<boolean> {
    let favorites = await CommodityStore.getFavorites(context);
    return favorites.indexOf(id) >= 0;
  }

  static async toggleFavorite(context: common.Context, id: number): Promise<boolean> {
    let prefs = await CommodityStore.getPrefs(context);
    let favorites = prefs.getSync(KEY_FAVORITES, [] as number[]) as number[];
    let index = favorites.indexOf(id);
    let nowFavorite = false;
    if (index >= 0) {
      favorites.splice(index, 1);
      nowFavorite = false;
    } else {
      favorites.push(id);
      nowFavorite = true;
    }
    await prefs.put(KEY_FAVORITES, favorites);
    await prefs.flush();
    return nowFavorite;
  }

  static async getHistory(context: common.Context): Promise<number[]> {
    let prefs = await CommodityStore.getPrefs(context);
    return prefs.getSync(KEY_HISTORY, [] as number[]) as number[];
  }

  static async addHistory(context: common.Context, id: number): Promise<void> {
    let prefs = await CommodityStore.getPrefs(context);
    let history = prefs.getSync(KEY_HISTORY, [] as number[]) as number[];
    let index = history.indexOf(id);
    if (index >= 0) {
      history.splice(index, 1);
    }
    history.unshift(id);
    if (history.length > 10) {
      history = history.slice(0, 10);
    }
    await prefs.put(KEY_HISTORY, history);
    await prefs.flush();
  }

  static async clearHistory(context: common.Context): Promise<void> {
    let prefs = await CommodityStore.getPrefs(context);
    await prefs.delete(KEY_HISTORY);
    await prefs.flush();
  }
}
