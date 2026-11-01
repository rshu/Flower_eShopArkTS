import { systemShare } from '@kit.ShareKit';
import { contact } from '@kit.ContactsKit';
import { common } from '@kit.AbilityKit';
import { DeliveryAddress } from '../model/Commodity';

export class ShareAndContactsService {
  static async shareCommodity(context: common.UIAbilityContext, title: string, content: string): Promise<void> {
    const sharedData: systemShare.SharedData = new systemShare.SharedData({
      utd: 'general.text',
      title: title,
      content: content
    });
    const controller: systemShare.ShareController = new systemShare.ShareController(sharedData);
    await controller.show(context, {});
  }

  static async pickRecipient(): Promise<DeliveryAddress | null> {
    const contacts: Array<contact.Contact> = await contact.selectContact();
    if (contacts.length === 0) {
      return null;
    }
    const selected: contact.Contact = contacts[0];
    let fullName: string = 'Recipient';
    if (selected.name !== undefined) {
      fullName = selected.name.fullName;
    }
    let phone: string = '';
    if (selected.phoneNumbers !== undefined && selected.phoneNumbers.length > 0) {
      phone = selected.phoneNumbers[0].phoneNumber;
    }
    return {
      name: fullName,
      phone: phone,
      address: ''
    };
  }
}
