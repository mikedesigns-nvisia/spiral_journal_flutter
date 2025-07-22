import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/models/slide_config.dart';
import 'package:spiral_journal/controllers/emotional_mirror_slide_controller.dart';
import 'slide_indicators.dart';

/// Navigation header component for the slide-based emotional mirror interface.
/// Displays the current slide title, icon, and navigation indicators with
/// smooth animations and tap-to-navigate functionality.
class SlideNavigationHeader extends StatefulWidget {
  /// The slide controller managing navigation state
  final EmotionalMirrorSlideController controller;
  
  /// List of slide configurations
  final List<SlideConfig> slides;
  
  /// Optional callback when a slide is selected via indicators
  final Function(int index)? onSlideSelected;
  
  /// Whether to show the slide indicators (defaults to true)
  final bool showIndicators;
  
  /// Custom background color override
  final Color? backgroundColor;
  
  /// Whether to show a border at the bottom (defaults to true)
  final bool showBorder;
  
  const SlideNavigationHeader({
    super.key,
    required this.controller,
    required this.slides,
    this.onSlideSelected,
    this.showIndicators = true,
    this.backgroundColor,
    this.showBorder = true,
  });

  @override
  State<SlideNavigationHeader> createState() => _SlideNavigationHeaderState();
}

class _SlideNavigationHeaderState extends State<SlideNavigationHeader>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late AnimationController _iconAnimationController;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;
  
  int _previousSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _listenToSlideChanges();
  }
  
  void _setupAnimations() {
    _titleAnimationController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    
    _iconAnimationController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: DesignTokens.curveStandard,
    ));
    
    _iconScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconAnimationController,
      curve: DesignTokens.curveSpring,
    ));
    
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: DesignTokens.curveStandard,
    ));
    
    // Start with animations completed
    _titleAnimationController.value = 1.0;
    _iconAnimationController.value = 1.0;
  }
  
  void _listenToSlideChanges() {
    widget.controller.addListener(_onSlideChanged);
  }
  
  void _onSlideChanged() {
    if (widget.controller.currentSlide != _previousSlideIndex) {
      _animateSlideChange();
      _previousSlideIndex = widget.controller.currentSlide;
    }
  }
  
  void _animateSlideChange() {
    // Animate out current content
    _titleAnimationController.reverse().then((_) {
      // Animate in new content
      if (mounted) {
        _titleAnimationController.forward();
        _iconAnimationController.reset();
        _iconAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSlideChanged);
    _titleAnimationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = widget.slides[widget.controller.currentSlide];
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.getiPhoneAdaptiveSpacing(
          context,
          base: DesignTokens.spaceL,
          compactScale: 0.8,
          largeScale: 1.2,
        ),
        vertical: DesignTokens.getiPhoneAdaptiveSpacing(
          context,
          base: DesignTokens.spaceM,
          compactScale: 0.8,
          largeScale: 1.2,
        ),
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? 
               DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.95),
        border: widget.showBorder ? Border(
          bottom: BorderSide(
            color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ) : null,
        boxShadow: DesignTokens.getShadow(context, 'xs'),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Current slide info
            Expanded(
              child: _buildSlideInfo(context, currentSlide),
            ),
            
            // Slide indicators
            if (widget.showIndicators && widget.slides.length > 1)
              SlideIndicators(
                currentSlide: widget.controller.currentSlide,
                totalSlides: widget.slides.length,
                onTap: _handleIndicatorTap,
                slides: widget.slides,
              ),
          ],
        ),
      ),
    );
  }
  
  /// Builds the current slide information (icon and title)
  Widget _buildSlideInfo(BuildContext context, SlideConfig currentSlide) {
    return Row(
      children: [
        // Animated slide icon
        AnimatedBuilder(
          animation: _iconScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _iconScaleAnimation.value,
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: DesignTokens.getPrimaryColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  currentSlide.icon,
                  size: DesignTokens.getiPhoneAdaptiveSpacing(
                    context,
                    base: DesignTokens.iconSizeL,
                    compactScale: 0.9,
                    largeScale: 1.1,
                  ),
                  color: DesignTokens.getPrimaryColor(context),
                ),
              ),
            );
          },
        ),
        
        SizedBox(width: DesignTokens.spaceM),
        
        // Animated slide title
        Expanded(
          child: AnimatedBuilder(
            animation: _titleAnimationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _titleFadeAnimation,
                child: SlideTransition(
                  position: _titleSlideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSlide.title,
                        style: DesignTokens.getTextStyle(
                          fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                            context,
                            base: DesignTokens.fontSizeXL,
                            compactScale: 0.9,
                            largeScale: 1.1,
                          ),
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: DesignTokens.getTextPrimary(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Slide position indicator text
                      Text(
                        '${widget.controller.currentSlide + 1} of ${widget.slides.length}',
                        style: DesignTokens.getTextStyle(
                          fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                            context,
                            base: DesignTokens.fontSizeS,
                            compactScale: 0.9,
                            largeScale: 1.1,
                          ),
                          fontWeight: DesignTokens.fontWeightRegular,
                          color: DesignTokens.getTextTertiary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// Handles tap on slide indicators
  void _handleIndicatorTap(int index) {
    if (index != widget.controller.currentSlide) {
      widget.onSlideSelected?.call(index);
      widget.controller.jumpToSlide(index);
    }
  }
}

/// Compact version of the slide navigation header for smaller screens
class CompactSlideNavigationHeader extends StatelessWidget {
  /// The slide controller managing navigation state
  final EmotionalMirrorSlideController controller;
  
  /// List of slide configurations
  final List<SlideConfig> slides;
  
  /// Optional callback when a slide is selected via indicators
  final Function(int index)? onSlideSelected;
  
  const CompactSlideNavigationHeader({
    super.key,
    required this.controller,
    required this.slides,
    this.onSlideSelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentSlide = slides[controller.currentSlide];
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Compact slide icon
            Icon(
              currentSlide.icon,
              size: DesignTokens.iconSizeM,
              color: DesignTokens.getPrimaryColor(context),
            ),
            
            SizedBox(width: DesignTokens.spaceS),
            
            // Compact slide title
            Expanded(
              child: Text(
                currentSlide.title,
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.getTextPrimary(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Compact slide indicators
            if (slides.length > 1)
              SlideIndicators(
                currentSlide: controller.currentSlide,
                totalSlides: slides.length,
                onTap: (index) {
                  onSlideSelected?.call(index);
                  controller.jumpToSlide(index);
                },
                slides: slides,
                isCompact: true,
              ),
          ],
        ),
      ),
    );
  }
}