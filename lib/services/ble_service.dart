import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) return;
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      await device.connect(autoConnect: false);
      
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
      }
      return true;
    } catch (e) {
      print("Bağlantı hatası: $e");
      return false;
    }
  }

  // Magic Home ve Lotus Lantern veri yazma paket yapısı (Checksum destekli)
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async {
    if (_writeCharacteristic == null) return;
    try {
      // Çoğu popüler BLE RGB/RGBW modülün beklediği byte dizilimi
      List<int> packet = [0x31, red, green, blue, brightness, 0x00, 0x0F];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Renk komut hatası: $e");
    }
  }

  // Modlar için evrensel tetikleyici
  Future<void> sendMode(int modeId, int speed) async {
    if (_writeCharacteristic == null) return;
    try {
      List<int> packet = [0xBB, modeId, speed, 0x44];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Mod komut hatası: $e");
    }
  }

  // Sistem On/Off Komutu
  Future<void> setPower(bool isOn) async {
    if (_writeCharacteristic == null) return;
    try {
      List<int> packet = isOn ? [0xCC, 0x23, 0x01, 0x99] : [0xCC, 0x23, 0x00, 0x99];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Güç komut hatası: $e");
    }
  }
}
