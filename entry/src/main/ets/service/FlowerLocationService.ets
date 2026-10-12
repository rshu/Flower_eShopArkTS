import { geoLocationManager } from '@kit.LocationKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { Constants } from '../common/Constants';

export interface LocationResult {
  latitude: number;
  longitude: number;
  time: number;
}

export class FlowerLocationService {
  static isLocationEnabled(): boolean {
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (error) {
      return false;
    }
  }

  static async getCurrentLocation(): Promise<LocationResult | null> {
    if (!FlowerLocationService.isLocationEnabled()) {
      return null;
    }
    try {
      const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation();
      return {
        latitude: location.latitude,
        longitude: location.longitude,
        time: Date.now()
      };
    } catch (error) {
      return null;
    }
  }

  static async getLastLocation(): Promise<LocationResult | null> {
    try {
      const location: geoLocationManager.Location = geoLocationManager.getLastLocation();
      if (location === undefined) {
        return null;
      }
      return {
        latitude: location.latitude,
        longitude: location.longitude,
        time: Date.now()
      };
    } catch (error) {
      return null;
    }
  }

  static async saveLastLocation(context: common.Context, result: LocationResult): Promise<void> {
    const prefs: preferences.Preferences = await preferences.getPreferences(context, Constants.PREF_FILE);
    await prefs.put(Constants.KEY_LAST_LOCATION, `${result.latitude},${result.longitude}`);
    await prefs.put(Constants.KEY_LAST_LOCATION_TIME, result.time);
    await prefs.flush();
  }

  static async loadLastLocation(context: common.Context): Promise<LocationResult | null> {
    const prefs: preferences.Preferences = await preferences.getPreferences(context, Constants.PREF_FILE);
    const raw: preferences.ValueType = await prefs.get(Constants.KEY_LAST_LOCATION, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return null;
    }
    const parts: string[] = raw.split(',');
    if (parts.length < 2) {
      return null;
    }
    return {
      latitude: Number(parts[0]),
      longitude: Number(parts[1]),
      time: Date.now()
    };
  }
}
