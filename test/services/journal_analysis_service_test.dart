import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/journal_analysis_service.dart';

void main() {
  group('JournalAnalysisService', () {
    late JournalAnalysisService service;

    setUp(() {
      service = JournalAnalysisService();
    });

    test('should provide initial cores for new users', () {
      final initialCores = service.getInitialCores();

      expect(initialCores.length, equals(6));
      expect(initialCores.every((core) => core.percentage > 0), isTrue);
      expect(initialCores.every((core) => core.percentage <= 100), isTrue);
      expect(initialCores.every((core) => core.insight.isNotEmpty), isTrue);
    });

    test('should analyze journal patterns with empty entries gracefully', () async {
      final initialCores = service.getInitialCores();
      final result = await service.analyzeJournalPatterns([], initialCores);

      expect(result.patterns, isEmpty);
      expect(result.trends, isEmpty);
      expect(result.coreSynergies, isEmpty);
      expect(result.combinations, isEmpty);
      expect(result.overallInsight, isNotEmpty);
    });

    test('should analyze journal patterns with multiple entries', () async {
      final entries = [
        JournalEntry(
          id: 'test-1',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: 2)),
          content: 'Grateful for a wonderful day with friends.',
          moods: ['grateful', 'happy'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          updatedAt: DateTime.now().subtract(Duration(days: 2)),
        ),
        JournalEntry(
          id: 'test-2',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Feeling grateful and excited about new opportunities.',
          moods: ['grateful', 'excited'],
          dayOfWeek: 'Wednesday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final initialCores = service.getInitialCores();
      final result = await service.analyzeJournalPatterns(entries, initialCores);

      expect(result.patterns, isNotEmpty);
      expect(result.trends, isNotEmpty);
      expect(result.coreSynergies, isNotEmpty);
      expect(result.overallInsight, isNotEmpty);
    });

    test('should handle cache operations correctly', () {
      // Test cache clearing
      service.clearCache();
      
      // This should not throw any errors
      expect(() => service.clearCache(), returnsNormally);
    });
  });
}