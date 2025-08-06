import 'dart:math';
import 'package:flutter/material.dart';
import '../models/core.dart';
import '../models/resonance_depth.dart';
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';

class ResonanceDepthVisualizer extends StatefulWidget {
  final EmotionalCore core;
  final double size;
  final bool showLabel;
  final bool showProgress;
  final bool isCompact;
  final bool focusable;
  final bool showTimestamp;
  final bool showTabs;
  
  const ResonanceDepthVisualizer({
    Key? key,
    required this.core,
    this.size = 100,
    this.showLabel = true,
    this.showProgress = true,
    this.isCompact = false,
    this.focusable = true,
    this.showTimestamp = false,
    this.showTabs = false,
  }) : super(key: key);
  
  @override
  State<ResonanceDepthVisualizer> createState() => _ResonanceDepthVisualizerState();
}

class _ResonanceDepthVisualizerState extends State<ResonanceDepthVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 4), // Slower for more subtle effect
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Always start animation for opal swirl effect
    _animationController.repeat(reverse: true);
  }
  
  @override
  void didUpdateWidget(ResonanceDepthVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animation is always running for continuous opal effect
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final depth = widget.core.resonanceDepth;
    final color = Color(int.parse('FF${widget.core.color}', radix: 16));
    
    if (widget.isCompact) {
      return _buildCompactView(depth, color);
    }
    
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.core.isTransitioning 
                    ? (1.0 + _pulseAnimation.value * 0.02) // Reduced from 0.05
                    : (1.0 + _pulseAnimation.value * 0.005), // Reduced from 0.01
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      boxShadow: widget.core.isTransitioning ? [
                        BoxShadow(
                          color: color.withOpacity(0.2), // Reduced from 0.3
                          blurRadius: 6, // Reduced from 8
                          spreadRadius: 1, // Reduced from 2
                        ),
                      ] : null,
                    ),
                    child: _buildSimplifiedSphere(color, depth),
                  ),
                );
              },
            ),
          ),
          if (widget.showLabel) ...[
            SizedBox(height: DesignTokens.spaceS),
            Text(
              depth.displayName,
              style: HeadingSystem.getTitleMedium(context)?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: widget.isCompact ? 12 : 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.showProgress && depth != ResonanceDepth.transcendent) ...[
              SizedBox(height: DesignTokens.spaceXS),
              _buildProgressIndicator(color),
            ],
            if (widget.core.isTransitioning) ...[
              SizedBox(height: DesignTokens.spaceXS),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  'Transitioning',
                  style: HeadingSystem.getBodySmall(context)?.copyWith(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildCompactView(ResonanceDepth depth, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            child: CustomPaint(
              painter: ResonanceDepthPainter(
                depth: depth,
                progress: widget.core.depthProgress,
                color: color,
                isTransitioning: widget.core.isTransitioning,
              ),
              child: Center(
                child: _buildSphere(color, depth, size: 10),
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spaceS),
          Text(
            depth.displayName,
            style: HeadingSystem.getBodyMedium(context)?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator(Color color) {
    final nextDepth = _getNextDepth();
    if (nextDepth == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        SizedBox(
          width: widget.size * 0.8,
          child: LinearProgressIndicator(
            value: widget.core.depthProgress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
        SizedBox(height: DesignTokens.spaceXS),
        Text(
          'Journey to ${nextDepth.displayName}',
          style: HeadingSystem.getBodySmall(context)?.copyWith(
            color: color.withOpacity(0.8),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  ResonanceDepth? _getNextDepth() {
    final currentIndex = ResonanceDepth.values.indexOf(widget.core.resonanceDepth);
    if (currentIndex < ResonanceDepth.values.length - 1) {
      return ResonanceDepth.values[currentIndex + 1];
    }
    return null;
  }
  
  Color _getIconColor(ResonanceDepth depth, Color coreColor) {
    switch (depth) {
      case ResonanceDepth.dormant:
        return Colors.white.withValues(alpha: 0.7);
      case ResonanceDepth.emerging:
        return Colors.white.withValues(alpha: 0.8);
      case ResonanceDepth.developing:
      case ResonanceDepth.deepening:
        return Colors.white.withValues(alpha: 0.9);
      case ResonanceDepth.integrated:
      case ResonanceDepth.transcendent:
        return Colors.white;
    }
  }
  
  Widget _buildSimplifiedSphere(Color color, ResonanceDepth depth, {double? size}) {
    final sphereSize = size ?? widget.size * 0.6;
    final isDormant = depth == ResonanceDepth.dormant;
    
    return Container(
      width: sphereSize,
      height: sphereSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Simplified gradient
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: isDormant ? 0.6 : 0.8),
            color.withValues(alpha: isDormant ? 0.7 : 0.9),
            color.withValues(alpha: isDormant ? 0.8 : 1.0),
            _getDarkerVariant(color).withValues(alpha: isDormant ? 0.6 : 0.8),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        // Simplified shadow
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDormant ? 0.15 : 0.25),
            blurRadius: sphereSize * 0.2,
            spreadRadius: sphereSize * 0.05,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Simple highlight
          Positioned(
            top: sphereSize * 0.15,
            left: sphereSize * 0.15,
            child: Container(
              width: sphereSize * 0.4,
              height: sphereSize * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: isDormant ? 0.3 : 0.5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Core center
          Center(
            child: Container(
              width: sphereSize * 0.3,
              height: sphereSize * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(isDormant ? 0.6 : 0.8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Keep original method for backward compatibility
  Widget _buildSphere(Color color, ResonanceDepth depth, {double? size}) {
    return _buildSimplifiedSphere(color, depth, size: size);
  }
  
  Color _getComplementaryColor(Color color) {
    // Create a complementary color for opal-like depth
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + 120) % 360).withSaturation(0.7).withLightness(0.6).toColor();
  }
  
  Color _getDarkerVariant(Color color) {
    // Create a darker variant of the color
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).withSaturation(0.8).toColor();
  }

  IconData _getCoreIcon(String coreId) {
    switch (coreId) {
      case 'optimism':
        return Icons.wb_sunny_rounded;
      case 'resilience':
        return Icons.shield_rounded;
      case 'self_awareness':
        return Icons.self_improvement_rounded;
      case 'creativity':
        return Icons.palette_rounded;
      case 'social_connection':
        return Icons.people_rounded;
      case 'growth_mindset':
        return Icons.trending_up_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class ResonanceDepthPainter extends CustomPainter {
  final ResonanceDepth depth;
  final double progress;
  final Color color;
  final bool isTransitioning;
  
  ResonanceDepthPainter({
    required this.depth,
    required this.progress,
    required this.color,
    required this.isTransitioning,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw depth-specific visualization
    switch (depth) {
      case ResonanceDepth.dormant:
        _drawDormant(canvas, center, radius);
        break;
      case ResonanceDepth.emerging:
        _drawEmerging(canvas, center, radius);
        break;
      case ResonanceDepth.developing:
        _drawDeveloping(canvas, center, radius);
        break;
      case ResonanceDepth.deepening:
        _drawDeepening(canvas, center, radius);
        break;
      case ResonanceDepth.integrated:
        _drawIntegrated(canvas, center, radius);
        break;
      case ResonanceDepth.transcendent:
        _drawTranscendent(canvas, center, radius);
        break;
    }
    
    // Add progress indicator if transitioning
    if (isTransitioning) {
      _drawTransitionRing(canvas, center, radius);
    }
  }
  
  void _drawDormant(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Simple, dim circle with subtle border
    canvas.drawCircle(center, radius * 0.4, paint);
    
    final borderPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawCircle(center, radius * 0.4, borderPaint);
  }
  
  void _drawEmerging(Canvas canvas, Offset center, double radius) {
    // Gentle pulsing rings
    for (int i = 0; i < 3; i++) {
      final paint = Paint()
        ..color = color.withOpacity(0.4 - i * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(
        center, 
        radius * (0.3 + i * 0.1 + progress * 0.05), 
        paint
      );
    }
    
    // Central core
    final corePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.2, corePaint);
  }
  
  void _drawDeveloping(Canvas canvas, Offset center, double radius) {
    // Growing spiral pattern
    final path = Path();
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    double angle = 0;
    double r = radius * 0.1;
    path.moveTo(
      center.dx + r * cos(angle),
      center.dy + r * sin(angle),
    );
    
    for (int i = 0; i < 80; i++) {
      angle += 0.15;
      r += radius * 0.008 * (1 + progress * 0.3);
      if (r > radius * 0.8) break;
      
      path.lineTo(
        center.dx + r * cos(angle),
        center.dy + r * sin(angle),
      );
    }
    
    canvas.drawPath(path, paint);
    
    // Central core
    final corePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.15, corePaint);
  }
  
  void _drawDeepening(Canvas canvas, Offset center, double radius) {
    // Rippling waves emanating from the center
    final waveCount = 3;
    for (int wave = 0; wave < waveCount; wave++) {
      final waveRadius = radius * (0.5 + wave * 0.2);
      final opacity = 0.3 - wave * 0.08;
      
      // Create ripple effect
      final path = Path();
      final points = 36; // More points for smoother waves
      
      for (int i = 0; i <= points; i++) {
        final angle = (i / points) * 2 * pi;
        final waveAmplitude = sin(angle * 4 + wave * pi / 2) * radius * 0.05 * progress;
        final r = waveRadius + waveAmplitude;
        
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      
      // Wave fill
      final wavePaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, wavePaint);
      
      // Wave outline
      final outlinePaint = Paint()
        ..color = color.withOpacity(opacity * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawPath(path, outlinePaint);
    }
    
    // Central glow
    final glowGradient = RadialGradient(
      colors: [
        color.withOpacity(0.4),
        color.withOpacity(0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    final glowPaint = Paint()
      ..shader = glowGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.6),
      );
    
    canvas.drawCircle(center, radius * 0.6, glowPaint);
  }
  
  void _drawIntegrated(Canvas canvas, Offset center, double radius) {
    // Draw a smooth, glowing circle that complements the sphere
    // Multiple soft glowing rings to create depth
    for (int i = 3; i >= 0; i--) {
      final ringRadius = radius * (0.95 - i * 0.1);
      final opacity = 0.15 + i * 0.05;
      
      // Outer glow
      final glowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(center, ringRadius, glowPaint);
      
      // Ring
      final ringPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - i * 0.3;
      
      canvas.drawCircle(center, ringRadius, ringPaint);
    }
    
    // Inner radiant circle with soft gradient
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.2),
        color.withOpacity(0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.8, 1.0],
    );
    
    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.9),
      )
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.9, gradientPaint);
    
    // Add subtle pulsing dots around the sphere for integrated energy
    final dotCount = 8;
    final dotRadius = radius * 0.7;
    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * pi;
      final dotX = center.dx + dotRadius * cos(angle);
      final dotY = center.dy + dotRadius * sin(angle);
      
      final dotPaint = Paint()
        ..color = color.withOpacity(0.4 + sin(angle * 2) * 0.2)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);
    }
  }
  
  void _drawTranscendent(Canvas canvas, Offset center, double radius) {
    // Radiant burst with dynamic rays
    final gradient = RadialGradient(
      colors: [
        color,
        color.withOpacity(0.8),
        color.withOpacity(0.4),
        color.withOpacity(0.1),
        color.withOpacity(0.0),
      ],
      stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
    );
    
    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    
    canvas.drawCircle(center, radius, gradientPaint);
    
    // Dynamic rays
    final rayPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi;
      final rayLength = radius * (0.7 + sin(i * 0.5) * 0.2);
      
      final start = Offset(
        center.dx + radius * 0.4 * cos(angle),
        center.dy + radius * 0.4 * sin(angle),
      );
      final end = Offset(
        center.dx + rayLength * cos(angle),
        center.dy + rayLength * sin(angle),
      );
      
      canvas.drawLine(start, end, rayPaint);
    }
    
    // Central brilliant core
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.25, corePaint);
  }
  
  void _drawTransitionRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius * 0.95, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Bioluminescent flow painter for jellyfish-like internal movement
class BioluminescentFlowPainter extends CustomPainter {
  final Color coreColor;
  final Color complementaryColor;
  final double flowPhase;
  final double intensity;
  final bool isDormant;
  final double breathingScale;
  
  BioluminescentFlowPainter({
    required this.coreColor,
    required this.complementaryColor,
    required this.flowPhase,
    required this.intensity,
    required this.isDormant,
    required this.breathingScale,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create organic flow patterns like jellyfish internal movement
    final flowPaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.screen;
    
    // Multiple flowing layers for depth
    for (int layer = 0; layer < (isDormant ? 2 : 3); layer++) {
      final layerRadius = radius * (0.3 + layer * 0.15);
      final layerPhase = flowPhase + layer * 3.14159 / 3;
      final layerOpacity = (isDormant ? 0.08 : 0.15) - layer * 0.02;
      
      // Create organic wave patterns
      final path = Path();
      bool first = true;
      
      for (int i = 0; i <= 40; i++) {
        final angle = (i / 40.0) * 2 * 3.14159;
        final waveOffset = sin(layerPhase + angle * (2 + layer)) * 
                          (isDormant ? 6 : 12) * breathingScale;
        final currentRadius = layerRadius + waveOffset;
        
        final x = center.dx + currentRadius * cos(angle);
        final y = center.dy + currentRadius * sin(angle);
        
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      
      // Create gradient for organic glow
      final gradient = RadialGradient(
        center: Alignment.center,
        colors: [
          coreColor.withOpacity(layerOpacity * intensity),
          complementaryColor.withOpacity(layerOpacity * intensity * 0.7),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      );
      
      flowPaint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: layerRadius * 1.3),
      );
      
      canvas.drawPath(path, flowPaint);
    }
    
    // Add flowing light tendrils (like jellyfish tentacles of light)
    if (!isDormant) {
      for (int i = 0; i < 4; i++) {
        final tendrilAngle = flowPhase + i * 3.14159 / 2;
        final tendrilPaint = Paint()
          ..color = coreColor.withOpacity(0.1 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        
        final startRadius = radius * 0.15;
        final endRadius = radius * 0.6;
        
        final path = Path();
        path.moveTo(
          center.dx + startRadius * cos(tendrilAngle),
          center.dy + startRadius * sin(tendrilAngle),
        );
        
        // Create wavy tendril
        for (double t = 0; t <= 1; t += 0.2) {
          final currentRadius = startRadius + (endRadius - startRadius) * t;
          final waveAngle = tendrilAngle + sin(flowPhase * 1.5 + t * 3) * 0.2;
          
          path.lineTo(
            center.dx + currentRadius * cos(waveAngle),
            center.dy + currentRadius * sin(waveAngle),
          );
        }
        
        canvas.drawPath(path, tendrilPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(BioluminescentFlowPainter oldDelegate) {
    return oldDelegate.flowPhase != flowPhase ||
           oldDelegate.intensity != intensity ||
           oldDelegate.breathingScale != breathingScale ||
           oldDelegate.isDormant != isDormant;
  }
}

class OpalSwirliPainter extends CustomPainter {
  final Color primaryColor;
  final Color complementaryColor;
  final double animationValue;
  
  OpalSwirliPainter({
    required this.primaryColor,
    required this.complementaryColor,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create opal-like swirls and patterns
    _drawOpalSwirls(canvas, center, radius);
    _drawInternalPatterns(canvas, center, radius);
  }
  
  void _drawOpalSwirls(Canvas canvas, Offset center, double radius) {
    // Create flowing organic shapes like in an opal
    final path1 = Path();
    final path2 = Path();
    final path3 = Path();
    
    // First swirl pattern
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * pi;
      final r = radius * (0.3 + sin(angle * 3 + animationValue * pi) * 0.2);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    path1.close();
    
    // Second swirl pattern
    for (int i = 0; i < 80; i++) {
      final angle = (i / 80) * 2 * pi + pi / 3;
      final r = radius * (0.5 + sin(angle * 2 + animationValue * pi * 0.7) * 0.15);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    path2.close();
    
    // Third swirl pattern
    for (int i = 0; i < 100; i++) {
      final angle = (i / 100) * 2 * pi - pi / 6;
      final r = radius * (0.7 + sin(angle * 1.5 + animationValue * pi * 1.3) * 0.1);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      
      if (i == 0) {
        path3.moveTo(x, y);
      } else {
        path3.lineTo(x, y);
      }
    }
    path3.close();
    
    // Paint the swirls with different colors and opacities
    final paint1 = Paint()
      ..color = complementaryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    final paint2 = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    final paint3 = Paint()
      ..color = Color.lerp(primaryColor, complementaryColor, 0.5)!.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint3);
  }
  
  void _drawInternalPatterns(Canvas canvas, Offset center, double radius) {
    // Add more subtle internal patterns for depth
    for (int layer = 0; layer < 3; layer++) {
      final layerRadius = radius * (0.8 - layer * 0.2);
      final opacity = 0.08 - layer * 0.02;
      
      final gradient = RadialGradient(
        center: Alignment(-0.3 + layer * 0.1, -0.4 + layer * 0.15),
        radius: 0.6,
        colors: [
          Colors.white.withValues(alpha: opacity * 2),
          primaryColor.withValues(alpha: opacity),
          complementaryColor.withValues(alpha: opacity * 0.7),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: layerRadius),
        );
      
      canvas.drawCircle(center, layerRadius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// A smaller, simpler version of the opal sphere for icons and small UI elements
class MiniOpalSphere extends StatefulWidget {
  final Color color;
  final double size;
  
  const MiniOpalSphere({
    Key? key,
    required this.color,
    this.size = 24,
  }) : super(key: key);
  
  @override
  State<MiniOpalSphere> createState() => _MiniOpalSphereState();
}

class _MiniOpalSphereState extends State<MiniOpalSphere>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _pulseAnimation.value * 0.02, // Very subtle breathing
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 1.0,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.6),
                  widget.color.withValues(alpha: 0.8),
                  widget.color.withValues(alpha: 1.0),
                  _getDarkerVariant(widget.color).withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.15, 0.4, 0.7, 0.9, 1.0],
              ),
              boxShadow: [
                // Soft glow
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: widget.size * 0.2,
                  spreadRadius: widget.size * 0.05,
                ),
                // Inner depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: widget.size * 0.1,
                  spreadRadius: -widget.size * 0.02,
                  offset: Offset(widget.size * 0.02, widget.size * 0.02),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subtle swirl pattern
                Positioned.fill(
                  child: ClipOval(
                    child: CustomPaint(
                      painter: MiniOpalSwirliPainter(
                        primaryColor: widget.color,
                        complementaryColor: _getComplementaryColor(widget.color),
                        animationValue: _pulseAnimation.value,
                      ),
                    ),
                  ),
                ),
                // Highlight
                Positioned(
                  top: widget.size * 0.1,
                  left: widget.size * 0.1,
                  child: Container(
                    width: widget.size * 0.3,
                    height: widget.size * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getComplementaryColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + 120) % 360).withSaturation(0.7).withLightness(0.6).toColor();
  }
  
  Color _getDarkerVariant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).withSaturation(0.8).toColor();
  }
}

/// Simplified painter for mini opal spheres
class MiniOpalSwirliPainter extends CustomPainter {
  final Color primaryColor;
  final Color complementaryColor;
  final double animationValue;
  
  MiniOpalSwirliPainter({
    required this.primaryColor,
    required this.complementaryColor,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Simplified swirl for small size
    final path = Path();
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * pi;
      final r = radius * (0.4 + sin(angle * 2 + animationValue * pi) * 0.15);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    final paint = Paint()
      ..color = complementaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}