import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../models/core.dart';
import '../providers/emotional_mirror_provider.dart';
import 'pattern_recognition_dashboard_card.dart';
import 'slide_wrapper.dart';
import 'slide_error_wrapper.dart';

/// Slide component that wraps the existing PatternRecognitionDashboardCard
/// for full-screen presentation in the slide-based emotional mirror interface.
/// Keeps all current pattern display and interaction functionality while
/// optimizing the card layout for dedicated slide space.
class PatternRecognitionSlide extends StatelessWidget {
  /// The emotional mirror provider for accessing pattern data
  final EmotionalMirrorProvider provider;
  
  /// Optional callback for refresh functionality
  final VoidCallback? onRefresh;
  
  const PatternRecognitionSlide({
    super.key,
    required this.provider,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SlideErrorWrapper(
      slideTitle: 'Pattern Recognition',
      error: provider.error,
      isLoading: provider.isLoading,
      onRetry: onRefresh ?? () => provider.refresh(),
      child: _buildSlideContent(context),
    );
  }
  
  /// Builds the main slide content based on data state
  Widget _buildSlideContent(BuildContext context) {
    // Handle empty data state
    if (provider.mirrorData?.emotionalPatterns == null) {
      return SlideWrapper(
        title: 'Pattern Recognition',
        icon: Icons.pattern_rounded,
        onRefresh: onRefresh ?? () => provider.refresh(),
        child: _buildEmptyState(context),
      );
    }
    
    // Main slide content with pattern recognition
    return SlideWrapper(
      title: 'Pattern Recognition',
      icon: Icons.pattern_rounded,
      onRefresh: onRefresh ?? () => provider.refresh(),
      child: _buildPatternContent(context),
    );
  }
  
  /// Builds the main pattern content using the existing dashboard card
  Widget _buildPatternContent(BuildContext context) {
    final patterns = provider.mirrorData!.emotionalPatterns;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pattern overview stats
          _buildPatternOverview(context, patterns),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Main pattern recognition dashboard card optimized for full-screen
          PatternRecognitionDashboardCard(
            patterns: patterns,
            onTap: () {
              // Pattern view has been removed - could navigate to insights instead
              provider.setViewMode(ViewMode.insights);
            },
          ),
        ],
      ),
    );
  }
  
  /// Builds pattern overview stats at the top of the slide
  Widget _buildPatternOverview(BuildContext context, List<EmotionalPattern> patterns) {
    final patternsByType = _groupPatternsByType(patterns);
    final totalPatterns = patterns.length;
    final strongPatterns = patterns.where((p) => _calculatePatternStrength(p) >= 0.7).length;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentYellow.withValues(alpha: 0.1),
            DesignTokens.accentYellow.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.accentYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Main pattern stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patterns Discovered',
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                    
                    SizedBox(height: DesignTokens.spaceS),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$totalPatterns',
                          style: DesignTokens.getTextStyle(
                            fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                              context,
                              base: 36.0,
                              compactScale: 0.9,
                              largeScale: 1.1,
                            ),
                            fontWeight: DesignTokens.fontWeightBold,
                            color: DesignTokens.accentYellow,
                          ),
                        ),
                        
                        SizedBox(width: DesignTokens.spaceS),
                        
                        Text(
                          'patterns',
                          style: DesignTokens.getTextStyle(
                            fontSize: DesignTokens.fontSizeM,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: DesignTokens.accentYellow,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: DesignTokens.spaceXS),
                    
                    Text(
                      '$strongPatterns strong patterns identified',
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.accentYellow,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Pattern strength indicator
              Expanded(
                child: Column(
                  children: [
                    _buildPatternStrengthIndicator(context, patterns),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Pattern type breakdown
          Row(
            children: [
              Expanded(
                child: _buildPatternTypeStat(
                  context,
                  'Growth',
                  '${patternsByType['growth']?.length ?? 0}',
                  Icons.trending_up_rounded,
                  DesignTokens.accentGreen,
                ),
              ),
              
              SizedBox(width: DesignTokens.spaceM),
              
              Expanded(
                child: _buildPatternTypeStat(
                  context,
                  'Recurring',
                  '${patternsByType['recurring']?.length ?? 0}',
                  Icons.repeat_rounded,
                  DesignTokens.accentBlue,
                ),
              ),
              
              SizedBox(width: DesignTokens.spaceM),
              
              Expanded(
                child: _buildPatternTypeStat(
                  context,
                  'Awareness',
                  '${patternsByType['awareness']?.length ?? 0}',
                  Icons.visibility_rounded,
                  DesignTokens.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds pattern strength indicator
  Widget _buildPatternStrengthIndicator(BuildContext context, List<EmotionalPattern> patterns) {
    final averageStrength = patterns.isEmpty 
        ? 0.0 
        : patterns.map(_calculatePatternStrength).reduce((a, b) => a + b) / patterns.length;
    
    return Column(
      children: [
        SizedBox(
          width: DesignTokens.getiPhoneAdaptiveSpacing(
            context,
            base: 80.0,
            compactScale: 0.8,
            largeScale: 1.2,
          ),
          height: DesignTokens.getiPhoneAdaptiveSpacing(
            context,
            base: 80.0,
            compactScale: 0.8,
            largeScale: 1.2,
          ),
          child: CircularProgressIndicator(
            value: averageStrength,
            backgroundColor: DesignTokens.accentYellow.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentYellow),
            strokeWidth: 6,
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceS),
        
        Text(
          '${(averageStrength * 100).round()}%',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.accentYellow,
          ),
        ),
        
        Text(
          'avg strength',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeXS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.getTextSecondary(context),
          ),
        ),
      ],
    );
  }
  
  /// Builds individual pattern type stat
  Widget _buildPatternTypeStat(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeM,
          ),
          
          SizedBox(height: DesignTokens.spaceS),
          
          Text(
            count,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignTokens.spaceXS),
          
          Text(
            label,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Builds empty state when no pattern data is available
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pattern_rounded,
            size: DesignTokens.getiPhoneAdaptiveSpacing(
              context,
              base: 64.0,
              compactScale: 0.8,
              largeScale: 1.2,
            ),
            color: DesignTokens.getTextTertiary(context),
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          Text(
            'Discovering Patterns',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                context,
                base: DesignTokens.fontSizeXXL,
                compactScale: 0.9,
                largeScale: 1.1,
              ),
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.getTextPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignTokens.spaceM),
          
          Text(
            'Continue journaling to reveal meaningful patterns in your emotional landscape',
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                context,
                base: DesignTokens.fontSizeM,
                compactScale: 0.9,
                largeScale: 1.1,
              ),
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to journal screen to build more patterns
              Navigator.of(context).pushNamed('/journal');
            },
            icon: Icon(
              Icons.insights_rounded,
              size: DesignTokens.iconSizeS,
            ),
            label: Text('Build Patterns'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentYellow,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceXL,
                vertical: DesignTokens.spaceM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Groups patterns by type for statistics
  Map<String, List<EmotionalPattern>> _groupPatternsByType(List<EmotionalPattern> patterns) {
    final Map<String, List<EmotionalPattern>> grouped = {};
    
    for (final pattern in patterns) {
      grouped.putIfAbsent(pattern.type, () => []).add(pattern);
    }
    
    return grouped;
  }
  
  /// Calculates pattern strength (simplified implementation)
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
}
