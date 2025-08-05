import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/ai_service_error_tracker.dart';

void main() {
  group('AIServiceErrorTracker', () {
    setUp(() {
      // Clear any existing errors before each test
      AIServiceErrorTracker.clearAll();
    });

    test('should log and retrieve errors', () {
      // Log an error
      final testError = Exception('Test error');
      AIServiceErrorTracker.logError(
        'testOperation',
        testError,
        context: {'testKey': 'testValue'},
        provider: 'TestProvider',
      );

      // Retrieve errors
      final errors = AIServiceErrorTracker.getRecentErrors(limit: 5);
      
      expect(errors.length, 1);
      expect(errors.first.operation, 'testOperation');
      expect(errors.first.error, 'Exception: Test error');
      expect(errors.first.provider, 'TestProvider');
      expect(errors.first.context['testKey'], 'testValue');
    });

    test('should log and retrieve fallback events', () {
      // Log a fallback event
      AIServiceErrorTracker.logFallback(
        'API key invalid',
        'ClaudeAIProvider',
        context: {'keyLength': 0},
      );

      // Retrieve fallback events
      final fallbacks = AIServiceErrorTracker.getRecentFallbacks(limit: 5);
      
      expect(fallbacks.length, 1);
      expect(fallbacks.first.reason, 'API key invalid');
      expect(fallbacks.first.originalProvider, 'ClaudeAIProvider');
      expect(fallbacks.first.context['keyLength'], 0);
    });

    test('should generate error statistics', () {
      // Log some errors and fallbacks
      AIServiceErrorTracker.logError('operation1', Exception('Error 1'), provider: 'Provider1');
      AIServiceErrorTracker.logError('operation2', Exception('Error 2'), provider: 'Provider1');
      AIServiceErrorTracker.logFallback('Reason 1', 'Provider1');

      final stats = AIServiceErrorTracker.getErrorStatistics();
      
      expect(stats.totalErrors, 2);
      expect(stats.totalFallbacks, 1);
      expect(stats.errorsByOperation['operation1'], 1);
      expect(stats.errorsByOperation['operation2'], 1);
      expect(stats.fallbacksByReason['Reason 1'], 1);
    });

    test('should filter errors by operation', () {
      // Log errors with different operations
      AIServiceErrorTracker.logError('analyzeJournalEntry', Exception('Error 1'));
      AIServiceErrorTracker.logError('generateMonthlyInsight', Exception('Error 2'));
      AIServiceErrorTracker.logError('analyzeJournalEntry', Exception('Error 3'));

      final analysisErrors = AIServiceErrorTracker.getRecentErrors(
        operation: 'analyzeJournalEntry',
      );
      
      expect(analysisErrors.length, 2);
      expect(analysisErrors.every((e) => e.operation == 'analyzeJournalEntry'), true);
    });

    test('should filter errors by provider', () {
      // Log errors with different providers
      AIServiceErrorTracker.logError('operation', Exception('Error 1'), provider: 'ClaudeAIProvider');
      AIServiceErrorTracker.logError('operation', Exception('Error 2'), provider: 'FallbackProvider');
      AIServiceErrorTracker.logError('operation', Exception('Error 3'), provider: 'ClaudeAIProvider');

      final claudeErrors = AIServiceErrorTracker.getRecentErrors(
        provider: 'ClaudeAIProvider',
      );
      
      expect(claudeErrors.length, 2);
      expect(claudeErrors.every((e) => e.provider == 'ClaudeAIProvider'), true);
    });

    test('should generate comprehensive error report', () {
      // Log some test data
      AIServiceErrorTracker.logError('testOperation', Exception('Test error'));
      AIServiceErrorTracker.logFallback('Test reason', 'TestProvider');

      final report = AIServiceErrorTracker.generateErrorReport();
      
      expect(report.contains('AI Service Error Report'), true);
      expect(report.contains('Total Errors: 1'), true);
      expect(report.contains('Total Fallbacks: 1'), true);
      expect(report.contains('testOperation'), true);
      expect(report.contains('Test reason'), true);
    });

    test('should clear errors correctly', () {
      // Log some errors
      AIServiceErrorTracker.logError('operation', Exception('Error'));
      AIServiceErrorTracker.logFallback('reason', 'provider');
      
      expect(AIServiceErrorTracker.getRecentErrors().length, 1);
      expect(AIServiceErrorTracker.getRecentFallbacks().length, 1);

      // Clear all
      AIServiceErrorTracker.clearAll();
      
      expect(AIServiceErrorTracker.getRecentErrors().length, 0);
      expect(AIServiceErrorTracker.getRecentFallbacks().length, 0);
    });

    test('should limit stored errors to prevent memory issues', () {
      // Log more than 100 errors
      for (int i = 0; i < 105; i++) {
        AIServiceErrorTracker.logError('operation$i', Exception('Error $i'));
      }

      final stats = AIServiceErrorTracker.getErrorStatistics();
      expect(stats.totalErrors, 100); // Should be capped at 100
    });

    test('should determine health status correctly', () {
      final stats = AIServiceErrorTracker.getErrorStatistics();
      expect(stats.isHealthy, true); // Should be healthy with no errors

      // Log many recent errors
      for (int i = 0; i < 10; i++) {
        AIServiceErrorTracker.logError('operation', Exception('Error $i'));
      }

      final unhealthyStats = AIServiceErrorTracker.getErrorStatistics();
      expect(unhealthyStats.isHealthy, false); // Should be unhealthy with many errors
    });
  });
}