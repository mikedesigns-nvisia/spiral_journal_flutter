import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/emotional_mirror_service.dart';
import 'chart_test_utils.dart';
import 'test_diagnostics_helper.dart';
import 'test_exception_handler.dart';

void main() {
  group('ChartTestUtils Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('validateChartCoordinates should detect invalid coordinates', () {
      final validCoordinates = [
        const Offset(10, 20),
        const Offset(30, 40),
        const Offset(50, 60),
      ];
      
      final invalidCoordinates = [
        const Offset(10, 20),
        Offset(30, double.nan),
        const Offset(50, 60),
      ];
      
      final infiniteCoordinates = [
        const Offset(10, 20),
        Offset(double.infinity, 40),
        const Offset(50, 60),
      ];
      
      expect(ChartTestUtils.validateChartCoordinates(validCoordinates), isTrue);
      expect(ChartTestUtils.validateChartCoordinates(invalidCoordinates), isFalse);
      expect(ChartTestUtils.validateChartCoordinates(infiniteCoordinates), isFalse);
      
      // Test with throwOnInvalid
      expect(
        () => ChartTestUtils.validateChartCoordinates(invalidCoordinates, throwOnInvalid: true),
        throwsA(isA<TestFailure>()),
      );
    });

    test('validateEmotionalTrendData should detect invalid data points', () {
      final validPoints = ChartTestUtils.generateEmotionalTrendPoints(5);
      final nanPoints = ChartErrorTestData.generateNaNIntensityData();
      final outOfRangePoints = ChartErrorTestData.generateOutOfRangeIntensityData();
      
      final validResult = ChartTestUtils.validateEmotionalTrendData(validPoints);
      final nanResult = ChartTestUtils.validateEmotionalTrendData(nanPoints);
      final outOfRangeResult = ChartTestUtils.validateEmotionalTrendData(outOfRangePoints);
      
      expect(validResult.isValid, isTrue);
      expect(nanResult.isValid, isFalse);
      expect(outOfRangeResult.isValid, isFalse);
      
      // Check detailed error messages
      expect(nanResult.issues, isNotNull);
      expect(nanResult.issues!.isNotEmpty, isTrue);
      expect(nanResult.issues!.first, contains('invalid intensity'));
      
      // Check detailed error message formatting
      final detailedMessage = nanResult.getDetailedErrorMessage();
      expect(detailedMessage, contains('Chart Data Validation Result:'));
      expect(detailedMessage, contains('Valid: false'));
      expect(detailedMessage, contains('Invalid points:'));
    });

    test('validateSentimentTrendData should detect invalid data points', () {
      final validPoints = ChartTestUtils.generateSentimentTrendPoints(5);
      final problematicPoints = ChartErrorTestData.generateProblematicSentimentData();
      
      final validResult = ChartTestUtils.validateSentimentTrendData(validPoints);
      final problematicResult = ChartTestUtils.validateSentimentTrendData(problematicPoints);
      
      expect(validResult.isValid, isTrue);
      expect(problematicResult.isValid, isFalse);
      
      // Check detailed error messages
      expect(problematicResult.issues, isNotNull);
      expect(problematicResult.issues!.isNotEmpty, isTrue);
      expect(problematicResult.issues!.any((issue) => issue.contains('invalid sentiment')), isTrue);
    });

    test('validateChartPainting should detect invalid calculations', () {
      final validPoints = ChartTestUtils.generateEmotionalTrendPoints(5);
      final nanPoints = ChartErrorTestData.generateNaNIntensityData();
      final size = const Size(300, 200);
      
      expect(ChartTestUtils.validateChartPainting(validPoints, size), isTrue);
      expect(ChartTestUtils.validateChartPainting(nanPoints, size), isFalse);
      
      // Test with throwOnInvalid
      expect(
        () => ChartTestUtils.validateChartPainting(nanPoints, size, throwOnInvalid: true),
        throwsA(isA<TestFailure>()),
      );
    });

    test('validateSentimentChartPainting should detect invalid calculations', () {
      final validPoints = ChartTestUtils.generateSentimentTrendPoints(5);
      final problematicPoints = ChartErrorTestData.generateProblematicSentimentData();
      final size = const Size(300, 200);
      
      expect(ChartTestUtils.validateSentimentChartPainting(validPoints, size), isTrue);
      expect(ChartTestUtils.validateSentimentChartPainting(problematicPoints, size), isFalse);
      
      // Test with throwOnInvalid
      expect(
        () => ChartTestUtils.validateSentimentChartPainting(problematicPoints, size, throwOnInvalid: true),
        throwsA(isA<TestFailure>()),
      );
    });

    test('sanitizeEmotionalTrendData should remove invalid points', () {
      final mixedPoints = ChartErrorTestData.generateMixedProblematicData();
      final sanitizedPoints = ChartTestUtils.sanitizeEmotionalTrendData(mixedPoints);
      
      expect(mixedPoints.length, greaterThan(sanitizedPoints.length));
      
      // Validate sanitized points
      final validationResult = ChartTestUtils.validateEmotionalTrendData(sanitizedPoints);
      expect(validationResult.isValid, isTrue);
    });

    test('sanitizeSentimentTrendData should remove invalid points', () {
      final problematicPoints = ChartErrorTestData.generateProblematicSentimentData();
      final sanitizedPoints = ChartTestUtils.sanitizeSentimentTrendData(problematicPoints);
      
      expect(problematicPoints.length, greaterThan(sanitizedPoints.length));
      
      // Validate sanitized points
      final validationResult = ChartTestUtils.validateSentimentTrendData(sanitizedPoints);
      expect(validationResult.isValid, isTrue);
    });

    test('ChartDataValidationResult should provide detailed error messages', () {
      final result = ChartDataValidationResult(
        isValid: false,
        message: 'Validation failed',
        invalidPoints: [1, 3],
        issues: ['Point 1 has NaN intensity', 'Point 3 has invalid date'],
        exception: null,
      );
      
      final detailedMessage = result.getDetailedErrorMessage();
      expect(detailedMessage, contains('Chart Data Validation Result:'));
      expect(detailedMessage, contains('Valid: false'));
      expect(detailedMessage, contains('Message: Validation failed'));
      expect(detailedMessage, contains('Invalid points: 2'));
      expect(detailedMessage, contains('Invalid indices: 1, 3'));
      expect(detailedMessage, contains('Point 1 has NaN intensity'));
      expect(detailedMessage, contains('Point 3 has invalid date'));
    });

    test('ChartTestUtils should handle exceptions gracefully', () {
      // Create a situation that would cause an exception
      final List<EmotionalTrendPoint> nullPoints = [];
      nullPoints.add(null as EmotionalTrendPoint); // This will cause an exception
      
      // Should not throw but return a validation result with the exception
      final result = ChartTestUtils.validateEmotionalTrendData(nullPoints);
      expect(result.isValid, isFalse);
      expect(result.exception, isNotNull);
      expect(result.issues, isNotNull);
      expect(result.issues!.first, contains('Exception during validation'));
    });

    test('ChartTestUtils should provide comprehensive test data', () {
      final testDataSet = ChartTestUtils.createComprehensiveTestDataSet();
      
      expect(testDataSet.normalEmotionalData, isNotEmpty);
      expect(testDataSet.normalSentimentData, isNotEmpty);
      expect(testDataSet.singlePointEmotionalData, isNotEmpty);
      expect(testDataSet.singlePointSentimentData, isNotEmpty);
      expect(testDataSet.extremeEmotionalData, isNotEmpty);
      expect(testDataSet.extremeSentimentData, isNotEmpty);
      expect(testDataSet.identicalEmotionalData, isNotEmpty);
      expect(testDataSet.identicalSentimentData, isNotEmpty);
    });
  });
}