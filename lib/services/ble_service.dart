import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  // Bluetooth taramasını başlatır
  Future<void> startScan() async {
    // Bluetooth açık mı kontrol edip tarama başlatır
    if (await FlutterBluePlus.isSupported == false) {
      return;
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  }

  // Bluetooth taramasını durdurur
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // Tarama sonuçlarını dinlemek için akış (stream)
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}
