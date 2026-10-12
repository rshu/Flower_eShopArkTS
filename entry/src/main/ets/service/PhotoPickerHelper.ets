import { photoAccessHelper } from '@kit.MediaLibraryKit';

export class PhotoPickerHelper {
  static async pickPhotos(maxSelectNumber: number): Promise<string[]> {
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxSelectNumber;
    const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    return result.photoUris;
  }
}
