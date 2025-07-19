import 'package:flutter/material.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/widgets/base_card.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class MindReflectionCard extends StatelessWidget {
  const MindReflectionCard({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: Column(
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
                
                // Description with consistent styling
                Text(
                  'Your recent entries show a positive emotional trajectory with increased self-awareness and deeper introspection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: DesignTokens.getTextSecondary(context),
                  ),
                ),
                SizedBox(height: DesignTokens.spaceXXL),
                
                // Insight bullets with consistent spacing
                _buildInsightBullet(
                  context,
                  'Gratitude practices are strengthening your emotional foundation',
                ),
                SizedBox(height: DesignTokens.spaceXL),
                _buildInsightBullet(
                  context,
                  'Stress management techniques showing measurable improvement',
                ),
                SizedBox(height: DesignTokens.spaceXL),
                _buildInsightBullet(
                  context,
                  'Self-reflection depth has increased significantly',
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Footer section using standardized component
          CardFooter(
            description: 'Based on your recent journal entries',
            ctaText: 'View Details',
            onCtaPressed: () {
              NavigationService.instance.switchToTab(NavigationService.mirrorTab);
            },
          ),
        ],
      ),
    );
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
