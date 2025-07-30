import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      analyticsService = AnalyticsService();
    });

    test('should initialize successfully', () async {
      await analyticsService.initialize();
      expect(analyticsService, isNotNull);
    });

    test('should track Haiku API usage', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackHaikuAPIUsage(
        modelName: 'claude-3-haiku-20240307',
        inputTokens: 100,
        outputTokens: 50,
        requestType: 'journal_analysis',
        success: true,
        processingTimeMs: 1500,
      );

      final stats = await analyticsService.getHaikuUsageStats();
      expect(stats['totalRequests'], equals(1));
      expect(stats['totalInputTokens'], equals(100));
      expect(stats['totalOutputTokens'], equals(50));
      expect(stats['successRate'], equals(1.0));
    });

    test('should track UI interactions', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackUIInteraction(
        componentType: 'AnimatedButton',
        actionType: 'tap',
        componentId: 'save_journal_button',
        screenName: 'journal_screen',
        interactionData: {'duration': 250},
      );

      final stats = await analyticsService.getUIInteractionStats();
      expect(stats['totalInteractions'], equals(1));
      expect(stats['uniqueComponents'], equals(1));
    });

    test('should track performance metrics', () async {
      await analyticsService.initialize();
      
      await analyticsService.trackLoadTime(
        loadType: 'app_start',
        loadTime: Duration(milliseconds: 2500),
        contextData: {'device': 'iPhone 15 Pro'},
      );

      final stats = await analyticsService.getPerformanceStats();
      expect(stats['totalMetrics'], equals(1));
      expect(stats['averageValues']['load_time.app_start'], equals(2500.0));
    });

    test('should track feature adoption', () async {
      await analyticsService.initialize();
      
      // First use
      await analyticsService.trackFeatureUsage(
        featureName: 'voice_journal',
        featureVersion: '1.0.0',
        contextData: {'screen': 'journal_screen'},
      );

      // Second use
      await analyticsService.trackFeatureUsage(
        featureName: 'voice_journal',
        featureVersion: '1.0.0',
      );

      final stats = await analyticsService.getFeatureAdoptionStats();
      expect(stats['totalFeatures'], equals(1));
      expect(stats['topFeatures']['voice_journal'], equals(2));
    });

    test('should generate comprehensive analytics report', () async {
      await analyticsService.initialize();
      
      // Add some test data
      await analyticsService.trackHaikuAPIUsage(
        modelName: 'claude-3-haiku-20240307',
        inputTokens: 200,
        outputTokens: 100,
        requestType: 'journal_analysis',
        success: true,
      );

      await analyticsService.trackUIInteraction(
        componentType: 'InteractiveCard',
        actionType: 'swipe',
        screenName: 'core_library_screen',
      );

      await analyticsService.trackFeatureUsage(featureName: 'emotional_mirror');

      final report = await analyticsService.getAnalyticsReport();
      
      expect(report['reportGeneratedAt'], isNotNull);
      expect(report['haikuUsage']['totalRequests'], equals(1));
      expect(report['uiInteractions']['totalInteractions'], equals(1));
      expect(report['featureAdoption']['totalFeatures'], equals(1));
    });

    test('should export and clear analytics data', () async {
      await analyticsService.initialize();
      
      // Add test data
      await analyticsService.trackHaikuAPIUsage(
        modelName: 'claude-3-haiku-20240307',
        inputTokens: 100,
        outputTokens: 50,
        requestType: 'test',
        success: true,
      );

      // Export data
      final exportedData = await analyticsService.exportAnalyticsData();
      expect(exportedData['haikuApiUsage'], isNotEmpty);

      // Clear data
      await analyticsService.clearAnalyticsData();

      // Verify data is cleared
      final statsAfterClear = await analyticsService.getHaikuUsageStats();
      expect(statsAfterClear['totalRequests'], equals(0));
    });
  });
}