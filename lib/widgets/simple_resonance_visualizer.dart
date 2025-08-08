import 'package:flutter/material.dart';
import '../models/core.dart';
import '../models/resonance_depth.dart';

/// Simplified, performance-optimized core visualizer
class SimpleResonanceVisualizer extends StatelessWidget {
  final EmotionalCore core;
  final double size;
  final double animationValue;
  
  const SimpleResonanceVisualizer({
    super.key,
    required this.core,
    this.size = 80,
    this.animationValue = 0.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = _getCoreColor(core.color);
    final isDormant = core.currentLevel < 0.1;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Simple gradient based on resonance depth
        gradient: _buildGradient(color, isDormant),
        // Minimal shadow for depth
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDormant ? 0.15 : 0.25),
            blurRadius: size * 0.1,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Simple depth indicator
          if (!isDormant) _buildDepthIndicator(color),
        ],
      ),
    );
  }
  
  Widget _buildDepthIndicator(Color color) {
    // Simple ring pattern based on depth
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
    );
  }
  
  RadialGradient _buildGradient(Color color, bool isDormant) {
    if (isDormant) {
      return RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
        colors: [
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.4),
        ],
        stops: const [0.0, 1.0],
      );
    }
    
    // Active gradient based on resonance depth
    switch (core.resonanceDepth) {
      case ResonanceDepth.emerging:
        return RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.8),
            color.withValues(alpha: 1.0),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        );
      case ResonanceDepth.developing:
        return RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.9),
            _getDarkerVariant(color),
          ],
          stops: const [0.0, 0.2, 0.6, 1.0],
        );
      case ResonanceDepth.deepening:
      case ResonanceDepth.integrated:
        return RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            color,
            color.withValues(alpha: 0.8),
            color,
            _getDarkerVariant(color),
          ],
          stops: const [0.0, 0.15, 0.5, 1.0],
        );
      case ResonanceDepth.transcendent:
        return RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            color,
            color.withValues(alpha: 0.9),
            color,
            _getDarkerVariant(color),
            Colors.black.withValues(alpha: 0.2),
          ],
          stops: const [0.0, 0.1, 0.4, 0.8, 1.0],
        );
      default: // dormant
        return RadialGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.4),
          ],
        );
    }
  }
  
  double _getCoreScale() {
    // Scale inner core based on current level
    final baseScale = 0.3;
    final levelMultiplier = core.currentLevel * 0.4;
    return (baseScale + levelMultiplier).clamp(0.2, 0.7);
  }
  
  Color _getCoreColor(String colorHex) {
    try {
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } else {
        return Color(int.parse('0xFF$colorHex'));
      }
    } catch (e) {
      return Colors.blue; // fallback
    }
  }
  
  Color _getDarkerVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
}