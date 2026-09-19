import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Bilinen Magic Home / Lotus Lantern / ELK / Triones Servis UUID'leri
  final List<Guid> targetServiceUuids = [
    Guid("0000ffe0-0000-1000-8000-00805f9b34fb"), // En yaygın RGB modül servisi
    Guid("ffd0"),
    Guid("ab00"),
    Guid("ffe5"),
  ];

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    var adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) return;
    
    await FlutterBluePlus.stopScan();
    // Genişletilmiş ve filtreli tarama
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
      // Bağlantı kararlılığı için autoConnect kapalı
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
      
      // MTU boyutunu artırarak veri kaybını önle
      try {
        await device.requestMtu(512);
      } catch (_) {}

      List<BluetoothService> services = await device.discoverServices();
      _writeCharacteristic = null;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          // Yazma özelliklerini kontrol et (Both Write & WriteWithoutResponse destekleyenleri önceliklendir)
          bool canWrite = characteristic.properties.write || characteristic.properties.writeWithoutResponse;
          if (canWrite) {
            _writeCharacteristic = characteristic;
            // Eğer özel FFE9 veya FFE1 gibi bilinen kanal bulunduysa direkt kilitle
            if (characteristic.uuid.toString().contains("ffe9") || 
                characteristic.uuid.toString().contains("ffe1") ||
                characteristic.uuid.toString().contains("ffd1")) {
              break;
            }
          }
        }
        if (_writeCharacteristic != null) break;
      }

      return _writeCharacteristic != null;
    } catch (e) {
      print("Bağlantı ve Karakteristik Hatası: $e");
      return false;
    }
  }

  // Güvenli Paket Gönderimi (Magic Home & Lotus Standart Protokolü)
  Future<void> _writePacket(List<int> packet) async {
    if (_writeCharacteristic == null) {
      print("Hata: Yazılacak aktif Bluetooth karakteristiği yok!");
      return;
    }
    try {
      bool withoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(packet, withoutResponse: withoutResponse);
    } catch (e) {
      print("Komut gönderme hatası: $e");
    }
  }

  // Renk Komutu (RGBW / RGB)
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async {
    // Magic Home / Lotus Lantern 7 baytlık renk protokolü
    List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, 0xAA];
    await _writePacket(packet);
  }

  // Güç Komutu (Aç / Kapat)
  Future<void> sendPower(bool isOn) async {
    List<int> packet = isOn ? [0xCC, 0x23, 0x33] : [0xCC, 0x24, 0x33];
    await _writePacket(packet);
  }

  // Efekt Modu Gönderimi
  Future<void> sendMode(int modeId, int speed) async {
    List<int> packet = [0xBB, modeId, speed, 0x44];
    await _writePacket(packet);
  }

  // Selamlama / Veda Komutu
  Future<void> sendWelcomeFarewell(int type, int modeIndex, int durationSec) async {
    List<int> packet = [0xDD, type, modeIndex, durationSec, 0x55];
    await _writePacket(packet);
  }
}
