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

class _EmotionalJourneyTimelineCardState extends State<EmotionalJourneyTimelineCard> {
  int _selectedMilestoneIndex = -1;

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
            color: DesignTokens.accentBlue,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.timeline_rounded,
            color: Colors.white,
            size: iPhoneDetector.getAdaptiveIconSize(context, base: DesignTokens.iconSizeL),
          ),
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
              ResponsiveText(
                '${widget.journeyData.milestones.length} milestones • ${widget.journeyData.totalEntries} entries',
                baseFontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightRegular,
                color: DesignTokens.getTextSecondary(context),
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
    return Container(
      width: iPhoneDetector.getAdaptiveValue(context, compact: 30, regular: 40, large: 50),
      height: 2,
      margin: EdgeInsets.only(top: iPhoneDetector.getAdaptiveValue(context, compact: 30, regular: 35, large: 40)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.getPrimaryColor(context).withOpacity(0.3),
            DesignTokens.getPrimaryColor(context).withOpacity(0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneDetails() {
    final milestone = widget.journeyData.milestones[_selectedMilestoneIndex];
    final milestoneColor = _getMilestoneColor(milestone.type);

    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        color: milestoneColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: milestoneColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getMilestoneIcon(milestone.type),
                color: milestoneColor,
                size: DesignTokens.iconSizeM,
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceM),
              Expanded(
                child: ResponsiveText(
                  milestone.title,
                  baseFontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.getTextPrimary(context),
                ),
              ),
            ],
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          
          ResponsiveText(
            milestone.description,
            baseFontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: DesignTokens.getTextSecondary(context),
          ),
          
          AdaptiveSpacing.vertical(baseSize: DesignTokens.spaceM),
          
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: DesignTokens.getTextTertiary(context),
                size: DesignTokens.iconSizeS,
              ),
              AdaptiveSpacing.horizontal(baseSize: DesignTokens.spaceS),
              ResponsiveText(
                DateFormat('EEEE, MMMM d, y').format(milestone.date),
                baseFontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.getTextTertiary(context),
              ),
            ],
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
      default:
        return DesignTokens.getPrimaryColor(context);
    }
  }

  IconData _getMilestoneIcon(String type) {
    switch (type) {
      case 'start':
        return Icons.play_arrow_rounded;
      case 'consistency':
        return Icons.trending_up_rounded;
      case 'growth':
        return Icons.psychology_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
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
      default:
        return 'Milestone';
    }
  }
}
