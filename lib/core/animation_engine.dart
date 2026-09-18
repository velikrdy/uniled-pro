import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/preset.dart';

class AnimationEngine {
  final _controller = StreamController<List<Color>>.broadcast();
  Stream<List<Color>> get stream => _controller.stream;

  Timer? _timer;
  int _frame = 0;

  void start(Preset preset) {
    stop();
    _frame = 0;
    _timer = Timer.periodic(Duration(milliseconds: (50 / preset.speed).round()), (_) {
      final colors = List<Color>.generate(preset.ledCount, (i) {
        final t = (_frame + i * 5) % 360 / 360.0;
        return Color.lerp(preset.startColor, preset.endColor, sin(t * 2 * pi) * 0.5 + 0.5)!;
      });
      _controller.add(colors);
      _frame++;
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
