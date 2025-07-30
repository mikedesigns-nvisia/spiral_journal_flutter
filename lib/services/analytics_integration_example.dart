import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

/// Example integration of AnalyticsService with app components
/// This demonstrates how to integrate the analytics tracking throughout the app
class AnalyticsIntegrationExample {
  static final AnalyticsService _analytics = AnalyticsService();

  /// Example: Integrate with Claude AI Provider to track API usage
  static Future<void> trackClaudeAPICall({
    required String model,
    required int inputTokens,
    required int outputTokens,
    required String requestType,
    required bool success,
    required int processingTimeMs,
    String? errorMessage,
  }) async {
    await _analytics.trackHaikuAPIUsage(
      modelName: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      requestType: requestType,
      success: success,
      errorMessage: errorMessage,
      processingTimeMs: processingTimeMs,
    );
  }

  /// Example: Track UI interactions for new animated components
  static Future<void> trackButtonInteraction({
    required String buttonId,
    required String screenName,
    required String action,
    int? interactionDuration,
  }) async {
    await _analytics.trackUIInteraction(
      componentType: 'AnimatedButton',
      actionType: action,
      componentId: buttonId,
      screenName: screenName,
      interactionData: {
        if (interactionDuration != null) 'duration_ms': interactionDuration,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Example: Track card interactions
  static Future<void> trackCardInteraction({
    required String cardType,
    required String action,
    required String screenName,
    Map<String, dynamic>? additionalData,
  }) async {
    await _analytics.trackUIInteraction(
      componentType: cardType,
      actionType: action,
      screenName: screenName,
      interactionData: {
        'interaction_type': 'card',
        ...?additionalData,
      },
    );
  }

  /// Example: Track screen load performance
  static Future<void> trackScreenLoadTime({
    required String screenName,
    required Duration loadTime,
    Map<String, dynamic>? contextData,
  }) async {
    await _analytics.trackLoadTime(
      loadType: 'screen_load',
      loadTime: loadTime,
      contextData: {
        'screen_name': screenName,
        ...?contextData,
      },
    );
  }

  /// Example: Track app startup performance
  static Future<void> trackAppStartup({
    required Duration startupTime,
    required bool coldStart,
    String? deviceModel,
  }) async {
    await _analytics.trackLoadTime(
      loadType: 'app_start',
      loadTime: startupTime,
      contextData: {
        'cold_start': coldStart,
        'device_model': deviceModel,
        'startup_type': coldStart ? 'cold' : 'warm',
      },
    );
  }

  /// Example: Track frame rate during animations
  static Future<void> trackAnimationPerformance({
    required String screenName,
    required double averageFps,
    required int animationDurationMs,
  }) async {
    await _analytics.trackFrameRate(
      screenName: screenName,
      fps: averageFps,
      contextData: {
        'animation_duration_ms': animationDurationMs,
        'performance_tier': _getPerformanceTier(averageFps),
      },
    );
  }

  /// Example: Track feature discovery and adoption
  static Future<void> trackFeatureDiscovery({
    required String featureName,
    required String discoveryContext,
    String? featureVersion,
  }) async {
    await _analytics.trackFeatureUsage(
      featureName: featureName,
      featureVersion: featureVersion ?? '1.0.0',
      contextData: {
        'discovery_context': discoveryContext,
        'discovery_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Example: Track voice journal usage
  static Future<void> trackVoiceJournalUsage({
    required int recordingDurationSeconds,
    required bool transcriptionSuccess,
    String? errorType,
  }) async {
    await _analytics.trackFeatureUsage(
      featureName: 'voice_journal',
      contextData: {
        'recording_duration_seconds': recordingDurationSeconds,
        'transcription_success': transcriptionSuccess,
        'error_type': errorType,
      },
    );

    // Also track performance metrics
    await _analytics.trackPerformanceMetric(
      metricType: 'voice_processing',
      metricName: 'recording_duration',
      value: recordingDurationSeconds.toDouble(),
      unit: 'seconds',
      contextData: {
        'success': transcriptionSuccess,
        'error_type': errorType,
      },
    );
  }

  /// Example: Track templated insight usage
  static Future<void> trackTemplatedInsightUsage({
    required String insightType,
    required String action,
    Map<String, dynamic>? insightData,
  }) async {
    await _analytics.trackFeatureUsage(
      featureName: 'templated_insights',
      contextData: {
        'insight_type': insightType,
        'action': action,
        ...?insightData,
      },
    );

    await _analytics.trackUIInteraction(
      componentType: 'TemplatedInsightCard',
      actionType: action,
      screenName: 'insights_screen',
      interactionData: {
        'insight_type': insightType,
        ...?insightData,
      },
    );
  }

  /// Example: Track emotional mirror interactions
  static Future<void> trackEmotionalMirrorUsage({
    required String reflectionType,
    required int sessionDurationSeconds,
    required List<String> emotionsExplored,
  }) async {
    await _analytics.trackFeatureUsage(
      featureName: 'emotional_mirror',
      contextData: {
        'reflection_type': reflectionType,
        'session_duration_seconds': sessionDurationSeconds,
        'emotions_explored': emotionsExplored,
        'emotions_count': emotionsExplored.length,
      },
    );
  }

  /// Example: Track offline queue usage
  static Future<void> trackOfflineQueueEvent({
    required String eventType,
    required int queueSize,
    int? processingTimeMs,
  }) async {
    await _analytics.trackFeatureUsage(
      featureName: 'offline_queue',
      contextData: {
        'event_type': eventType,
        'queue_size': queueSize,
        'processing_time_ms': processingTimeMs,
      },
    );
  }

  /// Example: Get analytics dashboard data
  static Future<Map<String, dynamic>> getAnalyticsDashboard() async {
    final report = await _analytics.getAnalyticsReport(
      startDate: DateTime.now().subtract(Duration(days: 30)),
      endDate: DateTime.now(),
    );

    return {
      'overview': {
        'totalApiCost': report['summary']['totalApiCost'],
        'totalInteractions': report['summary']['totalInteractions'],
        'totalFeatures': report['summary']['totalFeatures'],
        'averageLoadTime': report['summary']['averageLoadTime'],
      },
      'apiUsage': {
        'totalRequests': report['haikuUsage']['totalRequests'],
        'successRate': report['haikuUsage']['successRate'],
        'dailyUsage': report['haikuUsage']['dailyUsage'],
      },
      'userEngagement': {
        'topComponents': report['uiInteractions']['topComponents'],
        'topActions': report['uiInteractions']['topActions'],
        'screenBreakdown': report['uiInteractions']['screenBreakdown'],
      },
      'featureAdoption': {
        'adoptionStages': report['featureAdoption']['adoptionStages'],
        'topFeatures': report['featureAdoption']['topFeatures'],
      },
      'performance': {
        'averageValues': report['performance']['averageValues'],
        'metricTypes': report['performance']['metricTypes'],
      },
    };
  }

  /// Helper: Determine performance tier based on FPS
  static String _getPerformanceTier(double fps) {
    if (fps >= 55) return 'excellent';
    if (fps >= 45) return 'good';
    if (fps >= 30) return 'acceptable';
    return 'poor';
  }

  /// Example: Initialize analytics on app startup
  static Future<void> initializeAnalytics() async {
    try {
      await _analytics.initialize();
      
      if (kDebugMode) {
        debugPrint('📊 Analytics service initialized successfully');
      }
      
      // Track app initialization
      await trackAppStartup(
        startupTime: Duration(milliseconds: 2500), // Example startup time
        coldStart: true,
        deviceModel: 'iPhone 15 Pro', // This would come from device info
      );
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize analytics: $e');
      }
    }
  }

  /// Example: Get privacy-compliant data export
  static Future<Map<String, dynamic>> exportUserData() async {
    return await _analytics.exportAnalyticsData();
  }

  /// Example: Clear user data for privacy compliance
  static Future<void> clearUserData() async {
    await _analytics.clearAnalyticsData();
  }
}