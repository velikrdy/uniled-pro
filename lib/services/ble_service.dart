import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;

  // Bilinen tüm RGB / LED BLE kontrolcü servis ve karakteristik UUID imzaları
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
      // Otomatik bağlantıyı kapatıp direkt cihazla el sıkışma başlatıyoruz
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15));
      
      // MTU paket boyutunu artırarak veri kaybını sıfırlıyoruz
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
            
            // Eğer cihaz bildirim (notify) destekliyorsa, bazı kontrolcüler kilidi açmak için bunu ister
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              try {
                await characteristic.setNotifyValue(true);
              } catch (_) {}
            }

            // En yaygın LED kontrolcü yazma kanalları yakalandığında döngüyü kır
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

  // Evrensel Paket Gönderim Motoru (Alternatif yazma modlu)
  Future<void> _writePacket(List<int> packet) async {
    if (_writeCharacteristic == null) {
      print("Hata: Aktif yazma karakteristiği bulunamadı!");
      return;
    }
    try {
      // Lotus Lantern ve Magic Home bazı durumlarda withResponse (yanıt bekleyerek) yazmayı tercih eder
      bool withoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      
      await _writeCharacteristic!.write(packet, withoutResponse: withoutResponse);
      
      // Bazı hassas modüller paketler arası minik gecikme ister
      await Future.delayed(const Duration(milliseconds: 15));
    } catch (e) {
      print("Komut iletim hatası: $e");
    }
  }

  // 1. Renk Gönderimi (Magic Home / Lotus / ELK Uyumlu Checksum Eklendi)
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async {
    // Standart 7 baytlık RGB kontrol protokolü + Checksum
    int checksum = (0x56 + red + green + blue + 0x00) & 0xFF;
    List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, checksum];
    await _writePacket(packet);
  }

  // 2. Güç Açma / Kapatma Komutu
  Future<void> sendPower(bool isOn) async {
    // Çeşitli Çin çiplerinin ortak açma/kapama hex kodları
    List<int> packet = isOn ? [0xCC, 0x23, 0x33] : [0xCC, 0x24, 0x33];
    await _writePacket(packet);
  }

  // 3. Efekt Modu Gönderimi (Normal ve Kayar LED modları için)
  Future<void> sendMode(int modeId, int speed) async {
    // Mode ID ve hız parametreli evrensel komut yapısı
    int safeSpeed = speed.clamp(1, 100);
    List<int> packet = [0xBB, modeId & 0xFF, safeSpeed, 0x44];
    await _writePacket(packet);
  }

  // 4. Selamlama ve Veda Komutu (Zaman ayarlı)
  Future<void> sendWelcomeFarewell(int type, int modeIndex, int durationSec) async {
    // type: 1 (Selamlama), 2 (Veda) | durationSec: 5 - 120 saniye arası
    int safeDuration = durationSec.clamp(5, 120);
    List<int> packet = [0xDD, type & 0xFF, modeIndex & 0xFF, safeDuration & 0xFF, 0x55];
    await _writePacket(packet);
  }
}
