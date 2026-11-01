export class ImageProcessService {
  static readonly PLACEHOLDER: string = '';

  static isRemoteUrl(url: string): boolean {
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
