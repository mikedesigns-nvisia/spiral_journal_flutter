import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiral_journal/services/secure_data_deletion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SecureDataDeletionService', () {
    late SecureDataDeletionService deletionService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      deletionService = SecureDataDeletionService();
    });

    group('Initialization', () {
      test('should create instance successfully', () {
        expect(deletionService, isNotNull);
      });

      test('should initialize without dependencies', () async {
        await deletionService.initialize();
        expect(deletionService, isNotNull);
      });
    });

    group('Progress Tracking', () {
      test('should provide initial progress tracking properties', () {
        expect(deletionService.deletionProgress, equals(0.0));
        expect(deletionService.deletionStatus, equals(''));
        expect(deletionService.isDeletingData, isFalse);
        expect(deletionService.deletionLog, isEmpty);
      });

      test('should be a ChangeNotifier', () {
        expect(deletionService, isA<ChangeNotifier>());
      });
    });

    group('Data Deletion Results', () {
      test('should create successful deletion result', () {
        final result = DataDeletionResult.success(
          deletionLog: ['Test log entry'],
          verificationPassed: true,
        );
        
        expect(result.success, isTrue);
        expect(result.verificationPassed, isTrue);
        expect(result.deletionLog, contains('Test log entry'));
        expect(result.error, isNull);
      });

      test('should create failure deletion result', () {
        const errorMessage = 'Deletion failed';
        final result = DataDeletionResult.failure(
          error: errorMessage,
          deletionLog: ['Error occurred'],
        );
        
        expect(result.success, isFalse);
        expect(result.verificationPassed, isFalse);
        expect(result.error, equals(errorMessage));
        expect(result.deletionLog, contains('Error occurred'));
      });
    });

    group('Partial Deletion Methods', () {
      test('should provide journal data deletion method', () async {
        await deletionService.initialize();
        
        final result = await deletionService.deleteJournalDataOnly();
        
        // Should complete without error even with no dependencies
        expect(result, isA<DataDeletionResult>());
      });

      test('should provide settings deletion method', () async {
        await deletionService.initialize();
        
        final result = await deletionService.deleteSettingsOnly();
        
        // Should complete without error even with no dependencies
        expect(result, isA<DataDeletionResult>());
      });
    });

    group('State Management', () {
      test('should maintain singleton pattern', () {
        final instance1 = SecureDataDeletionService();
        final instance2 = SecureDataDeletionService();
        
        expect(identical(instance1, instance2), isTrue);
      });

      test('should prevent concurrent deletions', () async {
        await deletionService.initialize();
        
        // Start first deletion
        final future1 = deletionService.deleteAllUserData();
        
        // Try to start second deletion while first is running
        expect(
          () => deletionService.deleteAllUserData(),
          throwsA(isA<StateError>()),
        );
        
        // Wait for first deletion to complete
        await future1;
      });

      test('should reset state after deletion completes', () async {
        await deletionService.initialize();
        
        await deletionService.deleteAllUserData();
        
        // State should be reset after completion
        expect(deletionService.isDeletingData, isFalse);
        expect(deletionService.deletionProgress, equals(0.0));
        expect(deletionService.deletionStatus, equals(''));
      });
    });

    group('Error Handling', () {
      test('should handle deletion with null dependencies', () async {
        await deletionService.initialize(
          journalRepository: null,
          coreLibraryService: null,
          settingsService: null,
          apiKeyService: null,
          exportService: null,
          databaseHelper: null,
        );
        
        final result = await deletionService.deleteAllUserData();
        
        // Should handle null dependencies gracefully
        expect(result, isA<DataDeletionResult>());
      });

      test('should maintain deletion log even on errors', () async {
        await deletionService.initialize();
        
        await deletionService.deleteAllUserData();
        
        // Should have log entries even if some operations fail
        expect(deletionService.deletionLog.isNotEmpty, isTrue);
      });
    });

    group('Progress Updates', () {
      test('should update progress during deletion', () async {
        await deletionService.initialize();
        
        var progressUpdates = <double>[];
        var statusUpdates = <String>[];
        
        deletionService.addListener(() {
          progressUpdates.add(deletionService.deletionProgress);
          statusUpdates.add(deletionService.deletionStatus);
        });
        
        await deletionService.deleteAllUserData();
        
        expect(progressUpdates.isNotEmpty, isTrue);
        expect(statusUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.last, equals(1.0));
      });
    });

    group('Backup Creation', () {
      test('should handle backup creation request', () async {
        await deletionService.initialize();
        
        final result = await deletionService.deleteAllUserData(
          createBackup: true,
          backupPassword: 'test_password',
        );
        
        expect(result, isA<DataDeletionResult>());
        // Should complete even if backup creation fails
      });

      test('should handle backup creation without password', () async {
        await deletionService.initialize();
        
        final result = await deletionService.deleteAllUserData(
          createBackup: true,
        );
        
        expect(result, isA<DataDeletionResult>());
      });
    });

    group('Verification Process', () {
      test('should perform verification after deletion', () async {
        await deletionService.initialize();
        
        final result = await deletionService.deleteAllUserData();
        
        expect(result.verificationPassed, isA<bool>());
        // Verification should complete even with null dependencies
      });
    });

    group('Logging', () {
      test('should maintain detailed deletion log', () async {
        await deletionService.initialize();
        
        await deletionService.deleteAllUserData();
        
        final log = deletionService.deletionLog;
        expect(log.isNotEmpty, isTrue);
        
        // Check that log entries have timestamp format
        expect(log.every((entry) => entry.contains('[')), isTrue);
        
        // Check for key log entries
        expect(log.any((entry) => entry.contains('Starting')), isTrue);
        expect(log.any((entry) => entry.contains('completed')), isTrue);
      });

      test('should log different deletion phases', () async {
        await deletionService.initialize();
        
        await deletionService.deleteAllUserData();
        
        final log = deletionService.deletionLog;
        
        // Should log various deletion phases
        expect(log.any((entry) => entry.contains('journal')), isTrue);
        expect(log.any((entry) => entry.contains('settings')), isTrue);
        expect(log.any((entry) => entry.contains('verification')), isTrue);
      });
    });
  });
}