import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../models/emotional_mirror_data.dart';
import '../providers/emotional_mirror_provider.dart';
import 'emotional_journey_timeline_card.dart';
import 'slide_wrapper.dart';
import 'slide_error_wrapper.dart';

/// Slide component that wraps the existing EmotionalJourneyTimelineCard
/// for full-screen presentation in the slide-based emotional mirror interface.
/// Maintains all existing functionality and interactions while optimizing
/// the layout for dedicated slide space.
class EmotionalJourneySlide extends StatelessWidget {
  /// The emotional mirror provider for accessing journey data
  final EmotionalMirrorProvider provider;
  
  /// Optional callback for refresh functionality
  final VoidCallback? onRefresh;
  
  const EmotionalJourneySlide({
    super.key,
    required this.provider,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SlideErrorWrapper(
      slideTitle: 'Emotional Journey',
      error: provider.error,
      isLoading: provider.isLoading,
      onRetry: onRefresh ?? () => provider.refresh(),
      child: _buildSlideContent(context),
    );
  }
  
  /// Builds the main slide content based on data state
  Widget _buildSlideContent(BuildContext context) {
    // Handle empty data state
    if (provider.journeyData == null) {
      return SlideWrapper(
        title: 'Emotional Journey',
        icon: Icons.timeline_rounded,
        onRefresh: onRefresh ?? () => provider.refresh(),
        child: _buildEmptyState(context),
      );
    }
    
    // Main slide content with journey timeline
    return SlideWrapper(
      title: 'Emotional Journey',
      icon: Icons.timeline_rounded,
      onRefresh: onRefresh ?? () => provider.refresh(),
      child: _buildJourneyContent(context),
    );
  }
  
  /// Builds the main journey content using the existing timeline card
  Widget _buildJourneyContent(BuildContext context) {
    final journeyData = provider.journeyData!;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journey overview stats
          _buildJourneyStats(context, journeyData),
          
          SizedBox(height: DesignTokens.spaceXL),
          
          // Main timeline card optimized for full-screen
          EmotionalJourneyTimelineCard(
            journeyData: journeyData,
            onTap: () => provider.setViewMode(ViewMode.timeline),
          ),
        ],
      ),
    );
  }
  
  /// Builds journey statistics overview at the top of the slide
  Widget _buildJourneyStats(BuildContext context, EmotionalJourneyData journeyData) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: DesignTokens.getBackgroundSecondary(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.getBackgroundTertiary(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Milestones',
              '${journeyData.milestones.length}',
              Icons.flag_rounded,
              DesignTokens.accentBlue,
            ),
          ),
          
          Container(
            width: 1,
            height: 40,
            color: DesignTokens.getBackgroundTertiary(context),
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          ),
          
          Expanded(
            child: _buildStatItem(
              context,
              'Total Entries',
              '${journeyData.totalEntries}',
              Icons.edit_note_rounded,
              DesignTokens.accentGreen,
            ),
          ),
          
          Container(
            width: 1,
            height: 40,
            color: DesignTokens.getBackgroundTertiary(context),
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceM),
          ),
          
          Expanded(
            child: _buildStatItem(
              context,
              'Journey Days',
              '${_calculateJourneyDays(journeyData)}',
              Icons.calendar_today_rounded,
              DesignTokens.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds individual stat item
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
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
            fontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightBold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: DesignTokens.spaceXS),
        
        Text(
          label,
          style: DesignTokens.getTextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.getTextSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  /// Builds empty state when no journey data is available
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_rounded,
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
            'Your Journey Begins',
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
            'Continue journaling to see your emotional milestones unfold',
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
              // Navigate to journal screen to start journaling
              Navigator.of(context).pushNamed('/journal');
            },
            icon: Icon(
              Icons.edit_rounded,
              size: DesignTokens.iconSizeS,
            ),
            label: Text('Start Journaling'),
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
  
  /// Calculates the number of days in the journey
  int _calculateJourneyDays(EmotionalJourneyData journeyData) {
    if (journeyData.milestones.isEmpty) return 0;
    
    final firstMilestone = journeyData.milestones.first;
    final lastMilestone = journeyData.milestones.last;
    
    return lastMilestone.date.difference(firstMilestone.date).inDays + 1;
  }
}