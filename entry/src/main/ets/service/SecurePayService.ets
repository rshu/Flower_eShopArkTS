import cryptoFramework from '@ohos.security.cryptoFramework';
import dataPreferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

const PAY_PREFS = 'flower_eshop_pay';
const KEY_CIPHER = 'pwd_cipher';
const KEY_IV = 'pwd_iv';
const KEY_AES = 'pwd_aes_key';

export class SecurePayService {
  private static async getPrefs(context: common.Context): Promise<dataPreferences.Preferences> {
    return await dataPreferences.getPreferences(context, PAY_PREFS);
  }

  static async hasPassword(context: common.Context): Promise<boolean> {
    let prefs = await SecurePayService.getPrefs(context);
    let cipher = prefs.getSync(KEY_CIPHER, '') as string;
    return cipher.length > 0;
  }

  static async savePassword(context: common.Context, pwd: string): Promise<void> {
    let key = await SecurePayService.generateKey();
    let keyBlob = key.getEncoded();
    let base64 = new util.Base64Helper();
    let keyB64 = base64.encodeToStringSync(keyBlob.data);

    let random = cryptoFramework.createRandom();
    let ivBlob = await random.generateRandom(16);
    let ivB64 = base64.encodeToStringSync(ivBlob.data);

    let cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
    let ivParams: cryptoFramework.IvParamsSpec = {
      algName: 'IvParamsSpec',
      iv: { data: ivBlob.data }
    };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, ivParams);
    let plain = SecurePayService.strToBytes(pwd);
    let encrypted = await cipher.doFinal({ data: plain });
    let cipherB64 = base64.encodeToStringSync(encrypted.data);

    let prefs = await SecurePayService.getPrefs(context);
    await prefs.put(KEY_AES, keyB64);
    await prefs.put(KEY_IV, ivB64);
    await prefs.put(KEY_CIPHER, cipherB64);
    await prefs.flush();
  }

  static async verifyPassword(context: common.Context, pwd: string): Promise<boolean> {
    let prefs = await SecurePayService.getPrefs(context);
    let keyB64 = prefs.getSync(KEY_AES, '') as string;
    let ivB64 = prefs.getSync(KEY_IV, '') as string;
    let cipherB64 = prefs.getSync(KEY_CIPHER, '') as string;
    if (keyB64.length === 0 || ivB64.length === 0 || cipherB64.length === 0) {
      return false;
    }

    let base64 = new util.Base64Helper();
    let keyBytes = base64.decodeSync(keyB64);
    let ivBytes = base64.decodeSync(ivB64);
    let cipherBytes = base64.decodeSync(cipherB64);

    let keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    let key = await keyGenerator.convertKey({ data: keyBytes });
    let cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
    let ivParams: cryptoFramework.IvParamsSpec = {
      algName: 'IvParamsSpec',
      iv: { data: ivBytes }
    };
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, ivParams);
    let decrypted = await cipher.doFinal({ data: cipherBytes });
    let stored = SecurePayService.bytesToStr(decrypted.data);
    return stored === pwd;
  }

  static async clearPassword(context: common.Context): Promise<void> {
    let prefs = await SecurePayService.getPrefs(context);
    await prefs.delete(KEY_AES);
    await prefs.delete(KEY_IV);
    await prefs.delete(KEY_CIPHER);
    await prefs.flush();
  }

  private static async generateKey(): Promise<cryptoFramework.SymKey> {
    let keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    return await keyGenerator.generateSymKey();
  }

  private static strToBytes(s: string): Uint8Array {
    let bytes = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i++) {
      bytes[i] = s.charCodeAt(i);
    }
    return bytes;
  }

  private static bytesToStr(b: Uint8Array): string {
    let s = '';
    for (let i = 0; i < b.length; i++) {
      s += String.fromCharCode(b[i]);
    }
    return s;
  }
}
