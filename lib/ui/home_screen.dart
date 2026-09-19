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
  int _currentIndex = 0;
  
  double _red = 255;
  double _green = 0;
  double _blue = 0;
  double _brightness = 255;
  bool _isOn = true;

  // Selamlama & Veda Ayarları (5 - 120 saniye)
  String _selectedWelcomeMode = "Selamlama Mod 1";
  double _welcomeDuration = 10.0;
  String _selectedFarewellMode = "Veda Mod 1";
  double _farewellDuration = 10.0;

  @override
  void initState() {
    super.initState();
    widget.ble.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_connectedDevice == null ? "Cihaz Seç (MagicHome/Lotus)" : "RGB Kontrol Merkezi"),
        actions: [
          if (_connectedDevice != null)
            Row(
              children: [
                const Text("ON/OFF", style: TextStyle(fontSize: 12)),
                Switch(
                  value: _isOn,
                  activeColor: Colors.greenAccent,
                  onChanged: (v) {
                    setState(() => _isOn = v);
                    widget.ble.setPower(v);
                  },
                ),
              ],
            ),
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
            String name = r.device.name.isEmpty ? 'Bilinmeyen Cihaz (MagicHome/Lotus)' : r.device.name;
            return Card(
              color: Colors.black45,
              child: ListTile(
                leading: const Icon(Icons.bluetooth_connected, color: Colors.cyanAccent),
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

  Widget _buildActiveTabContent() {
    switch (_currentIndex) {
      case 0: return _buildColorsTab();       // 7 Ana Renk ve Renk Çemberi
      case 1: return _buildAddressableTab();  // 25 Kayar LED Animasyonu
      case 2: return _buildStandardTab();     // 25 Normal 3 Çipli LED Modu
      case 3: return _buildGreetingTab();     // 10 Selamlama Modu ve Süre (5-120sn)
      case 4: return _buildFarewellTab();     // 10 Veda Modu ve Süre (5-120sn)
      default: return _buildColorsTab();
    }
  }

  // Bölme 0: 7 Ana Renk ve Kontrol Paneli
  Widget _buildColorsTab() {
    final List<Map<String, dynamic>> baseColors = [
      {"name": "Kırmızı", "color": Colors.red, "r": 255, "g": 0, "b": 0},
      {"name": "Yeşil", "color": Colors.green, "r": 0, "g": 255, "b": 0},
      {"name": "Mavi", "color": Colors.blue, "r": 0, "g": 0, "b": 255},
      {"name": "Sarı", "color": Colors.yellow, "r": 255, "g": 255, "b": 0},
      {"name": "Camgöbeği", "color": Colors.cyan, "r": 0, "g": 255, "b": 255},
      {"name": "Mor", "color": Colors.purple, "r": 128, "g": 0, "b": 128},
      {"name": "Beyaz", "color": Colors.white, "r": 255, "g": 255, "b": 255},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("7 Ana Renk Seçimi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: baseColors.map((c) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: c["color"]),
                onPressed: () {
                  setState(() {
                    _red = (c["r"] as int).toDouble();
                    _green = (c["g"] as int).toDouble();
                    _blue = (c["b"] as int).toDouble();
                  });
                  widget.ble.sendColor(c["r"], c["g"], c["b"], _brightness.toInt());
                },
                child: Text(c["name"], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
        const Text("Parlaklık Ayarı", style: TextStyle(color: Colors.white)),
        Slider(
          value: _brightness, min: 0, max: 255, activeColor: Colors.cyanAccent,
          onChanged: (v) {
            setState(() => _brightness = v);
            widget.ble.sendColor(_red.toInt(), _green.toInt(), _blue.toInt(), _brightness.toInt());
          },
        ),
      ],
    );
  }

  // Bölme 1: 25 Adet Kayar LED Animasyon Modu
  Widget _buildAddressableTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("25 Adet Kayar LED (Addressable) Modu", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: 25,
          itemBuilder: (context, index) {
            int modeNum = index + 1;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () => widget.ble.sendMode(100 + modeNum, 50),
              child: Text("Kayar Mod $modeNum", style: const TextStyle(color: Colors.white, fontSize: 12)),
            );
          },
        ),
      ],
    );
  }

  // Bölme 2: 25 Adet Normal 3 Çipli LED Modu
  Widget _buildStandardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("25 Adet Normal 3 Çipli LED Modu", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
          itemCount: 25,
          itemBuilder: (context, index) {
            int modeNum = index + 1;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () => widget.ble.sendMode(modeNum, 50),
              child: Text("Normal Mod $modeNum", style: const TextStyle(color: Colors.white, fontSize: 12)),
            );
          },
        ),
      ],
    );
  }

  // Bölme 3: 10 Selamlama Modu ve 5-120sn Zaman Ayarı
  Widget _buildGreetingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Selamlama (Açılış) Modları ve Zaman Ayarı", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedWelcomeMode,
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white),
          items: List.generate(10, (index) => "Selamlama Mod ${index + 1}")
              .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _selectedWelcomeMode = v!),
        ),
        const SizedBox(height: 20),
        Text("Zaman Ayarı: ${_welcomeDuration.toInt()} Saniye (5s - 120s)", style: const TextStyle(color: Colors.white)),
        Slider(
          value: _welcomeDuration, min: 5, max: 120, divisions: 115, activeColor: Colors.greenAccent,
          onChanged: (v) => setState(() => _welcomeDuration = v),
        ),
      ],
    );
  }

  // Bölme 4: 10 Veda Modu ve 5-120sn Zaman Ayarı
  Widget _buildFarewellTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Veda (Kapanış) Modları ve Zaman Ayarı", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedFarewellMode,
          dropdownColor: Colors.black87,
          style: const TextStyle(color: Colors.white),
          items: List.generate(10, (index) => "Veda Mod ${index + 1}")
              .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _selectedFarewellMode = v!),
        ),
        const SizedBox(height: 20),
        Text("Zaman Ayarı: ${_farewellDuration.toInt()} Saniye (5s - 120s)", style: const TextStyle(color: Colors.white)),
        Slider(
          value: _farewellDuration, min: 5, max: 120, divisions: 115, activeColor: Colors.redAccent,
          onChanged: (v) => setState(() => _farewellDuration = v),
        ),
      ],
    );
  }

  // Alt Sekme Çubuğu (Her bölme ayrı ekranda)
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: Colors.cyanAccent,
      unselectedItemColor: Colors.white60,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.palette), label: "Renkler"),
        BottomNavigationBarItem(icon: Icon(Icons.linear_scale), label: "Kayar LED"),
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: "3 Çipli"),
        BottomNavigationBarItem(icon: Icon(Icons.login), label: "Selamlama"),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Veda"),
      ],
    );
  }
}
