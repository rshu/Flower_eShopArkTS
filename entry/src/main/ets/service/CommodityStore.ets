import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Constants } from '../common/Constants';

export class CommodityStore {
  static async getPrefs(context: common.Context): Promise<preferences.Preferences> {
    return await preferences.getPreferences(context, Constants.PREF_FILE);
  }

  static async getFavorites(context: common.Context): Promise<number[]> {
    const prefs: preferences.Preferences = await CommodityStore.getPrefs(context);
    const raw: preferences.ValueType = await prefs.get(Constants.KEY_FAVORITES, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return [];
    }
    return CommodityStore.parseIdList(raw);
  }

  static async isFavorite(context: common.Context, id: number): Promise<boolean> {
    const favorites: number[] = await CommodityStore.getFavorites(context);
    return favorites.includes(id);
  }

  static async toggleFavorite(context: common.Context, id: number): Promise<boolean> {
    const favorites: number[] = await CommodityStore.getFavorites(context);
    const index: number = favorites.indexOf(id);
    if (index >= 0) {
      favorites.splice(index, 1);
    } else {
      favorites.push(id);
    }
    await CommodityStore.saveFavorites(context, favorites);
    return index < 0;
  }

  static async saveFavorites(context: common.Context, ids: number[]): Promise<void> {
    const prefs: preferences.Preferences = await CommodityStore.getPrefs(context);
    await prefs.put(Constants.KEY_FAVORITES, ids.join(','));
    await prefs.flush();
  }

  static async getHistory(context: common.Context): Promise<number[]> {
    const prefs: preferences.Preferences = await CommodityStore.getPrefs(context);
    const raw: preferences.ValueType = await prefs.get(Constants.KEY_BROWSE_HISTORY, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return [];
    }
    return CommodityStore.parseIdList(raw);
  }

  static async addHistory(context: common.Context, id: number): Promise<number[]> {
    const history: number[] = await CommodityStore.getHistory(context);
    const existing: number = history.indexOf(id);
    if (existing >= 0) {
      history.splice(existing, 1);
    }
    history.unshift(id);
    if (history.length > Constants.MAX_HISTORY) {
      history.length = Constants.MAX_HISTORY;
    }
    const prefs: preferences.Preferences = await CommodityStore.getPrefs(context);
    await prefs.put(Constants.KEY_BROWSE_HISTORY, history.join(','));
    await prefs.flush();
    return history;
  }

  static async clearHistory(context: common.Context): Promise<void> {
    const prefs: preferences.Preferences = await CommodityStore.getPrefs(context);
    await prefs.put(Constants.KEY_BROWSE_HISTORY, '');
    await prefs.flush();
  }

  private static parseIdList(raw: string): number[] {
    const parts: string[] = raw.split(',');
    const result: number[] = [];
    for (let i = 0; i < parts.length; i++) {
      const value: number = Number(parts[i]);
      if (!Number.isNaN(value) && parts[i].length > 0) {
        result.push(value);
      }
    }
    return result;
  }
}
