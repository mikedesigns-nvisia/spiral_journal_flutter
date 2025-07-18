import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for common animations and transitions
class AnimationUtils {
  /// Slide transition from bottom
  static Widget slideFromBottom({
    required Widget child,
    required Animation<double> animation,
    Offset? offset,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: offset ?? const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  /// Slide transition from right
  static Widget slideFromRight({
    required Widget child,
    required Animation<double> animation,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  /// Fade transition
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeInOut,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }

  /// Scale transition
  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.elasticOut,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      alignment: alignment,
      child: child,
    );
  }

  /// Combined fade and scale transition
  static Widget fadeScaleTransition({
    required Widget child,
    required Animation<double> animation,
    double scaleBegin = 0.8,
    Curve curve = Curves.easeOutBack,
  }) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: scaleBegin,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        )),
        child: child,
      ),
    );
  }

  /// Staggered animation for lists
  static Widget staggeredAnimation({
    required Widget child,
    required Animation<double> animation,
    required int index,
    int totalItems = 1,
    Duration delay = const Duration(milliseconds: 100),
  }) {
    final itemDelay = delay.inMilliseconds * index;
    final totalDuration = 1000; // Default duration since Animation doesn't have duration property
    final startTime = itemDelay / totalDuration;
    
    if (startTime >= 1.0) return child;
    
    final interval = Interval(
      startTime.clamp(0.0, 1.0),
      1.0,
      curve: Curves.easeOutCubic,
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: interval,
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: interval,
        ),
        child: child,
      ),
    );
  }

  /// Bounce animation
  static Widget bounceAnimation({
    required Widget child,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final bounceValue = Curves.elasticOut.transform(animation.value);
        return Transform.scale(
          scale: bounceValue,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Rotation animation
  static Widget rotationAnimation({
    required Widget child,
    required Animation<double> animation,
    double turns = 1.0,
  }) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.0,
        end: turns,
      ).animate(animation),
      child: child,
    );
  }

  /// Custom page route with slide transition
  static PageRouteBuilder<T> createSlideRoute<T>({
    required Widget page,
    RouteSettings? settings,
    SlideDirection direction = SlideDirection.fromRight,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.fromRight:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.fromLeft:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.fromTop:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.fromBottom:
            begin = const Offset(0.0, 1.0);
            break;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
    );
  }

  /// Custom page route with fade transition
  static PageRouteBuilder<T> createFadeRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
    );
  }

  /// Custom page route with scale transition
  static PageRouteBuilder<T> createScaleRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutBack,
    Alignment alignment = Alignment.center,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          alignment: alignment,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Haptic feedback utilities
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Animated counter
  static Widget animatedCounter({
    required int value,
    required TextStyle style,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOutCubic,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toString(),
          style: style,
        );
      },
    );
  }

  /// Animated progress bar
  static Widget animatedProgressBar({
    required double progress,
    Color? backgroundColor,
    Color? valueColor,
    double height = 4.0,
    BorderRadius? borderRadius,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return LinearProgressIndicator(
          value: animatedProgress,
          backgroundColor: backgroundColor,
          valueColor: valueColor != null 
              ? AlwaysStoppedAnimation<Color>(valueColor)
              : null,
          minHeight: height,
        );
      },
    );
  }

  /// Pulse animation for attention
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // This would need to be handled by the parent widget to repeat
      },
      child: child,
    );
  }
}

/// Directions for slide animations
enum SlideDirection {
  fromLeft,
  fromRight,
  fromTop,
  fromBottom,
}

/// Animated list item widget
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final bool slideFromBottom;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.slideFromBottom = true,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    // Start animation with delay based on index
    Future.delayed(
      Duration(milliseconds: widget.delay.inMilliseconds * widget.index),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slideFromBottom) {
      return AnimationUtils.slideFromBottom(
        animation: _animation,
        child: AnimationUtils.fadeTransition(
          animation: _animation,
          child: widget.child,
        ),
      );
    } else {
      return AnimationUtils.fadeScaleTransition(
        animation: _animation,
        child: widget.child,
      );
    }
  }
}

/// Hero animation wrapper
class HeroWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  final bool enabled;

  const HeroWrapper({
    super.key,
    required this.tag,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    
    return Hero(
      tag: tag,
      child: child,
    );
  }
}