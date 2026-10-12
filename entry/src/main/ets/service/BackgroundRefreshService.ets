import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { common } from '@kit.AbilityKit';

export class BackgroundRefreshService {
  static async schedulePromotionReminder(context: common.Context, title: string, content: string, triggerTimeMs: number): Promise<number> {
    const date: Date = new Date(triggerTimeMs);
    const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: date.getFullYear(),
        month: date.getMonth() + 1,
        day: date.getDate(),
        hour: date.getHours(),
        minute: date.getMinutes(),
        second: date.getSeconds()
      },
      title: title,
      content: content
    };
    return await reminderAgentManager.publishReminder(reminderRequest);
  }
}
