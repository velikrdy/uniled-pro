import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) return;
    await FlutterBluePlus.stopScan();
    // Lotus Lantern, Magic Home ve ELK-BLEDOM gibi cihazları kaçırmamak için genişletilmiş tarama
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

  // RGBW ve Standart Kontrolcüler İçin Renk Gönderimi
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async {
    if (_writeCharacteristic == null) return;
    try {
      // Lotus Lantern ve ELK-BLEDOM protokol byte yapısı
      List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, 0xAA];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Renk gönderme hatası: $e");
    }
  }

  // İsimli Mod Komutları
  Future<void> sendMode(int modeId, int speed) async {
    if (_writeCharacteristic == null) return;
    try {
      List<int> packet = [0xBB, modeId, speed, 0x44];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Mod gönderme hatası: $e");
    }
  }
}
