import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final bool animate;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 8),
    this.animate = true,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<Color> _currentColors;
  late List<Color> _targetColors;

  @override
  void initState() {
    super.initState();
    _currentColors = List.from(widget.colors);
    _targetColors = _generateVariantColors(widget.colors);
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _generateVariantColors(List<Color> baseColors) {
    return baseColors.map((color) {
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness(
        (hsl.lightness + 0.05).clamp(0.0, 1.0)
      ).withSaturation(
        (hsl.saturation + 0.1).clamp(0.0, 1.0)
      ).toColor();
    }).toList();
  }

  Color _lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t) ?? a;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedColors = List.generate(
          _currentColors.length,
          (index) => _lerpColor(
            _currentColors[index],
            _targetColors[index],
            _animation.value,
          ),
        );

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: animatedColors,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}