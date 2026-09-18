import 'dart:ui';

class Preset {
  final String name;
  final String description;
  final Duration duration;
  final Color startColor;
  final Color endColor;
  final double speed;
  final int ledCount;

  const Preset({
    required this.name,
    required this.description,
    required this.duration,
    required this.startColor,
    required this.endColor,
    required this.speed,
    required this.ledCount,
  });
}
