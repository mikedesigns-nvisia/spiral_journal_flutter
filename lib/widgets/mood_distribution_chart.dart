import 'package:flutter/material.dart';
import '../models/emotional_mirror_data.dart';
import '../theme/app_theme.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/heading_system.dart';
import '../services/chart_optimization_service.dart';

/// Widget for displaying mood distribution as a pie chart or bar chart
class MoodDistributionChart extends StatelessWidget {
  final MoodDistribution distribution;
  final String title;
  final double height;
  final bool showAIMoods;

  const MoodDistributionChart({
    super.key,
    required this.distribution,
    this.title = 'Mood Distribution',
    this.height = 250,
    this.showAIMoods = true,
  });

  @override
  Widget build(BuildContext context) {
    final moods = showAIMoods ? distribution.aiDetectedMoods : distribution.manualMoods;
    
    if (moods.isEmpty) {
      return _buildEmptyState(context);
    }

    return OptimizedChartWidget(
      chartId: 'mood_distribution_${moods.length}',
      chartBuilder: () => ComponentLibrary.gradientCard(
        gradient: DesignTokens.getCardGradient(context),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(DesignTokens.spaceS),
                        decoration: BoxDecoration(
                          color: DesignTokens.accentYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        ),
                        child: Icon(
                          Icons.palette_rounded,
                          color: DesignTokens.accentYellow,
                          size: DesignTokens.iconSizeM,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spaceM),
                      Text(
                        title,
                        style: HeadingSystem.getHeadlineSmall(context),
                      ),
                    ],
                  ),
                  if (distribution.aiDetectedMoods.isNotEmpty && distribution.manualMoods.isNotEmpty)
                    _buildToggleButton(context),
                ],
              ),
              SizedBox(height: DesignTokens.spaceXL),
              Expanded(
                child: Row(
                  children: [
                    // Pie chart
                    Expanded(
                      flex: 2,
                      child: _buildPieChart(context, moods),
                    ),
                    const SizedBox(width: 16),
                    // Legend
                    Expanded(
                      flex: 1,
                      child: _buildLegend(context, moods),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        showAIMoods ? 'AI Detected' : 'Manual',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.getPrimaryColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, int> moods) {
    final total = moods.values.reduce((a, b) => a + b);
    final sortedMoods = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomPaint(
      size: Size.infinite,
      painter: _PieChartPainter(
        moods: Map.fromEntries(sortedMoods.take(6)), // Show top 6 moods
        total: total,
        colors: _getMoodColors(context),
        context: context,
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Map<String, int> moods) {
    final total = moods.values.reduce((a, b) => a + b);
    final sortedMoods = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = _getMoodColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sortedMoods.take(6).map((entry) {
          final percentage = (entry.value / total * 100).round();
          final color = colors[entry.key] ?? AppTheme.getPrimaryColor(context);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMoodName(entry.key),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        if (sortedMoods.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${sortedMoods.length - 6} more',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.getTextSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: DesignTokens.accentYellow.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.palette_rounded,
                  size: DesignTokens.iconSizeXL,
                  color: DesignTokens.accentYellow,
                ),
              ),
              SizedBox(height: DesignTokens.spaceL),
              Text(
                'Your Palette Awaits',
                style: HeadingSystem.getHeadlineSmall(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spaceS),
              Text(
                'Track your moods to see your emotional rainbow',
                style: HeadingSystem.getBodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getMoodColors(BuildContext context) {
    return {
      // Positive emotions - vibrant, warm colors
      'happy': const Color(0xFFFFD700), // Gold
      'joyful': const Color(0xFFFF6B35), // Vibrant orange
      'excited': const Color(0xFFFF1744), // Bright red-pink
      'grateful': const Color(0xFF4CAF50), // Fresh green
      'content': const Color(0xFF2196F3), // Clear blue
      'peaceful': const Color(0xFF00BCD4), // Turquoise
      'love': const Color(0xFFE91E63), // Bright pink
      'optimistic': const Color(0xFFFFC107), // Amber
      'confident': const Color(0xFF9C27B0), // Purple
      'proud': const Color(0xFFFF9800), // Deep orange
      'energetic': const Color(0xFFE53935), // Energetic red
      'accomplished': const Color(0xFF8BC34A), // Light green
      'hopeful': const Color(0xFF03DAC6), // Teal
      'blessed': const Color(0xFFFFEB3B), // Bright yellow
      'inspired': const Color(0xFF673AB7), // Deep purple
      
      // Challenging emotions - rich, deeper tones
      'sad': const Color(0xFF3F51B5), // Indigo blue
      'angry': const Color(0xFFD32F2F), // Strong red
      'frustrated': const Color(0xFFFF5722), // Deep orange-red
      'anxious': const Color(0xFF795548), // Brown
      'worried': const Color(0xFF607D8B), // Blue grey
      'fear': const Color(0xFF9E9E9E), // Grey
      'stress': const Color(0xFFFF7043), // Orange-red
      'overwhelmed': const Color(0xFF7B1FA2), // Dark purple
      'lonely': const Color(0xFF455A64), // Dark blue-grey
      'disappointed': const Color(0xFF8D6E63), // Light brown
      'confused': const Color(0xFF9575CD), // Light purple
      'hurt': const Color(0xFFAD1457), // Dark pink
      
      // Neutral/reflective emotions - sophisticated tones
      'neutral': const Color(0xFF9E9E9E), // Neutral grey
      'reflective': const Color(0xFF7986CB), // Soft blue
      'curious': const Color(0xFF26C6DA), // Light cyan
      'thoughtful': const Color(0xFF5C6BC0), // Soft indigo
      'contemplative': const Color(0xFFBA68C8), // Light purple
      'calm': const Color(0xFF81C784), // Soft green
      'focused': const Color(0xFF4FC3F7), // Light blue
      'creative': const Color(0xFFFFB74D), // Light orange
    };
  }

  String _formatMoodName(String mood) {
    return mood.split('_').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, int> moods;
  final int total;
  final Map<String, Color> colors;
  final BuildContext context;

  _PieChartPainter({
    required this.moods,
    required this.total,
    required this.colors,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (moods.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;
    final innerRadius = radius * 0.45;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    // Draw shadow first
    final shadowPaint = Paint()
      ..color = DesignTokens.getColorWithOpacity(DesignTokens.getTextPrimary(context), 0.08)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center.translate(1, 3), radius + 1, shadowPaint);

    for (final entry in moods.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      final baseColor = colors[entry.key] ?? DesignTokens.getTextTertiary(context);
      
      // Create gradient for each slice using design tokens
      final gradient = RadialGradient(
        center: Alignment.center,
        colors: [
          baseColor.withValues(alpha: 0.9),
          baseColor,
          baseColor.withValues(alpha: 0.85),
        ],
        stops: const [0.3, 0.7, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      // Draw main pie slice with gradient
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Add highlight effect on outer edge
      final highlightPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        startAngle,
        sweepAngle,
        false,
        highlightPaint,
      );

      // Draw subtle border between slices using design tokens
      final borderPaint = Paint()
        ..color = DesignTokens.getBackgroundPrimary(context).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle with gradient using design tokens
    final centerGradient = RadialGradient(
      colors: [
        DesignTokens.getBackgroundPrimary(context),
        DesignTokens.getBackgroundSecondary(context),
      ],
    );

    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
          Rect.fromCircle(center: center, radius: innerRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerRadius, centerPaint);

    // Add subtle inner shadow to center circle
    final innerShadowPaint = Paint()
      ..color = DesignTokens.getColorWithOpacity(DesignTokens.getTextPrimary(context), 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, innerRadius - 1, innerShadowPaint);

    // Draw total count in center with design tokens
    final textPainter = TextPainter(
      text: TextSpan(
        text: total.toString(),
        style: TextStyle(
          color: DesignTokens.getTextPrimary(context),
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 4,
      ),
    );

    // Draw "moods" label with design tokens
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'moods',
        style: TextStyle(
          color: DesignTokens.getTextSecondary(context),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy + textPainter.height / 2 - 2,
      ),
    );

    // Add sparkle effects for visual interest using design tokens
    if (moods.length >= 3) {
      _drawSparkles(canvas, center, radius);
    }
  }

  void _drawSparkles(Canvas canvas, Offset center, double radius) {
    final sparklePaint = Paint()
      ..color = DesignTokens.primaryOrange.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Add a few sparkle points around the chart
    final sparklePositions = [
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.3),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.6),
      Offset(center.dx + radius * 0.2, center.dy - radius * 0.8),
    ];

    for (final pos in sparklePositions) {
      // Draw small diamond sparkle
      final path = Path();
      path.moveTo(pos.dx, pos.dy - 2.5);
      path.lineTo(pos.dx + 1.5, pos.dy);
      path.lineTo(pos.dx, pos.dy + 2.5);
      path.lineTo(pos.dx - 1.5, pos.dy);
      path.close();
      canvas.drawPath(path, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Simple bar chart for mood distribution
class MoodBarChart extends StatelessWidget {
  final Map<String, int> moods;
  final String title;
  final double height;

  const MoodBarChart({
    super.key,
    required this.moods,
    this.title = 'Mood Frequency',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (moods.isEmpty) {
      return _buildEmptyState(context);
    }

    final sortedMoods = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = sortedMoods.first.value;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: sortedMoods.take(8).length,
              itemBuilder: (context, index) {
                final entry = sortedMoods[index];
                final percentage = entry.value / maxCount;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          _formatMoodName(entry.key),
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.getPrimaryColor(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.getCardGradient(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? AppTheme.darkBackgroundTertiary 
              : AppTheme.backgroundTertiary
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: DesignTokens.getTextSecondary(context),
            ),
            const SizedBox(height: 8),
            Text(
              'No mood data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoodName(String mood) {
    return mood.split('_').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}
