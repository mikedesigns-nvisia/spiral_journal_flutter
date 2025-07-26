import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/responsive_layout.dart';
import '../models/emotional_mirror_data.dart';
import '../utils/iphone_detector.dart';

/// Large premium card showing emotional journey timeline with milestones
class EmotionalJourneyTimelineCard extends StatefulWidget {
  final EmotionalJourneyData journeyData;
  final VoidCallback? onTap;

  const EmotionalJourneyTimelineCard({
    super.key,
    required this.journeyData,
    this.onTap,
  });

  @override
  State<EmotionalJourneyTimelineCard> createState() => _EmotionalJourneyTimelineCardState();
}

class _EmotionalJourneyTimelineCardState extends State<EmotionalJourneyTimelineCard> 
    with TickerProviderStateMixin {
  int _selectedMilestoneIndex = -1;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Start progress animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressController.forward();
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXXL),
          _buildTimeline(),
          if (_selectedMilestoneIndex >= 0) ...[
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
            _buildMilestoneDetails(),
          ],
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXL),
          _buildUpcomingMilestones(),
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final overallProgress = _calculateOverallProgress();
    final recentMilestones = _getRecentMilestones();
    
    return Column(
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _selectedMilestoneIndex >= 0 ? _pulseAnimation.value : 1.0,
                  child: Container(
                    padding: EdgeInsets.all(iPhoneDetector.getAdaptiveSpacing(context, base: DesignTokens.spaceM)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.accentBlue,
                          DesignTokens.primaryOrange,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.accentBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.timeline_rounded,
                      color: Colors.white,
                      size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeL),
                    ),
                  ),
                );
              },
            ),
            AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Emotional Journey',
                    baseFontSize: DesignTokens.fontSizeXXL,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                  AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
                  Row(
                    children: [
                      ResponsiveText(
                        '${widget.journeyData.milestones.length} milestones',
                        baseFontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DesignTokens.getTextSecondary(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      ResponsiveText(
                        '${widget.journeyData.totalEntries} entries',
                        baseFontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (recentMilestones > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: DesignTokens.accentGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: DesignTokens.accentGreen,
                      size: DesignTokens.iconSizeS,
                    ),
                    AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceXS),
                    ResponsiveText(
                      '$recentMilestones new',
                      baseFontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.accentGreen,
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        
        // Progress indicator
        _buildProgressIndicator(overallProgress),
      ],
    );
  }

  Widget _buildTimeline() {
    if (widget.journeyData.milestones.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: iPhoneDetector.getAdaptiveValue(context, compact: 200, regular: 250, large: 300),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
        itemCount: widget.journeyData.milestones.length,
        itemBuilder: (context, index) {
          final milestone = widget.journeyData.milestones[index];
          final isSelected = _selectedMilestoneIndex == index;
          final isLast = index == widget.journeyData.milestones.length - 1;

          return Row(
            children: [
              _buildMilestonePoint(milestone, index, isSelected),
              if (!isLast) _buildTimelineConnector(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMilestonePoint(JourneyMilestone milestone, int index, bool isSelected) {
    final milestoneColor = _getMilestoneColor(milestone.type);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMilestoneIndex = isSelected ? -1 : index;
        });
      },
      child: Container(
        width: iPhoneDetector.getAdaptiveValue(context, compact: 120, regular: 140, large: 160),
        child: Column(
          children: [
            // Milestone point
            Container(
              width: iPhoneDetector.getAdaptiveValue(context, compact: 60, regular: 70, large: 80),
              height: iPhoneDetector.getAdaptiveValue(context, compact: 60, regular: 70, large: 80),
              decoration: BoxDecoration(
                color: isSelected ? milestoneColor : milestoneColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: milestoneColor,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: milestoneColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Icon(
                _getMilestoneIcon(milestone.type),
                color: isSelected ? Colors.white : milestoneColor,
                size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeM),
              ),
            ),
            
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
            
            // Milestone info
            ResponsiveText(
              milestone.title,
              baseFontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.getTextPrimary(context),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceXS),
            
            ResponsiveText(
              DateFormat('MMM d, y').format(milestone.date),
              baseFontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightRegular,
              color: DesignTokens.getTextTertiary(context),
              textAlign: TextAlign.center,
            ),
            
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
            
            // Type badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceS,
                vertical: DesignTokens.spaceXS,
              ),
              decoration: BoxDecoration(
                color: milestoneColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(
                  color: milestoneColor.withOpacity(0.3),
                ),
              ),
              child: ResponsiveText(
                _getMilestoneTypeLabel(milestone.type),
                baseFontSize: DesignTokens.fontSizeXS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: milestoneColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineConnector() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: iPhoneDetector.getAdaptiveValue(context, compact: 30, regular: 40, large: 50),
          height: 4,
          margin: EdgeInsets.only(top: iPhoneDetector.getAdaptiveValue(context, compact: 30, regular: 35, large: 40)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                DesignTokens.primaryOrange.withOpacity(0.8 * _progressAnimation.value),
                DesignTokens.accentBlue.withOpacity(0.6 * _progressAnimation.value),
                DesignTokens.accentGreen.withOpacity(0.4 * _progressAnimation.value),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primaryOrange.withOpacity(0.2 * _progressAnimation.value),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestoneDetails() {
    final milestone = widget.journeyData.milestones[_selectedMilestoneIndex];
    final milestoneColor = _getMilestoneColor(milestone.type);
    final daysFromStart = _calculateDaysFromStart(milestone);
    final nextMilestone = _getNextMilestone();
    final progressToNext = _calculateProgressToNext();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            milestoneColor.withOpacity(0.08),
            milestoneColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: milestoneColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: milestoneColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceM),
                decoration: BoxDecoration(
                  color: milestoneColor,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: milestoneColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getMilestoneIcon(milestone.type),
                  color: Colors.white,
                  size: DesignTokens.iconSizeM,
                ),
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      milestone.title,
                      baseFontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.getTextPrimary(context),
                    ),
                    ResponsiveText(
                      _getMilestoneTypeLabel(milestone.type).toUpperCase(),
                      baseFontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: milestoneColor,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceM,
                  vertical: DesignTokens.spaceS,
                ),
                decoration: BoxDecoration(
                  color: milestoneColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: ResponsiveText(
                  'Day $daysFromStart',
                  baseFontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: milestoneColor,
                ),
              ),
            ],
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          // Description
          ResponsiveText(
            milestone.description,
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
            maxLines: 3,
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildDetailStat(
                  'Date Achieved',
                  DateFormat('MMM d, y').format(milestone.date),
                  Icons.calendar_today_rounded,
                  DesignTokens.accentBlue,
                ),
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              Expanded(
                child: _buildDetailStat(
                  'Journey Day',
                  '$daysFromStart',
                  Icons.access_time_rounded,
                  DesignTokens.accentGreen,
                ),
              ),
            ],
          ),
          
          if (nextMilestone != null) ...[
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
            
            // Next milestone preview
            Container(
              padding: EdgeInsets.all(DesignTokens.spaceM),
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundSecondary(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: DesignTokens.getBackgroundTertiary(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: DesignTokens.getTextSecondary(context),
                        size: DesignTokens.iconSizeS,
                      ),
                      AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceS),
                      ResponsiveText(
                        'Next Milestone',
                        baseFontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: DesignTokens.getTextSecondary(context),
                      ),
                      const Spacer(),
                      ResponsiveText(
                        '${(progressToNext * 100).toInt()}%',
                        baseFontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: _getMilestoneColor(nextMilestone.type),
                      ),
                    ],
                  ),
                  AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
                  ResponsiveText(
                    nextMilestone.title,
                    baseFontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ],
              ),
            ),
          ],
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
              Icons.timeline_rounded,
              size: iPhoneDetector.getAdaptiveIconSize(context, base: 48),
              color: DesignTokens.getTextTertiary(context),
            ),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
            ResponsiveText(
              'Your Journey Begins',
              baseFontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: DesignTokens.getTextPrimary(context),
              textAlign: TextAlign.center,
            ),
            AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
            ResponsiveText(
              'Continue journaling to see your emotional milestones unfold',
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

  Widget _buildUpcomingMilestones() {
    final upcomingMilestones = _getUpcomingMilestones();
    
    if (upcomingMilestones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: DesignTokens.primaryOrange,
              size: DesignTokens.iconSizeM,
            ),
            AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
            ResponsiveText(
              'Upcoming Milestones',
              baseFontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.getTextPrimary(context),
            ),
          ],
        ),
        
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
        
        ResponsiveText(
          'Keep journaling to unlock these achievements',
          baseFontSize: DesignTokens.fontSizeM,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.getTextSecondary(context),
        ),
        
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceL),
        
        Container(
          height: iPhoneDetector.getAdaptiveValue(context, compact: 120, regular: 140, large: 160),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spaceS),
            itemCount: upcomingMilestones.length,
            itemBuilder: (context, index) {
              final milestone = upcomingMilestones[index];
              return Container(
                width: iPhoneDetector.getAdaptiveValue(context, compact: 200, regular: 220, large: 240),
                margin: EdgeInsets.only(right: DesignTokens.spaceM),
                child: _buildUpcomingMilestoneCard(milestone),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMilestoneCard(Map<String, dynamic> milestone) {
    final color = _getMilestoneColor(milestone['type']);
    final progress = milestone['progress'] as double;
    final isNearCompletion = progress >= 0.8;

    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: color.withOpacity(isNearCompletion ? 0.6 : 0.3),
          width: isNearCompletion ? 2 : 1,
        ),
        boxShadow: isNearCompletion ? [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceS),
                decoration: BoxDecoration(
                  color: color.withOpacity(isNearCompletion ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Icon(
                  _getMilestoneIcon(milestone['type']),
                  color: color,
                  size: DesignTokens.iconSizeM,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                  vertical: DesignTokens.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: ResponsiveText(
                  '${(progress * 100).toInt()}%',
                  baseFontSize: DesignTokens.fontSizeXS,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: color,
                ),
              ),
            ],
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          
          ResponsiveText(
            milestone['title'],
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.getTextPrimary(context),
            maxLines: 2,
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
          
          ResponsiveText(
            milestone['description'],
            baseFontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
            maxLines: 2,
          ),
          
          const Spacer(),
          
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for enhanced functionality
  double _calculateOverallProgress() {
    if (widget.journeyData.milestones.isEmpty) return 0.0;
    
    // Calculate progress based on milestone types achieved
    final milestoneTypes = widget.journeyData.milestones.map((m) => m.type).toSet();
    final expectedTypes = {'start', 'consistency', 'growth', 'achievement'};
    
    return milestoneTypes.length / expectedTypes.length;
  }

  List<Map<String, dynamic>> _getUpcomingMilestones() {
    final achievedTypes = widget.journeyData.milestones.map((m) => m.type).toSet();
    final currentEntries = widget.journeyData.totalEntries;
    final journeyDays = _getJourneyDays();
    final currentStreak = _getCurrentStreak();
    
    List<Map<String, dynamic>> upcoming = [];

    // Entry-based milestones
    final entryMilestones = [
      {'target': 5, 'type': 'start', 'title': 'First Steps', 'description': 'Write your first 5 entries'},
      {'target': 10, 'type': 'consistency', 'title': 'Building Momentum', 'description': 'Reach 10 journal entries'},
      {'target': 25, 'type': 'growth', 'title': 'Quarter Century', 'description': 'Write 25 thoughtful entries'},
      {'target': 50, 'type': 'achievement', 'title': 'Half Century', 'description': 'Achieve 50 journal entries'},
      {'target': 100, 'type': 'breakthrough', 'title': 'Centurion', 'description': 'Complete 100 entries - a major milestone!'},
      {'target': 250, 'type': 'resilience', 'title': 'Dedicated Writer', 'description': 'Write 250 entries showing true commitment'},
      {'target': 500, 'type': 'achievement', 'title': 'Master Journaler', 'description': 'Reach 500 entries - exceptional dedication'},
      {'target': 1000, 'type': 'breakthrough', 'title': 'Thousand Words', 'description': '1000 entries - a legendary achievement'},
    ];

    for (final milestone in entryMilestones) {
      final target = milestone['target'] as int;
      if (currentEntries < target && !achievedTypes.contains(milestone['type'])) {
        upcoming.add({
          ...milestone,
          'progress': (currentEntries / target).clamp(0.0, 1.0),
          'requirement': '$currentEntries / $target entries',
        });
      }
    }

    // Streak-based milestones
    final streakMilestones = [
      {'target': 3, 'type': 'consistency', 'title': 'Three Day Streak', 'description': 'Journal for 3 consecutive days'},
      {'target': 7, 'type': 'consistency', 'title': 'Week Warrior', 'description': 'Complete a 7-day writing streak'},
      {'target': 14, 'type': 'growth', 'title': 'Two Week Champion', 'description': 'Maintain 14 days of consistent journaling'},
      {'target': 30, 'type': 'achievement', 'title': 'Monthly Master', 'description': 'Journal every day for a month'},
      {'target': 60, 'type': 'resilience', 'title': 'Unwavering Spirit', 'description': '60-day streak - incredible consistency'},
      {'target': 100, 'type': 'breakthrough', 'title': 'Hundred Day Hero', 'description': '100 consecutive days of journaling'},
    ];

    for (final milestone in streakMilestones) {
      final target = milestone['target'] as int;
      if (currentStreak < target) {
        upcoming.add({
          ...milestone,
          'progress': (currentStreak / target).clamp(0.0, 1.0),
          'requirement': '$currentStreak / $target day streak',
        });
      }
    }

    // Time-based milestones
    final timeMilestones = [
      {'target': 7, 'type': 'start', 'title': 'First Week', 'description': 'Complete your first week of journaling'},
      {'target': 30, 'type': 'consistency', 'title': 'One Month Journey', 'description': 'Journal for a full month'},
      {'target': 90, 'type': 'growth', 'title': 'Season of Growth', 'description': '3 months of emotional exploration'},
      {'target': 180, 'type': 'achievement', 'title': 'Half Year Milestone', 'description': '6 months of self-discovery'},
      {'target': 365, 'type': 'breakthrough', 'title': 'Year of Transformation', 'description': 'A full year of journaling'},
    ];

    for (final milestone in timeMilestones) {
      final target = milestone['target'] as int;
      if (journeyDays < target) {
        upcoming.add({
          ...milestone,
          'progress': (journeyDays / target).clamp(0.0, 1.0),
          'requirement': '$journeyDays / $target days',
        });
      }
    }

    // Special achievement milestones
    if (!achievedTypes.contains('reflection')) {
      upcoming.add({
        'type': 'reflection',
        'title': 'Deep Thinker',
        'description': 'Write an entry over 500 words',
        'progress': 0.3, // Placeholder - would calculate based on word counts
        'requirement': 'Write a detailed reflection',
      });
    }

    if (!achievedTypes.contains('connection')) {
      upcoming.add({
        'type': 'connection',
        'title': 'Emotional Intelligence',
        'description': 'Identify and track 10 different emotions',
        'progress': 0.6, // Placeholder - would calculate based on emotion diversity
        'requirement': 'Explore diverse emotions',
      });
    }

    // Sort by progress (closest to completion first) and take top 6
    upcoming.sort((a, b) => (b['progress'] as double).compareTo(a['progress'] as double));
    return upcoming.take(6).toList();
  }

  int _getJourneyDays() {
    if (widget.journeyData.milestones.isEmpty) return 0;
    final firstEntry = widget.journeyData.milestones.first.date;
    return DateTime.now().difference(firstEntry).inDays + 1;
  }

  int _getCurrentStreak() {
    // This would normally calculate the current consecutive day streak
    // For now, return a placeholder based on recent entries
    return _getRecentMilestones() * 2; // Placeholder calculation
  }
  
  int _getRecentMilestones() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    return widget.journeyData.milestones
        .where((milestone) => milestone.date.isAfter(sevenDaysAgo))
        .length;
  }
  
  Widget _buildProgressIndicator(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              'Journey Progress',
              baseFontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.getTextSecondary(context),
            ),
            ResponsiveText(
              '${(progress * 100).toInt()}%',
              baseFontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.primaryOrange,
            ),
          ],
        ),
        AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceS),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 6,
              decoration: BoxDecoration(
                color: DesignTokens.getBackgroundTertiary(context),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress * _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.accentGreen,
                        DesignTokens.primaryOrange,
                        DesignTokens.accentBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.primaryOrange.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  int _calculateDaysFromStart(JourneyMilestone milestone) {
    final firstMilestone = widget.journeyData.milestones.first;
    return milestone.date.difference(firstMilestone.date).inDays + 1;
  }
  
  JourneyMilestone? _getNextMilestone() {
    if (_selectedMilestoneIndex >= widget.journeyData.milestones.length - 1) {
      return null;
    }
    return widget.journeyData.milestones[_selectedMilestoneIndex + 1];
  }
  
  double _calculateProgressToNext() {
    final nextMilestone = _getNextMilestone();
    if (nextMilestone == null) return 1.0;
    
    final currentMilestone = widget.journeyData.milestones[_selectedMilestoneIndex];
    final totalDaysBetween = nextMilestone.date.difference(currentMilestone.date).inDays;
    final daysPassed = DateTime.now().difference(currentMilestone.date).inDays;
    
    if (totalDaysBetween <= 0) return 1.0;
    return (daysPassed / totalDaysBetween).clamp(0.0, 1.0);
  }
  
  Widget _buildDetailStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: color.withOpacity(0.2),
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
          ResponsiveText(
            label,
            baseFontSize: DesignTokens.fontSizeXS,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.getTextSecondary(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getMilestoneColor(String type) {
    switch (type) {
      case 'start':
        return DesignTokens.accentGreen;
      case 'consistency':
        return DesignTokens.accentBlue;
      case 'growth':
        return DesignTokens.accentYellow;
      case 'achievement':
        return DesignTokens.primaryOrange;
      case 'breakthrough':
        return DesignTokens.accentPink;
      case 'reflection':
        return DesignTokens.accentPurple;
      case 'connection':
        return DesignTokens.accentRed;
      case 'resilience':
        return DesignTokens.accentCyan;
      default:
        return DesignTokens.primaryOrange;
    }
  }

  IconData _getMilestoneIcon(String type) {
    switch (type) {
      case 'start':
        return Icons.rocket_launch_rounded;
      case 'consistency':
        return Icons.trending_up_rounded;
      case 'growth':
        return Icons.psychology_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'breakthrough':
        return Icons.lightbulb_rounded;
      case 'reflection':
        return Icons.self_improvement_rounded;
      case 'connection':
        return Icons.favorite_rounded;
      case 'resilience':
        return Icons.shield_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  String _getMilestoneTypeLabel(String type) {
    switch (type) {
      case 'start':
        return 'Beginning';
      case 'consistency':
        return 'Consistency';
      case 'growth':
        return 'Growth';
      case 'achievement':
        return 'Achievement';
      case 'breakthrough':
        return 'Breakthrough';
      case 'reflection':
        return 'Reflection';
      case 'connection':
        return 'Connection';
      case 'resilience':
        return 'Resilience';
      default:
        return 'Milestone';
    }
  }
}
