import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/models/slide_config.dart';

/// Animated slide indicators component that shows current position and allows
/// direct navigation to specific slides. Features smooth animations, haptic
/// feedback, and visual states for active/inactive indicators.
class SlideIndicators extends StatefulWidget {
  /// Current active slide index
  final int currentSlide;
  
  /// Total number of slides
  final int totalSlides;
  
  /// Callback when an indicator is tapped
  final Function(int index) onTap;
  
  /// List of slide configurations for enhanced indicators
  final List<SlideConfig>? slides;
  
  /// Whether to use compact layout
  final bool isCompact;
  
  /// Custom indicator size override
  final double? indicatorSize;
  
  /// Custom active indicator size override
  final double? activeIndicatorSize;
  
  /// Custom spacing between indicators
  final double? spacing;
  
  /// Whether to show slide icons in indicators
  final bool showIcons;
  
  /// Animation duration for state changes
  final Duration animationDuration;
  
  const SlideIndicators({
    super.key,
    required this.currentSlide,
    required this.totalSlides,
    required this.onTap,
    this.slides,
    this.isCompact = false,
    this.indicatorSize,
    this.activeIndicatorSize,
    this.spacing,
    this.showIcons = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SlideIndicators> createState() => _SlideIndicatorsState();
}

class _SlideIndicatorsState extends State<SlideIndicators>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationControllers = List.generate(
      widget.totalSlides,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );
    
    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: DesignTokens.curveSpring,
      ));
    }).toList();
    
    _opacityAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: DesignTokens.curveStandard,
      ));
    }).toList();
    
    // Set initial states
    _updateAnimations();
  }
  
  void _updateAnimations() {
    for (int i = 0; i < _animationControllers.length; i++) {
      if (i == widget.currentSlide) {
        _animationControllers[i].forward();
      } else {
        _animationControllers[i].reverse();
      }
    }
  }
  
  @override
  void didUpdateWidget(SlideIndicators oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSlide != widget.currentSlide) {
      _updateAnimations();
    }
  }
  
  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalSlides <= 1) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.totalSlides,
        (index) => _buildIndicator(context, index),
      ),
    );
  }
  
  /// Builds an individual slide indicator
  Widget _buildIndicator(BuildContext context, int index) {
    final isActive = index == widget.currentSlide;
    final slide = widget.slides?[index];
    
    final effectiveIndicatorSize = widget.indicatorSize ?? 
        (widget.isCompact ? 6.0 : 8.0);
    final effectiveActiveSize = widget.activeIndicatorSize ?? 
        (widget.isCompact ? 16.0 : 24.0);
    final effectiveSpacing = widget.spacing ?? 
        (widget.isCompact ? 6.0 : 8.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: effectiveSpacing / 2),
      child: GestureDetector(
        onTap: () => _handleTap(index),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimations[index],
            _opacityAnimations[index],
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: _buildIndicatorContent(
                context,
                index,
                isActive,
                slide,
                effectiveIndicatorSize,
                effectiveActiveSize,
              ),
            );
          },
        ),
      ),
    );
  }
  
  /// Builds the content of an indicator (dot or icon)
  Widget _buildIndicatorContent(
    BuildContext context,
    int index,
    bool isActive,
    SlideConfig? slide,
    double indicatorSize,
    double activeSize,
  ) {
    if (widget.showIcons && slide != null) {
      return _buildIconIndicator(context, index, isActive, slide, activeSize);
    } else {
      return _buildDotIndicator(context, index, isActive, indicatorSize, activeSize);
    }
  }
  
  /// Builds a dot-style indicator
  Widget _buildDotIndicator(
    BuildContext context,
    int index,
    bool isActive,
    double indicatorSize,
    double activeSize,
  ) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: DesignTokens.curveStandard,
      width: isActive ? activeSize : indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(
        color: _getIndicatorColor(context, index, isActive),
        borderRadius: BorderRadius.circular(indicatorSize / 2),
        boxShadow: isActive ? [
          BoxShadow(
            color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.3),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: isActive && !widget.isCompact ? Center(
        child: Container(
          width: indicatorSize * 0.4,
          height: indicatorSize * 0.4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(indicatorSize * 0.2),
          ),
        ),
      ) : null,
    );
  }
  
  /// Builds an icon-style indicator
  Widget _buildIconIndicator(
    BuildContext context,
    int index,
    bool isActive,
    SlideConfig slide,
    double size,
  ) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: DesignTokens.curveStandard,
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: _getIndicatorColor(context, index, isActive),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: isActive ? Border.all(
          color: DesignTokens.getPrimaryColor(context),
          width: 2.0,
        ) : null,
        boxShadow: isActive ? [
          BoxShadow(
            color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.3),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Icon(
        slide.icon,
        size: size * 0.5,
        color: isActive 
            ? Colors.white 
            : DesignTokens.getTextTertiary(context),
      ),
    );
  }
  
  /// Gets the appropriate color for an indicator based on its state
  Color _getIndicatorColor(BuildContext context, int index, bool isActive) {
    if (isActive) {
      return DesignTokens.getPrimaryColor(context);
    } else {
      return DesignTokens.getTextTertiary(context).withValues(alpha: 0.4);
    }
  }
  
  /// Handles tap on an indicator
  void _handleTap(int index) {
    if (index != widget.currentSlide) {
      // Provide haptic feedback
      HapticFeedback.selectionClick();
      
      // Trigger the callback
      widget.onTap(index);
    }
  }
}

/// A specialized slide indicator for progress-style display
class SlideProgressIndicator extends StatelessWidget {
  /// Current active slide index
  final int currentSlide;
  
  /// Total number of slides
  final int totalSlides;
  
  /// Whether to show progress as a continuous bar
  final bool showProgressBar;
  
  /// Custom height for the progress bar
  final double? progressHeight;
  
  const SlideProgressIndicator({
    super.key,
    required this.currentSlide,
    required this.totalSlides,
    this.showProgressBar = true,
    this.progressHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSlides <= 1) {
      return const SizedBox.shrink();
    }
    
    final progress = (currentSlide + 1) / totalSlides;
    final effectiveHeight = progressHeight ?? 4.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        if (showProgressBar)
          Container(
            width: double.infinity,
            height: effectiveHeight,
            decoration: BoxDecoration(
              color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(effectiveHeight / 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: AnimatedContainer(
                duration: DesignTokens.durationNormal,
                curve: DesignTokens.curveStandard,
                decoration: BoxDecoration(
                  color: DesignTokens.getPrimaryColor(context),
                  borderRadius: BorderRadius.circular(effectiveHeight / 2),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.3),
                      blurRadius: 4.0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        SizedBox(height: DesignTokens.spaceS),
        
        // Progress text
        Text(
          '${currentSlide + 1} of $totalSlides',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.getTextTertiary(context),
          ),
        ),
      ],
    );
  }
}

/// A minimal slide indicator for very compact layouts
class MinimalSlideIndicators extends StatelessWidget {
  /// Current active slide index
  final int currentSlide;
  
  /// Total number of slides
  final int totalSlides;
  
  /// Callback when an indicator is tapped
  final Function(int index) onTap;
  
  const MinimalSlideIndicators({
    super.key,
    required this.currentSlide,
    required this.totalSlides,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSlides <= 1) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSlides, (index) {
        final isActive = index == currentSlide;
        
        return GestureDetector(
          onTap: () {
            if (index != currentSlide) {
              HapticFeedback.selectionClick();
              onTap(index);
            }
          },
          child: AnimatedContainer(
            duration: DesignTokens.durationFast,
            curve: DesignTokens.curveStandard,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            width: isActive ? 12.0 : 4.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: isActive 
                  ? DesignTokens.getPrimaryColor(context)
                  : DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
        );
      }),
    );
  }
}