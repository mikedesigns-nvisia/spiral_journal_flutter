import 'package:flutter/material.dart';
import '../utils/animation_constants.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool enableHoverEffect;
  final bool enableTapEffect;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = AnimationConstants.mediumDuration,
    this.curve = AnimationConstants.smoothCurve,
    this.margin,
    this.padding,
    this.color,
    this.borderRadius,
    this.enableHoverEffect = true,
    this.enableTapEffect = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: AnimationConstants.cardElevationNormal,
      end: AnimationConstants.cardElevationHovered,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHoverEnter() {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = true);
    if (!_isPressed) _controller.forward();
  }

  void _handleHoverExit() {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = false);
    if (!_isPressed) _controller.reverse();
  }

  void _handleTapDown() {
    if (!widget.enableTapEffect || widget.onTap == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp() {
    if (!widget.enableTapEffect || widget.onTap == null) return;
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHoverEnter(),
      onExit: (_) => _handleHoverExit(),
      child: GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Container(
                margin: widget.margin,
                child: Material(
                  elevation: _elevationAnimation.value,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                  color: widget.color ?? Theme.of(context).cardColor,
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}