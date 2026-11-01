export class FlowerScanService {
  static parseCommodityCode(code: string): number | null {
    if (code.length === 0) {
      return null;
    }
    const trimmed: string = code.trim();
    let digits: string = trimmed;
    const schemeIndex: number = trimmed.lastIndexOf('/');
    if (schemeIndex >= 0) {
      digits = trimmed.substring(schemeIndex + 1);
    }
    const id: number = Number(digits);
    if (Number.isNaN(id) || id <= 0) {
      return null;
    }
    return Math.floor(id);
  }

  static buildDemoCode(id: number): string {
    return `flower://${id}`;
  }
}
