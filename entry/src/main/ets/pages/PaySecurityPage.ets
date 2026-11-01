import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { userAuth } from '@kit.UserAuthenticationKit';
import { SecurePayService } from '../service/SecurePayService';
import { Constants } from '../common/Constants';

class PayParams {
  mode: string = 'manage';
  commodityName: string = '';
  price: number = 0;
  orderId: string = '';
}

@Entry
@Component
struct PaySecurityPage {
  @State mode: string = 'manage';
  @State commodityName: string = '';
  @State price: number = 0;
  @State orderId: string = '';
  @State hasPassword: boolean = false;
  @State newPassword: string = '';
  @State confirmPassword: string = '';
  @State verifyInput: string = '';
  @State payInput: string = '';
  @State paySuccess: boolean = false;

  private context(): common.Context {
    return getContext(this) as common.Context;
  }

  aboutToAppear(): void {
    const params: PayParams = router.getParams() as PayParams;
    if (params !== undefined && params !== null) {
      if (params.mode === 'pay') {
        this.mode = 'pay';
        this.commodityName = params.commodityName;
        this.price = params.price;
        this.orderId = params.orderId;
      }
    }
    SecurePayService.hasPassword().then((value: boolean) => {
      this.hasPassword = value;
    });
  }

  private isValidPassword(value: string): boolean {
    return value.length === Constants.PAY_PASSWORD_LENGTH && /^\d{6}$/.test(value);
  }

  private setPassword(): void {
    if (!this.isValidPassword(this.newPassword)) {
      this.showToast('Enter a 6-digit numeric password');
      return;
    }
    if (this.newPassword !== this.confirmPassword) {
      this.showToast('Passwords do not match');
      return;
    }
    SecurePayService.setPassword(this.newPassword).then(() => {
      this.hasPassword = true;
      this.newPassword = '';
      this.confirmPassword = '';
      this.showToast('Payment password set');
    }).catch(() => {
      this.showToast('Failed to save password');
    });
  }

  private verifyPassword(): void {
    SecurePayService.verifyPassword(this.verifyInput).then((ok: boolean) => {
      this.verifyInput = '';
      this.showToast(ok ? 'Password correct' : 'Password incorrect');
    }).catch(() => {
      this.showToast('Verification failed');
    });
  }

  private clearPassword(): void {
    SecurePayService.clearPassword().then(() => {
      this.hasPassword = false;
      this.showToast('Payment password cleared');
    }).catch(() => {
      this.showToast('Failed to clear password');
    });
  }

  private doPay(): void {
    if (!this.hasPassword) {
      this.showToast('Set a payment password first');
      return;
    }
    SecurePayService.verifyPassword(this.payInput).then((ok: boolean) => {
      if (!ok) {
        this.showToast('Incorrect payment password');
        return;
      }
      this.payInput = '';
      this.runBiometricThenSuccess();
    });
  }

  private runBiometricThenSuccess(): void {
    const authParam: userAuth.AuthParam = {
      challenge: new Uint8Array([]),
      authType: [userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.FACE, userAuth.UserAuthType.PIN],
      authTrustLevel: userAuth.AuthTrustLevel.ATL1
    };
    const widgetParam: userAuth.WidgetParam = {
      title: 'Confirm payment'
    };
    const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
    instance.on('result', {
      onResult: (result: userAuth.UserAuthResult) => {
        if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
          this.paySuccess = true;
        } else if (result.result === userAuth.UserAuthResultCode.NOT_ENROLLED) {
          this.showToast('No biometric or PIN enrolled. Payment requires device unlock.');
          this.paySuccess = true;
        } else {
          this.showToast('Biometric verification failed');
        }
      }
    });
    instance.start();
  }

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 });
  }

  @Builder
  SectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .margin({ top: 16, bottom: 8 })
  }

  build() {
    Column() {
      Row() {
        Button('←')
          .fontSize(22)
          .backgroundColor('#00000000')
          .onClick(() => router.back())
        Text(this.mode === 'pay' ? 'Payment' : 'Payment security')
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
          if (this.mode === 'pay') {
            Column() {
              Text('Order summary')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
              Text(this.commodityName)
                .fontSize(15)
                .fontColor('#333333')
                .margin({ top: 8 })
              Text(`Order ${this.orderId}`)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 4 })
              Row() {
                Text('¥')
                  .fontSize(18)
                  .fontColor('#E64545')
                Text(this.price.toFixed(2))
                  .fontSize(34)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E64545')
              }
              .margin({ top: 12 })

              TextInput({ placeholder: 'Enter 6-digit payment password', text: $$this.payInput })
                .type(InputType.Password)
                .maxLength(Constants.PAY_PASSWORD_LENGTH)
                .width('100%')
                .height(48)
                .margin({ top: 16 })

              Button(this.paySuccess ? 'Payment successful ✓' : 'Pay')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .height(48)
                .margin({ top: 16 })
                .backgroundColor('#E64545')
                .fontColor(Color.White)
                .enabled(!this.paySuccess)
                .onClick(() => this.doPay())

              if (this.paySuccess) {
                Text('Payment simulated successfully. Order notification has been sent.')
                  .fontSize(13)
                  .fontColor('#2E7D32')
                  .margin({ top: 12 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          } else {
            Column() {
              this.SectionTitle('Payment password status')
              Text(this.hasPassword ? 'A payment password is set.' : 'No payment password set.')
                .fontSize(14)
                .fontColor(this.hasPassword ? '#2E7D32' : '#E65100')

              if (!this.hasPassword) {
                this.SectionTitle('Set payment password')
                TextInput({ placeholder: 'New 6-digit password', text: $$this.newPassword })
                  .type(InputType.Password)
                  .maxLength(Constants.PAY_PASSWORD_LENGTH)
                  .width('100%')
                  .height(48)
                TextInput({ placeholder: 'Confirm password', text: $$this.confirmPassword })
                  .type(InputType.Password)
                  .maxLength(Constants.PAY_PASSWORD_LENGTH)
                  .width('100%')
                  .height(48)
                  .margin({ top: 10 })
                Button('Save password')
                  .width('100%')
                  .height(44)
                  .margin({ top: 10 })
                  .onClick(() => this.setPassword())
              } else {
                this.SectionTitle('Verify password')
                TextInput({ placeholder: 'Enter 6-digit password', text: $$this.verifyInput })
                  .type(InputType.Password)
                  .maxLength(Constants.PAY_PASSWORD_LENGTH)
                  .width('100%')
                  .height(48)
                Button('Verify')
                  .width('100%')
                  .height(44)
                  .margin({ top: 10 })
                  .onClick(() => this.verifyPassword())

                Button('Clear password')
                  .width('100%')
                  .height(44)
                  .margin({ top: 10 })
                  .backgroundColor('#FFEBEE')
                  .fontColor('#C62828')
                  .onClick(() => this.clearPassword())
              }

              this.SectionTitle('Biometric verification')
              Text('Uses fingerprint, face, or PIN on devices that support it.')
                .fontSize(13)
                .fontColor('#666666')
              Button('Test biometric')
                .width('100%')
                .height(44)
                .margin({ top: 10 })
                .onClick(() => this.testBiometric())
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
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

  private testBiometric(): void {
    const authParam: userAuth.AuthParam = {
      challenge: new Uint8Array([]),
      authType: [userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.FACE, userAuth.UserAuthType.PIN],
      authTrustLevel: userAuth.AuthTrustLevel.ATL1
    };
    const widgetParam: userAuth.WidgetParam = {
      title: 'Verify identity'
    };
    const instance: userAuth.UserAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
    instance.on('result', {
      onResult: (result: userAuth.UserAuthResult) => {
        if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
          this.showToast('Identity verified');
        } else if (result.result === userAuth.UserAuthResultCode.NOT_ENROLLED) {
          this.showToast('No biometric or PIN enrolled on this device');
        } else {
          this.showToast('Verification failed');
        }
      }
    });
    instance.start();
  }
}
