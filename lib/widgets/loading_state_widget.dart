import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/design_tokens.dart';

/// Comprehensive loading state widget with various loading indicators
class LoadingStateWidget extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final double? progress;
  final bool showProgress;
  final Color? color;
  final double size;
  final Duration animationDuration;

  const LoadingStateWidget({
    super.key,
    this.type = LoadingType.circular,
    this.message,
    this.progress,
    this.showProgress = false,
    this.color,
    this.size = 40.0,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? DesignTokens.getPrimaryColor(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingIndicator(color),
        if (widget.message != null) ...[
          const SizedBox(height: ComponentTokens.loadingMessageSpacing),
          Text(
            widget.message!,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.showProgress && widget.progress != null) ...[
          const SizedBox(height: ComponentTokens.loadingProgressSpacing),
          LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: DesignTokens.getColorWithOpacity(color, 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: ComponentTokens.loadingProgressTextSpacing),
          Text(
            '${(widget.progress! * 100).round()}%',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );

      case LoadingType.dots:
        return _buildDotsIndicator(color);

      case LoadingType.pulse:
        return _buildPulseIndicator(color);

      case LoadingType.wave:
        return _buildWaveIndicator(color);

      case LoadingType.typing:
        return _buildTypingIndicator(color);

      case LoadingType.spinner:
        return _buildSpinnerIndicator(color);
    }
  }

  Widget _buildDotsIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_animation.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (animationValue - 0.5).abs() * 2));
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPulseIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.8 + (0.4 * _animation.value);
        final opacity = 1.0 - _animation.value;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final delay = index * 0.1;
            final animationValue = (_animation.value + delay) % 1.0;
            final height = 4 + (16 * (1 - (animationValue - 0.5).abs() * 2));
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTypingIndicator(Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animationValue = (_animation.value + delay) % 1.0;
            final opacity = animationValue < 0.5 ? animationValue * 2 : (1 - animationValue) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildSpinnerIndicator(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: 3),
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Types of loading indicators available
enum LoadingType {
  circular,
  dots,
  pulse,
  wave,
  typing,
  spinner,
}

/// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final LoadingType type;
  final Color? backgroundColor;
  final bool dismissible;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.type = LoadingType.circular,
    this.backgroundColor,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LoadingStateWidget(
                    type: type,
                    message: message,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Button with loading state
class LoadingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final Widget child;
  final bool isLoading;
  final LoadingType loadingType;
  final ButtonStyle? style;
  final bool hapticFeedback;

  const LoadingButton({
    super.key,
    this.onPressed,
    this.onPressedAsync,
    required this.child,
    this.isLoading = false,
    this.loadingType = LoadingType.circular,
    this.style,
    this.hapticFeedback = true,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.isLoading || _isLoading;
    
    return ElevatedButton(
      onPressed: isLoading ? null : _handlePress,
      style: widget.style,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: LoadingStateWidget(
                type: widget.loadingType,
                size: 20,
                color: Colors.white,
              ),
            )
          : widget.child,
    );
  }

  void _handlePress() async {
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (widget.onPressedAsync != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onPressedAsync!();
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      widget.onPressed?.call();
    }
  }
}

/// Shimmer loading effect for content placeholders
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
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
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surface;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
