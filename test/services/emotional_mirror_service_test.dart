import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spiral_journal/services/emotional_mirror_service.dart';
import 'package:spiral_journal/models/journal_entry.dart';
import 'package:spiral_journal/repositories/journal_repository_impl.dart';
import 'package:spiral_journal/database/database_helper.dart';

void main() {
  group('EmotionalMirrorService Tests', () {
    late EmotionalMirrorService mirrorService;
    late JournalRepositoryImpl repository;

    setUpAll(() async {
      // Initialize database factory for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Initialize database for testing
      await DatabaseHelper().database;
      mirrorService = EmotionalMirrorService();
      repository = JournalRepositoryImpl();
    });

    setUp(() async {
      // Clear any existing data
      await repository.clearAllEntries();
    });

    test('should handle empty data gracefully', () async {
      final mirrorData = await mirrorService.getEmotionalMirrorData();
      
      expect(mirrorData.totalEntries, equals(0));
      expect(mirrorData.analyzedEntries, equals(0));
      expect(mirrorData.moodOverview.dominantMoods, contains('neutral'));
      expect(mirrorData.insights.isNotEmpty, isTrue);
    });

    test('should process journal entries with AI analysis', () async {
      // Create sample entries with AI analysis
      final entries = await _createSampleEntriesWithAnalysis(repository);
      
      final mirrorData = await mirrorService.getEmotionalMirrorData();
      
      expect(mirrorData.totalEntries, equals(entries.length));
      expect(mirrorData.analyzedEntries, greaterThan(0));
      expect(mirrorData.moodOverview.dominantMoods.isNotEmpty, isTrue);
      expect(mirrorData.selfAwarenessScore, greaterThan(0.0));
    });

    test('should generate mood distribution data', () async {
      await _createSampleEntriesWithAnalysis(repository);
      
      final distribution = await mirrorService.getMoodDistribution();
      
      expect(distribution.totalEntries, greaterThan(0));
      expect(distribution.aiDetectedMoods.isNotEmpty, isTrue);
    });

    test('should generate emotional trends', () async {
      await _createSampleEntriesWithAnalysis(repository);
      
      final intensityTrend = await mirrorService.getEmotionalIntensityTrend();
      final sentimentTrend = await mirrorService.getSentimentTrend();
      
      expect(intensityTrend.isNotEmpty, isTrue);
      expect(sentimentTrend.isNotEmpty, isTrue);
    });

    test('should generate emotional journey data', () async {
      await _createSampleEntriesWithAnalysis(repository);
      
      final journeyData = await mirrorService.getEmotionalJourney();
      
      expect(journeyData.totalEntries, greaterThan(0));
      expect(journeyData.milestones.isNotEmpty, isTrue);
    });
  });
}

Future<List<JournalEntry>> _createSampleEntriesWithAnalysis(JournalRepositoryImpl repository) async {
  final entries = <JournalEntry>[];
  final now = DateTime.now();

  // Create entries over the past 30 days with varied emotional content
  for (int i = 0; i < 15; i++) {
    final date = now.subtract(Duration(days: i * 2));
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // Vary the emotional content and analysis
    final (content, moods, analysis) = _getSampleEntryData(i);
    
    final entry = JournalEntry(
      id: 'test_entry_$i',
      userId: 'test_user',
      date: date,
      content: content,
      moods: moods,
      dayOfWeek: dayNames[date.weekday - 1],
      createdAt: date,
      updatedAt: date,
      isSynced: true,
      metadata: {},
      aiAnalysis: analysis,
      isAnalyzed: true,
      aiDetectedMoods: analysis.primaryEmotions,
      emotionalIntensity: analysis.emotionalIntensity,
      keyThemes: analysis.keyThemes,
      personalizedInsight: analysis.personalizedInsight,
    );
    
    await repository.createEntry(entry);
    entries.add(entry);
  }
  
  return entries;
}

(String, List<String>, EmotionalAnalysis) _getSampleEntryData(int index) {
  final samples = [
    (
      "Had an amazing day today! Spent time with friends and felt really grateful for the connections in my life. The weather was perfect and everything just felt right.",
      ['happy', 'grateful'],
      EmotionalAnalysis(
        primaryEmotions: ['happy', 'grateful', 'content'],
        emotionalIntensity: 0.8,
        keyThemes: ['gratitude', 'social_connection', 'positive_mood'],
        personalizedInsight: "Your gratitude practice is strengthening your social connections and overall well-being.",
        coreImpacts: {'Optimism': 0.3, 'Social Connection': 0.4, 'Self-Awareness': 0.2},
        analyzedAt: DateTime.now(),
      ),
    ),
    (
      "Feeling a bit stressed with work lately. There's so much to do and not enough time. Need to find better ways to manage my stress and prioritize tasks.",
      ['stressed', 'tired'],
      EmotionalAnalysis(
        primaryEmotions: ['stressed', 'tired', 'sad'],
        emotionalIntensity: 0.7,
        keyThemes: ['work_pressure', 'time_management', 'stress_management'],
        personalizedInsight: "Recognizing stress is the first step. Consider breaking tasks into smaller, manageable pieces.",
        coreImpacts: {'Resilience': 0.2, 'Self-Awareness': 0.3, 'Growth Mindset': 0.1},
        analyzedAt: DateTime.now(),
      ),
    ),
    (
      "Took some time for self-reflection today. Reading and journaling help me understand my thoughts better. I'm learning to be more patient with myself.",
      ['reflective', 'peaceful'],
      EmotionalAnalysis(
        primaryEmotions: ['reflective', 'peaceful', 'thoughtful'],
        emotionalIntensity: 0.5,
        keyThemes: ['self_reflection', 'personal_growth', 'mindfulness'],
        personalizedInsight: "Your commitment to self-reflection is building emotional intelligence and self-compassion.",
        coreImpacts: {'Self-Awareness': 0.4, 'Growth Mindset': 0.3, 'Resilience': 0.2},
        analyzedAt: DateTime.now(),
      ),
    ),
    (
      "Excited about the new project I'm starting! It's challenging but I feel confident I can learn and grow from it. Looking forward to the creative process.",
      ['excited', 'confident'],
      EmotionalAnalysis(
        primaryEmotions: ['excited', 'confident', 'optimistic'],
        emotionalIntensity: 0.9,
        keyThemes: ['new_opportunities', 'creativity', 'confidence'],
        personalizedInsight: "Your enthusiasm for challenges shows strong growth mindset and creative confidence.",
        coreImpacts: {'Creativity': 0.4, 'Growth Mindset': 0.3, 'Optimism': 0.3},
        analyzedAt: DateTime.now(),
      ),
    ),
    (
      "Had a difficult conversation today but I'm glad I spoke up. It wasn't easy but I feel like I handled it well and stayed true to my values.",
      ['proud', 'relieved'],
      EmotionalAnalysis(
        primaryEmotions: ['proud', 'relieved', 'confident'],
        emotionalIntensity: 0.6,
        keyThemes: ['authentic_communication', 'personal_values', 'courage'],
        personalizedInsight: "Standing up for your values builds self-respect and authentic relationships.",
        coreImpacts: {'Self-Awareness': 0.3, 'Social Connection': 0.2, 'Resilience': 0.3},
        analyzedAt: DateTime.now(),
      ),
    ),
  ];
  
  // Cycle through samples and add some variation
  final baseIndex = index % samples.length;
  final (content, moods, analysis) = samples[baseIndex];
  
  // Add some variation to intensity based on index
  final intensityVariation = (index % 3) * 0.1 - 0.1; // -0.1, 0, or 0.1
  final adjustedIntensity = (analysis.emotionalIntensity + intensityVariation).clamp(0.0, 1.0);
  
  final adjustedAnalysis = EmotionalAnalysis(
    primaryEmotions: analysis.primaryEmotions,
    emotionalIntensity: adjustedIntensity,
    keyThemes: analysis.keyThemes,
    personalizedInsight: analysis.personalizedInsight,
    coreImpacts: analysis.coreImpacts,
    analyzedAt: DateTime.now().subtract(Duration(days: index * 2)),
  );
  
  return (content, moods, adjustedAnalysis);
}