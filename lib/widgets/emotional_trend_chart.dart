import 'package:flutter/material.dart';
import '../models/emotional_mirror_data.dart';
import '../theme/app_theme.dart';
import '../design_system/design_tokens.dart';
import '../design_system/component_library.dart';
import '../design_system/heading_system.dart';
import '../services/chart_optimization_service.dart';

/// Widget for displaying emotional intensity trends over time
class EmotionalTrendChart extends StatelessWidget {
  final List<EmotionalTrendPoint> trendPoints;
  final String title;
  final double height;

  const EmotionalTrendChart({
    super.key,
    required this.trendPoints,
    this.title = 'Emotional Intensity Trend',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (trendPoints.isEmpty) {
      return _buildEmptyState(context);
    }

    return OptimizedChartWidget(
      chartId: 'emotional_trend_${trendPoints.length}',
      chartBuilder: () => ComponentLibrary.gradientCard(
        gradient: DesignTokens.getCardGradient(context),
        child: Container(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spaceS),
                    decoration: BoxDecoration(
                      color: DesignTokens.accentBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: DesignTokens.accentBlue,
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
              SizedBox(height: DesignTokens.spaceXL),
              Expanded(
                child: _buildChart(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    // Validate and sanitize data before rendering
    List<EmotionalTrendPoint> validPoints = trendPoints;
    
    // Filter out points with NaN or infinite intensity values
    validPoints = validPoints.where((point) => 
      point.intensity.isFinite && !point.intensity.isNaN
    ).toList();
    
    // Handle empty data after filtering
    if (validPoints.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Calculate min and max intensity with validation
    double maxIntensity;
    double minIntensity;
    
    try {
      maxIntensity = validPoints.map((p) => p.intensity).reduce((a, b) => a > b ? a : b);
      minIntensity = validPoints.map((p) => p.intensity).reduce((a, b) => a < b ? a : b);
      
      // Ensure min and max are valid
      if (!maxIntensity.isFinite || maxIntensity.isNaN) maxIntensity = 10.0;
      if (!minIntensity.isFinite || minIntensity.isNaN) minIntensity = 0.0;
      
      // Ensure min and max are different to avoid division by zero
      if (maxIntensity <= minIntensity) {
        // Add a small range around the single value
        final value = minIntensity;
        minIntensity = value - 0.5;
        maxIntensity = value + 0.5;
      }
    } catch (e) {
      // Fallback to default range if calculation fails
      minIntensity = 0.0;
      maxIntensity = 10.0;
    }
    
    return CustomPaint(
      size: Size.infinite,
      painter: _TrendChartPainter(
        trendPoints: validPoints,
        minIntensity: minIntensity,
        maxIntensity: maxIntensity,
        primaryColor: DesignTokens.primaryOrange,
        secondaryColor: DesignTokens.accentBlue,
        backgroundColor: DesignTokens.getBackgroundPrimary(context),
        textColor: DesignTokens.getTextPrimary(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Container(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: DesignTokens.accentBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: DesignTokens.iconSizeXL,
                  color: DesignTokens.accentBlue,
                ),
              ),
              SizedBox(height: DesignTokens.spaceL),
              Text(
                'Your Growth Awaits',
                style: HeadingSystem.getHeadlineSmall(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spaceS),
              Text(
                'Continue journaling to discover your emotional trends',
                style: HeadingSystem.getBodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<EmotionalTrendPoint> trendPoints;
  final double minIntensity;
  final double maxIntensity;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textColor;

  _TrendChartPainter({
    required this.trendPoints,
    required this.minIntensity,
    required this.maxIntensity,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
  });
  
  /// Validates that a coordinate is finite and not NaN
  bool _isValidCoordinate(double value) {
    return value.isFinite && !value.isNaN;
  }
  
  /// Validates that a point has valid coordinates
  bool _isValidPoint(Offset point) {
    return _isValidCoordinate(point.dx) && _isValidCoordinate(point.dy);
  }
  
  /// Safely calculates x coordinate with division by zero protection
  double _calculateXCoordinate(int index, Rect chartRect) {
    if (trendPoints.length <= 1) {
      return chartRect.left + chartRect.width / 2; // Center single point
    }
    
    // Safe division with bounds checking
    final ratio = index / (trendPoints.length - 1);
    if (!ratio.isFinite || ratio.isNaN) {
      return chartRect.left + chartRect.width / 2; // Fallback to center
    }
    
    return chartRect.left + ratio * chartRect.width;
  }
  
  /// Safely calculates normalized intensity with division by zero protection
  double _calculateNormalizedIntensity(double intensity) {
    if (!_isValidCoordinate(intensity)) {
      return 0.5; // Default to middle if intensity is invalid
    }
    
    if (maxIntensity <= minIntensity) {
      return 0.5; // Default to middle if min/max are equal or inverted
    }
    
    final normalized = (intensity - minIntensity) / (maxIntensity - minIntensity);
    
    // Ensure result is valid
    if (!_isValidCoordinate(normalized)) {
      return 0.5; // Default to middle if calculation fails
    }
    
    return normalized;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (trendPoints.isEmpty) return;

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Calculate chart area (leave space for labels)
    final chartRect = Rect.fromLTWH(40, 20, size.width - 60, size.height - 40);
    
    // Create path for line and fill
    final linePath = Path();
    final fillPath = Path();
    
    // Calculate points using safe coordinate calculation methods
    final points = <Offset>[];
    for (int i = 0; i < trendPoints.length; i++) {
      final point = trendPoints[i];
      
      // Use safe coordinate calculation methods
      final x = _calculateXCoordinate(i, chartRect);
      final normalizedIntensity = _calculateNormalizedIntensity(point.intensity);
      
      // Calculate y coordinate with bounds checking
      final y = chartRect.bottom - (normalizedIntensity * chartRect.height);
      
      // Create point and validate before adding
      final chartPoint = Offset(x, y);
      if (_isValidPoint(chartPoint)) {
        points.add(chartPoint);
      }
    }

    // Draw fill area
    if (points.isNotEmpty) {
      fillPath.moveTo(points.first.dx, chartRect.bottom);
      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, chartRect.bottom);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    if (points.length > 1) {
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, paint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw grid lines and labels
    _drawGridAndLabels(canvas, size, chartRect);
  }

  void _drawGridAndLabels(Canvas canvas, Size size, Rect chartRect) {
    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.1)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal grid lines and intensity labels
    for (int i = 0; i <= 4; i++) {
      final y = chartRect.bottom - (i / 4) * chartRect.height;
      
      // Grid line
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      // Label - handle case when min and max are equal
      double intensity;
      if (maxIntensity > minIntensity) {
        intensity = minIntensity + (i / 4) * (maxIntensity - minIntensity);
      } else {
        // If min and max are equal, show consistent values around the single value
        intensity = minIntensity - 0.2 + (i / 4) * 0.4; // Show range of ±0.2 around the value
      }
      
      // Ensure intensity is finite and not NaN
      if (!intensity.isFinite || intensity.isNaN) {
        intensity = 0.0; // Fallback to zero if calculation fails
      }
      
      textPainter.text = TextSpan(
        text: intensity.toStringAsFixed(1),
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartRect.left - 35, y - textPainter.height / 2),
      );
    }

    // Draw vertical grid lines and date labels (simplified)
    if (trendPoints.length > 1) {
      final step = (trendPoints.length / 4).ceil();
      for (int i = 0; i < trendPoints.length; i += step) {
        // Handle single data point case to prevent division by zero
        final x = trendPoints.length > 1
            ? chartRect.left + (i / (trendPoints.length - 1)) * chartRect.width
            : chartRect.left + chartRect.width / 2; // Center the single point
        
        // Validate coordinate before drawing
        if (x.isFinite && !x.isNaN) {
          // Grid line
          canvas.drawLine(
            Offset(x, chartRect.top),
            Offset(x, chartRect.bottom),
            gridPaint,
          );

          // Date label (simplified)
          final date = trendPoints[i].date;
          textPainter.text = TextSpan(
            text: '${date.month}/${date.day}',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 10,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, chartRect.bottom + 5),
          );
        }
      }
    } else if (trendPoints.length == 1) {
      // Special case for single data point - draw a single vertical grid line
      final x = chartRect.left + chartRect.width / 2;
      
      // Grid line
      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        gridPaint,
      );
      
      // Date label
      final date = trendPoints[0].date;
      textPainter.text = TextSpan(
        text: '${date.month}/${date.day}',
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartRect.bottom + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget for displaying sentiment trends over time
class SentimentTrendChart extends StatelessWidget {
  final List<SentimentTrendPoint> trendPoints;
  final String title;
  final double height;

  const SentimentTrendChart({
    super.key,
    required this.trendPoints,
    this.title = 'Sentiment Trend',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (trendPoints.isEmpty) {
      return _buildEmptyState(context);
    }

    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Container(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.spaceS),
                  decoration: BoxDecoration(
                    color: DesignTokens.accentGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Icon(
                    Icons.mood_rounded,
                    color: DesignTokens.accentGreen,
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
            SizedBox(height: DesignTokens.spaceXL),
            Expanded(
              child: _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    // Validate and sanitize data before rendering
    List<SentimentTrendPoint> validPoints = trendPoints;
    
    // Filter out points with NaN or infinite sentiment values
    validPoints = validPoints.where((point) => 
      point.sentiment.isFinite && !point.sentiment.isNaN
    ).toList();
    
    // Handle empty data after filtering
    if (validPoints.isEmpty) {
      return _buildEmptyState(context);
    }
    
    // Ensure sentiment values are within valid range (-1.0 to 1.0)
    validPoints = validPoints.map((point) => 
      SentimentTrendPoint(
        date: point.date,
        sentiment: point.sentiment.clamp(-1.0, 1.0),
        entryCount: point.entryCount > 0 ? point.entryCount : 1,
      )
    ).toList();
    
    return CustomPaint(
      size: Size.infinite,
      painter: _SentimentChartPainter(
        trendPoints: validPoints,
        primaryColor: DesignTokens.primaryOrange,
        positiveColor: DesignTokens.accentGreen,
        negativeColor: DesignTokens.accentRed,
        backgroundColor: DesignTokens.getBackgroundPrimary(context),
        textColor: DesignTokens.getTextPrimary(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ComponentLibrary.gradientCard(
      gradient: DesignTokens.getCardGradient(context),
      child: Container(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spaceL),
                decoration: BoxDecoration(
                  color: DesignTokens.accentGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mood_rounded,
                  size: DesignTokens.iconSizeXL,
                  color: DesignTokens.accentGreen,
                ),
              ),
              SizedBox(height: DesignTokens.spaceL),
              Text(
                'Your Sentiment Journey Awaits',
                style: HeadingSystem.getHeadlineSmall(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignTokens.spaceS),
              Text(
                'Continue journaling to see your emotional sentiment patterns',
                style: HeadingSystem.getBodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SentimentChartPainter extends CustomPainter {
  final List<SentimentTrendPoint> trendPoints;
  final Color primaryColor;
  final Color positiveColor;
  final Color negativeColor;
  final Color backgroundColor;
  final Color textColor;

  _SentimentChartPainter({
    required this.trendPoints,
    required this.primaryColor,
    required this.positiveColor,
    required this.negativeColor,
    required this.backgroundColor,
    required this.textColor,
  });
  
  /// Validates that a coordinate is finite and not NaN
  bool _isValidCoordinate(double value) {
    return value.isFinite && !value.isNaN;
  }
  
  /// Validates that a rectangle has valid coordinates
  bool _isValidRect(Rect rect) {
    return _isValidCoordinate(rect.left) && 
           _isValidCoordinate(rect.top) && 
           _isValidCoordinate(rect.width) && 
           _isValidCoordinate(rect.height) &&
           rect.width >= 0 && 
           rect.height >= 0;
  }
  
  /// Safely calculates x coordinate with division by zero protection
  double _calculateXCoordinate(int index, Rect chartRect) {
    if (trendPoints.length <= 1) {
      return chartRect.left + chartRect.width / 2; // Center single point
    }
    
    // Safe division with bounds checking
    final ratio = index / (trendPoints.length - 1);
    if (!ratio.isFinite || ratio.isNaN) {
      return chartRect.left + chartRect.width / 2; // Fallback to center
    }
    
    return chartRect.left + ratio * chartRect.width;
  }
  
  /// Safely calculates sentiment height with validation
  double _calculateSentimentHeight(double sentiment, Rect chartRect) {
    // Ensure sentiment is within valid range
    final clampedSentiment = sentiment.clamp(-1.0, 1.0);
    
    // Calculate height with validation
    final height = (clampedSentiment * chartRect.height / 2).abs();
    
    // Validate result
    if (!_isValidCoordinate(height)) {
      return 0.0; // Default to zero height if calculation fails
    }
    
    return height;
  }
  
  /// Safely calculates bar width based on number of points
  double _calculateBarWidth(Rect chartRect) {
    if (trendPoints.length <= 1) {
      return chartRect.width * 0.2; // Narrower bar for single point
    }
    
    final width = chartRect.width / trendPoints.length * 0.6;
    
    // Validate result
    if (!_isValidCoordinate(width) || width <= 0) {
      return chartRect.width * 0.1; // Fallback to 10% of chart width
    }
    
    return width;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (trendPoints.isEmpty) return;

    // Calculate chart area (leave more space on left for labels)
    final chartRect = Rect.fromLTWH(80, 20, size.width - 100, size.height - 40);
    final centerY = chartRect.top + chartRect.height / 2;

    // Draw center line (neutral sentiment)
    final centerLinePaint = Paint()
      ..color = textColor.withOpacity(0.3)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(chartRect.left, centerY),
      Offset(chartRect.right, centerY),
      centerLinePaint,
    );

    // Calculate points and draw sentiment bars
    for (int i = 0; i < trendPoints.length; i++) {
      final point = trendPoints[i];
      
      // Use safe coordinate calculation methods
      final x = _calculateXCoordinate(i, chartRect);
      
      // Skip if x coordinate is invalid
      if (!_isValidCoordinate(x)) {
        continue;
      }
      
      // Calculate sentiment height using safe method
      final sentimentHeight = _calculateSentimentHeight(point.sentiment, chartRect);
      
      // Skip if sentiment height is invalid
      if (!_isValidCoordinate(sentimentHeight)) {
        continue;
      }
      
      // Ensure sentiment is within valid range
      final clampedSentiment = point.sentiment.clamp(-1.0, 1.0);
      final isPositive = clampedSentiment >= 0;
      
      final barPaint = Paint()
        ..color = isPositive ? positiveColor.withOpacity(0.7) : negativeColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      // Calculate bar width using safe method
      final barWidth = _calculateBarWidth(chartRect);
      
      // Calculate bar rectangle coordinates
      final barLeft = x - barWidth / 2;
      final barTop = isPositive ? centerY - sentimentHeight : centerY;
      
      // Create rectangle and validate before drawing
      final barRect = Rect.fromLTWH(
        barLeft,
        barTop,
        barWidth,
        sentimentHeight,
      );
      
      // Only draw if rectangle is valid
      if (_isValidRect(barRect)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(2)),
          barPaint,
        );
      }
    }

    // Draw grid and labels
    _drawGridAndLabels(canvas, size, chartRect, centerY);
  }

  void _drawGridAndLabels(Canvas canvas, Size size, Rect chartRect, double centerY) {
    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.1)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw sentiment labels
    final sentimentLabels = [
      (centerY - chartRect.height / 4, 'Positive'),
      (centerY, 'Neutral'),
      (centerY + chartRect.height / 4, 'Negative'),
    ];

    for (final (y, label) in sentimentLabels) {
      // Validate y coordinate
      if (!y.isFinite || y.isNaN) {
        continue; // Skip this label if y is invalid
      }
      
      // Grid line
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );

      // Label
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(chartRect.left - 75, y - textPainter.height / 2),
      );
    }

    // Draw date labels (simplified)
    if (trendPoints.length > 1) {
      final step = (trendPoints.length / 4).ceil();
      for (int i = 0; i < trendPoints.length; i += step) {
        // Handle single data point case to prevent division by zero
        final x = chartRect.left + (i / (trendPoints.length - 1)) * chartRect.width;
        
        // Validate x coordinate
        if (!x.isFinite || x.isNaN) {
          continue; // Skip this label if x is invalid
        }
        
        // Date label
        final date = trendPoints[i].date;
        textPainter.text = TextSpan(
          text: '${date.month}/${date.day}',
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 10,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartRect.bottom + 5),
        );
      }
    } else if (trendPoints.length == 1) {
      // Special case for single data point - draw a single date label
      final x = chartRect.left + chartRect.width / 2;
      
      // Date label
      final date = trendPoints[0].date;
      textPainter.text = TextSpan(
        text: '${date.month}/${date.day}',
        style: TextStyle(
          color: textColor.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, chartRect.bottom + 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
