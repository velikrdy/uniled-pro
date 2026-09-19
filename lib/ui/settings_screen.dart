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
      appBar: AppBar(
        title: const Text("UniLED Pro v2 - Ayarlar"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Otomasyon ve Güvenlik",
            style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[900],
            child: SwitchListTile(
              title: const Text("Keyless-Go Otomatik Aç", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Uygulama açılınca karşılama animasyonu", style: TextStyle(color: Colors.grey)),
              value: widget.settings.keylessEnabled,
              activeColor: Colors.blueAccent,
              onChanged: (v) {
                setState(() => widget.settings.keylessEnabled = v);
                widget.settings.save();
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Donanım ve Bağlantı",
            style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[900],
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Otomatik Yeniden Bağlan", style: TextStyle(color: Colors.white)),
                  subtitle: const Text("Bluetooth kapsama alanına girince bağlan", style: TextStyle(color: Colors.grey)),
                  value: true, // İleride service üzerinden bağlanabilir
                  activeColor: Colors.blueAccent,
                  onChanged: (v) {
                    // Özellik eklenebilir
                  },
                ),
                const Divider(color: Colors.grey, height: 1),
                ListTile(
                  title: const Text("LED Güç Sınırı (Akım Koruması)", style: TextStyle(color: Colors.white)),
                  subtitle: const Text("Maksimum parlaklık seviyesini sınırla", style: TextStyle(color: Colors.grey)),
                  trailing: const Text("%100", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    // Parlaklık ayar diyaloğu eklenebilir
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Uygulama Bilgisi",
            style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[900],
            child: const ListTile(
              title: Text("Sürüm", style: TextStyle(color: Colors.white)),
              subtitle: Text("v2.0.0 (Release)", style: TextStyle(color: Colors.grey)),
              trailing: Icon(Icons.info_outline, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
