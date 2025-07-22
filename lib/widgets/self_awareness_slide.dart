import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../models/emotional_mirror_data.dart';
import '../providers/emotional_mirror_provider.dart';
import 'self_awareness_evolution_card.dart';
import 'slide_wrapper.dart';
import 'slide_error_wrapper.dart';

/// Slide component that wraps the existing SelfAwarenessEvolutionCard
/// for full-screen presentation in the slide-based emotional mirror interface.
/// Maintains all current metrics and core evolution display while preserving
/// existing tap functionality and data presentation.
class SelfAwarenessSlide extends StatelessWidget {
  /// The emotional mirror provider for accessing self-awareness data
  final EmotionalMirrorProvider provider;
  
  /// Optional callback for refresh functionality
  final VoidCallback? onRefresh;
  
  const SelfAwarenessSlide({
    super.key,
    required this.provider,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SlideErrorWrapper(
      slideTitle: 'Self-Awareness Evolution',
      error: provider.error,
      isLoading: provider.isLoading,
      onRetry: onRefresh ?? () => provider.refresh(),
      child: _buildSlideContent(context),
    );
  }
  
  /// Builds the main slide content based on data state
  Widget _buildSlideContent(BuildContext context) {
    // Handle empty data state
    if (provider.mirrorData == null) {
      return SlideWrapper(
        title: 'Self-Awareness Evolution',
        icon: Icons.psychology_rounded,
        onRefresh: onRefresh ?? () => provider.refresh(),
        child: _buildEmptyState(context),
      );
    }
    
    // Main slide content with self-awareness evolution
    return SlideWrapper(
      title: 'Self-Awareness Evolution',
      icon: Icons.psychology_rounded,
      onRefresh: onRefresh ?? () => provider.refresh(),
      child: _buildSelfAwarenessContent(context),
    );
  }
  
  /// Builds the main self-awareness content using the existing evolution card
  Widget _buildSelfAwarenessContent(BuildContext context) {
    final mirrorData = provider.mirrorData!;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Self-awareness overview stats
          _buildAwarenessOverview(context, mirrorData),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Main self-awareness evolution card optimized for full-screen
          SelfAwarenessEvolutionCard(
            selfAwarenessScore: mirrorData.selfAwarenessScore,
            analyzedEntries: mirrorData.analyzedEntries,
            totalEntries: mirrorData.totalEntries,
            coreEvolution: provider.journeyData?.coreEvolution,
            onTap: () => provider.setViewMode(ViewMode.insights),
          ),
        ],
      ),
    );
  }
  
  /// Builds self-awareness overview stats at the top of the slide
  Widget _buildAwarenessOverview(BuildContext context, EmotionalMirrorData mirrorData) {
    final analysisRate = mirrorData.totalEntries > 0 
        ? (mirrorData.analyzedEntries / mirrorData.totalEntries) * 100 
        : 0.0;
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.accentGreen.withValues(alpha: 0.1),
            DesignTokens.accentGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Main awareness score display
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Awareness Level',
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
                          '${(mirrorData.selfAwarenessScore * 100).round()}',
                          style: DesignTokens.getTextStyle(
                            fontSize: DesignTokens.getiPhoneAdaptiveFontSize(
                              context,
                              base: 36.0,
                              compactScale: 0.9,
                              largeScale: 1.1,
                            ),
                            fontWeight: DesignTokens.fontWeightBold,
                            color: DesignTokens.accentGreen,
                          ),
                        ),
                        
                        Text(
                          '%',
                          style: DesignTokens.getTextStyle(
                            fontSize: DesignTokens.fontSizeL,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: DesignTokens.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: DesignTokens.spaceXS),
                    
                    Text(
                      _getAwarenessLevelDescription(mirrorData.selfAwarenessScore),
                      style: DesignTokens.getTextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              Expanded(
                child: Column(
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
                        value: mirrorData.selfAwarenessScore,
                        backgroundColor: DesignTokens.accentGreen.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.accentGreen),
                        strokeWidth: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: DesignTokens.spaceL),
          
          // Analysis stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Analyzed',
                  '${mirrorData.analyzedEntries}',
                  '${mirrorData.totalEntries} total',
                  Icons.analytics_rounded,
                  DesignTokens.accentBlue,
                ),
              ),
              
              SizedBox(width: DesignTokens.spaceM),
              
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Analysis Rate',
                  '${analysisRate.round()}%',
                  'completion',
                  Icons.trending_up_rounded,
                  DesignTokens.accentYellow,
                ),
              ),
              
              SizedBox(width: DesignTokens.spaceM),
              
              Expanded(
                child: _buildQuickStat(
                  context,
                  'Growth Stage',
                  _getGrowthStage(mirrorData.selfAwarenessScore),
                  'current level',
                  Icons.emoji_events_rounded,
                  DesignTokens.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Builds individual quick stat item
  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    String subtitle,
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
            value,
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
          
          Text(
            subtitle,
            style: DesignTokens.getTextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextTertiary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Builds empty state when no self-awareness data is available
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_rounded,
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
            'Building Self-Awareness',
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
            'Continue journaling to develop deeper emotional intelligence and self-understanding',
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
              // Navigate to journal screen to continue building awareness
              Navigator.of(context).pushNamed('/journal');
            },
            icon: Icon(
              Icons.psychology_rounded,
              size: DesignTokens.iconSizeS,
            ),
            label: Text('Continue Journaling'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accentGreen,
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
  
  /// Gets awareness level description based on score
  String _getAwarenessLevelDescription(double score) {
    if (score >= 0.8) {
      return 'Master Level';
    } else if (score >= 0.6) {
      return 'Advanced';
    } else if (score >= 0.4) {
      return 'Intermediate';
    } else {
      return 'Developing';
    }
  }
  
  /// Gets growth stage based on score
  String _getGrowthStage(double score) {
    if (score >= 0.8) {
      return 'Master';
    } else if (score >= 0.6) {
      return 'Advanced';
    } else if (score >= 0.4) {
      return 'Growing';
    } else {
      return 'Building';
    }
  }
}