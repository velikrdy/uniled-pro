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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  BluetoothDevice? _connectedDevice;
  late TabController _tabController;
  
  // Renk ve Mod Parametreleri
  double _red = 255;
  double _green = 0;
  double _blue = 0;
  int _selectedMode = 1;
  int _animationSpeed = 50;

  // Selamlama ve Veda Ayarları
  String _welcomeMode = "Yavaş Renk Geçişi";
  double _welcomeDuration = 3.0;
  String _farewellMode = "Flaş / Çakar";
  double _farewellDuration = 2.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.ble.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectedDevice == null ? "UniLED Pro v2 - Cihaz Seç" : "UniLED Pro v2 - Kontrol Paneli"),
        bottom: _connectedDevice != null ? TabControllerBar(_tabController) : null,
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: () async {
                await _connectedDevice?.disconnect();
                setState(() => _connectedDevice = null);
                widget.ble.startScan();
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: _connectedDevice == null
          ? StreamBuilder<List<ScanResult>>(
              stream: widget.ble.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  children: snapshot.data!.map((r) => ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                    title: Text(r.device.name.isEmpty ? 'Bilinmeyen RGB Cihaz' : r.device.name),
                    subtitle: Text(r.device.id.toString()),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        bool success = await widget.ble.connect(r.device);
                        if (success) setState(() => _connectedDevice = r.device);
                      },
                      child: const Text('Bağlan'),
                    ),
                  )).toList(),
                );
              },
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRgbMatrixTab(),
                _buildModesTab(),
                _buildAnimationMenuTab(),
              ],
            ),
    );
  }

  // Sekme 1: Profesyonel Renk Matrisi ve Çemberi
  Widget _buildRgbMatrixTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Color.fromRGBO(_red.toInt(), _green.toInt(), _blue.toInt(), 1.0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(child: Text("Canlı Renk Önizleme", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 20),
          _slider("Kırmızı (R)", _red, Colors.red, (v) => setState(() => _red = v)),
          _slider("Yeşil (G)", _green, Colors.green, (v) => setState(() => _green = v)),
          _slider("Mavi (B)", _blue, Colors.blue, (v) => setState(() => _blue = v)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.blueAccent),
            icon: const Icon(Icons.send),
            label: const Text("Rengi Cihaza Uygula"),
            onPressed: () => widget.ble.sendColor(_red.toInt(), _green.toInt(), _blue.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ${value.toInt()}", style: const TextStyle(color: Colors.white)),
        Slider(value: value, min: 0, max: 255, activeColor: color, onChanged: (v) {
          onChanged(v);
          widget.ble.sendColor(_red.toInt(), _green.toInt(), _blue.toInt());
        }),
      ],
    );
  }

  // Sekme 2: 50+ Mod ve Selamlama / Veda Ayarları
  Widget _buildModesTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text("50+ Efekt Modu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 50,
            itemBuilder: (context, index) {
              int modeId = index + 1;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[850], foregroundColor: Colors.white),
                onPressed: () {
                  setState(() => _selectedMode = modeId);
                  widget.ble.sendMode(_selectedMode, _animationSpeed);
                },
                child: Text("Mod $modeId", style: const TextStyle(fontSize: 12)),
              );
            },
          ),
        ),
        const Divider(color: Colors.grey, height: 30),
        const Text("Selamlama (Açılış) ve Veda Ayarları", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _welcomeMode,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Selamlama Modu Seç"),
          items: ["Yavaş Renk Geçişi", "Flaş / Çakar", "Akan Şerit", "Nefes Alma"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _welcomeMode = v!),
        ),
        Slider(
          label: "Selamlama Süresi: ${_welcomeDuration.toStringAsFixed(1)}s",
          value: _welcomeDuration, min: 1, max: 10, divisions: 9,
          onChanged: (v) => setState(() => _welcomeDuration = v),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _farewellMode,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Veda (Kapanış) Modu Seç"),
          items: ["Yavaş Renk Geçişi", "Flaş / Çakar", "Karartma", "Kapanış Efekti"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => setState(() => _farewellMode = v!),
        ),
        Slider(
          label: "Veda Süresi: ${_farewellDuration.toStringAsFixed(1)}s",
          value: _farewellDuration, min: 1, max: 10, divisions: 9,
          onChanged: (v) => setState(() => _farewellDuration = v),
        ),
      ],
    );
  }

  // Sekme 3: Kayar LED (Addressable/SPI) Menüsü
  Widget _buildAnimationMenuTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Kayar LED (Addressable SPI) Modları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            icon: const Icon(Icons.waves),
            label: const Text("Meteor Kayma Efekti"),
            onPressed: () => widget.ble.sendMode(101, _animationSpeed),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            icon: const Icon(Icons.bolt),
            label: const Text("Simge / Şimşek Akışı"),
            onPressed: () => widget.ble.sendMode(102, _animationSpeed),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
            icon: const Icon(Icons.gradient),
            label: const Text("Gökkuşağı Dalgalanması"),
            onPressed: () => widget.ble.sendMode(103, _animationSpeed),
          ),
          const SizedBox(height: 20),
          const Text("Animasyon Hızı Ayarı", style: TextStyle(color: Colors.white)),
          Slider(
            value: _animationSpeed.toDouble(), min: 1, max: 100, activeColor: Colors.orangeAccent,
            onChanged: (v) {
              setState(() => _animationSpeed = v.toInt());
              widget.ble.sendMode(_selectedMode, _animationSpeed);
            },
          ),
        ],
      ),
    );
  }
}

class TabControllerBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  const TabControllerBar(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: const [
        Tab(icon: Icon(Icons.palette), text: "RGB Matris"),
        Tab(icon: Icon(Icons.list), text: "50+ Mod"),
        Tab(icon: Icon(Icons.linear_scale), text: "Kayar LED"),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
