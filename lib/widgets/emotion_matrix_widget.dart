import 'package:flutter/material.dart';
import '../models/emotion_matrix.dart';
import '../models/emotional_state.dart';
import '../services/accessibility_service.dart' as accessibility;
import '../design_system/design_tokens.dart';
import '../design_system/heading_system.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';

/// Comprehensive emotion matrix widget that displays all emotions with percentages
/// 
/// This widget provides a visual representation of the complete emotional spectrum
/// with accessibility support, smooth animations, and multiple display modes.
/// 
/// Features:
/// - Full emotion matrix visualization with percentages
/// - Dominant emotion highlighting
/// - Emotional valence indicator
/// - Progress bars for top emotions
/// - Compact and expanded view modes
/// - Full accessibility support with screen reader announcements
/// - Smooth animations for value changes
/// - High contrast mode support
class EmotionMatrixWidget extends StatefulWidget {
  /// The emotion matrix to display
  final EmotionMatrix emotionMatrix;
  
  /// Whether to show in compact mode (fewer emotions)
  final bool compactMode;
  
  /// Maximum number of emotions to show in compact mode
  final int maxEmotionsShown;
  
  /// Whether to show smooth animations for value changes
  final bool showAnimation;
  
  /// Callback when the widget is tapped
  final VoidCallback? onTap;
  
  /// Whether to show the emotional valence indicator
  final bool showValence;
  
  /// Whether to show percentage values
  final bool showPercentages;
  
  /// Custom title for the widget
  final String? title;
  
  /// Whether to show the emotional balance description
  final bool showBalance;

  const EmotionMatrixWidget({
    super.key,
    required this.emotionMatrix,
    this.compactMode = false,
    this.maxEmotionsShown = 6,
    this.showAnimation = true,
    this.onTap,
    this.showValence = true,
    this.showPercentages = true,
    this.title,
    this.showBalance = true,
  });

  @override
  State<EmotionMatrixWidget> createState() => _EmotionMatrixWidgetState();
}

class _EmotionMatrixWidgetState extends State<EmotionMatrixWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _valenceController;
  late List<AnimationController> _emotionControllers;
  
  final accessibility.AccessibilityService _accessibilityService = accessibility.AccessibilityService();
  
  EmotionMatrix? _previousMatrix;
  List<MapEntry<String, double>> _displayEmotions = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateDisplayEmotions();
    _previousMatrix = widget.emotionMatrix;
    
    // Start animations
    if (widget.showAnimation) {
      _progressController.forward();
      _valenceController.forward();
      for (final controller in _emotionControllers) {
        controller.forward();
      }
    } else {
      _progressController.value = 1.0;
      _valenceController.value = 1.0;
      for (final controller in _emotionControllers) {
        controller.value = 1.0;
      }
    }
  }

  void _initializeAnimations() {
    // Progress bar animation
    _progressController = AnimationController(
      duration: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 1200)
      ),
      vsync: this,
    );
    
    // Valence indicator animation
    _valenceController = AnimationController(
      duration: _accessibilityService.getAnimationDuration(
        const Duration(milliseconds: 800)
      ),
      vsync: this,
    );
    
    // Individual emotion animations
    _updateDisplayEmotions();
    _emotionControllers = List.generate(
      _displayEmotions.length,
      (index) => AnimationController(
        duration: _accessibilityService.getAnimationDuration(
          Duration(milliseconds: 600 + (index * 100))
        ),
        vsync: this,
      ),
    );
  }

  void _updateDisplayEmotions() {
    if (widget.compactMode) {
      _displayEmotions = widget.emotionMatrix
          .getTopEmotions(widget.maxEmotionsShown)
          .where((e) => e.value > 0.5) // Only show emotions above 0.5%
          .toList();
    } else {
      _displayEmotions = widget.emotionMatrix
          .getEmotionsAboveThreshold(1.0) // Show all emotions above 1%
          .toList();
    }
  }

  @override
  void didUpdateWidget(EmotionMatrixWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.emotionMatrix != widget.emotionMatrix) {
      _updateDisplayEmotions();
      
      // Restart animations if matrix changed
      if (widget.showAnimation) {
        _progressController.reset();
        _valenceController.reset();
        
        _progressController.forward();
        _valenceController.forward();
      }
      
      _previousMatrix = oldWidget.emotionMatrix;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _valenceController.dispose();
    for (final controller in _emotionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSignificantEmotions = _displayEmotions.isNotEmpty;
    
    return Semantics(
      label: _getSemanticLabel(),
      hint: widget.onTap != null ? 'Double tap to view details' : null,
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ComponentLibrary.gradientCard(
          gradient: DesignTokens.getCardGradient(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: DesignTokens.spaceL),
              
              if (!hasSignificantEmotions)
                _buildEmptyState(context)
              else ...[
                if (widget.showValence)
                  _buildValenceIndicator(context),
                
                if (widget.showValence)
                  SizedBox(height: DesignTokens.spaceL),
                
                _buildEmotionProgressBars(context),
                
                if (widget.showBalance && !widget.compactMode)
                  SizedBox(height: DesignTokens.spaceL),
                
                if (widget.showBalance && !widget.compactMode)
                  _buildEmotionalBalance(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dominantEmotion = widget.emotionMatrix.dominantEmotion;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          decoration: BoxDecoration(
            color: DesignTokens.accentBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.psychology_rounded,
            color: DesignTokens.accentBlue,
            size: DesignTokens.iconSizeL,
          ),
        ),
        SizedBox(width: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                widget.title ?? 'Emotional Spectrum',
                baseFontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
              ),
              if (dominantEmotion != null)
                ResponsiveText(
                  'Dominated by ${_formatEmotionName(dominantEmotion)}',
                  baseFontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: DesignTokens.getTextSecondary(context),
                ),
            ],
          ),
        ),
        if (widget.showValence)
          AnimatedBuilder(
            animation: _valenceController,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: _getValenceColor().withValues(alpha: 0.2 * _valenceController.value),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getValenceIcon(),
                      size: DesignTokens.iconSizeS,
                      color: _getValenceColor(),
                    ),
                    SizedBox(width: DesignTokens.spaceXS),
                    ResponsiveText(
                      '${(widget.emotionMatrix.emotionalIntensity * 100).round()}%',
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: _getValenceColor(),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceXL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.sentiment_neutral,
              size: DesignTokens.iconSizeL,
              color: DesignTokens.getTextTertiary(context),
            ),
            SizedBox(height: DesignTokens.spaceM),
            ResponsiveText(
              'Neutral emotional state',
              baseFontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValenceIndicator(BuildContext context) {
    final valence = widget.emotionMatrix.emotionalValence;
    
    return AnimatedBuilder(
      animation: _valenceController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(DesignTokens.spaceL),
          decoration: BoxDecoration(
            color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.balance,
                    size: DesignTokens.iconSizeM,
                    color: DesignTokens.getTextSecondary(context),
                  ),
                  SizedBox(width: DesignTokens.spaceM),
                  Expanded(
                    child: ResponsiveText(
                      'Emotional Balance',
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ),
                  ResponsiveText(
                    _getValenceDescription(valence),
                    baseFontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: _getValenceColor(),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spaceM),
              
              // Valence bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  color: DesignTokens.getBackgroundTertiary(context),
                ),
                child: Stack(
                  children: [
                    // Center line
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.4, // Approximate center
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: Container(
                        color: DesignTokens.getTextTertiary(context).withValues(alpha: 0.3),
                      ),
                    ),
                    
                    // Valence indicator
                    FractionallySizedBox(
                      alignment: valence >= 0 ? Alignment.centerLeft : Alignment.centerRight,
                      widthFactor: ((valence.abs() * _valenceController.value) / 2 + 0.5).clamp(0.5, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          gradient: LinearGradient(
                            colors: valence >= 0 
                                ? [
                                    DesignTokens.getBackgroundTertiary(context),
                                    DesignTokens.successColor.withValues(alpha: 0.8),
                                  ]
                                : [
                                    DesignTokens.warningColor.withValues(alpha: 0.8),
                                    DesignTokens.getBackgroundTertiary(context),
                                  ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionProgressBars(BuildContext context) {
    return Column(
      children: _displayEmotions.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final emotionEntry = mapEntry.value;
        final emotion = emotionEntry.key;
        final percentage = emotionEntry.value;
        final isPositive = EmotionalState.isPositiveEmotion(emotion);
        
        final controllerIndex = index < _emotionControllers.length ? index : _emotionControllers.length - 1;
        
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spaceM),
          child: AnimatedBuilder(
            animation: _emotionControllers.isNotEmpty ? _emotionControllers[controllerIndex] : _progressController,
            builder: (context, child) {
              final animationValue = _emotionControllers.isNotEmpty 
                  ? _emotionControllers[controllerIndex].value 
                  : _progressController.value;
              
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.only(right: DesignTokens.spaceS),
                              decoration: BoxDecoration(
                                color: isPositive 
                                    ? DesignTokens.successColor.withValues(alpha: animationValue)
                                    : DesignTokens.warningColor.withValues(alpha: animationValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: ResponsiveText(
                                _formatEmotionName(emotion),
                                baseFontSize: DesignTokens.fontSizeM,
                                fontWeight: DesignTokens.fontWeightMedium,
                                color: DesignTokens.getTextPrimary(context).withValues(alpha: animationValue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showPercentages)
                        ResponsiveText(
                          '${percentage.round()}%',
                          baseFontSize: DesignTokens.fontSizeM,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: (isPositive ? DesignTokens.successColor : DesignTokens.warningColor)
                              .withValues(alpha: animationValue),
                        ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spaceS),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      color: DesignTokens.getBackgroundTertiary(context),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ((percentage / 100.0) * animationValue).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          gradient: LinearGradient(
                            colors: [
                              (isPositive 
                                  ? DesignTokens.successColor
                                  : DesignTokens.warningColor).withValues(alpha: 0.6),
                              isPositive ? DesignTokens.successColor : DesignTokens.warningColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmotionalBalance(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            size: DesignTokens.iconSizeM,
            color: DesignTokens.getTextSecondary(context),
          ),
          SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: ResponsiveText(
              'Overall Balance: ${_getValenceDescription(widget.emotionMatrix.emotionalValence)}',
              baseFontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEmotionName(String emotion) {
    return emotion.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Color _getValenceColor() {
    final valence = widget.emotionMatrix.emotionalValence;
    if (valence > 0.2) return DesignTokens.successColor;
    if (valence < -0.2) return DesignTokens.warningColor;
    return DesignTokens.accentBlue;
  }

  IconData _getValenceIcon() {
    final valence = widget.emotionMatrix.emotionalValence;
    if (valence > 0.2) return Icons.sentiment_very_satisfied;
    if (valence < -0.2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_neutral;
  }

  String _getValenceDescription(double valence) {
    if (valence > 0.4) return 'Very Positive';
    if (valence > 0.2) return 'Positive';
    if (valence > -0.2) return 'Balanced';
    if (valence > -0.4) return 'Negative';
    return 'Very Negative';
  }

  String _getSemanticLabel() {
    final dominantEmotion = widget.emotionMatrix.dominantEmotion;
    final intensity = (widget.emotionMatrix.emotionalIntensity * 100).round();
    final valence = _getValenceDescription(widget.emotionMatrix.emotionalValence);
    
    if (dominantEmotion != null) {
      return 'Emotion matrix showing ${_formatEmotionName(dominantEmotion)} as dominant emotion with $intensity percent intensity. Overall emotional balance is $valence.';
    }
    
    return 'Emotion matrix showing neutral emotional state with $valence balance.';
  }
}