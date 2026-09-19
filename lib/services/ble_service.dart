import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;

  // 1. Tarama Başlatma (Genişletilmiş filtre ve hata yakalama ile)
  Future<void> startScan() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        print("Cihaz Bluetooth desteklemiyor.");
        return;
      }

      // Bluetooth kapalıysa tarama yapmaz
      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print("Bluetooth kapalı durumda.");
        return;
      }

      // Önceki taramaları temizle
      await stopScan();

      // Taramayı başlat (Süre ve Android konum optimizasyonu)
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print("Tarama başlatılırken hata oluştu: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // 2. Cihaza Bağlanma ve Karakteristik Keşfi
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      
      await device.connect(
        autoConnect: false, 
        timeout: const Duration(seconds: 15),
      );

      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (_) {}
      }

      List<BluetoothService> services = await device.discoverServices();
      _writeCharacteristic = null;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          bool canWrite = characteristic.properties.write || 
                          characteristic.properties.writeWithoutResponse;
          
          if (canWrite) {
            _writeCharacteristic = characteristic;
            
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              try {
                await characteristic.setNotifyValue(true);
              } catch (_) {}
            }

            String uuidStr = characteristic.uuid.toString().toLowerCase();
            // Piyasadaki tüm Çin tipi LED ve Bluetooth modüllerinin UUID anahtarları
            if (uuidStr.contains("ffe9") || 
                uuidStr.contains("ffe1") || 
                uuidStr.contains("ffd1") || 
                uuidStr.contains("0003") || 
                uuidStr.contains("fff2")) {
              break; 
            }
          }
        }
        if (_writeCharacteristic != null) break;
      }

      return _writeCharacteristic != null;
    } catch (e) {
      print("Bağlantı hatası: $e");
      return false;
    }
  }

  // 3. Paket Gönderim Motoru
  Future<void> _writePacket(List<int> packet) async {
    if (_writeCharacteristic == null) {
      print("Yazma karakteristiği bulunamadı!");
      return;
    }
    try {
      bool withoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(packet, withoutResponse: withoutResponse);
      await Future.delayed(const Duration(milliseconds: 20));
    } catch (e) {
      print("Paket gönderme hatası: $e");
    }
  }

  // 4. Kontrol Komutları (Hem set hem send alias destekli)
  Future<void> setColor(int red, int green, int blue, [int brightness = 255]) async {
    int checksum = (0x56 + red + green + blue + 0x00) & 0xFF;
    List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, checksum];
    await _writePacket(packet);
  }
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async => setColor(red, green, blue, brightness);

  Future<void> setPower(bool isOn) async {
    List<int> packet = isOn ? [0xCC, 0x23, 0x33] : [0xCC, 0x24, 0x33];
    await _writePacket(packet);
  }
  Future<void> sendPower(bool isOn) async => setPower(isOn);

  Future<void> setMode(int modeId, int speed) async {
    int safeSpeed = speed.clamp(1, 100);
    List<int> packet = [0xBB, modeId & 0xFF, safeSpeed, 0x44];
    await _writePacket(packet);
  }
  Future<void> sendMode(int modeId, int speed) async => setMode(modeId, speed);

  Future<void> setWelcomeFarewell(int type, int modeIndex, int durationSec) async {
    int safeDuration = durationSec.clamp(5, 120);
    List<int> packet = [0xDD, type & 0xFF, modeIndex & 0xFF, safeDuration & 0xFF, 0x55];
    await _writePacket(packet);
  }
  Future<void> sendWelcomeFarewell(int type, int modeIndex, int durationSec) async => setWelcomeFarewell(type, modeIndex, durationSec);
}
