import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) return;
    
    await FlutterBluePlus.stopScan();
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: true,
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
      
      try {
        await device.requestMtu(512);
      } catch (_) {}

      List<BluetoothService> services = await device.discoverServices();
      _writeCharacteristic = null;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          bool canWrite = characteristic.properties.write || characteristic.properties.writeWithoutResponse;
          
          if (canWrite) {
            _writeCharacteristic = characteristic;
            
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              try {
                await characteristic.setNotifyValue(true);
              } catch (_) {}
            }

            String uuidStr = characteristic.uuid.toString().toLowerCase();
            if (uuidStr.contains("ffe9") || uuidStr.contains("ffe1") || uuidStr.contains("ffd1") || uuidStr.contains("0003")) {
              break;
            }
          }
        }
        if (_writeCharacteristic != null) break;
      }

      return _writeCharacteristic != null;
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return false;
    }
  }

  Future<void> _writePacket(List<int> packet) async {
    if (_writeCharacteristic == null) {
      print("Hata: Aktif yazma karakteristiği bulunamadı!");
      return;
    }
    try {
      bool withoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(packet, withoutResponse: withoutResponse);
      await Future.delayed(const Duration(milliseconds: 15));
    } catch (e) {
      print("Komut iletim hatası: $e");
    }
  }

  // Arayüzle uyumlu olması için metot adları 'set...' olarak güncellendi:
  
  Future<void> setColor(int red, int green, int blue, [int brightness = 255]) async {
    int checksum = (0x56 + red + green + blue + 0x00) & 0xFF;
    List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, checksum];
    await _writePacket(packet);
  }

  Future<void> setPower(bool isOn) async {
    List<int> packet = isOn ? [0xCC, 0x23, 0x33] : [0xCC, 0x24, 0x33];
    await _writePacket(packet);
  }

  Future<void> setMode(int modeId, int speed) async {
    int safeSpeed = speed.clamp(1, 100);
    List<int> packet = [0xBB, modeId & 0xFF, safeSpeed, 0x44];
    await _writePacket(packet);
  }

  Future<void> setWelcomeFarewell(int type, int modeIndex, int durationSec) async {
    int safeDuration = durationSec.clamp(5, 120);
    List<int> packet = [0xDD, type & 0xFF, modeIndex & 0xFF, safeDuration & 0xFF, 0x55];
    await _writePacket(packet);
  }
}
