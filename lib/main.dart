import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/animation_engine.dart';
import 'services/ble_service.dart';
import 'services/auto_service.dart';
import 'services/settings_service.dart';
import 'ui/home_screen.dart';
import 'ui/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location
  ].request();
  runApp(const UniLEDApp());
}

class UniLEDApp extends StatelessWidget {
  const UniLEDApp({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final ble = BleService();
    final engine = AnimationEngine();
    final auto = AutoService(engine, settings, ble);
    settings.load().then((_) => auto.appStarted());

    return MaterialApp(
      title: 'UniLED Pro v2',
      theme: ThemeData.dark(useMaterial3: true),
      home: HomeScreen(ble: ble, engine: engine, settings: settings, auto: auto),
      routes: {'/settings': (context) => SettingsScreen(settings: settings)},
    );
  }
}
