import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_diagnostics_helper.dart';

/// Utility class for testing chart components with valid data generation and validation
class ChartTestUtils {
  static final Random _random = Random(42); // Fixed seed for consistent tests

  /// Generates valid emotional trend points for testing
  static List<EmotionalTrendPoint> generateEmotionalTrendPoints(
    int count, {
    DateTime? startDate,
    double minIntensity = 0.0,
    double maxIntensity = 10.0,
    int minEntryCount = 1,
    int maxEntryCount = 5,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: count));
    final points = <EmotionalTrendPoint>[];

    for (int i = 0; i < count; i++) {
      final date = start.add(Duration(days: i));
      final intensity = minIntensity + _random.nextDouble() * (maxIntensity - minIntensity);
      final entryCount = minEntryCount + _random.nextInt(maxEntryCount - minEntryCount + 1);

      points.add(EmotionalTrendPoint(
        date: date,
        intensity: intensity,
        entryCount: entryCount,
      ));
    }

    return points;
  }

  /// Generates valid sentiment trend points for testing
  static List<SentimentTrendPoint> generateSentimentTrendPoints(
    int count, {
    DateTime? startDate,
    double minSentiment = -1.0,
    double maxSentiment = 1.0,
    int minEntryCount = 1,
    int maxEntryCount = 5,
  }) {
    final start = startDate ?? DateTime.now().subtract(Duration(days: count));
    final points = <SentimentTrendPoint>[];

    for (int i = 0; i < count; i++) {
      final date = start.add(Duration(days: i));
      final sentiment = minSentiment + _random.nextDouble() * (maxSentiment - minSentiment);
      final entryCount = minEntryCount + _random.nextInt(maxEntryCount - minEntryCount + 1);

      points.add(SentimentTrendPoint(
        date: date,
        sentiment: sentiment,
        entryCount: entryCount,
      ));
    }

    return points;
  }

  /// Generates edge case data for testing chart robustness
  static List<EmotionalTrendPoint> generateEdgeCaseEmotionalData() {
    return [
      // Single data point
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 5.0,
        entryCount: 1,
      ),
    ];
  }

  /// Generates edge case sentiment data
  static List<SentimentTrendPoint> generateEdgeCaseSentimentData() {
    return [
      // Single data point with neutral sentiment
      SentimentTrendPoint(
        date: DateTime.now(),
        sentiment: 0.0,
        entryCount: 1,
      ),
    ];
  }

  /// Generates extreme values for stress testing
  static List<EmotionalTrendPoint> generateExtremeEmotionalData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        intensity: 0.0, // Minimum intensity
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: 10.0, // Maximum intensity
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 5.0, // Middle intensity
        entryCount: 1,
      ),
    ];
  }

  /// Generates extreme sentiment values
  static List<SentimentTrendPoint> generateExtremeSentimentData() {
    return [
      SentimentTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        sentiment: -1.0, // Most negative
        entryCount: 1,
      ),
      SentimentTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        sentiment: 1.0, // Most positive
        entryCount: 1,
      ),
      SentimentTrendPoint(
        date: DateTime.now(),
        sentiment: 0.0, // Neutral
        entryCount: 1,
      ),
    ];
  }

  /// Validates that chart coordinates are finite and not NaN
  /// Returns true if all coordinates are valid, false otherwise
  /// If throwOnInvalid is true, throws a TestFailure with detailed error message
  static bool validateChartCoordinates(
    List<Offset> coordinates, {
    bool throwOnInvalid = false,
    String? chartName,
  }) {
    if (coordinates.isEmpty) return true;

    try {
      final invalidCoordinates = <int, Offset>{};
      final issues = <String>[];
      
      for (int i = 0; i < coordinates.length; i++) {
        final coordinate = coordinates[i];
        bool isValid = true;
        
        if (!coordinate.dx.isFinite) {
          issues.add('Coordinate $i has non-finite x value: ${coordinate.dx}');
          isValid = false;
        }
        
        if (!coordinate.dy.isFinite) {
          issues.add('Coordinate $i has non-finite y value: ${coordinate.dy}');
          isValid = false;
        }
        
        if (coordinate.dx.isNaN) {
          issues.add('Coordinate $i has NaN x value');
          isValid = false;
        }
        
        if (coordinate.dy.isNaN) {
          issues.add('Coordinate $i has NaN y value');
          isValid = false;
        }
        
        if (!isValid) {
          invalidCoordinates[i] = coordinate;
        }
      }
      
      if (invalidCoordinates.isNotEmpty) {
        if (throwOnInvalid) {
          final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
            dataType: 'Chart Coordinates',
            issue: 'Invalid coordinates detected',
            invalidPointCount: invalidCoordinates.length,
            specificIssues: issues,
            suggestion: 'Check coordinate calculations for division by zero or other mathematical errors',
          );
          
          throw TestFailure(errorMessage);
        }
        
        return false;
      }
      
      return true;
    } catch (error) {
      if (error is TestFailure) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
        dataType: chartName ?? 'Chart Coordinates',
        issue: 'Exception during coordinate validation: $error',
        suggestion: 'Check if coordinates are properly structured',
      );
      
      if (throwOnInvalid) {
        throw TestFailure(errorMessage);
      }
      
      debugPrint(errorMessage);
      return false;
    }
  }

  /// Validates emotional trend point data integrity
  /// Returns a validation result with details about any issues found
  static ChartDataValidationResult validateEmotionalTrendData(List<EmotionalTrendPoint> points) {
    if (points.isEmpty) {
      return ChartDataValidationResult(
        isValid: true,
        message: 'Empty data set is valid',
        invalidPoints: [],
      );
    }

    final invalidPoints = <int>[];
    final issues = <String>[];

    try {
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        bool pointValid = true;
        
        // Check intensity is finite and not NaN
        if (!point.intensity.isFinite || point.intensity.isNaN) {
          issues.add('Point $i has invalid intensity: ${point.intensity}');
          pointValid = false;
        }
        
        // Check intensity is within reasonable bounds
        if (point.intensity < 0 || point.intensity > 10) {
          issues.add('Point $i has out-of-range intensity: ${point.intensity}');
          pointValid = false;
        }
        
        // Check entry count is positive
        if (point.entryCount <= 0) {
          issues.add('Point $i has invalid entry count: ${point.entryCount}');
          pointValid = false;
        }
        
        // Check date is valid
        if (point.date == null || point.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          issues.add('Point $i has invalid date: ${point.date}');
          pointValid = false;
        }
        
        if (!pointValid) {
          invalidPoints.add(i);
        }
      }
      
      return ChartDataValidationResult(
        isValid: invalidPoints.isEmpty,
        message: invalidPoints.isEmpty 
            ? 'All emotional trend points are valid' 
            : 'Found ${invalidPoints.length} invalid points: ${issues.join(', ')}',
        invalidPoints: invalidPoints,
        issues: issues,
      );
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
        dataType: 'EmotionalTrendPoint',
        issue: 'Exception during validation: $error',
        suggestion: 'Check if the data points are properly structured',
      );
      
      debugPrint(errorMessage);
      
      return ChartDataValidationResult(
        isValid: false,
        message: 'Validation error: $error',
        invalidPoints: [],
        issues: ['Exception during validation: $error'],
        exception: error,
      );
    }
  }

  /// Validates sentiment trend point data integrity
  /// Returns a validation result with details about any issues found
  static ChartDataValidationResult validateSentimentTrendData(List<SentimentTrendPoint> points) {
    if (points.isEmpty) {
      return ChartDataValidationResult(
        isValid: true,
        message: 'Empty data set is valid',
        invalidPoints: [],
      );
    }

    final invalidPoints = <int>[];
    final issues = <String>[];

    try {
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        bool pointValid = true;
        
        // Check sentiment is finite and not NaN
        if (!point.sentiment.isFinite || point.sentiment.isNaN) {
          issues.add('Point $i has invalid sentiment: ${point.sentiment}');
          pointValid = false;
        }
        
        // Check sentiment is within valid range (-1 to 1)
        if (point.sentiment < -1.0 || point.sentiment > 1.0) {
          issues.add('Point $i has out-of-range sentiment: ${point.sentiment}');
          pointValid = false;
        }
        
        // Check entry count is positive
        if (point.entryCount <= 0) {
          issues.add('Point $i has invalid entry count: ${point.entryCount}');
          pointValid = false;
        }
        
        // Check date is valid
        if (point.date == null || point.date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
          issues.add('Point $i has invalid date: ${point.date}');
          pointValid = false;
        }
        
        if (!pointValid) {
          invalidPoints.add(i);
        }
      }
      
      return ChartDataValidationResult(
        isValid: invalidPoints.isEmpty,
        message: invalidPoints.isEmpty 
            ? 'All sentiment trend points are valid' 
            : 'Found ${invalidPoints.length} invalid points: ${issues.join(', ')}',
        invalidPoints: invalidPoints,
        issues: issues,
      );
    } catch (error) {
      final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
        dataType: 'SentimentTrendPoint',
        issue: 'Exception during validation: $error',
        suggestion: 'Check if the data points are properly structured',
      );
      
      debugPrint(errorMessage);
      
      return ChartDataValidationResult(
        isValid: false,
        message: 'Validation error: $error',
        invalidPoints: [],
        issues: ['Exception during validation: $error'],
        exception: error,
      );
    }
  }
  
  /// Validates chart data and returns a sanitized version with invalid points removed
  static List<EmotionalTrendPoint> sanitizeEmotionalTrendData(List<EmotionalTrendPoint> points) {
    final validationResult = validateEmotionalTrendData(points);
    
    if (validationResult.isValid) {
      return points; // No sanitization needed
    }
    
    // Create a new list without the invalid points
    final sanitizedPoints = <EmotionalTrendPoint>[];
    
    for (int i = 0; i < points.length; i++) {
      if (!validationResult.invalidPoints.contains(i)) {
        sanitizedPoints.add(points[i]);
      }
    }
    
    return sanitizedPoints;
  }
  
  /// Validates chart data and returns a sanitized version with invalid points removed
  static List<SentimentTrendPoint> sanitizeSentimentTrendData(List<SentimentTrendPoint> points) {
    final validationResult = validateSentimentTrendData(points);
    
    if (validationResult.isValid) {
      return points; // No sanitization needed
    }
    
    // Create a new list without the invalid points
    final sanitizedPoints = <SentimentTrendPoint>[];
    
    for (int i = 0; i < points.length; i++) {
      if (!validationResult.invalidPoints.contains(i)) {
        sanitizedPoints.add(points[i]);
      }
    }
    
    return sanitizedPoints;
  }

  /// Calculates expected coordinate bounds for chart validation
  static Rect calculateExpectedChartBounds(Size chartSize) {
    // Based on the chart implementation, calculate expected bounds
    const padding = 40.0; // Left padding for labels
    const topPadding = 20.0;
    const bottomPadding = 40.0; // Bottom padding for date labels
    
    return Rect.fromLTWH(
      padding,
      topPadding,
      chartSize.width - padding - 20, // Right padding
      chartSize.height - topPadding - bottomPadding,
    );
  }

  /// Validates that coordinates fall within expected chart bounds
  static bool validateCoordinatesInBounds(
    List<Offset> coordinates,
    Rect expectedBounds,
  ) {
    for (final coordinate in coordinates) {
      if (!expectedBounds.contains(coordinate)) {
        return false;
      }
    }
    return true;
  }

  /// Creates test data with identical values to test division by zero scenarios
  static List<EmotionalTrendPoint> generateIdenticalIntensityData(
    int count,
    double intensity,
  ) {
    final points = <EmotionalTrendPoint>[];
    final baseDate = DateTime.now().subtract(Duration(days: count));

    for (int i = 0; i < count; i++) {
      points.add(EmotionalTrendPoint(
        date: baseDate.add(Duration(days: i)),
        intensity: intensity,
        entryCount: 1,
      ));
    }

    return points;
  }

  /// Creates test data with identical sentiment values
  static List<SentimentTrendPoint> generateIdenticalSentimentData(
    int count,
    double sentiment,
  ) {
    final points = <SentimentTrendPoint>[];
    final baseDate = DateTime.now().subtract(Duration(days: count));

    for (int i = 0; i < count; i++) {
      points.add(SentimentTrendPoint(
        date: baseDate.add(Duration(days: i)),
        sentiment: sentiment,
        entryCount: 1,
      ));
    }

    return points;
  }

  /// Validates chart painting doesn't produce invalid coordinates
  /// Returns true if all coordinates are valid, false otherwise
  /// If throwOnInvalid is true, throws a TestFailure with detailed error message
  static bool validateChartPainting(
    List<EmotionalTrendPoint> trendPoints,
    Size chartSize, {
    bool throwOnInvalid = false,
    String? chartName,
  }) {
    if (trendPoints.isEmpty) return true;
    if (chartSize.width <= 0 || chartSize.height <= 0) {
      if (throwOnInvalid) {
        final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
          dataType: chartName ?? 'Emotional Trend Chart',
          issue: 'Invalid chart size: $chartSize',
          suggestion: 'Chart size must have positive width and height',
        );
        throw TestFailure(errorMessage);
      }
      return false;
    }

    try {
      // Simulate coordinate calculations from the chart painter
      final maxIntensity = trendPoints.map((p) => p.intensity).reduce((a, b) => a > b ? a : b);
      final minIntensity = trendPoints.map((p) => p.intensity).reduce((a, b) => a < b ? a : b);
      
      final chartRect = calculateExpectedChartBounds(chartSize);
      final invalidCoordinates = <int, Map<String, dynamic>>{};
      final issues = <String>[];
      
      for (int i = 0; i < trendPoints.length; i++) {
        final point = trendPoints[i];
        bool isValid = true;
        
        // Calculate x coordinate
        final x = trendPoints.length > 1
            ? chartRect.left + (i / (trendPoints.length - 1)) * chartRect.width
            : chartRect.left + chartRect.width / 2;
        
        // Calculate y coordinate
        double normalizedIntensity;
        try {
          normalizedIntensity = maxIntensity > minIntensity 
              ? (point.intensity - minIntensity) / (maxIntensity - minIntensity)
              : 0.5;
        } catch (e) {
          issues.add('Point $i has calculation error: $e');
          invalidCoordinates[i] = {
            'point': point,
            'error': 'Calculation error: $e',
          };
          continue;
        }
        
        final y = chartRect.bottom - (normalizedIntensity * chartRect.height);
        
        // Validate coordinates
        if (!x.isFinite) {
          issues.add('Point $i has non-finite x coordinate: $x');
          isValid = false;
        }
        
        if (!y.isFinite) {
          issues.add('Point $i has non-finite y coordinate: $y');
          isValid = false;
        }
        
        if (x.isNaN) {
          issues.add('Point $i has NaN x coordinate');
          isValid = false;
        }
        
        if (y.isNaN) {
          issues.add('Point $i has NaN y coordinate');
          isValid = false;
        }
        
        if (!isValid) {
          invalidCoordinates[i] = {
            'point': point,
            'x': x,
            'y': y,
          };
        }
      }
      
      if (invalidCoordinates.isNotEmpty) {
        if (throwOnInvalid) {
          final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
            dataType: chartName ?? 'Emotional Trend Chart',
            issue: 'Invalid chart coordinates detected',
            invalidPointCount: invalidCoordinates.length,
            specificIssues: issues,
            suggestion: 'Check coordinate calculations for division by zero or other mathematical errors',
          );
          throw TestFailure(errorMessage);
        }
        return false;
      }
      
      return true;
    } catch (error) {
      if (error is TestFailure) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
        dataType: chartName ?? 'Emotional Trend Chart',
        issue: 'Exception during chart painting validation: $error',
        suggestion: 'Check if the chart data is properly structured and calculations are valid',
      );
      
      if (throwOnInvalid) {
        throw TestFailure(errorMessage);
      }
      
      debugPrint(errorMessage);
      return false;
    }
  }

  /// Validates sentiment chart painting
  /// Returns true if all coordinates are valid, false otherwise
  /// If throwOnInvalid is true, throws a TestFailure with detailed error message
  static bool validateSentimentChartPainting(
    List<SentimentTrendPoint> trendPoints,
    Size chartSize, {
    bool throwOnInvalid = false,
    String? chartName,
  }) {
    if (trendPoints.isEmpty) return true;
    if (chartSize.width <= 0 || chartSize.height <= 0) {
      if (throwOnInvalid) {
        final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
          dataType: chartName ?? 'Sentiment Chart',
          issue: 'Invalid chart size: $chartSize',
          suggestion: 'Chart size must have positive width and height',
        );
        throw TestFailure(errorMessage);
      }
      return false;
    }

    try {
      final chartRect = calculateExpectedChartBounds(chartSize);
      final invalidCoordinates = <int, Map<String, dynamic>>{};
      final issues = <String>[];
      
      for (int i = 0; i < trendPoints.length; i++) {
        final point = trendPoints[i];
        bool isValid = true;
        
        // Calculate x coordinate
        final x = trendPoints.length > 1
            ? chartRect.left + (i / (trendPoints.length - 1)) * chartRect.width
            : chartRect.left + chartRect.width / 2;
        
        // Calculate sentiment height
        double sentimentHeight;
        try {
          sentimentHeight = (point.sentiment * chartRect.height / 2).abs();
        } catch (e) {
          issues.add('Point $i has calculation error: $e');
          invalidCoordinates[i] = {
            'point': point,
            'error': 'Calculation error: $e',
          };
          continue;
        }
        
        // Validate coordinates
        if (!x.isFinite) {
          issues.add('Point $i has non-finite x coordinate: $x');
          isValid = false;
        }
        
        if (!sentimentHeight.isFinite) {
          issues.add('Point $i has non-finite sentiment height: $sentimentHeight');
          isValid = false;
        }
        
        if (x.isNaN) {
          issues.add('Point $i has NaN x coordinate');
          isValid = false;
        }
        
        if (sentimentHeight.isNaN) {
          issues.add('Point $i has NaN sentiment height');
          isValid = false;
        }
        
        // Validate sentiment height is within bounds
        if (sentimentHeight > chartRect.height / 2) {
          issues.add('Point $i has sentiment height ($sentimentHeight) exceeding bounds (${chartRect.height / 2})');
          isValid = false;
        }
        
        if (!isValid) {
          invalidCoordinates[i] = {
            'point': point,
            'x': x,
            'sentimentHeight': sentimentHeight,
          };
        }
      }
      
      if (invalidCoordinates.isNotEmpty) {
        if (throwOnInvalid) {
          final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
            dataType: chartName ?? 'Sentiment Chart',
            issue: 'Invalid chart coordinates detected',
            invalidPointCount: invalidCoordinates.length,
            specificIssues: issues,
            suggestion: 'Check sentiment calculations for division by zero or other mathematical errors',
          );
          throw TestFailure(errorMessage);
        }
        return false;
      }
      
      return true;
    } catch (error) {
      if (error is TestFailure) {
        rethrow;
      }
      
      final errorMessage = TestDiagnosticsHelper.getChartDataValidationErrorMessage(
        dataType: chartName ?? 'Sentiment Chart',
        issue: 'Exception during chart painting validation: $error',
        suggestion: 'Check if the chart data is properly structured and calculations are valid',
      );
      
      if (throwOnInvalid) {
        throw TestFailure(errorMessage);
      }
      
      debugPrint(errorMessage);
      return false;
    }
  }

  /// Creates comprehensive test dataset for chart testing
  static ChartTestDataSet createComprehensiveTestDataSet() {
    return ChartTestDataSet(
      normalEmotionalData: generateEmotionalTrendPoints(10),
      normalSentimentData: generateSentimentTrendPoints(10),
      singlePointEmotionalData: generateEdgeCaseEmotionalData(),
      singlePointSentimentData: generateEdgeCaseSentimentData(),
      extremeEmotionalData: generateExtremeEmotionalData(),
      extremeSentimentData: generateExtremeSentimentData(),
      identicalEmotionalData: generateIdenticalIntensityData(5, 5.0),
      identicalSentimentData: generateIdenticalSentimentData(5, 0.0),
    );
  }
}

/// Comprehensive test data set for chart testing
class ChartTestDataSet {
  final List<EmotionalTrendPoint> normalEmotionalData;
  final List<SentimentTrendPoint> normalSentimentData;
  final List<EmotionalTrendPoint> singlePointEmotionalData;
  final List<SentimentTrendPoint> singlePointSentimentData;
  final List<EmotionalTrendPoint> extremeEmotionalData;
  final List<SentimentTrendPoint> extremeSentimentData;
  final List<EmotionalTrendPoint> identicalEmotionalData;
  final List<SentimentTrendPoint> identicalSentimentData;

  ChartTestDataSet({
    required this.normalEmotionalData,
    required this.normalSentimentData,
    required this.singlePointEmotionalData,
    required this.singlePointSentimentData,
    required this.extremeEmotionalData,
    required this.extremeSentimentData,
    required this.identicalEmotionalData,
    required this.identicalSentimentData,
  });
}
/// Result of chart data validation with detailed information
class ChartDataValidationResult {
  final bool isValid;
  final String message;
  final List<int> invalidPoints;
  final List<String>? issues;
  final Object? exception;

  ChartDataValidationResult({
    required this.isValid,
    required this.message,
    required this.invalidPoints,
    this.issues,
    this.exception,
  });
  
  /// Returns a formatted error message with detailed information about validation issues
  String getDetailedErrorMessage() {
    final buffer = StringBuffer();
    
    buffer.writeln('Chart Data Validation Result:');
    buffer.writeln('- Valid: $isValid');
    buffer.writeln('- Message: $message');
    
    if (invalidPoints.isNotEmpty) {
      buffer.writeln('- Invalid points: ${invalidPoints.length}');
      buffer.writeln('- Invalid indices: ${invalidPoints.join(', ')}');
    }
    
    if (issues != null && issues!.isNotEmpty) {
      buffer.writeln('\nIssues:');
      for (final issue in issues!) {
        buffer.writeln('  - $issue');
      }
    }
    
    if (exception != null) {
      buffer.writeln('\nException: $exception');
    }
    
    return buffer.toString();
  }
}

/// Generates problematic data for testing chart error handling
class ChartErrorTestData {
  /// Generates data with NaN values
  static List<EmotionalTrendPoint> generateNaNIntensityData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        intensity: 5.0,
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: double.nan,
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 7.0,
        entryCount: 1,
      ),
    ];
  }

  /// Generates data with infinite values
  static List<EmotionalTrendPoint> generateInfiniteIntensityData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        intensity: 5.0,
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: double.infinity,
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 7.0,
        entryCount: 1,
      ),
    ];
  }

  /// Generates data with out-of-range values
  static List<EmotionalTrendPoint> generateOutOfRangeIntensityData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 3)),
        intensity: -5.0, // Negative (invalid)
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        intensity: 15.0, // Above max (invalid)
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: 5.0, // Valid
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 7.0, // Valid
        entryCount: 1,
      ),
    ];
  }

  /// Generates data with invalid entry counts
  static List<EmotionalTrendPoint> generateInvalidEntryCountData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        intensity: 5.0,
        entryCount: 0, // Invalid (zero)
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: 6.0,
        entryCount: -1, // Invalid (negative)
      ),
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 7.0,
        entryCount: 1, // Valid
      ),
    ];
  }

  /// Generates data with future dates (invalid)
  static List<EmotionalTrendPoint> generateFutureDateData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: 5.0,
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now(),
        intensity: 6.0,
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().add(const Duration(days: 5)), // Future date (invalid)
        intensity: 7.0,
        entryCount: 1,
      ),
    ];
  }

  /// Generates mixed problematic data for comprehensive testing
  static List<EmotionalTrendPoint> generateMixedProblematicData() {
    return [
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 4)),
        intensity: 5.0, // Valid
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 3)),
        intensity: double.nan, // Invalid (NaN)
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        intensity: 15.0, // Invalid (out of range)
        entryCount: 1,
      ),
      EmotionalTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: 7.0, // Valid
        entryCount: 0, // Invalid (zero)
      ),
      EmotionalTrendPoint(
        date: DateTime.now().add(const Duration(days: 1)), // Invalid (future)
        intensity: 6.0,
        entryCount: 1,
      ),
    ];
  }

  /// Generates problematic sentiment data
  static List<SentimentTrendPoint> generateProblematicSentimentData() {
    return [
      SentimentTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 4)),
        sentiment: 0.5, // Valid
        entryCount: 1,
      ),
      SentimentTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 3)),
        sentiment: double.nan, // Invalid (NaN)
        entryCount: 1,
      ),
      SentimentTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 2)),
        sentiment: 1.5, // Invalid (out of range)
        entryCount: 1,
      ),
      SentimentTrendPoint(
        date: DateTime.now().subtract(const Duration(days: 1)),
        sentiment: -0.5, // Valid
        entryCount: 0, // Invalid (zero)
      ),
      SentimentTrendPoint(
        date: DateTime.now().add(const Duration(days: 1)), // Invalid (future)
        sentiment: 0.0,
        entryCount: 1,
      ),
    ];
  }
}