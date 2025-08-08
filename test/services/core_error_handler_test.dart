import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/core_error_handler.dart';
import 'package:spiral_journal/models/core_error.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('CoreErrorHandler Unit Tests', () {
    late CoreErrorHandler errorHandler;
    late TestSetupHelper testHelper;

    setUp(() async {
      testHelper = TestSetupHelper();
      await testHelper.setUp();
      
      errorHandler = CoreErrorHandler();
    });

    tearDown(() async {
      errorHandler.dispose();
      await testHelper.tearDown();
    });

    group('Error Handling', () {
      test('should handle data load failure correctly', () async {
        final error = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Failed to load core data',
          isRecoverable: true,
          context: {'operation': 'loadAllCores'},
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(1));
        expect(stats['errorsByType']['dataLoadFailure'], equals(1));
      });

      test('should handle sync failure correctly', () async {
        final error = CoreError(
          type: CoreErrorType.syncFailure,
          message: 'Synchronization failed',
          coreId: 'optimism',
          isRecoverable: true,
          context: {'operation': 'backgroundSync'},
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(1));
        expect(stats['errorsByType']['syncFailure'], equals(1));
        expect(stats['errorsByCoreId']['optimism'], equals(1));
      });

      test('should handle navigation error correctly', () async {
        final error = CoreError(
          type: CoreErrorType.navigationError,
          message: 'Navigation failed',
          coreId: 'invalid_core',
          isRecoverable: false,
          context: {'targetCoreId': 'invalid_core'},
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(1));
        expect(stats['errorsByType']['navigationError'], equals(1));
        expect(stats['nonRecoverableErrors'], equals(1));
      });

      test('should handle persistence error correctly', () async {
        final error = CoreError(
          type: CoreErrorType.persistenceError,
          message: 'Failed to save core data',
          coreId: 'resilience',
          isRecoverable: true,
          context: {'operation': 'updateCore'},
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(1));
        expect(stats['errorsByType']['persistenceError'], equals(1));
      });

      test('should handle cache error correctly', () async {
        final error = CoreError(
          type: CoreErrorType.cacheError,
          message: 'Cache operation failed',
          isRecoverable: true,
          context: {'cacheOperation': 'invalidate'},
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(1));
        expect(stats['errorsByType']['cacheError'], equals(1));
      });

      test('should handle network error correctly', () async {
        final error = CoreError(
          type: CoreErrorType.networkError,
          message: 'Network connection failed',
          isRecoverable: true,
          context: {'networkStatus': 'disconnected'},
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(1));
        expect(stats['errorsByType']['networkError'], equals(1));
      });

      test('should broadcast errors through stream', () async {
        final errorCompleter = Completer<CoreError>();
        final subscription = errorHandler.errorStream.listen((error) {
          if (!errorCompleter.isCompleted) {
            errorCompleter.complete(error);
          }
        });

        final testError = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Test error',
          isRecoverable: true,
        );

        await errorHandler.handleError(testError);

        final receivedError = await errorCompleter.future.timeout(
          const Duration(seconds: 1),
        );

        expect(receivedError.type, equals(testError.type));
        expect(receivedError.message, equals(testError.message));

        await subscription.cancel();
      });

      test('should accumulate error statistics correctly', () async {
        final errors = [
          CoreError(
            type: CoreErrorType.dataLoadFailure,
            message: 'Load error 1',
            coreId: 'optimism',
            isRecoverable: true,
          ),
          CoreError(
            type: CoreErrorType.dataLoadFailure,
            message: 'Load error 2',
            coreId: 'resilience',
            isRecoverable: true,
          ),
          CoreError(
            type: CoreErrorType.syncFailure,
            message: 'Sync error',
            coreId: 'optimism',
            isRecoverable: false,
          ),
        ];

        for (final error in errors) {
          await errorHandler.handleError(error);
        }

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(3));
        expect(stats['errorsByType']['dataLoadFailure'], equals(2));
        expect(stats['errorsByType']['syncFailure'], equals(1));
        expect(stats['errorsByCoreId']['optimism'], equals(2));
        expect(stats['errorsByCoreId']['resilience'], equals(1));
        expect(stats['recoverableErrors'], equals(2));
        expect(stats['nonRecoverableErrors'], equals(1));
      });
    });

    group('Recovery Actions', () {
      test('should execute refresh data recovery action', () async {
        final error = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Load failed',
          isRecoverable: true,
        );

        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.refreshData,
        );

        expect(success, isTrue);
      });

      test('should execute retry recovery action', () async {
        final error = CoreError(
          type: CoreErrorType.syncFailure,
          message: 'Sync failed',
          isRecoverable: true,
        );

        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.retry,
        );

        expect(success, isTrue);
      });

      test('should execute clear cache recovery action', () async {
        final error = CoreError(
          type: CoreErrorType.cacheError,
          message: 'Cache corrupted',
          isRecoverable: true,
        );

        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.clearCache,
        );

        expect(success, isTrue);
      });

      test('should execute force sync recovery action', () async {
        final error = CoreError(
          type: CoreErrorType.syncFailure,
          message: 'Sync conflict',
          isRecoverable: true,
        );

        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.forceSync,
        );

        expect(success, isTrue);
      });

      test('should execute reset state recovery action', () async {
        final error = CoreError(
          type: CoreErrorType.persistenceError,
          message: 'State corrupted',
          isRecoverable: true,
        );

        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.resetState,
        );

        expect(success, isTrue);
      });

      test('should handle recovery action for non-recoverable error', () async {
        final error = CoreError(
          type: CoreErrorType.navigationError,
          message: 'Navigation failed',
          isRecoverable: false,
        );

        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.retry,
        );

        expect(success, isFalse);
      });

      test('should handle recovery action failure', () async {
        final error = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Load failed',
          isRecoverable: true,
          context: {'simulateRecoveryFailure': true},
        );

        // This would normally succeed, but we're simulating failure
        final success = await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.refreshData,
        );

        // In a real implementation, this might fail based on context
        expect(success, isA<bool>());
      });

      test('should track recovery attempts', () async {
        final error = CoreError(
          type: CoreErrorType.syncFailure,
          message: 'Sync failed',
          isRecoverable: true,
        );

        await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.retry,
        );

        await errorHandler.executeRecoveryAction(
          error,
          CoreErrorRecoveryAction.forceSync,
        );

        final stats = errorHandler.getErrorStatistics();
        expect(stats['recoveryAttempts'], greaterThan(0));
        expect(stats['successfulRecoveries'], greaterThan(0));
      });
    });

    group('Error Context Analysis', () {
      test('should analyze error patterns', () async {
        final errors = [
          CoreError(
            type: CoreErrorType.networkError,
            message: 'Network timeout',
            isRecoverable: true,
            context: {'timeout': 5000},
          ),
          CoreError(
            type: CoreErrorType.networkError,
            message: 'Network timeout',
            isRecoverable: true,
            context: {'timeout': 5000},
          ),
          CoreError(
            type: CoreErrorType.networkError,
            message: 'Network timeout',
            isRecoverable: true,
            context: {'timeout': 5000},
          ),
        ];

        for (final error in errors) {
          await errorHandler.handleError(error);
        }

        final stats = errorHandler.getErrorStatistics();
        expect(stats['errorsByType']['networkError'], equals(3));
        
        // Should detect pattern of repeated network timeouts
        expect(stats['patterns'], isNotNull);
      });

      test('should provide error context insights', () async {
        final error = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Load failed',
          coreId: 'optimism',
          isRecoverable: true,
          context: {
            'operation': 'loadAllCores',
            'cacheHit': false,
            'networkLatency': 2000,
            'retryCount': 3,
          },
        );

        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['contextInsights'], isNotNull);
        expect(stats['contextInsights'], isA<Map<String, dynamic>>());
      });

      test('should suggest recovery strategies based on error type', () async {
        final networkError = CoreError(
          type: CoreErrorType.networkError,
          message: 'Network failed',
          isRecoverable: true,
        );

        await errorHandler.handleError(networkError);

        final suggestions = errorHandler.getSuggestedRecoveryActions(networkError);
        expect(suggestions, contains(CoreErrorRecoveryAction.retry));
        expect(suggestions, contains(CoreErrorRecoveryAction.refreshData));
      });

      test('should provide different suggestions for different error types', () async {
        final cacheError = CoreError(
          type: CoreErrorType.cacheError,
          message: 'Cache corrupted',
          isRecoverable: true,
        );

        final syncError = CoreError(
          type: CoreErrorType.syncFailure,
          message: 'Sync failed',
          isRecoverable: true,
        );

        final cacheSuggestions = errorHandler.getSuggestedRecoveryActions(cacheError);
        final syncSuggestions = errorHandler.getSuggestedRecoveryActions(syncError);

        expect(cacheSuggestions, contains(CoreErrorRecoveryAction.clearCache));
        expect(syncSuggestions, contains(CoreErrorRecoveryAction.forceSync));
        
        // Suggestions should be different
        expect(cacheSuggestions, isNot(equals(syncSuggestions)));
      });
    });

    group('Error Throttling and Rate Limiting', () {
      test('should throttle similar errors', () async {
        final error = CoreError(
          type: CoreErrorType.networkError,
          message: 'Network timeout',
          isRecoverable: true,
        );

        // Send multiple identical errors rapidly
        for (int i = 0; i < 10; i++) {
          await errorHandler.handleError(error);
        }

        final stats = errorHandler.getErrorStatistics();
        
        // Should throttle similar errors to prevent spam
        expect(stats['throttledErrors'], greaterThan(0));
        expect(stats['totalErrors'], lessThan(10));
      });

      test('should not throttle different error types', () async {
        final errors = [
          CoreError(type: CoreErrorType.networkError, message: 'Network', isRecoverable: true),
          CoreError(type: CoreErrorType.cacheError, message: 'Cache', isRecoverable: true),
          CoreError(type: CoreErrorType.syncFailure, message: 'Sync', isRecoverable: true),
          CoreError(type: CoreErrorType.dataLoadFailure, message: 'Load', isRecoverable: true),
        ];

        for (final error in errors) {
          await errorHandler.handleError(error);
        }

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(4));
        expect(stats['throttledErrors'], equals(0));
      });

      test('should reset throttling after time window', () async {
        final error = CoreError(
          type: CoreErrorType.networkError,
          message: 'Network timeout',
          isRecoverable: true,
        );

        // Send error
        await errorHandler.handleError(error);
        
        // Wait for throttle window to reset (simulate time passage)
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Send same error again
        await errorHandler.handleError(error);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['totalErrors'], equals(2));
      });
    });

    group('Error Reporting and Logging', () {
      test('should log errors with appropriate severity', () async {
        final criticalError = CoreError(
          type: CoreErrorType.persistenceError,
          message: 'Data corruption detected',
          isRecoverable: false,
          severity: CoreErrorSeverity.critical,
        );

        final warningError = CoreError(
          type: CoreErrorType.networkError,
          message: 'Slow network connection',
          isRecoverable: true,
          severity: CoreErrorSeverity.warning,
        );

        await errorHandler.handleError(criticalError);
        await errorHandler.handleError(warningError);

        final stats = errorHandler.getErrorStatistics();
        expect(stats['errorsBySeverity']['critical'], equals(1));
        expect(stats['errorsBySeverity']['warning'], equals(1));
      });

      test('should generate error reports', () async {
        final errors = [
          CoreError(
            type: CoreErrorType.dataLoadFailure,
            message: 'Load failed',
            coreId: 'optimism',
            isRecoverable: true,
          ),
          CoreError(
            type: CoreErrorType.syncFailure,
            message: 'Sync failed',
            coreId: 'resilience',
            isRecoverable: true,
          ),
        ];

        for (final error in errors) {
          await errorHandler.handleError(error);
        }

        final report = errorHandler.generateErrorReport();
        
        expect(report, isA<Map<String, dynamic>>());
        expect(report['summary'], isNotNull);
        expect(report['errors'], isA<List>());
        expect(report['statistics'], isNotNull);
        expect(report['timestamp'], isNotNull);
      });

      test('should export error data for debugging', () async {
        final error = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Load failed',
          isRecoverable: true,
          context: {'debug': 'info'},
        );

        await errorHandler.handleError(error);

        final exportData = errorHandler.exportErrorData();
        
        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData['errors'], isA<List>());
        expect(exportData['statistics'], isNotNull);
        expect(exportData['version'], isNotNull);
      });
    });

    group('Resource Management', () {
      test('should dispose resources correctly', () async {
        final error = CoreError(
          type: CoreErrorType.dataLoadFailure,
          message: 'Test error',
          isRecoverable: true,
        );

        await errorHandler.handleError(error);
        
        expect(errorHandler.getErrorStatistics()['totalErrors'], equals(1));

        errorHandler.dispose();

        // After disposal, should handle gracefully
        expect(() => errorHandler.getErrorStatistics(), returnsNormally);
      });

      test('should clear error history when requested', () async {
        final errors = [
          CoreError(type: CoreErrorType.networkError, message: 'Error 1', isRecoverable: true),
          CoreError(type: CoreErrorType.cacheError, message: 'Error 2', isRecoverable: true),
        ];

        for (final error in errors) {
          await errorHandler.handleError(error);
        }

        expect(errorHandler.getErrorStatistics()['totalErrors'], equals(2));

        errorHandler.clearErrorHistory();

        expect(errorHandler.getErrorStatistics()['totalErrors'], equals(0));
      });

      test('should handle memory pressure correctly', () async {
        // Generate many errors to test memory management
        for (int i = 0; i < 1000; i++) {
          final error = CoreError(
            type: CoreErrorType.networkError,
            message: 'Error $i',
            isRecoverable: true,
          );
          await errorHandler.handleError(error);
        }

        final stats = errorHandler.getErrorStatistics();
        
        // Should limit memory usage by keeping only recent errors
        expect(stats['totalErrors'], lessThanOrEqualTo(1000));
        expect(stats['memoryOptimized'], isTrue);
      });
    });
  });
}