import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../design_system/heading_system.dart';
import '../services/emotional_mirror_service.dart';
import '../models/core.dart';
import '../utils/iphone_detector.dart';

/// Large premium card showing pattern recognition dashboard with visual pattern maps
class PatternRecognitionDashboardCard extends StatefulWidget {
  final List<EmotionalPattern> patterns;
  final VoidCallback? onTap;

  const PatternRecognitionDashboardCard({
    super.key,
    required this.patterns,
    this.onTap,
  });

  @override
  State<PatternRecognitionDashboardCard> createState() => _PatternRecognitionDashboardCardState();
}

class _PatternRecognitionDashboardCardState extends State<PatternRecognitionDashboardCard> {
  String _selectedPatternType = 'all';
  int _selectedPatternIndex = -1;

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          _buildPatternTypeFilter(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          _buildPatternMap(),
          if (_selectedPatternIndex >= 0) ...[
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
            _buildPatternDetails(),
          ],
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceM)),
          decoration: BoxDecoration(
            color: DesignTokens.accentYellow,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.pattern_rounded,
            color: Colors.white,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeL),
          ),
        ),
        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pattern Recognition',
                style: HeadingSystem.getHeadlineLarge(context),
              ),
              AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
              Text(
                '${widget.patterns.length} patterns detected',
                style: HeadingSystem.getBodySmall(context),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios_rounded,
          color: DesignTokens.getTextTertiary(context),
          size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeS),
        ),
      ],
    );
  }

  Widget _buildPatternTypeFilter() {
    final patternTypes = ['all', 'growth', 'recurring', 'awareness'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: patternTypes.map((type) {
          final isSelected = _selectedPatternType == type;
          final patternColor = _getPatternTypeColor(type);
          
          return Padding(
            padding: EdgeInsets.only(right: DesignTokens.spaceM),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPatternType = type;
                  _selectedPatternIndex = -1; // Reset selection
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceL,
                  vertical: DesignTokens.spaceM,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? patternColor : patternColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  border: Border.all(
                    color: patternColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPatternTypeIcon(type),
                      color: isSelected ? Colors.white : patternColor,
                      size: DesignTokens.iconSizeS,
                    ),
                    AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceS),
                    ResponsiveText(
                      _getPatternTypeLabel(type),
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: isSelected ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightMedium,
                      color: isSelected ? Colors.white : patternColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPatternMap() {
    final filteredPatterns = _getFilteredPatterns();
    
    if (filteredPatterns.isEmpty) {
      return _buildEmptyState();
    }

    return Flexible(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: iPhoneDetector.getAdaptiveValue(context, compact: 2, regular: 3, large: 4),
          crossAxisSpacing: DesignTokens.spaceM,
          mainAxisSpacing: DesignTokens.spaceM,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredPatterns.length,
        itemBuilder: (context, index) {
          final pattern = filteredPatterns[index];
          final isSelected = _selectedPatternIndex == index;
          
          return _buildPatternNode(pattern, index, isSelected);
        },
      ),
    );
  }

  Widget _buildPatternNode(EmotionalPattern pattern, int index, bool isSelected) {
    final patternColor = _getPatternColor(pattern.type);
    final strength = _calculatePatternStrength(pattern);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPatternIndex = isSelected ? -1 : index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? patternColor.withOpacity(0.2) : DesignTokens.getBackgroundSecondary(context),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: isSelected ? patternColor : DesignTokens.getBackgroundTertiary(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: patternColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pattern icon and strength indicator
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spaceS),
                    decoration: BoxDecoration(
                      color: patternColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Icon(
                      _getPatternIcon(pattern.type),
                      color: patternColor,
                      size: DesignTokens.iconSizeM,
                    ),
                  ),
                  const Spacer(),
                  _buildStrengthIndicator(strength, patternColor),
                ],
              ),
              
              AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
              
              // Pattern title
              ResponsiveText(
                pattern.title,
                baseFontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
                maxLines: 2,
              ),
              
              AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
              
              // Pattern description
              ResponsiveText(
                pattern.description,
                baseFontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextSecondary(context),
                maxLines: 3,
              ),
              
              const Spacer(),
              
              // Pattern type badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: patternColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: ResponsiveText(
                  _getPatternTypeLabel(pattern.type),
                  baseFontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: patternColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator(double strength, Color color) {
    return Container(
      width: 40,
      height: 6,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: strength,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildPatternDetails() {
    final filteredPatterns = _getFilteredPatterns();
    if (_selectedPatternIndex >= filteredPatterns.length) return const SizedBox.shrink();
    
    final pattern = filteredPatterns[_selectedPatternIndex];
    final patternColor = _getPatternColor(pattern.type);
    final strength = _calculatePatternStrength(pattern);

    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: patternColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: patternColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPatternIcon(pattern.type),
                color: patternColor,
                size: DesignTokens.iconSizeL,
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      pattern.title,
                      baseFontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                    AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
                    Row(
                      children: [
                        ResponsiveText(
                          'Strength: ${(strength * 100).round()}%',
                          baseFontSize: DesignTokens.fontSizeS,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: patternColor,
                        ),
                        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceS,
                            vertical: DesignTokens.spaceXS,
                          ),
                          decoration: BoxDecoration(
                            color: patternColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                          ),
                          child: ResponsiveText(
                            _getPatternTypeLabel(pattern.type),
                            baseFontSize: DesignTokens.fontSizeXS,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: patternColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          ResponsiveText(
            pattern.description,
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          // Pattern insights or recommendations
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.getBackgroundSecondary(context),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: DesignTokens.accentYellow,
                  size: DesignTokens.iconSizeM,
                ),
                AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
                Expanded(
                  child: ResponsiveText(
                    _getPatternInsight(pattern.type),
                    baseFontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pattern_rounded,
              size: iPhoneDetector.getAdaptiveIconSize(context, base: 48),
              color: DesignTokens.getTextTertiary(context),
            ),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
            ResponsiveText(
              'No Patterns Found',
              baseFontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.getTextPrimary(context),
              textAlign: TextAlign.center,
            ),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
            ResponsiveText(
              'Continue journaling to discover your emotional patterns',
              baseFontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<EmotionalPattern> _getFilteredPatterns() {
    if (_selectedPatternType == 'all') {
      return widget.patterns;
    }
    return widget.patterns.where((pattern) => pattern.type == _selectedPatternType).toList();
  }

  double _calculatePatternStrength(EmotionalPattern pattern) {
    // This is a simplified calculation - you could make it more sophisticated
    // based on frequency, consistency, impact, etc.
    switch (pattern.type) {
      case 'growth':
        return 0.8;
      case 'recurring':
        return 0.6;
      case 'awareness':
        return 0.7;
      default:
        return 0.5;
    }
  }

  Color _getPatternTypeColor(String type) {
    switch (type) {
      case 'all':
        return DesignTokens.getPrimaryColor(context);
      case 'growth':
        return DesignTokens.accentGreen;
      case 'recurring':
        return DesignTokens.accentBlue;
      case 'awareness':
        return DesignTokens.accentYellow;
      default:
        return DesignTokens.getPrimaryColor(context);
    }
  }

  Color _getPatternColor(String type) {
    switch (type) {
      case 'growth':
        return DesignTokens.accentGreen;
      case 'recurring':
        return DesignTokens.accentBlue;
      case 'awareness':
        return DesignTokens.accentYellow;
      default:
        return DesignTokens.getPrimaryColor(context);
    }
  }

  IconData _getPatternTypeIcon(String type) {
    switch (type) {
      case 'all':
        return Icons.dashboard_rounded;
      case 'growth':
        return Icons.trending_up_rounded;
      case 'recurring':
        return Icons.repeat_rounded;
      case 'awareness':
        return Icons.visibility_rounded;
      default:
        return Icons.pattern_rounded;
    }
  }

  IconData _getPatternIcon(String type) {
    switch (type) {
      case 'growth':
        return Icons.trending_up_rounded;
      case 'recurring':
        return Icons.repeat_rounded;
      case 'awareness':
        return Icons.visibility_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  String _getPatternTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'All Patterns';
      case 'growth':
        return 'Growth';
      case 'recurring':
        return 'Recurring';
      case 'awareness':
        return 'Awareness';
      default:
        return 'Pattern';
    }
  }

  String _getPatternInsight(String type) {
    switch (type) {
      case 'growth':
        return 'This pattern shows positive emotional development. Continue the practices that support this growth.';
      case 'recurring':
        return 'This pattern repeats regularly. Consider what triggers it and how you can respond more effectively.';
      case 'awareness':
        return 'This pattern reflects increased self-awareness. Use these insights to guide your emotional journey.';
      default:
        return 'This pattern provides valuable insights into your emotional landscape.';
    }
  }
}
