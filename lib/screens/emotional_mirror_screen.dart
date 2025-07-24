import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../providers/emotional_mirror_provider.dart';
import '../widgets/emotional_trend_chart.dart';
import '../widgets/mood_distribution_chart.dart';
import '../widgets/emotional_journey_timeline_card.dart';
import '../widgets/pattern_recognition_dashboard_card.dart';
import '../widgets/self_awareness_evolution_card.dart';
import '../widgets/loading_state_widget.dart' as loading_widget;
import '../widgets/emotional_mirror_slide_view.dart';
import '../utils/iphone_detector.dart';

class EmotionalMirrorScreen extends StatefulWidget {
  const EmotionalMirrorScreen({super.key});

  @override
  State<EmotionalMirrorScreen> createState() => _EmotionalMirrorScreenState();
}

class _EmotionalMirrorScreenState extends State<EmotionalMirrorScreen> {

  @override
  void initState() {
    super.initState();
    
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EmotionalMirrorProvider>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.getBackgroundPrimary(context),
      body: SafeArea(
        child: Consumer<EmotionalMirrorProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Header and Controls Section - Preserved exactly as before
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(provider),
                      AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
                      _buildControls(provider),
                      if (provider.showFilters) ...[
                        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
                        _buildFilterSection(provider),
                      ],
                    ],
                  ),
                ),
                
                // Content Section - Now using slide-based layout
                Expanded(
                  child: _buildSlideContent(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(EmotionalMirrorProvider provider) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceS)),
          decoration: BoxDecoration(
            color: DesignTokens.getColorWithOpacity(DesignTokens.getPrimaryColor(context), 0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.psychology_rounded,
            color: DesignTokens.getPrimaryColor(context),
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeL),
          ),
        ),
        AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'Emotional Mirror',
                baseFontSize: DesignTokens.fontSizeXXXL,
                fontWeight: DesignTokens.fontWeightBold,
                color: DesignTokens.getTextPrimary(context),
              ),
              AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
              ResponsiveText(
                '${provider.selectedTimeRange.displayName} • Premium insights',
                baseFontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextSecondary(context),
              ),
            ],
          ),
        ),
        Icon(
          Icons.auto_awesome_rounded,
          color: DesignTokens.getPrimaryColor(context),
          size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeM),
        ),
      ],
    );
  }

  Widget _buildControls(EmotionalMirrorProvider provider) {
    return Column(
      children: [
        // Time Range and View Mode Controls
        Row(
          children: [
            // Time Range Selector
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: TimeRange.values.map((timeRange) {
                  final isSelected = provider.selectedTimeRange == timeRange;
                  return Padding(
                    padding: EdgeInsets.only(right: DesignTokens.spaceS),
                    child: FilterChip(
                      label: Text(timeRange.displayName),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) provider.setTimeRange(timeRange);
                      },
                      backgroundColor: DesignTokens.getBackgroundSecondary(context),
                      selectedColor: DesignTokens.getPrimaryColor(context),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : DesignTokens.getTextSecondary(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
                ),
              ),
            ),
            
            AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
            
            // Filter Toggle Button
            IconButton(
              onPressed: provider.toggleFilters,
              icon: Icon(
                provider.showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: DesignTokens.getPrimaryColor(context),
              ),
              tooltip: provider.showFilters ? 'Hide filters' : 'Show filters',
            ),
            
            AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceS),
            
            // View Mode Selector
            PopupMenuButton<ViewMode>(
              icon: Icon(
                provider.selectedViewMode.icon,
                color: DesignTokens.getPrimaryColor(context),
              ),
              onSelected: provider.setViewMode,
              itemBuilder: (context) => ViewMode.values.map((mode) {
                return PopupMenuItem<ViewMode>(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(
                        mode.icon,
                        color: provider.selectedViewMode == mode 
                            ? DesignTokens.getPrimaryColor(context)
                            : DesignTokens.getTextSecondary(context),
                      ),
                      AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          color: provider.selectedViewMode == mode 
                              ? DesignTokens.getPrimaryColor(context)
                              : DesignTokens.getTextPrimary(context),
                          fontWeight: provider.selectedViewMode == mode 
                              ? FontWeight.w600 
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        
        // Active filters indicator
        if (provider.hasActiveFilters) ...[
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 16,
                color: DesignTokens.getPrimaryColor(context),
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceS),
              Text(
                'Filters active',
                style: TextStyle(
                  color: DesignTokens.getPrimaryColor(context),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  provider.clearAllFilters();
                },
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    color: DesignTokens.getPrimaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterSection(EmotionalMirrorProvider provider) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emotional Categories Filter
          ResponsiveText(
            'Emotional Categories',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          Wrap(
            spacing: DesignTokens.spaceS,
            runSpacing: DesignTokens.spaceS,
            children: ['Positive', 'Negative', 'Neutral', 'Mixed'].map((category) {
              final isSelected = provider.selectedEmotionalCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) => provider.toggleEmotionalCategory(category),
                backgroundColor: DesignTokens.getBackgroundTertiary(context),
                selectedColor: DesignTokens.accentGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : DesignTokens.getTextSecondary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          // Intensity Levels Filter
          ResponsiveText(
            'Intensity Levels',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          Wrap(
            spacing: DesignTokens.spaceS,
            runSpacing: DesignTokens.spaceS,
            children: IntensityLevel.values.map((level) {
              final isSelected = provider.selectedIntensityLevels.contains(level);
              return FilterChip(
                label: Text(level.shortName),
                selected: isSelected,
                onSelected: (selected) => provider.toggleIntensityLevel(level),
                backgroundColor: DesignTokens.getBackgroundTertiary(context),
                selectedColor: DesignTokens.accentBlue,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : DesignTokens.getTextSecondary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          // Pattern Types Filter
          ResponsiveText(
            'Pattern Types',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          Wrap(
            spacing: DesignTokens.spaceS,
            runSpacing: DesignTokens.spaceS,
            children: ['growth', 'recurring', 'awareness'].map((patternType) {
              final isSelected = provider.selectedPatternTypes.contains(patternType);
              return FilterChip(
                label: Text(patternType.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) => provider.togglePatternType(patternType),
                backgroundColor: DesignTokens.getBackgroundTertiary(context),
                selectedColor: DesignTokens.accentYellow,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : DesignTokens.getTextSecondary(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build slide-based content that replaces the traditional scrolling layout
  Widget _buildSlideContent(EmotionalMirrorProvider provider) {
    // For overview mode, use the new slide-based interface
    if (provider.selectedViewMode == ViewMode.overview) {
      return EmotionalMirrorSlideView(
        provider: provider,
        onSlideChanged: (index) {
          // Optional: Handle slide changes if needed for analytics or state
        },
      );
    }
    
    // For other view modes, maintain the existing behavior
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (provider.isLoading)
              _buildLoadingState()
            else if (provider.error != null)
              _buildErrorState(provider)
            else
              _buildContent(provider),
            
            AdaptiveSpacing.vertical(baseSize: 100), // Extra space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildContent(EmotionalMirrorProvider provider) {
    if (provider.mirrorData == null) {
      return _buildEmptyState();
    }

    switch (provider.selectedViewMode) {
      case ViewMode.overview:
        return _buildOverviewContent(provider);
      case ViewMode.charts:
        return _buildChartsContent(provider);
      case ViewMode.timeline:
        return _buildTimelineContent(provider);
      case ViewMode.insights:
        return _buildInsightsContent(provider);
    }
  }

  Widget _buildOverviewContent(EmotionalMirrorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Emotional Journey Timeline Card
          if (provider.journeyData != null)
            EmotionalJourneyTimelineCard(
              journeyData: provider.journeyData!,
              onTap: () => provider.setViewMode(ViewMode.timeline),
            ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          
          // Self-Awareness Evolution Card
          SelfAwarenessEvolutionCard(
            selfAwarenessScore: provider.mirrorData!.selfAwarenessScore,
            analyzedEntries: provider.mirrorData!.analyzedEntries,
            totalEntries: provider.mirrorData!.totalEntries,
            coreEvolution: provider.journeyData?.coreEvolution,
            onTap: () => provider.setViewMode(ViewMode.insights),
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          
          // Pattern Recognition Dashboard Card
          PatternRecognitionDashboardCard(
            patterns: provider.getFilteredPatterns(),
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          
          // Enhanced Mood Overview
          _buildEnhancedMoodOverview(provider),
        ],
      ),
    );
  }

  Widget _buildChartsContent(EmotionalMirrorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Emotional Trends Charts
          if (provider.intensityTrend != null && provider.intensityTrend!.isNotEmpty) ...[
            EmotionalTrendChart(
              trendPoints: provider.intensityTrend!,
              title: 'Emotional Intensity Trend',
              height: 280,
            ),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          ],
          
          if (provider.sentimentTrend != null && provider.sentimentTrend!.isNotEmpty) ...[
            SentimentTrendChart(
              trendPoints: provider.sentimentTrend!,
              title: 'Sentiment Over Time',
              height: 280,
            ),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          ],
          
          // Mood Distribution
          if (provider.moodDistribution != null) ...[
            MoodDistributionChart(
              distribution: provider.moodDistribution!,
              title: 'Mood Distribution',
              height: 320,
              showAIMoods: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineContent(EmotionalMirrorProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          if (provider.journeyData != null)
            EmotionalJourneyTimelineCard(
              journeyData: provider.journeyData!,
            ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(EmotionalMirrorProvider provider) {
    final insights = provider.getFilteredInsights();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Self-Awareness Evolution Card
          SelfAwarenessEvolutionCard(
            selfAwarenessScore: provider.mirrorData!.selfAwarenessScore,
            analyzedEntries: provider.mirrorData!.analyzedEntries,
            totalEntries: provider.mirrorData!.totalEntries,
            coreEvolution: provider.journeyData?.coreEvolution,
          ),
          
          if (insights.isNotEmpty) ...[
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
            _buildInsightsCard(insights),
          ],
        ],
      ),
    );
  }


  Widget _buildEnhancedMoodOverview(EmotionalMirrorProvider provider) {
    final overview = provider.mirrorData!.moodOverview;
    
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              ResponsiveText(
                'Emotional Overview',
                baseFontSize: DesignTokens.fontSizeXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
              ),
            ],
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          
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
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          
          // Enhanced metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Balance',
                  _formatBalance(overview.moodBalance),
                  _getBalanceColor(overview.moodBalance),
                  Icons.balance_rounded,
                ),
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              Expanded(
                child: _buildMetricCard(
                  'Variety',
                  '${(overview.emotionalVariety * 100).round()}%',
                  DesignTokens.accentBlue,
                  Icons.palette_rounded,
                ),
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              Expanded(
                child: _buildMetricCard(
                  'Entries',
                  '${provider.mirrorData!.totalEntries}',
                  DesignTokens.accentGreen,
                  Icons.edit_note_rounded,
                ),
              ),
            ],
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          
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

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
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
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          ResponsiveText(
            value,
            baseFontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightBold,
            color: color,
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
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


  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: iPhoneDetector.getAdaptivePadding(context, compact: 24, regular: 32, large: 40),
        child: loading_widget.LoadingStateWidget(
          type: loading_widget.LoadingType.wave,
          message: 'Analyzing your emotional patterns...',
          color: DesignTokens.getPrimaryColor(context),
          size: iPhoneDetector.getAdaptiveIconSize(context, base: 48),
        ),
      ),
    );
  }

  Widget _buildErrorState(EmotionalMirrorProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: 64),
            color: DesignTokens.getTextTertiary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          ResponsiveText(
            'Unable to load emotional mirror',
            baseFontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          ResponsiveText(
            provider.error ?? 'An unexpected error occurred',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          ComponentLibrary.primaryButton(
            text: 'Retry',
            onPressed: provider.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(List<String> insights) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.getPrimaryColor(context),
                size: DesignTokens.iconSizeL,
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              ResponsiveText(
                'Personal Insights',
                baseFontSize: DesignTokens.fontSizeXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.getTextPrimary(context),
              ),
            ],
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          
          ...insights.map((insight) {
            return Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spaceL),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(
                      top: DesignTokens.spaceS, 
                      right: DesignTokens.spaceL
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.getPrimaryColor(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: ResponsiveText(
                      insight,
                      baseFontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: DesignTokens.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            );
          }),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: 64),
            color: DesignTokens.getTextTertiary(context),
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          ResponsiveText(
            'Your Emotional Mirror',
            baseFontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.getTextPrimary(context),
            textAlign: TextAlign.center,
          ),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          ResponsiveText(
            'Start journaling to see your emotional patterns and insights unfold here.',
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<Color> _getMoodBalanceColors(double balance) {
    if (balance > 0.3) {
      return [DesignTokens.successColor.withOpacity(0.7), DesignTokens.successColor];
    } else if (balance < -0.3) {
      return [DesignTokens.errorColor.withOpacity(0.7), DesignTokens.errorColor];
    } else {
      return [DesignTokens.accentBlue.withOpacity(0.7), DesignTokens.accentYellow, DesignTokens.successColor.withOpacity(0.7)];
    }
  }

  String _formatBalance(double balance) {
    if (balance > 0.3) return 'Positive';
    if (balance < -0.3) return 'Challenging';
    return 'Balanced';
  }

  Color _getBalanceColor(double balance) {
    if (balance > 0.3) return DesignTokens.successColor;
    if (balance < -0.3) return DesignTokens.warningColor;
    return DesignTokens.getPrimaryColor(context);
  }
}
