import 'package:flutter/material.dart';
import 'package:spiral_journal/theme/app_theme.dart';

class YourCoresCard extends StatelessWidget {
  const YourCoresCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xfffffefd9),
            Color(0xFFFFF8F5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.backgroundTertiary),
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
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.primaryOrange,
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
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            // Core items
            _buildCoreItem(
              context,
              'Optimist Core',
              '78%',
              'rising',
              AppTheme.coreOptimist,
              Icons.sentiment_very_satisfied_rounded,
            ),
            const SizedBox(height: 12),
            _buildCoreItem(
              context,
              'Reflective Core',
              '64%',
              'stable',
              AppTheme.coreReflective,
              Icons.self_improvement_rounded,
            ),
            const SizedBox(height: 12),
            _buildCoreItem(
              context,
              'Creative Core',
              '52%',
              'rising',
              AppTheme.coreCreative,
              Icons.palette_rounded,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Based on your journal patterns',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
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
                          color: AppTheme.primaryOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppTheme.primaryOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        color: coreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: coreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: coreColor.withOpacity(0.8),
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
                    color: AppTheme.textPrimary,
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
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
