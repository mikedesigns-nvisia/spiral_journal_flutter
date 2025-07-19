import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/design_system/design_tokens.dart';
import 'package:spiral_journal/providers/core_provider.dart';
import 'package:spiral_journal/services/navigation_service.dart';
import 'package:spiral_journal/widgets/base_card.dart';


class YourCoresCard extends StatelessWidget {
  const YourCoresCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section using standardized component
          CardHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'Your Cores',
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Subtitle with consistent styling
          Text(
            'Active emotional patterns shaping your mindset',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DesignTokens.getTextSecondary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Core items using Provider
          Consumer<CoreProvider>(
            builder: (context, coreProvider, child) {
              if (coreProvider.isLoading) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spaceXL),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (coreProvider.topCores.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spaceXL),
                    child: Text(
                      'Start journaling to develop your cores!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DesignTokens.getTextTertiary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                return Column(
                  children: coreProvider.topCores.asMap().entries.map((entry) {
                    final index = entry.key;
                    final core = entry.value;
                    return Column(
                      children: [
                        if (index > 0) SizedBox(height: DesignTokens.spaceL),
                        _buildCoreItem(
                          context,
                          core.name,
                          '${core.percentage.round()}%',
                          core.trend,
                          _getCoreColor(core.color),
                          _getCoreIcon(core.name),
                        ),
                      ],
                    );
                  }).toList(),
                );
              }
            },
          ),
          SizedBox(height: DesignTokens.spaceXL),
          
          // Footer section using standardized component
          CardFooter(
            description: 'Based on your journal patterns',
            ctaText: 'Explore All',
            onCtaPressed: () {
              NavigationService.instance.switchToTab(NavigationService.insightsTab);
            },
          ),
        ],
      ),
    );
  }

  Color _getCoreColor(String colorHex) {
    try {
      // Remove # if present and ensure it's 6 characters
      final cleanHex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (e) {
      return AppTheme.primaryOrange; // Fallback color
    }
  }

  IconData _getCoreIcon(String coreName) {
    switch (coreName.toLowerCase()) {
      case 'optimism':
        return Icons.sentiment_very_satisfied_rounded;
      case 'resilience':
        return Icons.shield_rounded;
      case 'self-awareness':
        return Icons.self_improvement_rounded;
      case 'creativity':
        return Icons.palette_rounded;
      case 'social connection':
        return Icons.people_rounded;
      case 'growth mindset':
        return Icons.trending_up_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  Widget _buildCoreItem(
    BuildContext context,
    String name,
    String percentage,
    String trend,
    Color coreColor,
    IconData icon,
  ) {
    final trendIcon = trend == 'rising' 
        ? Icons.trending_up_rounded 
        : trend == 'declining' 
            ? Icons.trending_down_rounded 
            : Icons.trending_flat_rounded;
    
    final trendColor = trend == 'rising' 
        ? DesignTokens.accentGreen 
        : trend == 'declining' 
            ? DesignTokens.accentRed 
            : DesignTokens.primaryOrange;

    return Container(
      padding: EdgeInsets.all(DesignTokens.spaceXL),
      decoration: BoxDecoration(
        color: DesignTokens.getColorWithOpacity(coreColor, 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: DesignTokens.getColorWithOpacity(coreColor, 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: DesignTokens.getColorWithOpacity(coreColor, 0.8),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: DesignTokens.iconSizeM,
            ),
          ),
          SizedBox(width: DesignTokens.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.getTextPrimary(context),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      trendIcon,
                      size: DesignTokens.iconSizeS,
                      color: trendColor,
                    ),
                    SizedBox(width: DesignTokens.spaceS),
                    Text(
                      trend.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            percentage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: DesignTokens.getTextPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
