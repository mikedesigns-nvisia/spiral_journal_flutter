import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/accessibility_service.dart';
import '../services/core_visual_consistency_service.dart';

/// Service that provides smooth 60fps animations and micro-interactions for core components
class CoreAnimationService {
  static final CoreAnimationService _instance = CoreAnimationService._internal();
  factory CoreAnimationService() => _instance;
  CoreAnimationService._internal();

  final AccessibilityService _accessibilityService = AccessibilityService();
  final CoreVisualConsistencyService _visualConsistencyService = CoreVisualConsistencyService();

  /// Create smooth core transition animations
  PageRouteBuilder<T> createCoreTransition<T>({
    required Widget destination,
    required String transitionType,
    Duration? duration,
    Curve? curve,
  }) {
    final animationDuration = duration ?? 
        _accessibilityService.getAnimationDuration(const Duration(milliseconds: 300));
    final animationCurve = curve ?? 
        _accessibilityService.getAnimationCurve(Curves.easeInOutCubic);

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => destination,
      transitionDuration: animationDuration,
      reverseTransitionDuration: animationDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case 'slide':
            return _buildSlideTransition(animation, child);
          case 'fade':
            return _buildFadeTransition(animation, child);
          case 'scale':
            return _buildScaleTransition(animation, child);
          case 'hero':
            return _buildHeroTransition(animation, child);
          default:
            return _buildSlideTransition(animation, child);
        }
      },
    );
  }

  Widget _buildSlideTransition(Animation<double> animation, Widget child) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: child,
    );
  }

  Widget _buildFadeTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  Widget _buildScaleTransition(Animation<double> animation, Widget child) {
    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: _accessibilityService.getAnimationCurve(Curves.elasticOut),
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: child,
    );
  }

  Widget _buildHeroTransition(Animation<double> animation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
        )),
        child: child,
      ),
    );
  }

  /// Create smooth level change animations
  Widget createLevelChangeAnimation({
    required Widget child,
    required AnimationController controller,
    required double fromLevel,
    required double toLevel,
    required Color color,
  }) {
    final progressAnimation = Tween<double>(
      begin: fromLevel,
      end: toLevel,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
    ));

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _accessibilityService.reducedMotionMode ? 1.02 : 1.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.elasticOut),
    ));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: _accessibilityService.reducedMotionMode ? null : [
                BoxShadow(
                  color: color.withValues(alpha: 0.3 * controller.value),
                  blurRadius: 8 * controller.value,
                  spreadRadius: 2 * controller.value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Create milestone celebration animation
  Widget createMilestoneAnimation({
    required Widget child,
    required AnimationController controller,
    required Color celebrationColor,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: _accessibilityService.reducedMotionMode ? 1.05 : 1.3,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.bounceOut),
    ));

    final rotationAnimation = Tween<double>(
      begin: 0.0,
      end: _accessibilityService.reducedMotionMode ? 0.0 : 0.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.elasticOut),
    ));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: _accessibilityService.reducedMotionMode ? null : [
                  BoxShadow(
                    color: celebrationColor.withValues(alpha: 0.5 * controller.value),
                    blurRadius: 20 * controller.value,
                    spreadRadius: 5 * controller.value,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  child,
                  if (!_accessibilityService.reducedMotionMode)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CelebrationParticlesPainter(
                          progress: controller.value,
                          color: celebrationColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Create pulse animation for updates
  Widget createPulseAnimation({
    required Widget child,
    required AnimationController controller,
    required Color pulseColor,
    double intensity = 1.0,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0 + (0.05 * intensity * (_accessibilityService.reducedMotionMode ? 0.5 : 1.0)),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOut),
    ));

    final opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Opacity(
            opacity: opacityAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: _accessibilityService.reducedMotionMode ? null : [
                  BoxShadow(
                    color: pulseColor.withValues(alpha: 0.3 * controller.value),
                    blurRadius: 6 * controller.value,
                    spreadRadius: 1 * controller.value,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Create shimmer effect for loading states
  Widget createShimmerEffect({
    required Widget child,
    required AnimationController controller,
    Color? shimmerColor,
  }) {
    if (_accessibilityService.reducedMotionMode) {
      return child;
    }

    final shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                (shimmerColor ?? Colors.white).withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: [
                (shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                shimmerAnimation.value.clamp(0.0, 1.0),
                (shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }

  /// Provide contextual haptic feedback
  void provideHapticFeedback(CoreInteractionType type) {
    if (_accessibilityService.reducedMotionMode) return;

    switch (type) {
      case CoreInteractionType.coreSelection:
        HapticFeedback.lightImpact();
        break;
      case CoreInteractionType.levelIncrease:
        HapticFeedback.mediumImpact();
        break;
      case CoreInteractionType.milestoneAchieved:
        HapticFeedback.heavyImpact();
        break;
      case CoreInteractionType.navigation:
        HapticFeedback.selectionClick();
        break;
      case CoreInteractionType.error:
        HapticFeedback.vibrate();
        break;
    }
  }

  /// Create micro-interactions for enhanced UX
  Widget createMicroInteraction({
    required Widget child,
    required VoidCallback? onTap,
    CoreInteractionType interactionType = CoreInteractionType.coreSelection,
    bool enableHover = true,
    bool enableScale = true,
  }) {
    return _MicroInteractionWidget(
      onTap: onTap,
      interactionType: interactionType,
      enableHover: enableHover,
      enableScale: enableScale,
      animationService: this,
      child: child,
    );
  }

  /// Create staggered animation for multiple items
  List<Widget> createStaggeredAnimation({
    required List<Widget> children,
    required AnimationController controller,
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    final adjustedDelay = _accessibilityService.getAnimationDuration(staggerDelay);
    
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      final delayedAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          (index * adjustedDelay.inMilliseconds / controller.duration!.inMilliseconds).clamp(0.0, 0.8),
          1.0,
          curve: _accessibilityService.getAnimationCurve(Curves.easeOutCubic),
        ),
      ));

      return AnimatedBuilder(
        animation: delayedAnimation,
        builder: (context, _) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - delayedAnimation.value)),
            child: Opacity(
              opacity: delayedAnimation.value,
              child: child,
            ),
          );
        },
      );
    }).toList();
  }

  /// Create smooth progress bar animation
  Widget createProgressBarAnimation({
    required double progress,
    required Color color,
    required double height,
    Duration? duration,
  }) {
    final animationDuration = duration ?? 
        _accessibilityService.getAnimationDuration(const Duration(milliseconds: 800));

    return TweenAnimationBuilder<double>(
      duration: animationDuration,
      tween: Tween<double>(begin: 0, end: progress),
      curve: _accessibilityService.getAnimationCurve(Curves.easeInOutCubic),
      builder: (context, animatedProgress, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedProgress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: _accessibilityService.reducedMotionMode ? null : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Micro-interaction widget for enhanced UX
class _MicroInteractionWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final CoreInteractionType interactionType;
  final bool enableHover;
  final bool enableScale;
  final CoreAnimationService animationService;

  const _MicroInteractionWidget({
    required this.child,
    required this.onTap,
    required this.interactionType,
    required this.enableHover,
    required this.enableScale,
    required this.animationService,
  });

  @override
  State<_MicroInteractionWidget> createState() => _MicroInteractionWidgetState();
}

class _MicroInteractionWidgetState extends State<_MicroInteractionWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isHovered = false;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    
    final accessibilityService = AccessibilityService();
    
    _hoverController = AnimationController(
      duration: accessibilityService.getAnimationDuration(const Duration(milliseconds: 200)),
      vsync: this,
    );
    
    _tapController = AnimationController(
      duration: accessibilityService.getAnimationDuration(const Duration(milliseconds: 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: accessibilityService.reducedMotionMode ? 1.02 : 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: accessibilityService.getAnimationCurve(Curves.easeInOut),
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: accessibilityService.getAnimationCurve(Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isTapped = true);
    _tapController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isTapped = false);
    _tapController.reverse();
    
    if (widget.onTap != null) {
      widget.animationService.provideHapticFeedback(widget.interactionType);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    setState(() => _isTapped = false);
    _tapController.reverse();
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (!widget.enableHover) return;
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _handleHoverExit(PointerExitEvent event) {
    if (!widget.enableHover) return;
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handleHoverEnter,
      onExit: _handleHoverExit,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_hoverController, _tapController]),
          builder: (context, child) {
            final scale = widget.enableScale 
                ? _scaleAnimation.value * (1.0 - (_tapController.value * 0.05))
                : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: AccessibilityService().reducedMotionMode ? null : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1 * _elevationAnimation.value / 4),
                      blurRadius: _elevationAnimation.value * 2,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for celebration particles
class CelebrationParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  CelebrationParticlesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6 * (1 - progress))
      ..style = PaintingStyle.fill;

    // Draw celebration particles
    final random = math.Random(42); // Fixed seed for consistent animation
    
    for (int i = 0; i < 15; i++) {
      final angle = (i * 2 * math.pi / 15) + (progress * math.pi);
      final distance = (20 + random.nextDouble() * 30) * progress;
      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance;
      final radius = (2 + random.nextDouble() * 3) * (1 - progress);
      
      if (x >= 0 && x <= size.width && y >= 0 && y <= size.height) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CelebrationParticlesPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}

/// Core interaction types for haptic feedback
enum CoreInteractionType {
  coreSelection,
  levelIncrease,
  milestoneAchieved,
  navigation,
  error,
}