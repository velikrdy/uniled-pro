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
        title: const Text("UniLED Pro v2"),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'))]
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: widget.ble.scanResults,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            children: snapshot.data!.map((r) => ListTile(
              title: Text(r.device.name.isEmpty ? 'Bilinmeyen Cihaz' : r.device.name),
              subtitle: Text(r.device.id.toString()),
              trailing: ElevatedButton(
                onPressed: () async {
                  await widget.ble.connect(r.device);
                  setState(() => _connectedDevice = r.device);
                },
                child: const Text('Bağlan')
              ),
            )).toList()
          );
        }
      ),
      floatingActionButton: _connectedDevice != null
        ? FloatingActionButton(
            onPressed: () => widget.ble.sendColor(_connectedDevice!, [255, 0, 0]),
            child: const Icon(Icons.color_lens)
          )
        : null
    );
  }
}
