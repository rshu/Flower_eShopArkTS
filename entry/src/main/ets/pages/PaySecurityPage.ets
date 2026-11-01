import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import { SecurePayService } from '../service/SecurePayService';

@Entry
@Component
struct PaySecurityPage {
  @State hasPassword: boolean = false;
  @State inputPwd: string = '';

  aboutToAppear(): void {
    this.refreshStatus();
  }

  abilityCtx(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  toast(msg: string): void {
    promptAction.showToast({ message: msg });
  }

  refreshStatus(): void {
    SecurePayService.hasPassword(this.abilityCtx()).then((has: boolean) => {
      this.hasPassword = has;
    });
  }

  isValidPwd(s: string): boolean {
    if (s.length !== 6) {
      return false;
    }
    for (let i = 0; i < s.length; i++) {
      let c = s.charCodeAt(i);
      if (c < 48 || c > 57) {
        return false;
      }
    }
    return true;
  }

  setPassword(): void {
    if (!this.isValidPwd(this.inputPwd)) {
      this.toast('请输入6位数字支付密码');
      return;
    }
    SecurePayService.savePassword(this.abilityCtx(), this.inputPwd).then(() => {
      this.hasPassword = true;
      this.inputPwd = '';
      this.toast('支付密码已设置');
    }).catch(() => {
      this.toast('设置失败，请重试');
    });
  }

  verifyPassword(): void {
    if (!this.isValidPwd(this.inputPwd)) {
      this.toast('请输入6位数字支付密码');
      return;
    }
    SecurePayService.verifyPassword(this.abilityCtx(), this.inputPwd).then((ok: boolean) => {
      this.inputPwd = '';
      this.toast(ok ? '密码验证成功' : '密码错误');
    }).catch(() => {
      this.toast('验证失败，请重试');
    });
  }

  clearPassword(): void {
    SecurePayService.clearPassword(this.abilityCtx()).then(() => {
      this.hasPassword = false;
      this.inputPwd = '';
      this.toast('已清除支付密码');
    }).catch(() => {
      this.toast('清除失败，请重试');
    });
  }

  build() {
    Column() {
      this.topBar()
      Scroll() {
        Column() {
          Text(this.hasPassword ? '支付密码：已设置' : '支付密码：未设置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          TextInput({ text: this.inputPwd, placeholder: '请输入6位数字支付密码' })
            .type(InputType.Password)
            .maxLength(6)
            .fontSize(16)
            .width('100%')
            .margin({ top: 16 })
            .onChange((value: string) => {
              this.inputPwd = value;
            })

          Button('设置 / 更新密码')
            .width('100%')
            .height(44)
            .fontSize(15)
            .margin({ top: 16 })
            .backgroundColor('#E53935')
            .onClick(() => this.setPassword())

          Button('验证密码')
            .width('100%')
            .height(44)
            .fontSize(15)
            .margin({ top: 12 })
            .backgroundColor('#FFB74D')
            .onClick(() => this.verifyPassword())

          Button('清除密码')
            .width('100%')
            .height(44)
            .fontSize(15)
            .margin({ top: 12 })
            .backgroundColor('#90A4AE')
            .onClick(() => this.clearPassword())

          Button('生物认证（指纹 / 人脸）')
            .width('100%')
            .height(44)
            .fontSize(15)
            .margin({ top: 12 })
            .backgroundColor('#5C6BC0')
            .onClick(() => this.toast('生物认证需 User Auth Kit，暂未接入'))

          Text('密码采用 AES-CBC 加密后存储于本地，用于下单支付验证。')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .margin({ top: 16 })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  topBar() {
    Row() {
      Text('←')
        .fontSize(22)
        .padding({ right: 8 })
        .onClick(() => router.back())
      Text('支付安全')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }
}
