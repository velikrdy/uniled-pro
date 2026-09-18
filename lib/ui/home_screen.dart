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

  @override
  void initState() {
    super.initState();
    widget.ble.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_connectedDevice == null ? "UniLED Pro v2 - Cihaz Seç" : "UniLED Pro v2 - Kontrol Paneli"),
        actions: [
          if (_connectedDevice != null)
            IconButton(
              icon: const Icon(Icons.link_off),
              tooltip: "Bağlantıyı Kes",
              onPressed: () async {
                await _connectedDevice?.disconnect();
                setState(() {
                  _connectedDevice = null;
                });
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
          // 1. DURUM: Cihaz bağlı değilse Bluetooth Tarama Listesi Göster
          ? StreamBuilder<List<ScanResult>>(
              stream: widget.ble.scanResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Bluetooth cihazları aranıyor..."),
                      ],
                    ),
                  );
                }
                return ListView(
                  children: snapshot.data!.map((r) => ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(r.device.name.isEmpty ? 'Bilinmeyen Cihaz' : r.device.name),
                    subtitle: Text(r.device.id.toString()),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await widget.ble.connect(r.device);
                        setState(() => _connectedDevice = r.device);
                      },
                      child: const Text('Bağlan'),
                    ),
                  )).toList(),
                );
              },
            )
          // 2. DURUM: Cihaz bağlıysa Tam Fonksiyonel LED Kontrol Paneli Göster
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.grey[900],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Bağlı Cihaz: ${_connectedDevice!.name.isEmpty ? _connectedDevice!.id : _connectedDevice!.name}",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Hızlı Renk Seçimi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _colorButton("Kırmızı", const Color(0xFFFF0000), [255, 0, 0]),
                      _colorButton("Yeşil", const Color(0xFF00FF00), [0, 255, 0]),
                      _colorButton("Mavi", const Color(0xFF0000FF), [0, 0, 255]),
                      _colorButton("Beyaz", const Color(0xFFFFFFFF), [255, 255, 255]),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("LED Efektleri ve Modlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    icon: const Icon(Icons.animation),
                    label: const Text("Özel Efekt Gönder"),
                    onPressed: () {
                      widget.ble.sendColor(_connectedDevice!, [255, 128, 0]);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                    icon: const Icon(Icons.flash_on),
                    label: const Text("Çakar Modu (Strobe)"),
                    onPressed: () {
                      widget.ble.sendColor(_connectedDevice!, [255, 255, 0]);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _colorButton(String label, Color color, List<int> rgbValues) {
    return GestureDetector(
      onTap: () => widget.ble.sendColor(_connectedDevice!, rgbValues),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, spreadRadius: 2)],
        ),
      ),
    );
  }
}
