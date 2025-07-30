import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
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
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = widget.baseColor ?? 
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ?? 
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double width;
  final int lines;
  final double lineHeight;
  final double spacing;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.lines = 1,
    this.lineHeight = 16,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        final lineWidth = isLastLine ? width * 0.7 : width;
        
        return Padding(
          padding: EdgeInsets.only(bottom: isLastLine ? 0 : spacing),
          child: SkeletonLoader(
            width: lineWidth,
            height: lineHeight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final bool hasAvatar;
  final bool hasTitle;
  final bool hasSubtitle;
  final int textLines;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.hasAvatar = false,
    this.hasTitle = true,
    this.hasSubtitle = false,
    this.textLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar || hasTitle || hasSubtitle)
            Row(
              children: [
                if (hasAvatar) ...[
                  const SkeletonLoader(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasTitle)
                        const SkeletonLoader(
                          width: 120,
                          height: 16,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      if (hasTitle && hasSubtitle) const SizedBox(height: 4),
                      if (hasSubtitle)
                        const SkeletonLoader(
                          width: 80,
                          height: 12,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          if (hasAvatar || hasTitle || hasSubtitle) const SizedBox(height: 16),
          Expanded(
            child: SkeletonText(
              lines: textLines,
              lineHeight: 14,
              spacing: 8,
            ),
          ),
        ],
      ),
    );
  }
}