import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/services/accessibility_service.dart';
import 'package:spiral_journal/services/core_animation_service.dart';
import 'package:spiral_journal/services/core_visual_consistency_service.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';

class InteractiveCoreCard extends StatefulWidget {
  final EmotionalCore core;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final bool isPulsing;
  final bool showEvolutionStory;
  final EdgeInsets? margin;

  const InteractiveCoreCard({
    super.key,
    required this.core,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.isPulsing = false,
    this.showEvolutionStory = true,
    this.margin,
  });

  @override
  State<InteractiveCoreCard> createState() => _InteractiveCoreCardState();
}

class _InteractiveCoreCardState extends State<InteractiveCoreCard>
    with TickerProviderStateMixin {
  late final AccessibilityService _accessibilityService;
  late final CoreAnimationService _animationService;
  late final CoreVisualConsistencyService _visualConsistencyService;
  
  late final AnimationController _pulseController;
  late final AnimationController _celebrationController;
  late final AnimationController _gradientController;
  late final AnimationController _detailsController;
  
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _celebrationAnimation;
  late final Animation<double> _gradientAnimation;
  late final Animation<double> _detailsAnimation;
  late final Animation<Color?> _colorAnimation;
  
  late final FocusNode _focusNode;
  
  bool _showDetails = false;
  bool _showEvolutionStory = false;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    
    _accessibilityService = AccessibilityService();
    _animationService = CoreAnimationService();
    _visualConsistencyService = CoreVisualConsistencyService();
    
    _initializeAnimationControllers();
    _initializeAnimations();
    _initializeFocus();
    
    if (widget.isPulsing) {
      _startPulsingAnimation();
    }
  }

  void _initializeAnimationControllers() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _detailsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _initializeAnimations() {
    final coreColor = _getCoreColor();
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _celebrationAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
    
    _detailsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _detailsController,
      curve: Curves.easeOutCubic,
    ));
    
    _colorAnimation = ColorTween(
      begin: coreColor.withValues(alpha: 0.1),
      end: coreColor.withValues(alpha: 0.3),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeFocus() {
    _focusNode = _accessibilityService.createAccessibleFocusNode(
      debugLabel: '${widget.core.name} interactive core card',
    );
  }

  @override
  void didUpdateWidget(InteractiveCoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _startPulsingAnimation();
      } else {
        _stopPulsingAnimation();
      }
    }
    
    if (widget.core.currentLevel != oldWidget.core.currentLevel) {
      _animateProgressChange();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrationController.dispose();
    _gradientController.dispose();
    _detailsController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
      child: _buildInteractiveCard(),
    );
  }

  Widget _buildInteractiveCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _celebrationAnimation,
        _gradientAnimation,
        _detailsAnimation,
        _colorAnimation,
      ]),
      builder: (context, child) {
        final scale = _celebrationAnimation.value > 1.0 
            ? _celebrationAnimation.value 
            : _pulseAnimation.value;
            
        return Transform.scale(
          scale: _accessibilityService.reducedMotionMode ? 1.0 : scale,
          child: _buildCardContent(),
        );
      },
    );
  }

  Widget _buildCardContent() {
    final coreColor = _getCoreColor();
    final animatedColor = _colorAnimation.value ?? coreColor.withValues(alpha: 0.1);
    
    return Semantics(
      button: true,
      focusable: true,
      focused: _focusNode.hasFocus,
      label: _getSemanticLabel(),
      hint: _getSemanticHint(),
      onTap: _handleTap,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          onDoubleTap: _handleDoubleTap,
          child: Container(
            constraints: BoxConstraints(
              minHeight: _accessibilityService.getMinimumTouchTargetSize(),
            ),
            decoration: BoxDecoration(
              color: animatedColor,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: coreColor.withValues(alpha: 0.4),
                width: _showDetails ? 2.0 : 1.0,
              ),
              boxShadow: _buildBoxShadow(coreColor),
            ),
            child: Column(
              children: [
                _buildMainContent(),
                if (_showDetails) _buildDetailsSection(),
                if (_showEvolutionStory) _buildEvolutionStory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Row(
        children: [
          _buildCoreIcon(),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoreName(),
                SizedBox(height: DesignTokens.spaceS),
                _buildProgressBar(),
                SizedBox(height: DesignTokens.spaceXS),
                _buildTrendIndicator(),
              ],
            ),
          ),
          _buildPercentageDisplay(),
        ],
      ),
    );
  }

  Widget _buildCoreIcon() {
    final coreColor = _getCoreColor();
    final icon = _getCoreIcon();
    
    return Hero(
      tag: 'core_icon_${widget.core.id}',
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spaceM),
        decoration: BoxDecoration(
          color: coreColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          boxShadow: [
            BoxShadow(
              color: coreColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: DesignTokens.iconSizeL,
        ),
      ),
    );
  }

  Widget _buildCoreName() {
    return Text(
      widget.core.name,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: DesignTokens.getTextPrimary(context),
      ),
    );
  }

  Widget _buildProgressBar() {
    final coreColor = _getCoreColor();
    final progress = widget.core.currentLevel;
    
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: coreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    coreColor.withValues(alpha: 0.8),
                    coreColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: coreColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isPulsing) _buildProgressShimmer(coreColor),
        ],
      ),
    );
  }

  Widget _buildProgressShimmer(Color coreColor) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        if (!_gradientController.isAnimating) {
          _gradientController.repeat();
        }
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                coreColor.withValues(alpha: 0.5),
                Colors.transparent,
              ],
              stops: [
                (_gradientController.value - 0.3).clamp(0.0, 1.0),
                _gradientController.value,
                (_gradientController.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildTrendIndicator() {
    final trendIcon = _getTrendIcon();
    final trendColor = _getTrendColor();
    
    return Row(
      children: [
        Icon(
          trendIcon,
          size: DesignTokens.iconSizeS,
          color: trendColor,
        ),
        SizedBox(width: DesignTokens.spaceXS),
        Text(
          'Level ${(widget.core.currentLevel * 10).round()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: DesignTokens.getTextSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (_getPercentageChange() != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              _getPercentageChange()!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: trendColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPercentageDisplay() {
    final percentage = '${widget.core.percentage.round()}%';
    
    return Hero(
      tag: 'core_percentage_${widget.core.id}',
      child: Text(
        percentage,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: DesignTokens.getTextPrimary(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showDetails ? null : 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_detailsAnimation),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spaceL),
          decoration: BoxDecoration(
            color: DesignTokens.getColorWithOpacity(_getCoreColor(), 0.05),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(DesignTokens.radiusL),
              bottomRight: Radius.circular(DesignTokens.radiusL),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.core.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.getTextSecondary(context),
                ),
              ),
              if (widget.core.insight.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spaceM),
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceM),
                  decoration: BoxDecoration(
                    color: DesignTokens.getColorWithOpacity(_getCoreColor(), 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: DesignTokens.iconSizeS,
                        color: _getCoreColor(),
                      ),
                      SizedBox(width: DesignTokens.spaceS),
                      Expanded(
                        child: Text(
                          widget.core.insight,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DesignTokens.getTextSecondary(context),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvolutionStory() {
    if (!_showEvolutionStory || widget.core.milestones.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getColorWithOpacity(_getCoreColor(), 0.05),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DesignTokens.radiusL),
          bottomRight: Radius.circular(DesignTokens.radiusL),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolution Story',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceM),
          ...widget.core.milestones.take(3).map((milestone) => 
            _buildMilestoneItem(milestone)
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(CoreMilestone milestone) {
    final isAchieved = milestone.isAchieved;
    final coreColor = _getCoreColor();
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spaceS),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isAchieved ? coreColor : Colors.transparent,
              border: Border.all(
                color: coreColor,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isAchieved
                ? Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isAchieved 
                        ? DesignTokens.getTextPrimary(context)
                        : DesignTokens.getTextSecondary(context),
                  ),
                ),
                if (milestone.description.isNotEmpty)
                  Text(
                    milestone.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.getTextTertiary(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<BoxShadow> _buildBoxShadow(Color coreColor) {
    if (_celebrationController.isAnimating) {
      return [
        BoxShadow(
          color: coreColor.withValues(alpha: 0.4),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ];
    }
    
    if (_showDetails) {
      return [
        BoxShadow(
          color: coreColor.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  void _handleTap() {
    final now = DateTime.now();
    
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!).inMilliseconds < 300) {
      _handleDoubleTap();
      return;
    }
    
    _lastTapTime = now;
    
    HapticFeedback.lightImpact();
    
    _toggleDetails();
    
    _accessibilityService.announceToScreenReader(
      _showDetails 
          ? 'Showing ${widget.core.name} core details'
          : 'Hiding ${widget.core.name} core details',
      assertiveness: Assertiveness.polite,
    );
    
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _showEvolutionStory = !_showEvolutionStory;
    });
    
    _accessibilityService.announceToScreenReader(
      _showEvolutionStory 
          ? 'Showing ${widget.core.name} evolution story'
          : 'Hiding ${widget.core.name} evolution story',
      assertiveness: Assertiveness.polite,
    );
    
    widget.onLongPress?.call();
  }

  void _handleDoubleTap() {
    HapticFeedback.heavyImpact();
    
    _playCelebrationAnimation();
    
    _accessibilityService.announceToScreenReader(
      'Celebrating ${widget.core.name} core progress!',
      assertiveness: Assertiveness.polite,
    );
    
    widget.onDoubleTap?.call();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _handleTap();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });
    
    if (_showDetails) {
      _detailsController.forward();
    } else {
      _detailsController.reverse();
    }
  }

  void _startPulsingAnimation() {
    if (!_accessibilityService.reducedMotionMode) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulsingAnimation() {
    _pulseController.stop();
    _pulseController.reset();
  }

  void _playCelebrationAnimation() {
    if (!_accessibilityService.reducedMotionMode) {
      _celebrationController.forward().then((_) {
        _celebrationController.reverse();
      });
    }
  }

  void _animateProgressChange() {
    if (!_accessibilityService.reducedMotionMode) {
      _gradientController.forward().then((_) {
        _gradientController.reverse();
      });
    }
  }

  Color _getCoreColor() {
    try {
      final cleanHex = widget.core.color.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (e) {
      return AppTheme.primaryOrange;
    }
  }

  IconData _getCoreIcon() {
    switch (widget.core.name.toLowerCase()) {
      case 'optimism':
        return Icons.wb_sunny_rounded;
      case 'resilience':
        return Icons.security_rounded;
      case 'self-awareness':
        return Icons.psychology_rounded;
      case 'creativity':
        return Icons.lightbulb_rounded;
      case 'social connection':
        return Icons.groups_rounded;
      case 'growth mindset':
        return Icons.escalator_warning_rounded;
      case 'confidence':
        return Icons.emoji_events_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  IconData _getTrendIcon() {
    switch (widget.core.trend) {
      case 'rising':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color _getTrendColor() {
    switch (widget.core.trend) {
      case 'rising':
        return DesignTokens.accentGreen;
      case 'declining':
        return DesignTokens.accentRed;
      default:
        return DesignTokens.primaryOrange;
    }
  }

  String? _getPercentageChange() {
    final change = widget.core.currentLevel - widget.core.previousLevel;
    if (change.abs() < 0.01) return null;
    
    final changePercent = (change * 100).round();
    return changePercent > 0 ? '+$changePercent%' : '$changePercent%';
  }

  String _getSemanticLabel() {
    return _accessibilityService.getCoreCardSemanticLabel(
      widget.core.name,
      widget.core.currentLevel,
      widget.core.previousLevel,
      widget.core.trend,
      false,
    );
  }

  String _getSemanticHint() {
    return 'Tap to show details, long press for evolution story, double tap for celebration';
  }
}