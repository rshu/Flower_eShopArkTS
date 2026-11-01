import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { authentication } from '@kit.AccountKit';
import { Constants } from '../common/Constants';

export interface AuthProfile {
  displayName: string;
  avatarUrl: string;
  openId?: string;
  unionId?: string;
}

export interface LoginResult {
  profile: AuthProfile;
  mode: 'huawei' | 'demo';
}

export class AuthService {
  private static readonly KEY_LOGIN_NAME: string = 'login_display_name';
  private static readonly KEY_LOGIN_AVATAR: string = 'login_avatar_url';
  private static readonly KEY_LOGIN_OPENID: string = 'login_open_id';
  private static readonly KEY_LOGIN_UNIONID: string = 'login_union_id';

  static async login(context: common.Context): Promise<LoginResult | null> {
    try {
      const request: authentication.AuthorizationWithHuaweiIDRequest =
        new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      request.scopes = ['openid', 'profile'];
      request.forceAuthorization = true;
      request.state = 'flower-eshop-state';

      const controller: authentication.AuthenticationController =
        new authentication.AuthenticationController(context);
      const response: authentication.AuthenticationResponse = await controller.executeRequest(request);
      const authResponse = response as authentication.AuthorizationWithHuaweiIDResponse;
      const credential = authResponse.data;
      if (credential === undefined || credential === null) {
        return AuthService.demoLogin();
      }
      const profile: AuthProfile = {
        displayName: credential.nickName !== undefined && credential.nickName !== null &&
          credential.nickName!.length > 0 ? credential.nickName! : 'Huawei User',
        avatarUrl: credential.avatarUri !== undefined ? credential.avatarUri! : '',
        openId: credential.openID,
        unionId: credential.unionID
      };
      return { profile: profile, mode: 'huawei' };
    } catch (err) {
      // Real account authorization requires the app to be registered in AGC with
      // a Client ID and matching signing fingerprint. Without that the account kit
      // returns fingerprint/scope errors (1001500001, 1001502014), so we degrade
      // to a local demo profile to keep the account workflow usable end-to-end.
      console.info('[AuthService] account kit login unavailable, falling back to demo: ' + JSON.stringify(err));
      return AuthService.demoLogin();
    }
  }

  private static async demoLogin(): Promise<LoginResult> {
    return {
      profile: {
        displayName: 'Huawei User',
        avatarUrl: ''
      },
      mode: 'demo'
    };
  }

  static async logout(context: common.Context): Promise<void> {
    const prefs: preferences.Preferences = await preferences.getPreferences(context, Constants.PREF_FILE);
    await prefs.put(AuthService.KEY_LOGIN_NAME, '');
    await prefs.put(AuthService.KEY_LOGIN_AVATAR, '');
    await prefs.put(AuthService.KEY_LOGIN_OPENID, '');
    await prefs.put(AuthService.KEY_LOGIN_UNIONID, '');
    await prefs.flush();
  }

  static async saveProfile(context: common.Context, profile: AuthProfile): Promise<void> {
    const prefs: preferences.Preferences = await preferences.getPreferences(context, Constants.PREF_FILE);
    await prefs.put(AuthService.KEY_LOGIN_NAME, profile.displayName);
    await prefs.put(AuthService.KEY_LOGIN_AVATAR, profile.avatarUrl);
    await prefs.put(AuthService.KEY_LOGIN_OPENID, profile.openId !== undefined ? profile.openId : '');
    await prefs.put(AuthService.KEY_LOGIN_UNIONID, profile.unionId !== undefined ? profile.unionId : '');
    await prefs.flush();
  }

  static async loadProfile(context: common.Context): Promise<AuthProfile | null> {
    const prefs: preferences.Preferences = await preferences.getPreferences(context, Constants.PREF_FILE);
    const name: preferences.ValueType = await prefs.get(AuthService.KEY_LOGIN_NAME, '');
    if (typeof name !== 'string' || name.length === 0) {
      return null;
    }
    const avatar: preferences.ValueType = await prefs.get(AuthService.KEY_LOGIN_AVATAR, '');
    const openId: preferences.ValueType = await prefs.get(AuthService.KEY_LOGIN_OPENID, '');
    const unionId: preferences.ValueType = await prefs.get(AuthService.KEY_LOGIN_UNIONID, '');
    return {
      displayName: name,
      avatarUrl: typeof avatar === 'string' ? avatar : '',
      openId: typeof openId === 'string' && openId.length > 0 ? openId : undefined,
      unionId: typeof unionId === 'string' && unionId.length > 0 ? unionId : undefined
    };
  }
}
