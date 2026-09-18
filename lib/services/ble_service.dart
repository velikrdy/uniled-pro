import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final FlutterBluePlus _ble = FlutterBluePlus;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> startScan() async => FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  Future<void> stopScan() async => FlutterBluePlus.stopScan();
  Future<void> connect(BluetoothDevice d) async => await d.connect(autoConnect: false);
  Future<void> disconnect(BluetoothDevice d) async => await d.disconnect();

  Future<void> sendColor(BluetoothDevice device, List<int> rgb) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          // MagicHome / Lotus ortak protokol. 0x56 = start, 0xF0 0xAA = end
          await characteristic.write([0x56, rgb[0], rgb[1], rgb[2], 0x00, 0xF0, 0xAA]);
        }
      }
    }
  }
}
