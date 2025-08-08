import 'package:flutter/material.dart';
import 'dart:math' as math;

class CoreOrbWidget extends StatefulWidget {
  final String coreId;
  final String coreName;
  final Color coreColor;
  final double progress; // 0.0 to 1.0
  final bool isDormant;
  final double size;
  final Animation<double>? breathingAnimation;
  final Animation<double>? glowAnimation;
  
  const CoreOrbWidget({
    super.key,
    required this.coreId,
    required this.coreName,
    required this.coreColor,
    required this.progress,
    this.isDormant = false,
    this.size = 120,
    this.breathingAnimation,
    this.glowAnimation,
  });

  @override
  State<CoreOrbWidget> createState() => _CoreOrbWidgetState();
}

class _CoreOrbWidgetState extends State<CoreOrbWidget>
    with TickerProviderStateMixin {
  late AnimationController _flowAnimationController;
  late AnimationController _breathingController;
  late List<AnimationController> _particleControllers;
  late Animation<double> _flowAnimation;
  late Animation<double> _internalBreathingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Flow animation for bioluminescent effect (slow, continuous)
    _flowAnimationController = AnimationController(
      duration: Duration(seconds: widget.isDormant ? 8 : 4),
      vsync: this,
    )..repeat();
    
    // Breathing animation (gentle pulsing)
    _breathingController = AnimationController(
      duration: Duration(seconds: widget.isDormant ? 6 : 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Particle controllers for floating light particles
    _particleControllers = List.generate(
      widget.isDormant ? 3 : 8,
      (index) => AnimationController(
        duration: Duration(seconds: 4 + (index % 3)),
        vsync: this,
      )..repeat(),
    );
    
    _flowAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _flowAnimationController,
      curve: Curves.linear,
    ));
    
    _internalBreathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flowAnimationController.dispose();
    _breathingController.dispose();
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adjustedColor = widget.isDormant 
        ? _desaturateColor(widget.coreColor, 0.3) 
        : widget.coreColor;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _flowAnimation,
        _internalBreathingAnimation,
        ...(_particleControllers.take(3))
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Outer translucent membrane (jellyfish shell)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      adjustedColor.withOpacity(0.1),
                      adjustedColor.withOpacity(0.2),
                      adjustedColor.withOpacity(0.05),
                    ],
                    stops: const [0.0, 0.8, 1.0],
                  ),
                  border: Border.all(
                    color: adjustedColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: adjustedColor.withOpacity(widget.isDormant ? 0.2 : 0.4),
                      blurRadius: widget.isDormant ? 15 : 25,
                      spreadRadius: widget.isDormant ? 2 : 5,
                    ),
                  ],
                ),
              ),
              
              // Layer 2: Inner bioluminescent flow
              ClipOval(
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: BioluminescentFlowPainter(
                    coreColor: adjustedColor,
                    flowPhase: _flowAnimation.value,
                    intensity: widget.progress,
                    isDormant: widget.isDormant,
                    breathingScale: _internalBreathingAnimation.value,
                  ),
                ),
              ),
              
              // Layer 3: Central nucleus (brighter core with breathing)
              Transform.scale(
                scale: _internalBreathingAnimation.value,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: adjustedColor.withOpacity(widget.isDormant ? 0.3 : 0.6),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [
                        adjustedColor.withOpacity(widget.isDormant ? 0.8 : 1.0),
                        adjustedColor.withOpacity(widget.isDormant ? 0.6 : 0.9),
                        adjustedColor.withOpacity(widget.isDormant ? 0.3 : 0.5),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Layer 4: Floating light particles (jellyfish bioluminescence)
              ...List.generate(widget.isDormant ? 3 : 8, (index) {
                if (index >= _particleControllers.length) return Container();
                return FloatingLightParticle(
                  coreColor: adjustedColor,
                  size: widget.size,
                  index: index,
                  animationController: _particleControllers[index],
                );
              }),
              
              // Layer 5: Progress indicator for active cores (subtle ring)
              if (!widget.isDormant && widget.progress > 0)
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: OrbProgressPainter(
                    progress: widget.progress,
                    color: adjustedColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to desaturate color for dormant state
  Color _desaturateColor(Color color, double amount) {
    return Color.lerp(color, Colors.grey, amount) ?? color;
  }
}

// Custom painter for progress visualization
class OrbProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  OrbProgressPainter({
    required this.progress,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Create subtle progress ring inside the orb
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round;
    
    // Draw progress arc
    final rect = Rect.fromCircle(center: center, radius: radius * 0.8);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }
  
  @override
  bool shouldRepaint(OrbProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Custom painter for bioluminescent flow effect (jellyfish-like internal movement)
class BioluminescentFlowPainter extends CustomPainter {
  final Color coreColor;
  final double flowPhase;
  final double intensity;
  final bool isDormant;
  final double breathingScale;
  
  BioluminescentFlowPainter({
    required this.coreColor,
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
    for (int layer = 0; layer < (isDormant ? 2 : 4); layer++) {
      final layerRadius = radius * (0.3 + layer * 0.2);
      final layerPhase = flowPhase + layer * math.pi / 3;
      final layerOpacity = isDormant ? 0.1 : 0.2 - layer * 0.03;
      
      // Create organic wave patterns
      final path = Path();
      bool first = true;
      
      for (int i = 0; i <= 60; i++) {
        final angle = (i / 60.0) * 2 * math.pi;
        final waveOffset = math.sin(layerPhase + angle * (3 + layer)) * 
                          (isDormant ? 8 : 15) * breathingScale;
        final currentRadius = layerRadius + waveOffset;
        
        final x = center.dx + currentRadius * math.cos(angle);
        final y = center.dy + currentRadius * math.sin(angle);
        
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
          coreColor.withOpacity(layerOpacity * intensity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      );
      
      flowPaint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: layerRadius * 1.5),
      );
      
      canvas.drawPath(path, flowPaint);
    }
    
    // Add flowing light tendrils (like jellyfish tentacles of light)
    if (!isDormant) {
      for (int i = 0; i < 6; i++) {
        final tendrilAngle = flowPhase + i * math.pi / 3;
        final tendrilPaint = Paint()
          ..color = coreColor.withOpacity(0.15 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        
        final startRadius = radius * 0.2;
        final endRadius = radius * 0.8;
        
        final path = Path();
        path.moveTo(
          center.dx + startRadius * math.cos(tendrilAngle),
          center.dy + startRadius * math.sin(tendrilAngle),
        );
        
        // Create wavy tendril
        for (double t = 0; t <= 1; t += 0.1) {
          final currentRadius = startRadius + (endRadius - startRadius) * t;
          final waveAngle = tendrilAngle + math.sin(flowPhase * 2 + t * 4) * 0.3;
          
          path.lineTo(
            center.dx + currentRadius * math.cos(waveAngle),
            center.dy + currentRadius * math.sin(waveAngle),
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

// Floating light particle widget for jellyfish-like bioluminescence
class FloatingLightParticle extends StatelessWidget {
  final Color coreColor;
  final double size;
  final int index;
  final AnimationController animationController;
  
  const FloatingLightParticle({
    super.key,
    required this.coreColor,
    required this.size,
    required this.index,
    required this.animationController,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final progress = animationController.value;
        final radius = size / 2;
        
        // Create orbital motion with some randomness
        final baseAngle = (progress * 2 * math.pi) + (index * math.pi / 4);
        final orbitRadius = radius * (0.4 + (index % 3) * 0.1);
        final waveOffset = math.sin(progress * 4 * math.pi + index) * 10;
        
        final x = radius + (orbitRadius + waveOffset) * math.cos(baseAngle);
        final y = radius + (orbitRadius + waveOffset) * math.sin(baseAngle);
        
        // Particle opacity pulsing
        final opacity = (math.sin(progress * 6 * math.pi + index) + 1) / 2 * 0.4;
        
        return Positioned(
          left: x - 3,
          top: y - 3,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: coreColor.withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: coreColor.withOpacity(opacity * 0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}