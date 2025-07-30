import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/animation_constants.dart';

class Particle {
  late double x;
  late double y;
  late double velocityX;
  late double velocityY;
  late double size;
  late Color color;
  late double opacity;
  late double rotation;
  late double rotationSpeed;
  late double gravity;
  late double life;
  late double maxLife;

  Particle({
    required double startX,
    required double startY,
    required List<Color> colors,
  }) {
    final random = math.Random();
    x = startX;
    y = startY;
    
    velocityX = (random.nextDouble() - 0.5) * 200;
    velocityY = -random.nextDouble() * 150 - 50;
    
    size = random.nextDouble() * (AnimationConstants.particleMaxSize - AnimationConstants.particleMinSize) + AnimationConstants.particleMinSize;
    color = colors[random.nextInt(colors.length)];
    opacity = 1.0;
    rotation = random.nextDouble() * 2 * math.pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 10;
    gravity = 200;
    maxLife = random.nextDouble() * 2 + 1;
    life = maxLife;
  }

  void update(double deltaTime) {
    x += velocityX * deltaTime;
    y += velocityY * deltaTime;
    velocityY += gravity * deltaTime;
    rotation += rotationSpeed * deltaTime;
    life -= deltaTime;
    opacity = (life / maxLife).clamp(0.0, 1.0);
  }

  bool get isDead => life <= 0;
}

class CelebrationParticles extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final List<Color> colors;
  final int particleCount;
  final Duration duration;

  const CelebrationParticles({
    super.key,
    required this.child,
    this.isActive = false,
    this.colors = const [
      Colors.amber,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.cyan,
      Colors.green,
    ],
    this.particleCount = AnimationConstants.particleCount,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<CelebrationParticles> createState() => _CelebrationParticlesState();
}

class _CelebrationParticlesState extends State<CelebrationParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CelebrationParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    _particles.clear();
    _controller.reset();
    _controller.forward();
    
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      
      for (int i = 0; i < widget.particleCount; i++) {
        _particles.add(Particle(
          startX: centerX,
          startY: centerY,
          colors: widget.colors,
        ));
      }
    }
  }

  void _updateParticles() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;

    _particles.removeWhere((particle) {
      particle.update(deltaTime);
      return particle.isDead;
    });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (_controller.isAnimating) {
                  // Schedule particle update for next frame instead of during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _updateParticles();
                    }
                  });
                }
                
                return CustomPaint(
                  painter: ParticlePainter(_particles),
                  child: Container(),
                );
              },
            ),
          ),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(particle.size / 4)),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return particles.length != oldDelegate.particles.length ||
        particles.any((p1) => !oldDelegate.particles.any((p2) => 
            p1.x == p2.x && p1.y == p2.y && p1.opacity == p2.opacity));
  }
}

class CelebrationButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool triggerCelebration;

  const CelebrationButton({
    super.key,
    required this.child,
    this.onPressed,
    this.triggerCelebration = false,
  });

  @override
  State<CelebrationButton> createState() => _CelebrationButtonState();
}

class _CelebrationButtonState extends State<CelebrationButton> {
  bool _showParticles = false;

  @override
  void didUpdateWidget(CelebrationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerCelebration && !oldWidget.triggerCelebration) {
      _celebrate();
    }
  }

  void _celebrate() {
    setState(() => _showParticles = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showParticles = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CelebrationParticles(
      isActive: _showParticles,
      child: GestureDetector(
        onTap: () {
          widget.onPressed?.call();
          if (widget.triggerCelebration) _celebrate();
        },
        child: widget.child,
      ),
    );
  }
}