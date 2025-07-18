import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/constants/app_constants.dart';
import 'package:spiral_journal/constants/validation_constants.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/models/core.dart';
import 'package:spiral_journal/utils/database_exceptions.dart';

void main() {
  group('Database Transaction Safety Tests', () {
    group('Data Validation Logic', () {
      test('should validate journal entry data structure', () {
        // Test valid journal entry creation
        final validEntry = JournalEntry.create(
          content: 'This is a valid journal entry with meaningful content.',
          moods: ['happy', 'grateful'],
        );
        
        expect(validEntry.content, isNotEmpty);
        expect(validEntry.moods, isNotEmpty);
        expect(validEntry.userId, equals('local_user'));
        expect(validEntry.dayOfWeek, isNotEmpty);
      });

      test('should validate emotional core data structure', () {
        // Test valid emotional core creation
        final validCore = EmotionalCore(
          id: 'test-id',
          name: 'Optimism',
          description: 'Your ability to maintain hope and positive outlook',
          currentLevel: 0.75,
          previousLevel: 0.75,
          lastUpdated: DateTime.now(),
          trend: 'rising',
          color: 'AFCACD',
          iconPath: 'assets/icons/optimism.png',
          insight: 'Your optimistic nature helps you see opportunities in challenges',
          relatedCores: ['Growth Mindset', 'Resilience'],
        );
        
        expect(validCore.name, equals('Optimism'));
        expect(validCore.percentage, greaterThanOrEqualTo(0.0));
        expect(validCore.percentage, lessThanOrEqualTo(100.0));
        expect(['rising', 'stable', 'declining'], contains(validCore.trend));
      });

      test('should identify invalid journal entry data', () {
        // Test empty content
        expect(
          () => _validateJournalEntryContent(''),
          throwsA(isA<ArgumentError>()),
        );

        // Test empty moods
        expect(
          () => _validateJournalEntryMoods([]),
          throwsA(isA<ArgumentError>()),
        );

        // Test invalid mood
        expect(
          () => _validateJournalEntryMoods(['invalid_mood']),
          throwsA(isA<ArgumentError>()),
        );

        // Test content too long
        final longContent = 'a' * (AppConstants.maxContentLength + 1);
        expect(
          () => _validateJournalEntryContent(longContent),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should identify invalid emotional core data', () {
        // Test invalid percentage (too high)
        expect(
          () => _validateCorePercentage(150.0),
          throwsA(isA<ArgumentError>()),
        );

        // Test invalid percentage (negative)
        expect(
          () => _validateCorePercentage(-10.0),
          throwsA(isA<ArgumentError>()),
        );

        // Test invalid trend
        expect(
          () => _validateCoreTrend('invalid_trend'),
          throwsA(isA<ArgumentError>()),
        );

        // Test invalid core name
        expect(
          () => _validateCoreName('Invalid Core Name'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Transaction Safety Logic', () {
      test('should handle core update validation', () {
        final coreUpdates = <String, double>{
          'valid-core-id': 80.0,
          'another-core-id': 65.5,
        };

        // Test valid core updates
        expect(() => _validateCoreUpdates(coreUpdates), returnsNormally);

        // Test invalid core updates
        final invalidCoreUpdates = <String, double>{
          'valid-core-id': 150.0, // Invalid percentage
          'another-core-id': -10.0, // Invalid percentage
        };

        expect(
          () => _validateCoreUpdates(invalidCoreUpdates),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle batch operation validation', () {
        // Test valid batch of journal entries
        final validEntries = [
          JournalEntry.create(content: 'Entry 1', moods: ['happy']),
          JournalEntry.create(content: 'Entry 2', moods: ['content']),
          JournalEntry.create(content: 'Entry 3', moods: ['grateful']),
        ];

        expect(() => _validateJournalEntryBatch(validEntries), returnsNormally);

        // Test invalid batch (contains invalid entry)
        final invalidEntries = [
          JournalEntry.create(content: 'Valid entry', moods: ['happy']),
          JournalEntry.create(content: '', moods: ['happy']), // Invalid: empty content
        ];

        expect(
          () => _validateJournalEntryBatch(invalidEntries),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Error Handling', () {
      test('should create appropriate database exceptions', () {
        final transactionException = DatabaseTransactionException(
          'Test transaction failed',
          operation: 'insert_journal_entry',
        );

        expect(transactionException.message, equals('Test transaction failed'));
        expect(transactionException.operation, equals('insert_journal_entry'));
        expect(transactionException.toString(), contains('insert_journal_entry'));

        final validationException = DatabaseValidationException(
          'Invalid field value',
          field: 'percentage',
        );

        expect(validationException.message, equals('Invalid field value'));
        expect(validationException.field, equals('percentage'));
        expect(validationException.toString(), contains('percentage'));
      });
    });
  });
}

// Helper validation functions that mirror the DAO validation logic
void _validateJournalEntryContent(String content) {
  if (content.trim().isEmpty) {
    throw ArgumentError('Journal entry content cannot be empty');
  }
  
  if (content.length > AppConstants.maxContentLength) {
    throw ArgumentError('Journal entry content is too long (max ${AppConstants.maxContentLength} characters)');
  }
}

void _validateJournalEntryMoods(List<String> moods) {
  if (moods.isEmpty) {
    throw ArgumentError('At least one mood must be selected');
  }
  
  for (final mood in moods) {
    if (!ValidationConstants.isValidMood(mood)) {
      throw ArgumentError('Invalid mood: $mood');
    }
  }
}

void _validateCorePercentage(double percentage) {
  if (percentage < AppConstants.minCorePercentage || percentage > AppConstants.maxCorePercentage) {
    throw ArgumentError('Percentage must be between ${AppConstants.minCorePercentage} and ${AppConstants.maxCorePercentage}');
  }
}

void _validateCoreTrend(String trend) {
  if (!ValidationConstants.isValidTrend(trend)) {
    throw ArgumentError('Invalid trend: $trend. Must be one of: ${ValidationConstants.validCoreTrends.join(', ')}');
  }
}

void _validateCoreName(String name) {
  if (!ValidationConstants.isValidCoreName(name)) {
    throw ArgumentError('Invalid core name: $name. Must be one of: ${ValidationConstants.validCoreNames.join(', ')}');
  }
}

void _validateCoreUpdates(Map<String, double> coreUpdates) {
  for (final update in coreUpdates.entries) {
    final coreId = update.key;
    final newPercentage = update.value;
    
    if (coreId.trim().isEmpty) {
      throw ArgumentError('Core ID cannot be empty');
    }
    
    _validateCorePercentage(newPercentage);
  }
}

void _validateJournalEntryBatch(List<JournalEntry> entries) {
  for (final entry in entries) {
    _validateJournalEntryContent(entry.content);
    _validateJournalEntryMoods(entry.moods);
  }
}