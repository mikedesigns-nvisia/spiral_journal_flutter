import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';
import '../design_system/component_library.dart';
import '../models/emotional_mirror_data.dart';

class EmotionalStateVisualization extends StatefulWidget {
  final MoodOverview? moodOverview;
  final bool showDescription;
  final double height;
  
  const EmotionalStateVisualization({
    super.key,
    required this.moodOverview,
    this.showDescription = true,
    this.height = 200,
  });

  @override
  State<EmotionalStateVisualization> createState() => _EmotionalStateVisualizationState();
}

class _EmotionalStateVisualizationState extends State<EmotionalStateVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<_EmotionalParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _initializeParticles();
    
    // Start animation after widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.repeat();
      }
    });
  }
  
  @override
  void dispose() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }
  
  void _initializeParticles() {
    final random = math.Random();
    const particleCount = 15;
    
    for (int i = 0; i < particleCount; i++) {
      _particles.add(
        _EmotionalParticle(
          position: Offset(
            random.nextDouble() * 280,
            random.nextDouble() * 160,
          ),
          velocity: Offset(
            (random.nextDouble() - 0.5) * 2,
            (random.nextDouble() - 0.5) * 2,
          ),
          size: random.nextDouble() * 6 + 3,
          baseColor: _getParticleColorDuringInit(random.nextDouble()),
        ),
      );
    }
  }
  
  Color _getParticleColorDuringInit(double t) {
    // Use default light theme colors during initialization
    return Color.lerp(
      DesignTokens.accentBlue,
      DesignTokens.accentYellow,
      t,
    )!;
  }
  
  Color _getParticleColor(double t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      return Color.lerp(
        const Color(0xFF64B5F6),
        const Color(0xFFFFD54F),
        t,
      )!;
    } else {
      return Color.lerp(
        DesignTokens.accentBlue,
        DesignTokens.accentYellow,
        t,
      )!;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.moodOverview == null) {
      return _buildEmptyState();
    }
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              Text(
                'Your Emotional State',
                style: HeadingSystem.getHeadlineSmall(context),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Visualization
          Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _EmotionalStatePainter(
                      particles: _particles,
                      moodBalance: widget.moodOverview!.moodBalance,
                      animationValue: _animationController.value,
                      emotionalVariety: widget.moodOverview!.emotionalVariety,
                      dominantMoods: widget.moodOverview!.dominantMoods,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          
          if (widget.showDescription) ...[
            SizedBox(height: DesignTokens.spaceL),
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: DesignTokens.iconSizeS,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                      SizedBox(width: DesignTokens.spaceS),
                      Text(
                        'Your Unique Visualization',
                        style: HeadingSystem.getTitleSmall(context),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  Text(
                    'This visualization is uniquely yours. The colors, movement, and patterns reflect your emotional journey based on your journal entries. As you continue to journal, this visualization evolves to mirror your changing emotional landscape.',
                    style: HeadingSystem.getBodySmall(context),
                  ),
                  SizedBox(height: DesignTokens.spaceM),
                  Text(
                    widget.moodOverview!.description,
                    style: HeadingSystem.getBodyMedium(context).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: SizedBox(
        height: widget.height + 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: DesignTokens.getTextTertiary(context),
              ),
              SizedBox(height: DesignTokens.spaceM),
              Text(
                'Complete your daily journal entry',
                style: HeadingSystem.getTitleMedium(context),
              ),
              SizedBox(height: DesignTokens.spaceS),
              Text(
                'Your emotional state visualization will appear here',
                style: HeadingSystem.getBodySmall(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionalParticle {
  Offset position;
  final Offset velocity;
  final Color baseColor;
  final double size;
  
  _EmotionalParticle({
    required this.position,
    required this.velocity,
    required this.baseColor,
    required this.size,
  });
}

class _EmotionalStatePainter extends CustomPainter {
  final List<_EmotionalParticle> particles;
  final double moodBalance;
  final double animationValue;
  final double emotionalVariety;
  final List<String> dominantMoods;
  
  _EmotionalStatePainter({
    required this.particles,
    required this.moodBalance,
    required this.animationValue,
    required this.emotionalVariety,
    required this.dominantMoods,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Calculate emotional state intensity
    final emotionalIntensity = (moodBalance + 1.0) / 2.0;
    
    // Draw background gradient
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0 + emotionalVariety * 0.5,
      colors: [
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.3),
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.1),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );
    
    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw particles
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      paint.shader = null;
      
      final particleSpeed = 0.5 + emotionalVariety * 1.5;
      final particleAlpha = 0.3 + emotionalIntensity * 0.4;
      
      paint.color = particle.baseColor.withValues(
        alpha: particleAlpha + math.sin(animationValue * 2 * math.pi + particle.position.dx) * 0.2,
      );
      
      final phase = i * 0.3;
      final animatedPosition = Offset(
        particle.position.dx + math.sin(animationValue * particleSpeed * math.pi + phase) * 15 * emotionalVariety,
        particle.position.dy + math.cos(animationValue * particleSpeed * math.pi * 1.3 + phase) * 10 * emotionalVariety,
      );
      
      final clampedPosition = Offset(
        animatedPosition.dx.clamp(particle.size, size.width - particle.size),
        animatedPosition.dy.clamp(particle.size, size.height - particle.size),
      );
      
      final particleSize = particle.size * (0.8 + emotionalIntensity * 0.4);
      canvas.drawCircle(clampedPosition, particleSize, paint);
      
      if (moodBalance > 0.3) {
        paint.color = particle.baseColor.withValues(alpha: 0.1);
        canvas.drawCircle(clampedPosition, particleSize * 2, paint);
      }
    }
    
    // Draw central core
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final coreRadius = 30.0 + emotionalVariety * 20.0;
    
    final coreGradient = RadialGradient(
      colors: [
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.6),
        _getEmotionalStateColor(moodBalance, emotionalVariety)
            .withValues(alpha: 0.2),
      ],
    );
    
    paint.shader = coreGradient.createShader(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: coreRadius),
    );
    
    final pulseRadius = coreRadius * (1.0 + math.sin(animationValue * 2 * math.pi) * 0.1);
    canvas.drawCircle(Offset(centerX, centerY), pulseRadius, paint);
  }
  
  Color _getEmotionalStateColor(double balance, double variety) {
    if (balance > 0.3) {
      return Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFFFF8A65),
        variety,
      )!;
    } else if (balance < -0.3) {
      return Color.lerp(
        const Color(0xFF64B5F6),
        const Color(0xFF9575CD),
        variety,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFF81C784),
        const Color(0xFF4DB6AC),
        variety,
      )!;
    }
  }
  
  @override
  bool shouldRepaint(_EmotionalStatePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.moodBalance != moodBalance ||
           oldDelegate.emotionalVariety != emotionalVariety;
  }
}