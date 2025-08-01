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
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.core.isTransitioning) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(ResonanceDepthVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.core.isTransitioning != oldWidget.core.isTransitioning) {
      if (widget.core.isTransitioning) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
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
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.core.isTransitioning ? _pulseAnimation.value : 1.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size / 2),
                  boxShadow: widget.core.isTransitioning ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: CustomPaint(
                  painter: ResonanceDepthPainter(
                    depth: depth,
                    progress: widget.core.depthProgress,
                    color: color,
                    isTransitioning: widget.core.isTransitioning,
                  ),
                  child: Center(
                    child: Icon(
                      _getCoreIcon(widget.core.id),
                      color: _getIconColor(depth, color),
                      size: widget.size * 0.3,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showLabel) ...[
          SizedBox(height: DesignTokens.spaceM),
          Text(
            depth.displayName,
            style: HeadingSystem.getTitleMedium(context)?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: widget.isCompact ? 14 : 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.showProgress && depth != ResonanceDepth.transcendent) ...[
            SizedBox(height: DesignTokens.spaceS),
            _buildProgressIndicator(color),
          ],
          if (widget.core.isTransitioning) ...[
            SizedBox(height: DesignTokens.spaceS),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ],
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
                child: Icon(
                  _getCoreIcon(widget.core.id),
                  color: _getIconColor(depth, color),
                  size: 12,
                ),
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
        return Colors.white70;
      case ResonanceDepth.emerging:
        return Colors.white80;
      case ResonanceDepth.developing:
      case ResonanceDepth.deepening:
        return Colors.white90;
      case ResonanceDepth.integrated:
      case ResonanceDepth.transcendent:
        return Colors.white;
    }
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
    // Flowing organic shape with depth layers
    final layers = 3;
    for (int layer = 0; layer < layers; layer++) {
      final layerRadius = radius * (0.9 - layer * 0.15);
      final paint = Paint()
        ..color = color.withOpacity(0.8 - layer * 0.2)
        ..style = PaintingStyle.fill;
      
      final path = Path();
      final points = 8;
      
      for (int i = 0; i <= points; i++) {
        final angle = (i / points) * 2 * pi;
        final variation = sin(angle * 3 + layer * pi / 3) * 0.15;
        final r = layerRadius * (0.8 + variation * progress);
        
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.close();
      canvas.drawPath(path, paint);
    }
  }
  
  void _drawIntegrated(Canvas canvas, Offset center, double radius) {
    // Mandala-like pattern with multiple layers
    for (int layer = 0; layer < 4; layer++) {
      final layerRadius = radius * (0.85 - layer * 0.15);
      final segments = 6 + layer * 2;
      
      for (int i = 0; i < segments; i++) {
        final angle = (i / segments) * 2 * pi + layer * pi / 6;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(layerRadius * 0.4, -layerRadius * 0.08)
          ..quadraticBezierTo(
            layerRadius * 0.7, 0,
            layerRadius * 0.4, layerRadius * 0.08,
          )
          ..close();
        
        final paint = Paint()
          ..color = color.withOpacity(0.9 - layer * 0.15)
          ..style = PaintingStyle.fill;
        
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
    
    // Central radiant core
    final gradient = RadialGradient(
      colors: [
        color,
        color.withOpacity(0.7),
        color.withOpacity(0.3),
      ],
      stops: const [0.0, 0.7, 1.0],
    );
    
    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.3),
      );
    
    canvas.drawCircle(center, radius * 0.3, gradientPaint);
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