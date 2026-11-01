export class Constants {
  static readonly PREF_FILE: string = 'flower_eshop_prefs';
  static readonly KEY_FAVORITES: string = 'favorites';
  static readonly KEY_BROWSE_HISTORY: string = 'browse_history';
  static readonly KEY_COMMODITY_CACHE: string = 'commodity_cache';
  static readonly KEY_HAS_PAY_PASSWORD: string = 'has_pay_password';
  static readonly KEY_LAST_LOCATION: string = 'last_location';
  static readonly KEY_LAST_LOCATION_TIME: string = 'last_location_time';

  static readonly ASSET_ALIAS: string = 'flower_pay_password';
  static readonly ASSET_ALIAS_KEY: string = 'flower_aes_key';

  static readonly MAX_HISTORY: number = 10;

  static readonly API_BASE_URL: string = 'https://flower-eshop.example.com/api';

  static readonly NOTIFICATION_ID_PAY: number = 1001;
  static readonly NOTIFICATION_ID_PROMOTION: number = 1002;

  static readonly AES_ALG_NAME: string = 'AES256';
  static readonly AES_CIPHER_TRANSFORMATION: string = 'AES256|CBC|PKCS5';
  static readonly AES_IV: string = '0123456789abcdef';

  static readonly PAY_PASSWORD_LENGTH: number = 6;
}
