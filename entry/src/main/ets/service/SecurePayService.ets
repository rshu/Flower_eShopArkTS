import { asset } from '@kit.AssetStoreKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { Constants } from '../common/Constants';

export class SecurePayService {
  static async hasPassword(): Promise<boolean> {
    try {
      const result: Array<Map<asset.Tag, asset.Value>> =
        await asset.query(SecurePayService.aliasQuery(Constants.ASSET_ALIAS));
      return result.length > 0;
    } catch (error) {
      return false;
    }
  }

  static async setPassword(password: string): Promise<void> {
    const keyGenerator: cryptoFramework.SymKeyGenerator =
      cryptoFramework.createSymKeyGenerator(Constants.AES_ALG_NAME);
    const key: cryptoFramework.SymKey = await keyGenerator.generateSymKey();
    const keyBlob: cryptoFramework.DataBlob = key.getEncoded();
    const encrypted: Uint8Array = await SecurePayService.encrypt(password, key);

    await SecurePayService.removeAsset(Constants.ASSET_ALIAS);
    await SecurePayService.removeAsset(Constants.ASSET_ALIAS_KEY);

    const keyMap: Map<asset.Tag, asset.Value> = new Map<asset.Tag, asset.Value>();
    keyMap.set(asset.Tag.ALIAS, SecurePayService.stringToBytes(Constants.ASSET_ALIAS_KEY));
    keyMap.set(asset.Tag.SECRET, keyBlob.data);
    await asset.add(keyMap);

    const passwordMap: Map<asset.Tag, asset.Value> = new Map<asset.Tag, asset.Value>();
    passwordMap.set(asset.Tag.ALIAS, SecurePayService.stringToBytes(Constants.ASSET_ALIAS));
    passwordMap.set(asset.Tag.SECRET, encrypted);
    await asset.add(passwordMap);
  }

  static async verifyPassword(input: string): Promise<boolean> {
    const keyBytes: Uint8Array | null = await SecurePayService.readSecret(Constants.ASSET_ALIAS_KEY);
    const cipherBytes: Uint8Array | null = await SecurePayService.readSecret(Constants.ASSET_ALIAS);
    if (keyBytes === null || cipherBytes === null) {
      return false;
    }
    const keyGenerator: cryptoFramework.SymKeyGenerator =
      cryptoFramework.createSymKeyGenerator(Constants.AES_ALG_NAME);
    const keyBlob: cryptoFramework.DataBlob = { data: keyBytes };
    const key: cryptoFramework.SymKey = await keyGenerator.convertKey(keyBlob);
    const decrypted: string = await SecurePayService.decrypt(cipherBytes, key);
    return decrypted === input;
  }

  static async clearPassword(): Promise<void> {
    await SecurePayService.removeAsset(Constants.ASSET_ALIAS);
    await SecurePayService.removeAsset(Constants.ASSET_ALIAS_KEY);
  }

  private static async encrypt(plain: string, key: cryptoFramework.SymKey): Promise<Uint8Array> {
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher(Constants.AES_CIPHER_TRANSFORMATION);
    const ivParams: cryptoFramework.IvParamsSpec = {
      algName: 'IvParamsSpec',
      iv: { data: SecurePayService.stringToBytes(Constants.AES_IV) }
    };
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, ivParams);
    const input: cryptoFramework.DataBlob = { data: SecurePayService.stringToBytes(plain) };
    const output: cryptoFramework.DataBlob = await cipher.doFinal(input);
    return output.data;
  }

  private static async decrypt(cipherBytes: Uint8Array, key: cryptoFramework.SymKey): Promise<string> {
    const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher(Constants.AES_CIPHER_TRANSFORMATION);
    const ivParams: cryptoFramework.IvParamsSpec = {
      algName: 'IvParamsSpec',
      iv: { data: SecurePayService.stringToBytes(Constants.AES_IV) }
    };
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, ivParams);
    const input: cryptoFramework.DataBlob = { data: cipherBytes };
    const output: cryptoFramework.DataBlob = await cipher.doFinal(input);
    return SecurePayService.bytesToString(output.data);
  }

  private static async readSecret(alias: string): Promise<Uint8Array | null> {
    try {
      const result: Array<Map<asset.Tag, asset.Value>> =
        await asset.query(SecurePayService.aliasQuery(alias));
      if (result.length === 0) {
        return null;
      }
      const value: asset.Value | undefined = result[0].get(asset.Tag.SECRET);
      if (value === undefined || !(value instanceof Uint8Array)) {
        return null;
      }
      return value;
    } catch (error) {
      return null;
    }
  }

  private static async removeAsset(alias: string): Promise<void> {
    try {
      await asset.remove(SecurePayService.aliasQuery(alias));
    } catch (error) {
      // Ignore: asset may not exist yet.
    }
  }

  private static aliasQuery(alias: string): Map<asset.Tag, asset.Value> {
    const query: Map<asset.Tag, asset.Value> = new Map<asset.Tag, asset.Value>();
    query.set(asset.Tag.ALIAS, SecurePayService.stringToBytes(alias));
    return query;
  }

  private static stringToBytes(value: string): Uint8Array {
    const bytes: number[] = [];
    for (let i = 0; i < value.length; i++) {
      const code: number = value.charCodeAt(i);
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xC0 | (code >> 6), 0x80 | (code & 0x3F));
      } else {
        bytes.push(0xE0 | (code >> 12), 0x80 | ((code >> 6) & 0x3F), 0x80 | (code & 0x3F));
      }
    }
    return new Uint8Array(bytes);
  }

  private static bytesToString(bytes: Uint8Array): string {
    let result: string = '';
    let i: number = 0;
    while (i < bytes.length) {
      const code: number = bytes[i];
      if (code < 0x80) {
        result += String.fromCharCode(code);
        i += 1;
      } else if (code < 0xE0) {
        const codePoint: number = ((code & 0x1F) << 6) | (bytes[i + 1] & 0x3F);
        result += String.fromCharCode(codePoint);
        i += 2;
      } else {
        const codePoint: number = ((code & 0x0F) << 12) | ((bytes[i + 1] & 0x3F) << 6) | (bytes[i + 2] & 0x3F);
        result += String.fromCharCode(codePoint);
        i += 3;
      }
    }
    return result;
  }
}
