import { notificationManager } from '@kit.NotificationKit';
import { Constants } from '../common/Constants';

export interface OrderInfo {
  commodityName: string;
  orderId: string;
}

export class PromotionNotifier {
  static async isEnabled(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      return false;
    }
  }

  static async requestEnable(): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification();
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      return false;
    }
  }

  static async sendOrderConfirmation(order: OrderInfo): Promise<void> {
    const content: notificationManager.NotificationContent = {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: 'Order confirmed',
        text: `${order.commodityName} · Order ${order.orderId}`
      }
    };
    const request: notificationManager.NotificationRequest = {
      id: Constants.NOTIFICATION_ID_PAY,
      content: content
    };
    await notificationManager.publish(request);
  }

  static async sendPromotionReminder(title: string, text: string): Promise<void> {
    const content: notificationManager.NotificationContent = {
      notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
      normal: {
        title: title,
        text: text
      }
    };
    const request: notificationManager.NotificationRequest = {
      id: Constants.NOTIFICATION_ID_PROMOTION,
      content: content
    };
    await notificationManager.publish(request);
  }
}
