import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  late SharedPreferences _prefs;
  bool keylessEnabled = true;
  int proximityMeters = 5;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    keylessEnabled = _prefs.getBool('keyless') ?? true;
    proximityMeters = _prefs.getInt('proximity') ?? 5;
  }

  Future<void> save() async {
    await _prefs.setBool('keyless', keylessEnabled);
    await _prefs.setInt('proximity', proximityMeters);
  }
}
