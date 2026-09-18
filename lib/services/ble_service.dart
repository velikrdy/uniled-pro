import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  // Bluetooth taramasını başlatır
  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      return;
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  }

  // Bluetooth taramasını durdurur
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // Tarama sonuçlarını dinlemek için akış
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // Bluetooth cihazına bağlanma fonksiyonu
  Future<void> connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      // Bağlantı hatası durumunda loglanabilir
      print("Bağlantı hatası: $e");
    }
  }

  // LED'lere renk komutu gönderme fonksiyonu
  Future<void> sendColor(BluetoothDevice device, List<int> colorData) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            await characteristic.write(colorData);
          }
        }
      }
    } catch (e) {
      print("Renk gönderme hatası: $e");
    }
  }
}
