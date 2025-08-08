import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/services/providers/claude_ai_provider.dart';
import 'package:spiral_journal/services/ai_service_interface.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import '../utils/test_setup_helper.dart';

void main() {
  group('Claude AI Integration - Modern API (3.7 Sonnet)', () {
    late ClaudeAIProvider provider;

    setUpAll(() {
      TestSetupHelper.ensureFlutterBinding();
      TestSetupHelper.setupTestConfiguration(enablePlatformChannels: true);
    });

    tearDownAll(() {
      TestSetupHelper.teardownTestConfiguration();
    });

    setUp(() {
      final config = AIServiceConfig(
        provider: AIProvider.enabled,
        apiKey: 'test-key', // Mock API key for testing
      );
      provider = ClaudeAIProvider(config);
    });

    test('should handle journal entry analysis with fallback', () async {
      final now = DateTime.now();
      final entry = JournalEntry(
        id: 'test-1',
        userId: 'test-user',
        date: now,
        content: 'Today was a great day! I felt really grateful for my friends and family. I learned something new at work and overcame a challenging problem.',
        moods: ['happy', 'grateful', 'confident'],
        dayOfWeek: 'Monday',
        createdAt: now,
        updatedAt: now,
      );

      // This will use fallback analysis since we don't have a real API key
      final analysis = await provider.analyzeJournalEntry(entry);

      expect(analysis, isA<Map<String, dynamic>>());
      expect(analysis['primary_emotions'], isA<List>());
      expect(analysis['emotional_intensity'], isA<num>());
      expect(analysis['core_adjustments'], isA<Map>());
      expect(analysis['entry_insight'], isA<String>());
      
      // Verify core adjustments are reasonable
      final coreAdjustments = analysis['core_adjustments'] as Map<String, dynamic>;
      expect(coreAdjustments['Optimism'], greaterThan(0)); // Should increase due to 'grateful' mood
      expect(coreAdjustments['Self-Awareness'], greaterThan(0)); // Should increase due to reflection
    });

    test('should generate monthly insights with fallback', () async {
      final now = DateTime.now();
      final entries = [
        JournalEntry(
          id: 'test-1',
          userId: 'test-user',
          date: now.subtract(const Duration(days: 5)),
          content: 'Great day with friends',
          moods: ['happy', 'social'],
          dayOfWeek: 'Monday',
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        JournalEntry(
          id: 'test-2',
          userId: 'test-user',
          date: now.subtract(const Duration(days: 2)),
          content: 'Learned something new today and felt accomplished',
          moods: ['motivated', 'confident'],
          dayOfWeek: 'Thursday',
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        JournalEntry(
          id: 'test-3',
          userId: 'test-user',
          date: now,
          content: 'Reflecting on my growth this month',
          moods: ['reflective', 'grateful'],
          dayOfWeek: 'Sunday',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final insight = await provider.generateMonthlyInsight(entries);

      expect(insight, isA<String>());
      expect(insight.length, greaterThan(10)); // Should be a meaningful insight
      expect(insight.toLowerCase(), contains('reflect')); // Should mention reflection
    });

    test('should handle empty entries gracefully', () async {
      final insight = await provider.generateMonthlyInsight([]);
      
      expect(insight, isA<String>());
      expect(insight.toLowerCase(), contains('no entries'));
    });

    test('should validate API key format', () async {
      expect(() async => await provider.setApiKey('invalid-key'), throwsException);
      expect(() async => await provider.setApiKey(''), throwsException);
      expect(() async => await provider.setApiKey('sk-ant-old-format'), throwsException);
      
      // Valid format should not throw
      await provider.setApiKey('sk-ant-api03-test-key-12345678901234567890123456789012345678901234567890');
      expect(provider.isConfigured, true);
    });
  });
}
