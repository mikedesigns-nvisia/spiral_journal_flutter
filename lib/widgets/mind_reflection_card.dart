import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/widgets/base_card.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/providers/emotional_mirror_provider.dart';
import 'package:spiral_journal/models/emotional_mirror_data.dart';

class MindReflectionCard extends StatelessWidget {
  const MindReflectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionalMirrorProvider>(
      builder: (context, mirrorProvider, child) {
        return BaseCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section using standardized component
              CardHeader(
                icon: Icons.psychology_rounded,
                title: 'Mind Reflection',
                iconBackgroundColor: DesignTokens.accentYellow,
                iconColor: DesignTokens.getPrimaryColor(context),
              ),
              SizedBox(height: DesignTokens.spaceXL),
              
              // Analysis content section using standardized container
              CardContentContainer(
                child: _buildContent(context, mirrorProvider),
              ),
              SizedBox(height: DesignTokens.spaceXL),
              
              // Footer section using standardized component
              CardFooter(
                description: _getFooterDescription(mirrorProvider),
                ctaText: 'View Details',
                onCtaPressed: () {
                  NavigationService.instance.switchToTab(NavigationService.mirrorTab);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, EmotionalMirrorProvider provider) {
    if (provider.isLoading) {
      return Column(
        children: [
          CircularProgressIndicator(
            color: DesignTokens.getPrimaryColor(context),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'Analyzing your journal insights...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      );
    }

    if (provider.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to Load Insights',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'We couldn\'t analyze your recent entries right now. Try refreshing or check back later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      );
    }

    final mirrorData = provider.mirrorData;
    if (mirrorData == null || mirrorData.insights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No Insights Yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: DesignTokens.getTextPrimary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceL),
          Text(
            'Start journaling to see personalized insights about your emotional patterns and growth.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
        ],
      );
    }

    // Show real insights from the emotional mirror data
    final insights = mirrorData.insights.take(3).toList(); // Show top 3 insights
    final moodDescription = mirrorData.moodOverview.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with consistent styling
        Text(
          'Emotional Pattern Analysis',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: DesignTokens.getTextPrimary(context),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: DesignTokens.spaceXL),
        
        // Description from real mood overview
        Text(
          moodDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: DesignTokens.getTextSecondary(context),
          ),
        ),
        SizedBox(height: DesignTokens.spaceXXL),
        
        // Real insight bullets
        ...insights.asMap().entries.map((entry) {
          final index = entry.key;
          final insight = entry.value;
          return Column(
            children: [
              _buildInsightBullet(context, insight),
              if (index < insights.length - 1) SizedBox(height: DesignTokens.spaceXL),
            ],
          );
        }).toList(),
      ],
    );
  }

  String _getFooterDescription(EmotionalMirrorProvider provider) {
    final mirrorData = provider.mirrorData;
    if (mirrorData == null) {
      return 'Connect with your emotional patterns';
    }
    
    final analyzedCount = mirrorData.analyzedEntries;
    final totalCount = mirrorData.totalEntries;
    
    if (analyzedCount == 0) {
      return 'Start journaling to see insights';
    }
    
    return 'Based on $analyzedCount analyzed entries';
  }

  Widget _buildInsightBullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(top: DesignTokens.spaceS),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: DesignTokens.spaceL),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
