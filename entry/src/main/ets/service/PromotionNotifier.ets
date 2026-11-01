import notificationManager from '@ohos.notificationManager';
import common from '@ohos.app.ability.common';

export class PromotionNotifier {
  static async requestEnable(context: common.UIAbilityContext): Promise<void> {
    await notificationManager.requestEnableNotification(context);
  }

  static async publishOrderConfirmation(
    context: common.UIAbilityContext,
    commodityName: string,
    orderNo: string
  ): Promise<void> {
    let request: notificationManager.NotificationRequest = {
      id: PromotionNotifier.nextId(),
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '订单确认',
          text: `您已成功下单：${commodityName}（订单号 ${orderNo}）`
        }
      }
    };
    await notificationManager.publish(request);
  }

  private static nextId(): number {
    return Math.floor(Math.random() * 100000) + 1;
  }
}
