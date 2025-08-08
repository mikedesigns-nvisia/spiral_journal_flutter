import 'package:flutter/material.dart';
import '../models/emotional_state.dart';
import '../models/emotion_matrix.dart';
import '../services/accessibility_service.dart' as accessibility;
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';
import 'emotion_matrix_widget.dart';

/// Primary emotional state widget that displays the user's dominant emotion
/// with full accessibility support and smooth animations.
/// 
/// Features:
/// - Large, prominent display of primary emotion
/// - Text label alongside color indicator
/// - Confidence level indicator with visual and textual representation
/// - Smooth state change animations with reduced motion support
/// - Full screen reader support with semantic labels
/// - Keyboard navigation and focus management
/// - High contrast mode support
/// - Theme-aware color adaptation
/// 
/// This widget meets WCAG AA accessibility standards and provides
/// comprehensive support for users with color vision deficiencies.
class PrimaryEmotionalStateWidget extends StatefulWidget {
  /// The primary emotional state to display
  final EmotionalState? primaryState;
  
  /// The secondary emotional state to display
  final EmotionalState? secondaryState;
  
  /// Whether to show smooth animations for state changes
  final bool showAnimation;
  
  /// Callback when the widget is tapped
  final VoidCallback? onTap;
  
  /// Whether the widget should be focusable for keyboard navigation
  final bool focusable;
  
  /// Custom semantic label override
  final String? customSemanticLabel;
  
  /// Whether to show the confidence indicator
  final bool showConfidence;
  
  /// Whether to show the last updated timestamp
  final bool showTimestamp;
  
  /// Whether to show tab navigation for primary/secondary emotions
  final bool showTabs;

  /// Optional emotion matrix for comprehensive emotional display
  final EmotionMatrix? emotionMatrix;

  /// Whether to use emotion matrix mode instead of traditional primary/secondary
  final bool useMatrixMode;

  const PrimaryEmotionalStateWidget({
    super.key,
    this.primaryState,
    this.secondaryState,
    this.showAnimation = true,
    this.onTap,
    this.focusable = true,
    this.customSemanticLabel,
    this.showConfidence = true,
    this.showTimestamp = true,
    this.showTabs = true,
    this.emotionMatrix,
    this.useMatrixMode = false,
  });

  @override
  State<PrimaryEmotionalStateWidget> createState() => _PrimaryEmotionalStateWidgetState();
}

class _PrimaryEmotionalStateWidgetState extends State<PrimaryEmotionalStateWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confidenceController;
  late TabController _tabController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _confidenceAnimation;
  
  final accessibility.AccessibilityService _accessibilityService = accessibility.AccessibilityService();
  late FocusNode _focusNode;
  
  EmotionalState? _previousState;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAccessibility();
    _initializeTabController();
    _previousState = widget.primaryState;
  }

  void _initializeTabController() {
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        
        // Announce tab change to screen reader
        final tabName = _currentTabIndex == 0 ? 'Primary Emotion' : 'Secondary Emotion';
        _accessibilityService.announceToScreenReader(
          'Switched to $tabName tab',
          assertiveness: accessibility.Assertiveness.polite,
        );
      }
    });
  }

  void _initializeAnimations() {
    final accessibilityService = accessibility.AccessibilityService();
    
    // Fade animation for state transitions
    _fadeController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 600)
      ),
      vsync: this,
    );
    
    // Scale animation for emphasis
    _scaleController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 400)
      ),
      vsync: this,
    );
    
    // Confidence bar animation
    _confidenceController = AnimationController(
      duration: accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 800)
      ),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: accessibilityService.getAnimationCurve(Curves.easeInOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: accessibilityService.getAnimationCurve(Curves.elasticOut),
    ));
    
    _confidenceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confidenceController,
      curve: accessibilityService.getAnimationCurve(Curves.easeOutCubic),
    ));
    
    // Start initial animations
    if (widget.primaryState != null) {
      _startInitialAnimation();
    }
  }

  void _initializeAccessibility() {
    _focusNode = _accessibilityService.createAccessibleFocusNode(
      debugLabel: 'Primary Emotional State',
      canRequestFocus: widget.focusable,
    );
  }

  void _startInitialAnimation() {
    if (!widget.showAnimation || _accessibilityService.reducedMotionMode) {
      _fadeController.value = 1.0;
      _scaleController.value = 1.0;
      _confidenceController.value = 1.0;
      return;
    }
    
    _fadeController.forward();
    _scaleController.forward();
    
    // Delay confidence animation for staggered effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _confidenceController.forward();
      }
    });
  }

  void _animateStateChange() {
    if (!widget.showAnimation || _accessibilityService.reducedMotionMode) {
      return;
    }
    
    // Fade out, then fade in with new state
    _fadeController.reverse().then((_) {
      if (mounted) {
        _fadeController.forward();
        _confidenceController.reset();
        _confidenceController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(PrimaryEmotionalStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if state changed
    if (oldWidget.primaryState != widget.primaryState) {
      if (_previousState != null && widget.primaryState != null) {
        // Announce state change to screen reader
        _announceStateChange();
        _animateStateChange();
      } else if (widget.primaryState != null) {
        _startInitialAnimation();
      }
      _previousState = widget.primaryState;
    }
  }

  void _announceStateChange() {
    if (widget.primaryState != null) {
      final message = 'Primary emotion changed to ${widget.primaryState!.displayName}';
      _accessibilityService.announceToScreenReader(
        message,
        assertiveness: accessibility.Assertiveness.polite,
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _confidenceController.dispose();
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use emotion matrix mode if available and enabled
    if (widget.useMatrixMode && widget.emotionMatrix != null) {
      return EmotionMatrixWidget(
        emotionMatrix: widget.emotionMatrix!,
        compactMode: true,
        maxEmotionsShown: 5,
        showAnimation: widget.showAnimation,
        onTap: widget.onTap,
        showValence: true,
        showPercentages: true,
        title: 'Current Emotional State',
        showBalance: false, // Keep compact in this context
      );
    }
    
    // Fall back to traditional display
    if (widget.primaryState == null && widget.secondaryState == null) {
      return _buildEmptyState();
    }
    
    return _buildEmotionalStateDisplay();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: DesignTokens.iconSizeXL,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'No Emotional Data',
            style: HeadingSystem.getTitleMedium(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Start journaling to see your primary emotional state',
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextTertiary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionalStateDisplay() {
    final hasSecondary = widget.secondaryState != null;
    final showTabs = widget.showTabs && hasSecondary;
    
    return Semantics(
      label: _getSemanticLabel(),
      hint: widget.onTap != null ? 'Double tap for details' : null,
      button: widget.onTap != null,
      focusable: widget.focusable,
      child: Focus(
        focusNode: _focusNode,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _fadeAnimation,
              _scaleAnimation,
            ]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    decoration: _buildContainerDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTabs) _buildTabNavigation(),
                        _buildEmotionContent(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getSemanticLabel() {
    if (widget.customSemanticLabel != null) {
      return widget.customSemanticLabel!;
    }
    
    final currentState = _getCurrentEmotionalState();
    if (currentState != null) {
      return currentState.semanticLabel;
    }
    
    return 'Emotional state information';
  }

  EmotionalState? _getCurrentEmotionalState() {
    if (_currentTabIndex == 0 && widget.primaryState != null) {
      return widget.primaryState;
    } else if (_currentTabIndex == 1 && widget.secondaryState != null) {
      return widget.secondaryState;
    }
    return widget.primaryState ?? widget.secondaryState;
  }

  BoxDecoration _buildContainerDecoration() {
    final currentState = _getCurrentEmotionalState();
    if (currentState == null) {
      return BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
          width: _focusNode.hasFocus ? 2 : 1,
        ),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          currentState.accessibleColor.withValues(alpha: 0.1),
          currentState.accessibleColor.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      border: Border.all(
        color: currentState.accessibleColor.withValues(alpha: 0.3),
        width: _focusNode.hasFocus ? 2 : 1,
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 44, // Slightly taller for better touch targets
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: DesignTokens.getPrimaryColor(context),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.all(2), // Small padding around indicator
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: DesignTokens.getTextSecondary(context),
              labelStyle: HeadingSystem.getLabelMedium(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: HeadingSystem.getLabelMedium(context),
              tabs: [
              Tab(
                child: Semantics(
                  label: 'Primary emotion tab',
                  hint: 'Double tap to view primary emotion',
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          size: DesignTokens.iconSizeS,
                        ),
                        SizedBox(width: DesignTokens.spaceS),
                        Text(
                          'Primary',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Tab(
                child: Semantics(
                  label: 'Secondary emotion tab',
                  hint: 'Double tap to view secondary emotion',
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_half,
                          size: DesignTokens.iconSizeS,
                        ),
                        SizedBox(width: DesignTokens.spaceS),
                        Text(
                          'Secondary',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionContent() {
    final currentState = _getCurrentEmotionalState();
    
    if (currentState == null) {
      return _buildEmptyStateContent();
    }

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEmotionHeader(currentState),
          SizedBox(height: DesignTokens.spaceL),
          _buildEmotionDescription(currentState),
          if (widget.showConfidence) ...[
            SizedBox(height: DesignTokens.spaceL),
            _buildConfidenceIndicator(currentState),
          ],
          if (widget.showTimestamp) ...[
            SizedBox(height: DesignTokens.spaceM),
            _buildTimestamp(currentState),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: DesignTokens.iconSizeXL,
            color: DesignTokens.getTextTertiary(context),
          ),
          SizedBox(height: DesignTokens.spaceM),
          Text(
            'No Emotional Data',
            style: HeadingSystem.getTitleMedium(context).copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceS),
          Text(
            'Start journaling to see your emotional state',
            style: HeadingSystem.getBodySmall(context).copyWith(
              color: DesignTokens.getTextTertiary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionHeader(EmotionalState state) {
    return Row(
      children: [
        // Emotion color indicator
        Container(
          width: DesignTokens.iconSizeL,
          height: DesignTokens.iconSizeL,
          decoration: BoxDecoration(
            color: state.accessibleColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: state.accessibleColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              _getEmotionIcon(state.emotion),
              color: state.primaryColor.computeLuminance() > 0.5 
                  ? Colors.black 
                  : Colors.white,
              size: DesignTokens.iconSizeM,
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spaceM),
        
        // Emotion name and intensity
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.displayName,
                style: HeadingSystem.getHeadlineMedium(context).copyWith(
                  color: state.accessibleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getEmotionTypeLabel(),
                style: HeadingSystem.getLabelMedium(context).copyWith(
                  color: DesignTokens.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
        
        // Intensity indicator
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          decoration: BoxDecoration(
            color: state.accessibleColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Center(
            child: Text(
              '${((state.intensity > 1.0 ? state.intensity / 10.0 : state.intensity).clamp(0.0, 1.0) * 100).round()}%',
              style: HeadingSystem.getTitleMedium(context).copyWith(
                color: state.accessibleColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionDescription(EmotionalState state) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            color: DesignTokens.getTextTertiary(context),
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spaceS),
          Expanded(
            child: Text(
              state.description,
              style: HeadingSystem.getBodyMedium(context).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(EmotionalState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confidence Level',
              style: HeadingSystem.getLabelMedium(context),
            ),
            Text(
              '${(state.confidence * 100).round()}%',
              style: HeadingSystem.getLabelMedium(context).copyWith(
                fontWeight: FontWeight.bold,
                color: _getConfidenceColor(state.confidence),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spaceS),
        
        // Confidence bar with animation
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            color: DesignTokens.getBackgroundTertiary(context),
          ),
          child: AnimatedBuilder(
            animation: _confidenceAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: state.confidence * _confidenceAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    gradient: LinearGradient(
                      colors: [
                        _getConfidenceColor(state.confidence),
                        _getConfidenceColor(state.confidence).withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Confidence description
        SizedBox(height: DesignTokens.spaceS),
        Text(
          _getConfidenceDescription(state.confidence),
          style: HeadingSystem.getBodySmall(context).copyWith(
            color: DesignTokens.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(EmotionalState state) {
    final timeAgo = _getTimeAgo(state.timestamp);
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: DesignTokens.iconSizeS,
          color: DesignTokens.getTextTertiary(context),
        ),
        SizedBox(width: DesignTokens.spaceS),
        Text(
          'Last updated $timeAgo',
          style: HeadingSystem.getBodySmall(context).copyWith(
            color: DesignTokens.getTextTertiary(context),
          ),
        ),
      ],
    );
  }

  IconData _getEmotionIcon(String emotion) {
    final iconMap = {
      'happy': Icons.sentiment_very_satisfied,
      'sad': Icons.sentiment_very_dissatisfied,
      'angry': Icons.sentiment_very_dissatisfied,
      'anxious': Icons.sentiment_dissatisfied,
      'excited': Icons.sentiment_very_satisfied,
      'calm': Icons.sentiment_satisfied,
      'frustrated': Icons.sentiment_dissatisfied,
      'content': Icons.sentiment_satisfied,
      'worried': Icons.sentiment_dissatisfied,
      'joyful': Icons.sentiment_very_satisfied,
      'peaceful': Icons.sentiment_satisfied,
      'stressed': Icons.sentiment_dissatisfied,
      'optimistic': Icons.sentiment_satisfied,
      'melancholy': Icons.sentiment_neutral,
      'energetic': Icons.sentiment_very_satisfied,
      'tired': Icons.sentiment_neutral,
      'confident': Icons.sentiment_satisfied,
      'uncertain': Icons.sentiment_neutral,
      'grateful': Icons.sentiment_satisfied,
      'lonely': Icons.sentiment_dissatisfied,
    };
    
    return iconMap[emotion.toLowerCase()] ?? Icons.sentiment_neutral;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return DesignTokens.successColor;
    if (confidence >= 0.6) return DesignTokens.accentYellow;
    if (confidence >= 0.4) return DesignTokens.accentBlue;
    return DesignTokens.warningColor;
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence >= 0.8) return 'High confidence in this emotional assessment';
    if (confidence >= 0.6) return 'Good confidence in this emotional assessment';
    if (confidence >= 0.4) return 'Moderate confidence in this emotional assessment';
    return 'Lower confidence - may need more data';
  }

  String _getEmotionTypeLabel() {
    if (!widget.showTabs || widget.secondaryState == null) {
      return 'Primary Emotion';
    }
    
    return _currentTabIndex == 0 ? 'Primary Emotion' : 'Secondary Emotion';
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return 'over a week ago';
    }
  }
}