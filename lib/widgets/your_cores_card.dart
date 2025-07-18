import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spiral_journal/theme/app_theme.dart';
import 'package:spiral_journal/providers/core_provider.dart';


class YourCoresCard extends StatelessWidget {
  const YourCoresCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.getPrimaryColor(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Cores',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Active emotional patterns shaping your mindset',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            // Core items using Provider
            Consumer<CoreProvider>(
              builder: (context, coreProvider, child) {
                if (coreProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (coreProvider.topCores.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Start journaling to develop your cores!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getTextTertiary(context),
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
                          if (index > 0) const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Based on your journal patterns',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.getTextTertiary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      // Navigate to core library
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore All',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.getPrimaryColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppTheme.getPrimaryColor(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        ? AppTheme.accentGreen 
        : trend == 'declining' 
            ? AppTheme.accentRed 
            : AppTheme.primaryOrange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getColorWithOpacity(coreColor, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getColorWithOpacity(coreColor, 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.getColorWithOpacity(coreColor, 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      trendIcon,
                      size: 16,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
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
              color: AppTheme.getTextPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
