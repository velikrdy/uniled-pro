import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settings;
  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: SwitchListTile(
        title: const Text("Keyless-Go Otomatik Aç"),
        subtitle: const Text("Uygulama açılınca karşılama animasyonu"),
        value: widget.settings.keylessEnabled,
        onChanged: (v) {
          setState(() => widget.settings.keylessEnabled = v);
          widget.settings.save();
        }
      ),
    );
  }
}
