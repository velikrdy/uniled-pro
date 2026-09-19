import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // 1. Tarama Başlatma (Android/iOS izin ve adaptör kontrolleriyle güçlendirilmiş)
  Future<void> startScan() async {
    try {
      // Bluetooth destekleniyor mu ve açık mı?
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth bu cihazda desteklenmiyor.");
        return;
      }

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print("Bluetooth kapalı! Lütfen açın.");
        return;
      }

      // Tarama öncesi varsa eski taramayı durdur
      await stopScan();

      // Android için konum servislerinin açık olduğundan emin olunması gerekebilir
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print("Tarama başlatma hatası: $e");
    }
  }

  // 2. Taramayı Durdurma
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Tarama durdurma hatası: $e");
    }
  }

  // 3. Tarama Sonuçları Akışı
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // 4. Cihaza Bağlanma ve Yazma Karakteristiğini Otomatik Bulma
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      
      // Cihaza bağlan
      await device.connect(
        autoConnect: false, 
        timeout: const Duration(seconds: 15),
      );

      // Bağlantı koptuğunda temizlik yapmak için dinleyici eklenebilir
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print("Cihaz bağlantısı koptu.");
          _writeCharacteristic = null;
        }
      });

      // MTU boyutunu artır (Veri akışının kararlılığı için)
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (_) {}
      }

      // Servisleri keşfet
      List<BluetoothService> services = await device.discoverServices();
      _writeCharacteristic = null;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          bool canWrite = characteristic.properties.write || 
                          characteristic.properties.writeWithoutResponse;
          
          if (canWrite) {
            _writeCharacteristic = characteristic;
            
            // Bildirimleri (Notify/Indicate) etkinleştirmeye çalış
            if (characteristic.properties.notify || characteristic.properties.indicate) {
              try {
                await characteristic.setNotifyValue(true);
              } catch (_) {}
            }

            // LED / Araç modüllerinde yaygın kullanılan yazma UUID'leri önceliği
            String uuidStr = characteristic.uuid.toString().toLowerCase();
            if (uuidStr.contains("ffe9") || 
                uuidStr.contains("ffe1") || 
                uuidStr.contains("ffd1") || 
                uuidStr.contains("0003") || 
                uuidStr.contains("fff2")) {
              break; // En uygun olanı bulduk, döngüden çık
            }
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic != null) {
        print("Başarılı: Yazma karakteristiği bulundu!");
        return true;
      } else {
        print("Hata: Cihazda yazılabilir karakteristik bulunamadı.");
        return false;
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return false;
    }
  }

  // 5. Güvenli Paket Gönderim Motoru
  Future<void> _writePacket(List<int> packet) async {
    if (_writeCharacteristic == null) {
      print("Hata: Aktif yazma karakteristiği bulunamadı! Önce cihaza bağlanın.");
      return;
    }
    try {
      bool withoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;
      await _writeCharacteristic!.write(packet, withoutResponse: withoutResponse);
      // Komutların üst üste binip modülü kilitlemesini önlemek için mini gecikme
      await Future.delayed(const Duration(milliseconds: 20));
    } catch (e) {
      print("Komut iletim hatası: $e");
    }
  }

  // --- ARAYÜZ UYUMLU KOMUT METOTLARI (Hem set... hem send... destekler) ---

  // Renk Komutu (RGB + Opsiyonel Parlaklık)
  Future<void> setColor(int red, int green, int blue, [int brightness = 255]) async {
    int checksum = (0x56 + red + green + blue + 0x00) & 0xFF;
    List<int> packet = [0x56, red, green, blue, 0x00, 0xF0, checksum];
    await _writePacket(packet);
  }
  Future<void> sendColor(int red, int green, int blue, [int brightness = 255]) async => 
      await setColor(red, green, blue, brightness);

  // Güç Komutu (Açma / Kapatma)
  Future<void> setPower(bool isOn) async {
    List<int> packet = isOn ? [0xCC, 0x23, 0x33] : [0xCC, 0x24, 0x33];
    await _writePacket(packet);
  }
  Future<void> sendPower(bool isOn) async => await setPower(isOn);

  // Mod Komutu (Efekt ID ve Hız)
  Future<void> setMode(int modeId, int speed) async {
    int safeSpeed = speed.clamp(1, 100);
    List<int> packet = [0xBB, modeId & 0xFF, safeSpeed, 0x44];
    await _writePacket(packet);
  }
  Future<void> sendMode(int modeId, int speed) async => await setMode(modeId, speed);

  // Karşılama / Uğurlama Animasyon Komutu
  Future<void> setWelcomeFarewell(int type, int modeIndex, int durationSec) async {
    int safeDuration = durationSec.clamp(5, 120);
    List<int> packet = [0xDD, type & 0xFF, modeIndex & 0xFF, safeDuration & 0xFF, 0x55];
    await _writePacket(packet);
  }
  Future<void> sendWelcomeFarewell(int type, int modeIndex, int durationSec) async => 
      await setWelcomeFarewell(type, modeIndex, durationSec);
}
