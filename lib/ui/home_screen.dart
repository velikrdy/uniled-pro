import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../core/animation_engine.dart';
import '../services/settings_service.dart';
import '../services/auto_service.dart';

class HomeScreen extends StatefulWidget {
  final BleService ble;
  final AnimationEngine engine;
  final SettingsService settings;
  final AutoService auto;

  const HomeScreen({super.key, required this.ble, required this.engine, required this.settings, required this.auto});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothDevice? _connectedDevice;
  int _currentIndex = 0; // Alt sekmeler için index
  
  double _red = 0;
  double _green = 96;
  double _blue = 255;
  double _brightness = 255;
  bool _isOn = true;

  @override
  void initState() {
    super.initState();
    widget.ble.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Mavi tonu
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_connectedDevice == null ? "Cihaz Seç (Lotus / MagicHome / ELK)" : "Kontrol Paneli"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: _connectedDevice == null ? _buildDeviceScanner() : _buildActiveTabContent(),
      bottomNavigationBar: _connectedDevice != null ? _buildBottomNavBar() : null,
    );
  }

  // Cihaz Tarama Ekranı
  Widget _buildDeviceScanner() {
    return StreamBuilder<List<ScanResult>>(
      stream: widget.ble.scanResults,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.map((r) {
            String name = r.device.name.isEmpty ? 'Bilinmeyen RGB Cihaz' : r.device.name;
            return Card(
              color: Colors.black45,
              child: ListTile(
                leading: const Icon(Icons.bluetooth_searching, color: Colors.cyanAccent),
                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(r.device.id.toString(), style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () async {
                    bool success = await widget.ble.connect(r.device);
                    if (success) setState(() => _connectedDevice = r.device);
                  },
                  child: const Text('Bağlan'),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Aktif Sekmelere Göre İçerik Dağılımı
  Widget _buildActiveTabContent() {
    switch (_currentIndex) {
      case 0:
        return _buildAdjustTab();
      case 1:
        return _buildModesTab();
      case 2:
        return _buildMusicTab();
      case 3:
        return _buildMicTab();
      case 4:
        return _buildTimerTab();
      default:
        return _buildAdjustTab();
    }
  }

  // Sekme 0: Ayarlamak (Renk Çemberi, Parlaklık ve Ön Ayarlar)
  Widget _buildAdjustTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(_red.toInt(), _green.toInt(), _blue.toInt(), 1.0),
              ),
            ),
            Switch(
              value: _isOn,
              activeColor: Colors.white,
              onChanged: (v) => setState(() => _isOn = v),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Profesyonel Renk Çemberi Simülasyon Alanı (Hata Düzeltildi: 'child' parametresi kullanıldı)
        Center(
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 4),
              gradient: const SweepGradient(
                colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // RGB Değer Göstergeleri
        Row(
          children: [
            _rgbBadge("R", _red.toInt(), Colors.red),
            const SizedBox(width: 10),
            _rgbBadge("G", _green.toInt(), Colors.green),
            const SizedBox(width: 10),
            _rgbBadge("B", _blue.toInt(), Colors.blue),
          ],
        ),
        const SizedBox(height: 20),
        // Parlaklık Slider
        Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, color: Colors.white70),
            Expanded(
              child: Slider(
                value: _brightness, min: 0, max: 255, activeColor: Colors.cyanAccent,
                onChanged: (v) {
                  setState(() => _brightness = v);
                  widget.ble.sendColor(_red.toInt(), _green.toInt(), _blue.toInt(), _brightness.toInt());
                },
              ),
            ),
            const Icon(Icons.wb_sunny, color: Colors.white),
          ],
        ),
        const SizedBox(height: 15),
        const Text("Ön Ayar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _presetColorButton(Colors.blue),
              _presetColorButton(Colors.cyan),
              _presetColorButton(Colors.indigo),
              _presetColorButton(Colors.green),
              _presetColorButton(Colors.amber),
              _presetColorButton(Colors.white),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rgbBadge(String label, int val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text("$label  $val", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _presetColorButton(Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _red = color.red.toDouble();
            _green = color.green.toDouble();
            _blue = color.blue.toDouble();
          });
          widget.ble.sendColor(_red.toInt(), _green.toInt(), _blue.toInt());
        },
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        ),
      ),
    );
  }

  // Sekme 1: Üslup (İsimli Mod Butonları)
  Widget _buildModesTab() {
    final List<Map<String, dynamic>> modeList = [
      {"id": 1, "name": "Yavaş Renk Geçişi"},
      {"id": 2, "name": "Hızlı Strobe (Çakar)"},
      {"id": 3, "name": "Nefes Alma Efekti"},
      {"id": 4, "name": "Gökkuşağı Atlaması"},
      {"id": 5, "name": "Kırmızı Flaş"},
      {"id": 6, "name": "Yeşil Dalgalanma"},
      {"id": 7, "name": "Mavi Akış"},
      {"id": 8, "name": "Parti Modu"},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Efekt Modları ve İsimleri", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...modeList.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () => widget.ble.sendMode(m["id"], 50),
            child: Text(m["name"], style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )),
      ],
    );
  }

  Widget _buildMusicTab() => const Center(child: Text("Müzik Senkronizasyon Modu", style: TextStyle(color: Colors.white)));
  Widget _buildMicTab() => const Center(child: Text("Mikrofon Ses Duyarlılığı", style: TextStyle(color: Colors.white)));
  Widget _buildTimerTab() => const Center(child: Text("Tarife / Zamanlayıcı Ayarları", style: TextStyle(color: Colors.white)));

  // Alt Sekme Çubuğu
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.cyanAccent,
      unselectedItemColor: Colors.white60,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.tune), label: "Ayarlamak"),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Üslup"),
        BottomNavigationBarItem(icon: Icon(Icons.music_note), label: "Müzik"),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Mikrofon"),
        BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Tarife"),
      ],
    );
  }
}
