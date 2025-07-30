import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spiral_journal/models/insight_template.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/widgets/base_card.dart';

class TemplatedInsightCard extends StatefulWidget {
  final List<TemplateSelection> insights;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(int)? onPageChanged;
  final EdgeInsets? margin;
  final double? height;

  const TemplatedInsightCard({
    super.key,
    required this.insights,
    this.onTap,
    this.onLongPress,
    this.onPageChanged,
    this.margin,
    this.height,
  });

  @override
  State<TemplatedInsightCard> createState() => _TemplatedInsightCardState();
}

class _TemplatedInsightCardState extends State<TemplatedInsightCard>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _textRevealController;
  late AnimationController _pulseController;
  late AnimationController _swipeIndicatorController;
  
  late Animation<double> _textRevealAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _swipeIndicatorAnimation;
  
  int _currentIndex = 0;
  bool _showInteractionHints = true;

  @override
  void initState() {
    super.initState();
    
    _pageController = PageController();
    
    _textRevealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _swipeIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _textRevealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textRevealController,
      curve: Curves.easeOutQuart,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _swipeIndicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _swipeIndicatorController,
      curve: Curves.easeInOut,
    ));
    
    _startInitialAnimations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textRevealController.dispose();
    _pulseController.dispose();
    _swipeIndicatorController.dispose();
    super.dispose();
  }

  void _startInitialAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _textRevealController.forward();
        _pulseController.repeat(reverse: true);
        _swipeIndicatorController.repeat(reverse: true);
      }
    });
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showInteractionHints = false;
        });
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    _textRevealController.reset();
    _textRevealController.forward();
    
    HapticFeedback.lightImpact();
    
    widget.onPageChanged?.call(index);
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin ?? EdgeInsets.all(DesignTokens.spaceM),
      height: widget.height ?? 280,
      child: Stack(
        children: [
          _buildPageView(),
          if (widget.insights.length > 1) _buildPageIndicator(),
          if (_showInteractionHints) _buildInteractionHints(),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.insights.length,
      itemBuilder: (context, index) {
        return _buildInsightCard(widget.insights[index], index);
      },
    );
  }

  Widget _buildInsightCard(TemplateSelection selection, int index) {
    final template = selection.template;
    final insight = selection.generatedInsight;
    final isCurrentPage = index == _currentIndex;
    
    return Hero(
      tag: 'insight_card_${template.id}_$index',
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isCurrentPage ? _pulseAnimation.value : 1.0,
            child: GestureDetector(
              onTap: _handleTap,
              onLongPress: _handleLongPress,
              child: BaseCard(
                gradient: _getCategoryGradient(template.category),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardHeader(template),
                    SizedBox(height: DesignTokens.spaceL),
                    Expanded(
                      child: _buildInsightContent(insight, template.animationType),
                    ),
                    _buildCardFooter(template),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardHeader(InsightTemplate template) {
    return Row(
      children: [
        Hero(
          tag: 'insight_icon_${template.id}',
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: template.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Text(
              template.category.emoji,
              style: TextStyle(fontSize: DesignTokens.iconSizeM),
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
              Text(
                template.category.id.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: template.category.color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (template.priority == TemplatePriority.high ||
            template.priority == TemplatePriority.critical)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: template.category.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              template.priority == TemplatePriority.critical ? '!' : '★',
              style: TextStyle(
                color: template.category.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInsightContent(String insight, AnimationType animationType) {
    return AnimatedBuilder(
      animation: _textRevealAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: _getAnimationOffset(animationType),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _textRevealController,
            curve: _getAnimationCurve(animationType),
          )),
          child: FadeTransition(
            opacity: _textRevealAnimation,
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spaceL),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: DesignTokens.getBackgroundTertiary(context),
                  width: 1,
                ),
              ),
              child: Text(
                insight,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DesignTokens.getTextPrimary(context),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFooter(InsightTemplate template) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: DesignTokens.spaceXS,
            children: template.tags.take(3).map((tag) => 
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.getBackgroundTertiary(context),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.getTextTertiary(context),
                    fontSize: 10,
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        Text(
          'Score: ${selection.score.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DesignTokens.getTextTertiary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: DesignTokens.spaceM,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.insights.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceXS / 2),
            width: index == _currentIndex ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == _currentIndex
                  ? widget.insights[_currentIndex].template.category.color
                  : DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionHints() {
    return Positioned(
      top: DesignTokens.spaceM,
      right: DesignTokens.spaceM,
      child: AnimatedBuilder(
        animation: _swipeIndicatorAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: (1.0 - _swipeIndicatorAnimation.value) * 0.7,
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: DesignTokens.getBackgroundTertiary(context),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.getTextTertiary(context),
                  ),
                  SizedBox(width: DesignTokens.spaceXS),
                  if (widget.insights.length > 1) ...[
                    Icon(
                      Icons.swipe_rounded,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.getTextTertiary(context),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                  ],
                  Icon(
                    Icons.hold_rounded,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.getTextTertiary(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Gradient _getCategoryGradient(InsightCategory category) {
    final baseColor = category.color;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: 0.05),
        baseColor.withValues(alpha: 0.15),
        baseColor.withValues(alpha: 0.08),
      ],
      stops: const [0.0, 0.3, 1.0],
    );
  }

  Offset _getAnimationOffset(AnimationType animationType) {
    switch (animationType) {
      case AnimationType.slideUp:
        return const Offset(0, 1);
      case AnimationType.fadeIn:
        return Offset.zero;
      case AnimationType.bounce:
        return const Offset(0, -0.5);
      case AnimationType.scaleIn:
        return const Offset(0, 0.3);
      case AnimationType.flipIn:
        return const Offset(-1, 0);
      case AnimationType.pulse:
        return const Offset(0, 0.2);
      case AnimationType.heartbeat:
        return const Offset(0, -0.2);
      case AnimationType.shimmer:
        return const Offset(1, 0);
    }
  }

  Curve _getAnimationCurve(AnimationType animationType) {
    switch (animationType) {
      case AnimationType.bounce:
        return Curves.bounceOut;
      case AnimationType.scaleIn:
        return Curves.elasticOut;
      case AnimationType.flipIn:
        return Curves.easeOutBack;
      case AnimationType.heartbeat:
        return Curves.easeInOutSine;
      case AnimationType.shimmer:
        return Curves.easeInOutQuart;
      default:
        return Curves.easeOutCubic;
    }
  }
}