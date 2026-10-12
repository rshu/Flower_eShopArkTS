import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { AuthService, AuthProfile, LoginResult } from '../service/AuthService';

@Entry
@Component
struct PersonalPage {
  @State profile: AuthProfile | null = null;
  @State isLoggingIn: boolean = false;

  private context(): common.Context {
    return getContext(this) as common.Context;
  }

  aboutToAppear(): void {
    AuthService.loadProfile(this.context()).then((profile: AuthProfile | null) => {
      this.profile = profile;
    });
  }

  private login(): void {
    this.isLoggingIn = true;
    AuthService.login(this.context()).then((result: LoginResult | null) => {
      this.isLoggingIn = false;
      if (result === null) {
        this.showToast('Login failed. Huawei account requires AGC configuration.');
        return;
      }
      this.profile = result.profile;
      AuthService.saveProfile(this.context(), result.profile).then(() => {});
      if (result.mode === 'huawei') {
        this.showToast('Logged in with Huawei account as ' + result.profile.displayName);
      } else {
        this.showToast('AGC not configured, using demo profile: ' + result.profile.displayName);
      }
    });
  }

  private logout(): void {
    AuthService.logout(this.context()).then(() => {
      this.profile = null;
      this.showToast('Logged out');
    });
  }

  private openPaySecurity(): void {
    router.pushUrl({ url: 'pages/PaySecurityPage', params: { mode: 'manage' } });
  }

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  @Builder
  MenuRow(icon: string, title: string, action: () => void) {
    Row() {
      Text(icon).fontSize(20)
      Text(title)
        .fontSize(15)
        .margin({ left: 12 })
      Blank()
      Text('›')
        .fontSize(20)
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .borderRadius(10)
    .onClick(() => action())
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .fontSize(22)
          .backgroundColor('#00000000')
          .onClick(() => router.back())
        Text('My account')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 8, right: 16 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          Column() {
            Stack({ alignContent: Alignment.Center }) {
              Text('👤')
                .fontSize(56)
              if (this.profile !== null && this.profile!.avatarUrl.length > 0) {
                Image(this.profile!.avatarUrl)
                  .width(72)
                  .height(72)
                  .borderRadius(36)
                  .objectFit(ImageFit.Cover)
              }
            }
            .width(72)
            .height(72)

            if (this.profile === null) {
              Text('Not logged in')
                .fontSize(16)
                .fontColor('#999999')
                .margin({ top: 12 })
              Button(this.isLoggingIn ? 'Signing in...' : 'Sign in with Huawei account')
                .fontSize(15)
                .margin({ top: 16 })
                .enabled(!this.isLoggingIn)
                .onClick(() => this.login())
            } else {
              Text(this.profile!.displayName)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 12 })
              Button('Sign out')
                .fontSize(13)
                .fontColor('#666666')
                .backgroundColor('#00000000')
                .margin({ top: 4 })
                .onClick(() => this.logout())
            }
          }
          .width('100%')
          .padding(24)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Center)

          Column({ space: 12 }) {
            this.MenuRow('🔒', 'Payment security', () => this.openPaySecurity())
            this.MenuRow('📦', 'My orders', () => this.showToast('Orders are reserved for future releases'))
            this.MenuRow('⚙️', 'Settings', () => this.showToast('Settings are reserved for future releases'))
          }
          .width('100%')
          .margin({ top: 16 })

          Text('Huawei account login and map features require AppGallery Connect registration (Client ID and API keys).')
            .fontSize(11)
            .fontColor('#999999')
            .width('100%')
            .padding(16)
        }
        .width('100%')
        .padding(12)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}
