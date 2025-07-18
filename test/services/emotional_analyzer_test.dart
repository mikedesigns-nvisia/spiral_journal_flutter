import 'package:flutter_test/flutter_test.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/services/emotional_analyzer.dart';

void main() {
  group('EmotionalAnalyzer', () {
    late EmotionalAnalyzer analyzer;
    late JournalEntry testEntry;

    setUp(() {
      analyzer = EmotionalAnalyzer();
      testEntry = JournalEntry(
        id: 'test-1',
        userId: 'test-user',
        date: DateTime.now(),
        content: 'Today was a great day! I felt really happy and grateful for all the good things in my life.',
        moods: ['happy', 'grateful'],
        dayOfWeek: 'Monday',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('should process AI analysis response correctly', () {
      final aiResponse = {
        'primary_emotions': ['happy', 'grateful'],
        'emotional_intensity': 7.5,
        'growth_indicators': ['gratitude_practice', 'positive_outlook'],
        'core_adjustments': {
          'Optimism': 0.3,
          'Self-Awareness': 0.1,
        },
        'entry_insight': 'Your gratitude practice is strengthening your optimism.',
      };

      final result = analyzer.processAnalysis(aiResponse, testEntry);

      expect(result.primaryEmotions, contains('happy'));
      expect(result.primaryEmotions, contains('grateful'));
      expect(result.emotionalIntensity, equals(7.5));
      expect(result.coreImpacts['Optimism'], equals(0.3));
      expect(result.personalizedInsight, contains('gratitude'));
      expect(result.validationScore, greaterThan(0.0));
    });

    test('should validate analysis results correctly', () {
      final validResult = EmotionalAnalysisResult(
        primaryEmotions: ['happy'],
        emotionalIntensity: 6.0,
        keyThemes: ['gratitude'],
        overallSentiment: 0.5,
        personalizedInsight: 'Great insight',
        coreImpacts: {'Optimism': 0.2},
        emotionalPatterns: [],
        growthIndicators: ['growth'],
        validationScore: 0.8,
      );

      expect(analyzer.validateAnalysisResult(validResult), isTrue);

      final invalidResult = EmotionalAnalysisResult(
        primaryEmotions: [], // Empty emotions - invalid
        emotionalIntensity: 15.0, // Out of range - invalid
        keyThemes: [],
        overallSentiment: 2.0, // Out of range - invalid
        personalizedInsight: '',
        coreImpacts: {},
        emotionalPatterns: [],
        growthIndicators: [],
        validationScore: 0.5,
      );

      expect(analyzer.validateAnalysisResult(invalidResult), isFalse);
    });

    test('should sanitize analysis results', () {
      final unsafeResult = EmotionalAnalysisResult(
        primaryEmotions: ['<script>alert("hack")</script>', 'happy', 'sad', 'angry', 'excited', 'peaceful', 'extra'], // Too many + unsafe
        emotionalIntensity: 15.0, // Out of range
        keyThemes: ['theme1', 'theme2', 'theme3', 'theme4', 'theme5', 'theme6'], // Too many
        overallSentiment: 2.0, // Out of range
        personalizedInsight: '<b>Unsafe HTML</b> content that is way too long and should be truncated because it exceeds the maximum length limit that we have set for safety and performance reasons in our application to prevent potential issues with display and storage of overly verbose insights that could impact user experience negatively.',
        coreImpacts: {'Test': 5.0}, // Out of range
        emotionalPatterns: [],
        growthIndicators: [],
        validationScore: 2.0, // Out of range
      );

      final sanitized = analyzer.sanitizeAnalysisResult(unsafeResult);

      expect(sanitized.primaryEmotions.length, lessThanOrEqualTo(5));
      expect(sanitized.primaryEmotions, isNot(contains('<script>alert("hack")</script>')));
      expect(sanitized.emotionalIntensity, equals(10.0)); // Clamped to max
      expect(sanitized.keyThemes.length, lessThanOrEqualTo(5));
      expect(sanitized.overallSentiment, equals(1.0)); // Clamped to max
      expect(sanitized.personalizedInsight.length, lessThanOrEqualTo(500));
      expect(sanitized.personalizedInsight, isNot(contains('<b>')));
      expect(sanitized.coreImpacts['Test'], equals(1.0)); // Clamped to max
      expect(sanitized.validationScore, equals(1.0)); // Clamped to max
    });

    test('should identify patterns from multiple entries', () {
      final entries = [
        JournalEntry(
          id: 'test-1',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: 2)),
          content: 'Happy day with friends',
          moods: ['happy', 'social'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          updatedAt: DateTime.now().subtract(Duration(days: 2)),
        ),
        JournalEntry(
          id: 'test-2',
          userId: 'test-user',
          date: DateTime.now().subtract(Duration(days: 1)),
          content: 'Another happy day',
          moods: ['happy', 'content'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          updatedAt: DateTime.now().subtract(Duration(days: 1)),
        ),
        JournalEntry(
          id: 'test-3',
          userId: 'test-user',
          date: DateTime.now(),
          content: 'Feeling happy again',
          moods: ['happy', 'grateful'],
          dayOfWeek: 'Monday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final patterns = analyzer.identifyPatterns(entries);

      expect(patterns, isNotEmpty);
      expect(patterns.any((p) => p.category == 'Mood Patterns'), isTrue);
      expect(patterns.any((p) => p.category == 'Temporal Patterns'), isTrue);
    });

    test('should handle empty or invalid input gracefully', () {
      final emptyResponse = <String, dynamic>{};
      final result = analyzer.processAnalysis(emptyResponse, testEntry);

      expect(result.primaryEmotions, isNotEmpty);
      expect(result.emotionalIntensity, greaterThanOrEqualTo(0.0));
      expect(result.personalizedInsight, isNotEmpty);
      expect(result.validationScore, greaterThanOrEqualTo(0.0));
    });
  });
}