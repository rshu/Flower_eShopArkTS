import { ble, constant } from '@kit.ConnectivityKit';

export interface VaseScanDevice {
  deviceId: string;
  name: string;
  rssi: number;
}

export class SmartVaseService {
  private static readonly SERVICE_UUID: string = '0000ffe0-0000-1000-8000-00805f9b34fb';
  private static readonly COMMAND_UUID: string = '0000ffe1-0000-1000-8000-00805f9b34fb';
  private static readonly NAME_HINTS: string[] = ['vase', 'flower', 'huawei', 'smart'];

  static scan(timeoutMs: number): Promise<VaseScanDevice[]> {
    return new Promise<VaseScanDevice[]>((resolve: (devices: VaseScanDevice[]) => void) => {
      const found: Map<string, VaseScanDevice> = new Map<string, VaseScanDevice>();
      const onFind = (results: Array<ble.ScanResult>): void => {
        for (let i = 0; i < results.length; i++) {
          const result: ble.ScanResult = results[i];
          if (!found.has(result.deviceId)) {
            found.set(result.deviceId, {
              deviceId: result.deviceId,
              name: result.deviceName,
              rssi: result.rssi
            });
          }
        }
      };
      try {
        ble.on('BLEDeviceFind', onFind);
        ble.startBLEScan([], { dutyMode: ble.ScanDuty.SCAN_MODE_LOW_LATENCY });
      } catch (e) {
        // Scanning can be unavailable when Bluetooth is off; resolve empty below.
      }
      setTimeout(() => {
        try {
          ble.off('BLEDeviceFind', onFind);
          ble.stopBLEScan();
        } catch (e) {
        }
        const list: VaseScanDevice[] = [];
        found.forEach((device: VaseScanDevice) => {
          list.push(device);
        });
        resolve(list);
      }, timeoutMs);
    });
  }

  static findLikelyVase(devices: VaseScanDevice[]): VaseScanDevice | null {
    if (devices.length === 0) {
      return null;
    }
    for (let i = 0; i < devices.length; i++) {
      const name: string = devices[i].name.toLowerCase();
      for (let j = 0; j < SmartVaseService.NAME_HINTS.length; j++) {
        if (name.indexOf(SmartVaseService.NAME_HINTS[j]) >= 0) {
          return devices[i];
        }
      }
    }
    return devices[0];
  }

  static async sendWaterCommand(deviceId: string): Promise<string> {
    const client: ble.GattClientDevice = ble.createGattClientDevice(deviceId);
    await SmartVaseService.waitForConnection(client, 8000);
    const services: Array<ble.GattService> = await client.getServices();
    for (let i = 0; i < services.length; i++) {
      const service: ble.GattService = services[i];
      if (service.serviceUuid.toLowerCase() !== SmartVaseService.SERVICE_UUID) {
        continue;
      }
      const characteristics: Array<ble.BLECharacteristic> = service.characteristics;
      for (let j = 0; j < characteristics.length; j++) {
        const characteristic: ble.BLECharacteristic = characteristics[j];
        if (characteristic.characteristicUuid.toLowerCase() === SmartVaseService.COMMAND_UUID) {
          characteristic.characteristicValue = SmartVaseService.waterCommandBytes();
          await client.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE_NO_RESPONSE);
          client.close();
          return 'Watering command sent to vase';
        }
      }
    }
    client.close();
    return 'Connected, but vase service not found';
  }

  private static waterCommandBytes(): ArrayBuffer {
    const bytes: Uint8Array = new Uint8Array([0x57, 0x01]);
    return bytes.buffer;
  }

  private static waitForConnection(client: ble.GattClientDevice, timeoutMs: number): Promise<void> {
    return new Promise<void>((resolve: () => void, reject: (e: Error) => void) => {
      let settled: boolean = false;
      const onChange = (state: ble.BLEConnectionChangeState): void => {
        if (settled) {
          return;
        }
        if (state.state === constant.ProfileConnectionState.STATE_CONNECTED) {
          settled = true;
          resolve();
        }
      };
      client.on('BLEConnectionStateChange', onChange);
      client.connect();
      setTimeout(() => {
        if (!settled) {
          settled = true;
          reject(new Error('BLE connection timed out'));
        }
      }, timeoutMs);
    });
  }
}
