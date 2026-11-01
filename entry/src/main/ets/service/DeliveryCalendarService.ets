import { calendarManager } from '@kit.CalendarKit';
import { common } from '@kit.AbilityKit';

export class DeliveryCalendarService {
  static async addDeliveryEvent(
    context: common.Context,
    commodityName: string,
    recipientName: string,
    deliveryTime: number
  ): Promise<number> {
    const manager: calendarManager.CalendarManager = calendarManager.getCalendarManager(context);
    const calendar: calendarManager.Calendar = await manager.getCalendar();
    const event: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: 'Flower delivery',
      description: `Bouquet: ${commodityName}\nRecipient: ${recipientName}`,
      startTime: deliveryTime,
      endTime: deliveryTime + 3600000,
      isAllDay: false
    };
    return await calendar.addEvent(event);
  }
}
