import 'package:flutter/material.dart';

enum ResonanceDepth {
  dormant('Dormant', 0.0, 0.15),
  emerging('Emerging', 0.15, 0.35),
  developing('Developing', 0.35, 0.55),
  deepening('Deepening', 0.55, 0.75),
  integrated('Integrated', 0.75, 0.90),
  transcendent('Transcendent', 0.90, 1.0);

  const ResonanceDepth(this.displayName, this.minLevel, this.maxLevel);

  final String displayName;
  final double minLevel;
  final double maxLevel;
  
  static ResonanceDepth fromLevel(double level) {
    return ResonanceDepth.values.firstWhere(
      (depth) => level >= depth.minLevel && level < depth.maxLevel,
      orElse: () => level >= 0.90 ? ResonanceDepth.transcendent : ResonanceDepth.dormant,
    );
  }
  
  String get description {
    switch (this) {
      case ResonanceDepth.dormant:
        return 'This aspect lies quiet within you, waiting to be awakened';
      case ResonanceDepth.emerging:
        return 'Beginning to stir, showing early signs of recognition';
      case ResonanceDepth.developing:
        return 'Growing stronger through conscious attention and practice';
      case ResonanceDepth.deepening:
        return 'Becoming a meaningful part of your daily experience';
      case ResonanceDepth.integrated:
        return 'Woven into the fabric of who you are';
      case ResonanceDepth.transcendent:
        return 'A profound strength that flows naturally through all you do';
    }
  }
  
  Color getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case ResonanceDepth.dormant:
        return isDark ? Colors.grey[700]! : Colors.grey[300]!;
      case ResonanceDepth.emerging:
        return isDark ? Colors.blue[700]! : Colors.blue[200]!;
      case ResonanceDepth.developing:
        return isDark ? Colors.green[700]! : Colors.green[300]!;
      case ResonanceDepth.deepening:
        return isDark ? Colors.orange[700]! : Colors.orange[300]!;
      case ResonanceDepth.integrated:
        return isDark ? Colors.purple[700]! : Colors.purple[300]!;
      case ResonanceDepth.transcendent:
        return isDark ? Colors.amber[700]! : Colors.amber[300]!;
    }
  }
  
  String get shortDescription {
    switch (this) {
      case ResonanceDepth.dormant:
        return 'Quiet and waiting';
      case ResonanceDepth.emerging:
        return 'First stirrings';
      case ResonanceDepth.developing:
        return 'Growing stronger';
      case ResonanceDepth.deepening:
        return 'Meaningful presence';
      case ResonanceDepth.integrated:
        return 'Core identity';
      case ResonanceDepth.transcendent:
        return 'Natural flow';
    }
  }
}