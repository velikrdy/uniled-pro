import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) return;
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      await device.connect(autoConnect: false);
      
      // Servisleri ve yazılabilir karakteristiği keşfet
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

  // Evrensel RGB Komut Gönderici (ELK-BLEDOM ve standartlar için uyumlu bayt dizilimi)
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async {
    if (_writeCharacteristic == null) return;
    try {
      // ELK-BLEDOM ve benzeri protokoller için RGB formatı
      List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, 0xAA];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Renk gönderme hatası: $e");
    }
  }

  // 50+ Mod ve Kayar LED Efektleri İçin Komut Tetikleyici
  Future<void> sendMode(int modeId, int speed) async {
    if (_writeCharacteristic == null) return;
    try {
      // Standart kontrolcüler için mod ve hız paket yapısı
      List<int> packet = [0xBB, modeId, speed, 0x44];
      await _writeCharacteristic!.write(packet, withoutResponse: true);
    } catch (e) {
      print("Mod gönderme hatası: $e");
    }
  }
}
