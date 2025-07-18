import 'package:flutter/material.dart';
import '../services/emotional_mirror_service.dart';
import '../theme/app_theme.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (distribution.aiDetectedMoods.isNotEmpty && distribution.manualMoods.isNotEmpty)
                _buildToggleButton(context),
            ],
          ),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
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
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (sortedMoods.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${sortedMoods.length - 6} more',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextSecondary(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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
              Icons.pie_chart,
              size: 48,
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(height: 8),
            Text(
              'No mood data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
            ),
            Text(
              'Start journaling to see your mood patterns',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.getTextSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getMoodColors(BuildContext context) {
    return {
      'happy': Colors.yellow.shade600,
      'joyful': Colors.orange.shade400,
      'excited': Colors.pink.shade400,
      'grateful': Colors.green.shade400,
      'content': Colors.blue.shade300,
      'peaceful': Colors.teal.shade300,
      'love': Colors.red.shade300,
      'optimistic': Colors.amber.shade400,
      'confident': Colors.purple.shade300,
      'sad': Colors.blue.shade600,
      'angry': Colors.red.shade600,
      'frustrated': Colors.orange.shade600,
      'anxious': Colors.grey.shade500,
      'worried': Colors.brown.shade400,
      'fear': Colors.indigo.shade600,
      'stress': Colors.red.shade800,
      'overwhelmed': Colors.purple.shade600,
      'neutral': Colors.grey.shade400,
      'reflective': Colors.indigo.shade300,
      'curious': Colors.cyan.shade400,
      'thoughtful': Colors.deepPurple.shade300,
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

  _PieChartPainter({
    required this.moods,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (moods.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 20;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    for (final entry in moods.entries) {
      final sweepAngle = (entry.value / total) * 2 * 3.14159;
      final color = colors[entry.key] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw pie slice
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.4, centerPaint);

    // Draw total count in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: total.toString(),
        style: TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Draw "entries" label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'entries',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(
        center.dx - labelPainter.width / 2,
        center.dy + textPainter.height / 2 + 2,
      ),
    );
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
                            color: AppTheme.getPrimaryColor(context).withOpacity(0.1),
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
              color: AppTheme.getTextSecondary(context),
            ),
            const SizedBox(height: 8),
            Text(
              'No mood data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.getTextSecondary(context),
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