import '../core/animation_engine.dart';
import 'settings_service.dart';
import 'ble_service.dart';
import 'package:flutter/material.dart';
import '../models/preset.dart';

class AutoService {
  final AnimationEngine _engine;
  final SettingsService _settings;
  final BleService _ble;

  AutoService(this._engine, this._settings, this._ble);

  void appStarted() {
    if (_settings.keylessEnabled) {
      _engine.start(Preset(
        name: "Welcome",
        description: "Keyless Welcome",
        duration: const Duration(seconds: 5),
        startColor: const Color(0xFF00FF00),
        endColor: const Color(0xFF0000FF),
        speed: 1.5,
        ledCount: 100,
      ));
    }
  }
}
