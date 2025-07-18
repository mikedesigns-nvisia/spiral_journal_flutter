import 'package:flutter/foundation.dart';
import 'package:spiral_journal/services/analytics_service.dart';

/// Feedback collection service for TestFlight users
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final AnalyticsService _analytics = AnalyticsService();

  /// Collect user feedback for TestFlight
  Future<void> submitFeedback({
    required String category,
    required String feedback,
    int? rating,
    String? userEmail,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log feedback event for analytics
      await _analytics.logTestFlightEvent('feedback_submitted', extra: {
        'category': category,
        'rating': rating,
        'has_email': userEmail != null,
        'feedback_length': feedback.length,
        'additional_data_keys': additionalData?.keys.toList(),
      });

      // In a real implementation, this would send to a backend
      // For TestFlight, we're just logging for analytics
      debugPrint('TestFlight Feedback Submitted:');
      debugPrint('Category: $category');
      debugPrint('Rating: $rating');
      debugPrint('Feedback: $feedback');
      debugPrint('Email: $userEmail');
      debugPrint('Additional Data: $additionalData');

    } catch (e) {
      await _analytics.logError('feedback_submission_failed', context: e.toString());
      rethrow;
    }
  }

  /// Log feature usage for TestFlight feedback
  Future<void> logFeatureUsage(String feature, {Map<String, dynamic>? context}) async {
    await _analytics.logTestFlightEvent('feature_used', extra: {
      'feature': feature,
      ...?context,
    });
  }

  /// Log user journey events
  Future<void> logUserJourney(String step, {Map<String, dynamic>? context}) async {
    await _analytics.logTestFlightEvent('user_journey', extra: {
      'step': step,
      ...?context,
    });
  }

  /// Log performance issues
  Future<void> logPerformanceIssue(String issue, {Map<String, dynamic>? context}) async {
    await _analytics.logTestFlightEvent('performance_issue', extra: {
      'issue': issue,
      ...?context,
    });
  }

  /// Log UI/UX feedback
  Future<void> logUIFeedback(String screen, String feedback, {int? rating}) async {
    await _analytics.logTestFlightEvent('ui_feedback', extra: {
      'screen': screen,
      'feedback_type': feedback,
      'rating': rating,
    });
  }

  /// Log crash recovery events
  Future<void> logCrashRecovery(String recoveryAction, {Map<String, dynamic>? context}) async {
    await _analytics.logTestFlightEvent('crash_recovery', extra: {
      'recovery_action': recoveryAction,
      ...?context,
    });
  }
}