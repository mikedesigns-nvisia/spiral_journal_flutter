import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/core.dart';
import '../models/journal_entry.dart';
import '../design_system/design_tokens.dart';

/// Animated widget showing the flow from journal entry to core impacts
class JournalToCoreFlowAnimation extends StatefulWidget {
  final JournalEntry journalEntry;
  final List<EmotionalCore> affectedCores;
  final Map<String, double> coreImpacts;
  final bool autoStart;
  final VoidCallback? onAnimationComplete;
  final Duration animationDuration;

  const JournalToCoreFlowAnimation({
    super.key,
    required this.journalEntry,
    required this.affectedCores,
    required this.coreImpacts,
    this.autoStart = true,
    this.onAnimationComplete,
    this.animationDuration = const Duration(milliseconds: 3000),
  });

  @override
  State<JournalToCoreFlowAnimation> createState() => _JournalToCoreFlowAnimationState();
}

class _JournalToCoreFlowAnimationState extends State<JournalToCoreFlowAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  
  late Animation<double> _journalScaleAnimation;
  late Animation<double> _analysisAnimation;
  late Animation<double> _flowAnimation;
  late Animation<double> _coreRevealAnimation;
  late Animation<double> _impactAnimation;
  
  final List<FlowParticle> _particles = [];
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    
    if (widget.autoStart) {
      _startAnimation();
    }
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Journal entry scale animation
    _journalScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.2, curve: Curves.elasticOut),
    ));

    // Analysis phase animation
    _analysisAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
    ));

    // Flow particles animation
    _flowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    ));

    // Core reveal animation
    _coreRevealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 0.8, curve: Curves.elasticOut),
    ));

    // Impact animation
    _impactAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.8, 1.0, curve: Curves.bounceOut),
    ));

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _initializeParticles() {
    final random = math.Random();
    
    for (int i = 0; i < 20; i++) {
      _particles.add(FlowParticle(
        startX: 0.5,
        startY: 0.3,
        endX: 0.2 + (random.nextDouble() * 0.6),
        endY: 0.7 + (random.nextDouble() * 0.2),
        color: _getRandomParticleColor(),
        size: 2.0 + (random.nextDouble() * 3.0),
        delay: random.nextDouble() * 0.5,
      ));
    }
  }

  Color _getRandomParticleColor() {
    final colors = [
      DesignTokens.primaryColor,
      DesignTokens.successColor,
      DesignTokens.warningColor,
      Colors.purple,
      Colors.teal,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  void _startAnimation() {
    if (!_isAnimating) {
      setState(() {
        _isAnimating = true;
      });
      _mainController.forward();
      _particleController.repeat();
    }
  }

  void resetAnimation() {
    _mainController.reset();
    _particleController.reset();
    _pulseController.reset();
    setState(() {
      _isAnimating = false;
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.primaryColor.withValues(alpha: 0.05),
            DesignTokens.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadius3),
        border: Border.all(
          color: DesignTokens.borderColor,
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return CustomPaint(
            painter: FlowAnimationPainter(
              journalScale: _journalScaleAnimation.value,
              analysisProgress: _analysisAnimation.value,
              flowProgress: _flowAnimation.value,
              coreReveal: _coreRevealAnimation.value,
              impactProgress: _impactAnimation.value,
              particles: _particles,
              particleProgress: _particleController.value,
              pulseProgress: _pulseController.value,
              journalEntry: widget.journalEntry,
              affectedCores: widget.affectedCores,
              coreImpacts: widget.coreImpacts,
            ),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  // Start button (if not auto-started)
                  if (!widget.autoStart && !_isAnimating)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: _startAnimation,
                        backgroundColor: DesignTokens.primaryColor,
                        child: const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                    ),
                  
                  // Reset button (if animation completed)
                  if (_mainController.isCompleted)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: resetAnimation,
                        backgroundColor: DesignTokens.neutralColor,
                        child: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                  
                  // Animation labels
                  _buildAnimationLabels(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimationLabels() {
    return Stack(
      children: [
        // Journal label
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _journalScaleAnimation.value,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacing3,
                  vertical: DesignTokens.spacing2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Journal Entry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Analysis label
        Positioned(
          top: 180,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _analysisAnimation.value,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacing3,
                  vertical: DesignTokens.spacing2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DesignTokens.primaryColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: DesignTokens.spacing2),
                    
                    Text(
                      'Processing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Core impact labels
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _coreRevealAnimation.value,
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.affectedCores.take(3).map((core) {
                final impact = widget.coreImpacts[core.id] ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacing2,
                    vertical: DesignTokens.spacing1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DesignTokens.borderRadius2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        core.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      
                      Text(
                        '${impact > 0 ? '+' : ''}${(impact * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: impact > 0 
                              ? DesignTokens.successColor 
                              : DesignTokens.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Data model for flow particles
class FlowParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final double size;
  final double delay;

  FlowParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.size,
    required this.delay,
  });
}

/// Custom painter for the flow animation
class FlowAnimationPainter extends CustomPainter {
  final double journalScale;
  final double analysisProgress;
  final double flowProgress;
  final double coreReveal;
  final double impactProgress;
  final List<FlowParticle> particles;
  final double particleProgress;
  final double pulseProgress;
  final JournalEntry journalEntry;
  final List<EmotionalCore> affectedCores;
  final Map<String, double> coreImpacts;

  FlowAnimationPainter({
    required this.journalScale,
    required this.analysisProgress,
    required this.flowProgress,
    required this.coreReveal,
    required this.impactProgress,
    required this.particles,
    required this.particleProgress,
    required this.pulseProgress,
    required this.journalEntry,
    required this.affectedCores,
    required this.coreImpacts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw journal entry
    _drawJournalEntry(canvas, size, paint);
    
    // Draw analysis phase
    _drawAnalysisPhase(canvas, size, paint);
    
    // Draw flow particles
    _drawFlowParticles(canvas, size, paint);
    
    // Draw cores
    _drawCores(canvas, size, paint);
    
    // Draw impact indicators
    _drawImpactIndicators(canvas, size, paint);
  }

  void _drawJournalEntry(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.5, size.height * 0.3);
    final radius = 30.0 * journalScale;
    
    // Journal circle
    paint.color = DesignTokens.primaryColor.withValues(alpha: 0.8);
    canvas.drawCircle(center, radius, paint);
    
    // Journal icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw pen icon
    final penPath = Path();
    penPath.moveTo(center.dx - 8, center.dy + 8);
    penPath.lineTo(center.dx + 8, center.dy - 8);
    penPath.moveTo(center.dx + 4, center.dy - 12);
    penPath.lineTo(center.dx + 8, center.dy - 8);
    penPath.lineTo(center.dx + 12, center.dy - 4);
    
    canvas.drawPath(penPath, iconPaint);
  }

  void _drawAnalysisPhase(Canvas canvas, Size size, Paint paint) {
    if (analysisProgress <= 0) return;
    
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final radius = 40.0 * analysisProgress;
    
    // Analysis circle
    paint.color = DesignTokens.warningColor.withValues(alpha: 0.3 * analysisProgress);
    canvas.drawCircle(center, radius, paint);
    
    // Analysis waves
    for (int i = 0; i < 3; i++) {
      final waveRadius = radius + (i * 15.0);
      final waveOpacity = (1.0 - (i * 0.3)) * analysisProgress;
      
      paint.color = DesignTokens.warningColor.withValues(alpha: 0.2 * waveOpacity);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      
      canvas.drawCircle(center, waveRadius, paint);
    }
    
    paint.style = PaintingStyle.fill;
  }

  void _drawFlowParticles(Canvas canvas, Size size, Paint paint) {
    if (flowProgress <= 0) return;
    
    for (final particle in particles) {
      final adjustedProgress = math.max(0.0, 
          math.min(1.0, (particleProgress - particle.delay) / (1.0 - particle.delay)));
      
      if (adjustedProgress <= 0) continue;
      
      final startPos = Offset(
        size.width * particle.startX,
        size.height * particle.startY,
      );
      
      final endPos = Offset(
        size.width * particle.endX,
        size.height * particle.endY,
      );
      
      final currentPos = Offset.lerp(startPos, endPos, adjustedProgress)!;
      
      paint.color = particle.color.withValues(alpha: 
        (1.0 - adjustedProgress) * flowProgress,
      );
      
      canvas.drawCircle(currentPos, particle.size, paint);
    }
  }

  void _drawCores(Canvas canvas, Size size, Paint paint) {
    if (coreReveal <= 0) return;
    
    final corePositions = _getCorePositions(size);
    
    for (int i = 0; i < affectedCores.length && i < corePositions.length; i++) {
      final core = affectedCores[i];
      final position = corePositions[i];
      final radius = 25.0 * coreReveal;
      
      // Core circle
      try {
        paint.color = Color(int.parse(core.color.replaceFirst('#', '0xFF')))
            .withValues(alpha: 0.8 * coreReveal);
      } catch (e) {
        paint.color = DesignTokens.primaryColor.withValues(alpha: 0.8 * coreReveal);
      }
      
      canvas.drawCircle(position, radius, paint);
      
      // Pulse effect
      if (pulseProgress > 0) {
        final pulseRadius = radius + (10.0 * pulseProgress);
        paint.color = paint.color.withValues(alpha: 0.3 * (1.0 - pulseProgress));
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2.0;
        
        canvas.drawCircle(position, pulseRadius, paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  void _drawImpactIndicators(Canvas canvas, Size size, Paint paint) {
    if (impactProgress <= 0) return;
    
    final corePositions = _getCorePositions(size);
    
    for (int i = 0; i < affectedCores.length && i < corePositions.length; i++) {
      final core = affectedCores[i];
      final position = corePositions[i];
      final impact = coreImpacts[core.id] ?? 0.0;
      
      if (impact.abs() < 0.05) continue;
      
      // Impact arrow
      final arrowColor = impact > 0 
          ? DesignTokens.successColor 
          : DesignTokens.warningColor;
      
      paint.color = arrowColor.withValues(alpha: impactProgress);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;
      paint.strokeCap = StrokeCap.round;
      
      final arrowPath = Path();
      final arrowStart = Offset(position.dx, position.dy - 35);
      final arrowEnd = Offset(position.dx, position.dy - 45);
      
      arrowPath.moveTo(arrowStart.dx, arrowStart.dy);
      arrowPath.lineTo(arrowEnd.dx, arrowEnd.dy);
      
      // Arrow head
      if (impact > 0) {
        arrowPath.moveTo(arrowEnd.dx - 5, arrowEnd.dy + 5);
        arrowPath.lineTo(arrowEnd.dx, arrowEnd.dy);
        arrowPath.lineTo(arrowEnd.dx + 5, arrowEnd.dy + 5);
      } else {
        arrowPath.moveTo(arrowStart.dx - 5, arrowStart.dy - 5);
        arrowPath.lineTo(arrowStart.dx, arrowStart.dy);
        arrowPath.lineTo(arrowStart.dx + 5, arrowStart.dy - 5);
      }
      
      canvas.drawPath(arrowPath, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  List<Offset> _getCorePositions(Size size) {
    final positions = <Offset>[];
    final centerY = size.height * 0.75;
    final spacing = size.width / (affectedCores.length + 1);
    
    for (int i = 0; i < affectedCores.length; i++) {
      positions.add(Offset(spacing * (i + 1), centerY));
    }
    
    return positions;
  }

  @override
  bool shouldRepaint(FlowAnimationPainter oldDelegate) {
    return journalScale != oldDelegate.journalScale ||
           analysisProgress != oldDelegate.analysisProgress ||
           flowProgress != oldDelegate.flowProgress ||
           coreReveal != oldDelegate.coreReveal ||
           impactProgress != oldDelegate.impactProgress ||
           particleProgress != oldDelegate.particleProgress ||
           pulseProgress != oldDelegate.pulseProgress;
  }
}