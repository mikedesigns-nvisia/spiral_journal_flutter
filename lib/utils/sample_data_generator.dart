import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../repositories/journal_repository_impl.dart';

/// Utility class for generating sample journal data for testing and demonstration
class SampleDataGenerator {
  static final JournalRepositoryImpl _repository = JournalRepositoryImpl();

  /// Generate sample journal entries for testing and demonstration
  /// This version works offline without requiring AI services
  /// DISABLED for TestFlight production builds
  static Future<void> generateSampleData() async {
    // Disable sample data generation for production/TestFlight builds
    if (kReleaseMode) {
      debugPrint('🚫 Sample data generation disabled in production builds');
      return;
    }
    
    try {
      debugPrint('🔄 Starting sample data generation (debug mode only)...');
      
      // Clear existing data first
      await _repository.clearAllEntries();
      debugPrint('✅ Cleared existing entries');
      
      final now = DateTime.now();
      final entries = <JournalEntry>[];

      // Create varied journal entries over the past 30 days
      final sampleEntries = [
        _createSampleEntry(
          now.subtract(const Duration(days: 1)),
          "Had an amazing day today! Spent time with friends and felt really grateful for the connections in my life. The weather was perfect and everything just felt right.",
          ['happy', 'grateful'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 3)),
          "Feeling a bit stressed with work lately. There's so much to do and not enough time. Need to find better ways to manage my workload.",
          ['stressed', 'anxious'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 5)),
          "Took some time for self-reflection today. Reading and journaling help me understand my thoughts better. I'm learning to be more patient with myself.",
          ['reflective', 'peaceful'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 7)),
          "Excited about the new project I'm starting! It's challenging but I feel confident I can learn and grow from it. Looking forward to the creative process.",
          ['excited', 'confident'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 10)),
          "Had a difficult conversation today but I'm glad I spoke up. It wasn't easy but I feel like I handled it well and stayed true to my values.",
          ['proud', 'relieved'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 12)),
          "Feeling really creative today. Worked on some art and music. There's something magical about expressing yourself through different mediums.",
          ['creative', 'inspired'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 15)),
          "Spent quality time with family this weekend. It reminded me how important these relationships are and how much joy they bring to my life.",
          ['joyful', 'content'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 18)),
          "Feeling a bit lonely lately. Sometimes it's hard to connect with others, but I know this feeling will pass. Working on being more social.",
          ['lonely', 'hopeful'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 20)),
          "Accomplished something I've been working on for weeks! The persistence really paid off. Feeling proud of the progress I've made.",
          ['accomplished', 'proud'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 22)),
          "Nature walk today was exactly what I needed. The fresh air and quiet time helped clear my mind and reset my perspective.",
          ['peaceful', 'refreshed'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 25)),
          "Learning something new is both exciting and challenging. Making mistakes is part of the process, and I'm trying to embrace that.",
          ['curious', 'determined'],
        ),
        _createSampleEntry(
          now.subtract(const Duration(days: 28)),
          "Grateful for the small moments today - morning coffee, a good book, and some quiet time to think. Sometimes simplicity is perfect.",
          ['grateful', 'content'],
        ),
      ];

      // Create and save entries
      for (int i = 0; i < sampleEntries.length; i++) {
        final entryData = sampleEntries[i];
        
        try {
          await _repository.createEntry(entryData);
          entries.add(entryData);
          debugPrint('✅ Created entry ${i + 1}/${sampleEntries.length}');
        } catch (e) {
          debugPrint('❌ Failed to create entry ${i + 1}: $e');
          // Continue with next entry
        }
      }

      debugPrint('✅ Generated ${entries.length} sample journal entries');
      debugPrint('📊 All entries are ready for use');
      
    } catch (e) {
      debugPrint('Error generating sample data: $e');
      rethrow;
    }
  }

  static JournalEntry _createSampleEntry(DateTime date, String content, List<String> moods) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return JournalEntry.create(
      content: content,
      moods: moods,
      id: 'sample_${date.millisecondsSinceEpoch}',
      userId: 'sample_user',
    ).copyWith(
      date: date,
      dayOfWeek: dayNames[date.weekday - 1],
      createdAt: date,
      updatedAt: date,
    );
  }
}

// Extension to convert EmotionalAnalysisResult to EmotionalAnalysis
extension EmotionalAnalysisResultExtension on dynamic {
  EmotionalAnalysis toEmotionalAnalysis() {
    // Access properties from the dynamic object
    final emotions = (this as dynamic).primaryEmotions as List<String>? ?? [];
    final intensity = (this as dynamic).emotionalIntensity as double? ?? 5.0;
    final themes = (this as dynamic).keyThemes as List<String>? ?? [];
    final insight = (this as dynamic).personalizedInsight as String?;
    final impacts = (this as dynamic).coreImpacts as Map<String, double>? ?? {};
    
    return EmotionalAnalysis(
      primaryEmotions: emotions,
      emotionalIntensity: intensity / 10.0, // Convert to 0-1 scale
      keyThemes: themes,
      personalizedInsight: insight,
      coreImpacts: impacts,
      analyzedAt: DateTime.now(),
    );
  }
}
