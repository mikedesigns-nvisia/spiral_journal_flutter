import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../models/emotional_mirror_data.dart';
import '../providers/emotional_mirror_provider.dart';
import 'slide_wrapper.dart';
import 'slide_error_wrapper.dart';

/// Slide component that wraps the enhanced mood overview section
/// for full-screen presentation in the slide-based emotional mirror interface.
/// Preserves all current mood balance visualizations and metrics while
/// maintaining existing metric cards and their interactions.
class MoodOverviewSlide extends StatelessWidget {
  /// The emotional mirror provider for accessing mood overview data
  final EmotionalMirrorProvider provider;
  
  /// Optional callback for refresh functionality
  final VoidCallback? onRefresh;
  
  const MoodOverviewSlide({
    super.key,
    required this.provider,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SlideErrorWrapper(
      slideTitle: 'Mood Overview',
      error: provider.error,
      isLoading: provider.isLoading,
      onRetry: onRefresh ?? () => provider.refresh(),
      child: _buildSlideContent(context),
    );
  }
  
  /// Builds the main slide content based on data state
  Widget _buildSlideContent(BuildContext context) {
    // Handle empty data state
    if (provider.mirrorData?.moodOverview == null) {
      return SlideWrapper(
        title: 'Mood Overview',
        icon: Icons.dashboard_rounded,
        onRefresh: onRefresh ?? () => provider.refresh(),
        child: _buildEmptyState(context),
      );
    }
    
    // Main slide content with mood overview
    return SlideWrapper(
      title: 'Mood Overview',
      icon: Icons.dashboard_rounded,
      onRefresh: onRefresh ?? () => provider.refresh(),
      child: _buildMoodOverviewContent(context),
    );
  }
  
  /// Builds the main mood overview content
  Widget _buildMoodOverviewContent(BuildContext context) {
    final overview = provider.mirrorData!.moodOverview;
    final mirrorData = provider.mirrorData!;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mood balance summary
          _buildMoodBalanceSummary(context, overview),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Enhanced mood overview card
          _buildEnhancedMoodOverview(context, overview, mirrorData),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Additional mood insights
          _buildMoodInsights(context, overview),
        ],
      ),
    );
  }
  
  /// Builds mood balance summary at the top
  Widget _buildMoodBalanceSummary(BuildContext context, MoodOverview overview) {
    final balanceDescription = _getBalanceDescription(overview.moodBalance);
    final balanceColor = _getBalanceColor(overview.moodBalance);
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            balanceColor.withValues(alpha: 0.1),
            balanceColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: balanceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Balance indicator
          Container(
            height: DesignTokens.spaceL,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              gradient: LinearGradient(
                colors: _getMoodBalanceColors(overview.moodBalance),
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Balance description
          Row(
            children: [
              Icon(
                Icons.balance_rounded,
                color: balanceColor,
                size: DesignTokens.iconSizeL,
              ),
              
              SizedBox(width: DesignTokens.spaceM),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emotional Balance',
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ),
                    
                    SizedBox(height: DesignTokens.spaceXS),
                    
                    Text(
                      balanceDescription,
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeXL,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Balance percentage
              Text(
                '${(overview.moodBalance.abs() * 100).round()}%',
                style: DesignTokens.getTextStyle(
                  fontSize: DesignTokens.fontSizeXXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: balanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds the enhanced mood overview card (similar to the original)
  Widget _buildEnhancedMoodOverview(
    BuildContext context, 
    MoodOverview overview, 
    EmotionalMirrorData mirrorData,
  ) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spaceM),
              ResponsiveText(
                'Emotional Overview',
                baseFontSize: DesignTokens.fontSizeXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Mood balance visualization
          Container(
            height: DesignTokens.spaceL,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              gradient: LinearGradient(
                colors: _getMoodBalanceColors(overview.moodBalance),
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Enhanced metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Balance',
                  _formatBalance(overview.moodBalance),
                  _getBalanceColor(overview.moodBalance),
                  Icons.balance_rounded,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Variety',
                  '${(overview.emotionalVariety * 100).round()}%',
                  DesignTokens.accentBlue,
                  Icons.palette_rounded,
                ),
              ),
              SizedBox(width: DesignTokens.spaceM),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Entries',
                  '${mirrorData.totalEntries}',
                  DesignTokens.accentGreen,
                  Icons.edit_note_rounded,
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Description
          ResponsiveText(
            overview.description,
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
          ),
        ],
      ),
    );
  }
  
  /// Builds additional mood insights
  Widget _buildMoodInsights(BuildContext context, MoodOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood Insights',
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
        ),
        
        SizedBox(height: DesignTokens.spaceL),
        
        // Insight cards
        _buildInsightCard(
          context,
          'Emotional Range',
          'You\'ve experienced ${(overview.emotionalVariety * 10).round()} different emotional states',
          Icons.psychology_rounded,
          DesignTokens.accentBlue,
        ),
        
        SizedBox(height: DesignTokens.spaceM),
        
        _buildInsightCard(
          context,
          'Balance Trend',
          _getBalanceTrendDescription(overview.moodBalance),
          Icons.trending_up_rounded,
          _getBalanceColor(overview.moodBalance),
        ),
        
        SizedBox(height: DesignTokens.spaceM),
        
        _buildInsightCard(
          context,
          'Growth Opportunity',
          _getGrowthOpportunity(overview.moodBalance, overview.emotionalVariety),
          Icons.lightbulb_outline_rounded,
          DesignTokens.accentYellow,
        ),
      ],
    );
  }
  
  /// Builds individual metric card
  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
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
          ResponsiveText(
            value,
            baseFontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: color,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spaceXS),
          ResponsiveText(
            title,
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.getTextSecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Builds individual insight card
  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignTokens.iconSizeM,
          ),
          
          SizedBox(width: DesignTokens.spaceM),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ),
                
                SizedBox(height: DesignTokens.spaceXS),
                
                Text(
                  description,
                  style: DesignTokens.getTextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
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
  
  /// Builds empty state when no mood overview data is available
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_rounded,
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
            'Building Your Overview',
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
            'Continue journaling to see your emotional balance and mood patterns emerge',
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
              // Navigate to journal screen to build mood data
              Navigator.of(context).pushNamed('/journal');
            },
            icon: Icon(
              Icons.mood_rounded,
              size: DesignTokens.iconSizeS,
            ),
            label: Text('Start Tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.getPrimaryColor(context),
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
  
  // Helper methods (similar to the original emotional mirror screen)
  
  List<Color> _getMoodBalanceColors(double balance) {
    if (balance > 0.3) {
      return [Colors.green.shade300, Colors.green.shade600];
    } else if (balance < -0.3) {
      return [Colors.red.shade300, Colors.red.shade600];
    } else {
      return [Colors.blue.shade300, Colors.orange.shade400, Colors.green.shade300];
    }
  }
  
  String _formatBalance(double balance) {
    if (balance > 0.3) return 'Positive';
    if (balance < -0.3) return 'Challenging';
    return 'Balanced';
  }
  
  Color _getBalanceColor(double balance) {
    if (balance > 0.3) return DesignTokens.accentGreen;
    if (balance < -0.3) return DesignTokens.accentRed;
    return DesignTokens.accentBlue;
  }
  
  String _getBalanceDescription(double balance) {
    if (balance > 0.6) return 'Very Positive';
    if (balance > 0.3) return 'Positive';
    if (balance < -0.6) return 'Very Challenging';
    if (balance < -0.3) return 'Challenging';
    return 'Well Balanced';
  }
  
  String _getBalanceTrendDescription(double balance) {
    if (balance > 0.3) {
      return 'Your emotional balance is trending positively, showing resilience and growth';
    } else if (balance < -0.3) {
      return 'You\'re navigating some challenges - this awareness is the first step to growth';
    } else {
      return 'You\'re maintaining a healthy emotional balance across different experiences';
    }
  }
  
  String _getGrowthOpportunity(double balance, double variety) {
    if (variety < 0.3) {
      return 'Explore expressing a wider range of emotions in your journaling';
    } else if (balance < -0.3) {
      return 'Focus on identifying positive moments and growth opportunities';
    } else {
      return 'Continue your excellent emotional awareness and self-reflection practice';
    }
  }
}