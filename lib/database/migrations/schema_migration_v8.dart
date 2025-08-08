import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Database migration from v7 to v8: Add emotion_matrix column for comprehensive emotional data
/// 
/// This migration adds the 'emotion_matrix' column to the journal_entries table
/// to enable storing complete emotional state data with percentages for all emotions.
/// This replaces the simple 'moods' list approach with a more nuanced matrix system.
class SchemaMigrationV8 {
  static Future<void> migrate(Database db) async {
    debugPrint('🔄 Running database migration v7 -> v8: Adding emotion_matrix column for comprehensive emotional data');
    
    await db.transaction((txn) async {
      try {
        // Add emotion_matrix column to journal_entries table
        await txn.execute('''
          ALTER TABLE journal_entries 
          ADD COLUMN emotion_matrix TEXT DEFAULT '{}'
        ''');
        
        // Migrate existing moods data to emotion_matrix format
        final entries = await txn.query('journal_entries');
        
        for (final entry in entries) {
          final id = entry['id'] as String;
          final moodsText = entry['moods'] as String? ?? '[]';
          
          try {
            // Parse existing moods
            final moodsData = jsonDecode(moodsText);
            List<String> moods = [];
            
            if (moodsData is List) {
              moods = moodsData.cast<String>();
            } else if (moodsData is String && moodsData.isNotEmpty) {
              moods = [moodsData];
            }
            
            // Convert moods to emotion matrix
            final emotionMatrix = _convertMoodsToEmotionMatrix(moods);
            
            // Update entry with new emotion matrix
            await txn.update(
              'journal_entries',
              {'emotion_matrix': jsonEncode(emotionMatrix)},
              where: 'id = ?',
              whereArgs: [id],
            );
            
          } catch (e) {
            debugPrint('⚠️  Warning: Could not migrate moods for entry $id: $e');
            // Set empty emotion matrix as fallback
            await txn.update(
              'journal_entries',
              {'emotion_matrix': '{}'},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
        
        debugPrint('✅ Successfully added emotion_matrix column and migrated ${entries.length} entries');
        
      } catch (e) {
        debugPrint('❌ Migration v7 -> v8 failed: $e');
        rethrow;
      }
    });
  }
  
  /// Convert old moods list to emotion matrix format
  static Map<String, double> _convertMoodsToEmotionMatrix(List<String> moods) {
    // All supported emotions
    const supportedEmotions = [
      'happy', 'sad', 'angry', 'anxious', 'excited', 'calm',
      'frustrated', 'content', 'worried', 'joyful', 'peaceful',
      'stressed', 'optimistic', 'melancholy', 'energetic', 'tired',
      'confident', 'uncertain', 'grateful', 'lonely',
    ];
    
    final emotionMatrix = <String, double>{};
    
    // Initialize all emotions to 0
    for (final emotion in supportedEmotions) {
      emotionMatrix[emotion] = 0.0;
    }
    
    // If no moods, return empty matrix
    if (moods.isEmpty) {
      return emotionMatrix;
    }
    
    // Distribute percentages evenly among the provided moods
    final percentagePerMood = 100.0 / moods.length;
    
    for (final mood in moods) {
      final normalizedMood = mood.toLowerCase().trim();
      if (supportedEmotions.contains(normalizedMood)) {
        emotionMatrix[normalizedMood] = percentagePerMood;
      } else {
        // Try to map common mood variations to supported emotions
        final mappedEmotion = _mapMoodToEmotion(normalizedMood);
        if (mappedEmotion != null && supportedEmotions.contains(mappedEmotion)) {
          emotionMatrix[mappedEmotion] = (emotionMatrix[mappedEmotion] ?? 0.0) + percentagePerMood;
        }
      }
    }
    
    return emotionMatrix;
  }
  
  /// Map common mood variations to supported emotions
  static String? _mapMoodToEmotion(String mood) {
    final moodMappings = {
      // Happy variations
      'happiness': 'happy',
      'joy': 'joyful',
      'elated': 'joyful',
      'cheerful': 'happy',
      'upbeat': 'happy',
      
      // Sad variations
      'sadness': 'sad',
      'depressed': 'sad',
      'down': 'sad',
      'blue': 'sad',
      'melancholic': 'melancholy',
      
      // Angry variations
      'anger': 'angry',
      'mad': 'angry',
      'irritated': 'frustrated',
      'annoyed': 'frustrated',
      'rage': 'angry',
      
      // Anxious variations
      'anxiety': 'anxious',
      'nervous': 'anxious',
      'worried': 'worried',
      'concern': 'worried',
      'fear': 'anxious',
      'scared': 'anxious',
      
      // Excited variations
      'excitement': 'excited',
      'thrilled': 'excited',
      'enthusiastic': 'excited',
      
      // Calm variations
      'relaxed': 'calm',
      'serene': 'peaceful',
      'tranquil': 'peaceful',
      
      // Energy variations
      'energy': 'energetic',
      'hyper': 'energetic',
      'lethargic': 'tired',
      'exhausted': 'tired',
      'fatigue': 'tired',
      
      // Confidence variations
      'confidence': 'confident',
      'sure': 'confident',
      'doubt': 'uncertain',
      'insecure': 'uncertain',
      
      // Gratitude variations
      'gratitude': 'grateful',
      'thankful': 'grateful',
      'appreciative': 'grateful',
      
      // Stress variations
      'stress': 'stressed',
      'overwhelmed': 'stressed',
      'pressure': 'stressed',
      
      // Content variations
      'satisfied': 'content',
      'fulfilled': 'content',
      'pleased': 'content',
      
      // Optimism variations
      'hopeful': 'optimistic',
      'positive': 'optimistic',
      
      // Loneliness variations
      'alone': 'lonely',
      'isolated': 'lonely',
    };
    
    return moodMappings[mood];
  }
}