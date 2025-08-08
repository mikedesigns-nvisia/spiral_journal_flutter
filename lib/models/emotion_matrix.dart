import 'dart:math';
import 'package:flutter/material.dart';
import 'emotional_state.dart';

/// EmotionMatrix represents a comprehensive emotional state with percentages for all emotions.
/// 
/// This model provides a full spectrum view of emotional states, where each emotion
/// has an intensity percentage (0.0 to 100.0). This allows for more nuanced emotional
/// analysis compared to the traditional primary/secondary emotion approach.
/// 
/// Features:
/// - All supported emotions with intensity percentages
/// - Automatic normalization to ensure percentages add up to 100%
/// - Dominant emotion detection
/// - Emotion filtering and sorting utilities
/// - Accessibility-compliant color and display management
/// - JSON serialization for storage and API communication
class EmotionMatrix {
  final Map<String, double> _emotions;
  final DateTime timestamp;
  final double confidence;
  
  /// All supported emotions in the system
  static const List<String> supportedEmotions = [
    'happy',
    'sad', 
    'angry',
    'anxious',
    'excited',
    'calm',
    'frustrated',
    'content',
    'worried',
    'joyful',
    'peaceful',
    'stressed',
    'optimistic',
    'melancholy',
    'energetic',
    'tired',
    'confident',
    'uncertain',
    'grateful',
    'lonely',
  ];

  EmotionMatrix({
    required Map<String, double> emotions,
    DateTime? timestamp,
    this.confidence = 1.0,
    bool normalize = true,
  }) : timestamp = timestamp ?? DateTime.now(),
       _emotions = normalize ? _normalizeEmotions(emotions) : Map.from(emotions);

  /// Create EmotionMatrix from individual emotion percentages
  factory EmotionMatrix.fromPercentages({
    required Map<String, double> percentages,
    DateTime? timestamp,
    double confidence = 1.0,
    bool normalize = true,
  }) {
    // Ensure all supported emotions are included with default 0.0 if not specified
    final allEmotions = <String, double>{};
    for (final emotion in supportedEmotions) {
      allEmotions[emotion] = percentages[emotion] ?? 0.0;
    }
    
    return EmotionMatrix(
      emotions: allEmotions,
      timestamp: timestamp,
      confidence: confidence,
      normalize: normalize,
    );
  }

  /// Create EmotionMatrix from a list of primary emotions (backward compatibility)
  factory EmotionMatrix.fromPrimaryEmotions({
    required List<String> primaryEmotions,
    DateTime? timestamp,
    double confidence = 1.0,
  }) {
    final emotions = <String, double>{};
    
    // Initialize all emotions to 0
    for (final emotion in supportedEmotions) {
      emotions[emotion] = 0.0;
    }
    
    // Distribute percentages based on primary emotions
    if (primaryEmotions.isNotEmpty) {
      final percentagePerEmotion = 100.0 / primaryEmotions.length;
      for (final emotion in primaryEmotions) {
        if (supportedEmotions.contains(emotion.toLowerCase())) {
          emotions[emotion.toLowerCase()] = percentagePerEmotion;
        }
      }
    }
    
    return EmotionMatrix(
      emotions: emotions,
      timestamp: timestamp,
      confidence: confidence,
      normalize: false, // Already distributed correctly
    );
  }

  /// Create empty EmotionMatrix with all emotions at 0%
  factory EmotionMatrix.empty({DateTime? timestamp, double confidence = 0.0}) {
    final emotions = <String, double>{};
    for (final emotion in supportedEmotions) {
      emotions[emotion] = 0.0;
    }
    
    return EmotionMatrix(
      emotions: emotions,
      timestamp: timestamp,
      confidence: confidence,
      normalize: false,
    );
  }

  /// Get percentage for a specific emotion
  double getEmotionPercentage(String emotion) {
    return _emotions[emotion.toLowerCase()] ?? 0.0;
  }

  /// Get all emotions with their percentages
  Map<String, double> get emotions => Map.unmodifiable(_emotions);

  /// Get dominant emotion (highest percentage)
  String? get dominantEmotion {
    if (_emotions.isEmpty) return null;
    
    double maxPercentage = 0.0;
    String? dominant;
    
    for (final entry in _emotions.entries) {
      if (entry.value > maxPercentage) {
        maxPercentage = entry.value;
        dominant = entry.key;
      }
    }
    
    return maxPercentage > 0.0 ? dominant : null;
  }

  /// Get secondary emotion (second highest percentage)
  String? get secondaryEmotion {
    if (_emotions.isEmpty) return null;
    
    final sortedEmotions = getSortedEmotions();
    return sortedEmotions.length > 1 ? sortedEmotions[1].key : null;
  }

  /// Get emotions sorted by percentage (descending)
  List<MapEntry<String, double>> getSortedEmotions() {
    final entries = _emotions.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Get emotions above a certain threshold percentage
  List<MapEntry<String, double>> getEmotionsAboveThreshold(double threshold) {
    return _emotions.entries
        .where((entry) => entry.value >= threshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Get top N emotions by percentage
  List<MapEntry<String, double>> getTopEmotions(int count) {
    final sorted = getSortedEmotions();
    return sorted.take(count).toList();
  }

  /// Check if matrix contains any positive emotions above threshold
  bool hasPositiveEmotionsAbove(double threshold) {
    for (final emotion in supportedEmotions) {
      if (EmotionalState.isPositiveEmotion(emotion) &&
          getEmotionPercentage(emotion) >= threshold) {
        return true;
      }
    }
    return false;
  }

  /// Check if matrix contains any negative emotions above threshold
  bool hasNegativeEmotionsAbove(double threshold) {
    for (final emotion in supportedEmotions) {
      if (!EmotionalState.isPositiveEmotion(emotion) && 
          getEmotionPercentage(emotion) >= threshold) {
        return true;
      }
    }
    return false;
  }

  /// Get overall emotional valence (-1.0 to 1.0, negative to positive)
  double get emotionalValence {
    double positiveSum = 0.0;
    double negativeSum = 0.0;
    
    for (final entry in _emotions.entries) {
      if (EmotionalState.isPositiveEmotion(entry.key)) {
        positiveSum += entry.value;
      } else {
        negativeSum += entry.value;
      }
    }
    
    final totalSum = positiveSum + negativeSum;
    if (totalSum == 0.0) return 0.0;
    
    return (positiveSum - negativeSum) / totalSum;
  }

  /// Get emotional intensity (0.0 to 1.0)
  double get emotionalIntensity {
    // Calculate intensity based on how concentrated the emotions are
    final dominantPercentage = dominantEmotion != null 
        ? getEmotionPercentage(dominantEmotion!) 
        : 0.0;
    
    return min(dominantPercentage / 100.0, 1.0);
  }

  /// Convert to EmotionalState for backward compatibility
  EmotionalState toEmotionalState(BuildContext context) {
    final dominant = dominantEmotion ?? 'neutral';
    final intensity = emotionalIntensity;
    
    return EmotionalState.create(
      emotion: dominant,
      intensity: intensity,
      confidence: confidence,
      context: context,
      relatedEmotions: getTopEmotions(3).map((e) => e.key).toList(),
    );
  }

  /// Get primary emotions (top 3) for backward compatibility
  List<String> get primaryEmotions {
    return getTopEmotions(3)
        .where((entry) => entry.value > 5.0) // Only include emotions above 5%
        .map((entry) => entry.key)
        .toList();
  }

  /// Create copy with updated emotions
  EmotionMatrix copyWith({
    Map<String, double>? emotions,
    DateTime? timestamp,
    double? confidence,
    bool normalize = true,
  }) {
    return EmotionMatrix(
      emotions: emotions ?? this._emotions,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      normalize: normalize,
    );
  }

  /// Update specific emotion percentage
  EmotionMatrix updateEmotion(String emotion, double percentage, {bool normalize = true}) {
    final updatedEmotions = Map<String, double>.from(_emotions);
    updatedEmotions[emotion.toLowerCase()] = max(0.0, min(100.0, percentage));
    
    return EmotionMatrix(
      emotions: updatedEmotions,
      timestamp: timestamp,
      confidence: confidence,
      normalize: normalize,
    );
  }

  /// Blend with another EmotionMatrix
  EmotionMatrix blendWith(EmotionMatrix other, double weight) {
    final blendedEmotions = <String, double>{};
    
    for (final emotion in supportedEmotions) {
      final thisValue = getEmotionPercentage(emotion);
      final otherValue = other.getEmotionPercentage(emotion);
      blendedEmotions[emotion] = (thisValue * (1.0 - weight)) + (otherValue * weight);
    }
    
    return EmotionMatrix(
      emotions: blendedEmotions,
      timestamp: DateTime.now(),
      confidence: (confidence + other.confidence) / 2,
      normalize: true,
    );
  }

  /// Normalize emotions so they sum to 100%
  static Map<String, double> _normalizeEmotions(Map<String, double> emotions) {
    final normalized = <String, double>{};
    final total = emotions.values.fold(0.0, (sum, value) => sum + value);
    
    if (total == 0.0) {
      // If all emotions are 0, return as-is
      for (final emotion in supportedEmotions) {
        normalized[emotion] = emotions[emotion] ?? 0.0;
      }
      return normalized;
    }
    
    // Normalize to 100%
    for (final emotion in supportedEmotions) {
      final value = emotions[emotion] ?? 0.0;
      normalized[emotion] = (value / total) * 100.0;
    }
    
    return normalized;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'emotions': _emotions,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'dominant_emotion': dominantEmotion,
      'secondary_emotion': secondaryEmotion,
      'emotional_valence': emotionalValence,
      'emotional_intensity': emotionalIntensity,
      'primary_emotions': primaryEmotions, // For backward compatibility
    };
  }

  /// Create from JSON
  factory EmotionMatrix.fromJson(Map<String, dynamic> json) {
    final emotions = <String, double>{};
    
    if (json['emotions'] is Map) {
      final emotionMap = Map<String, dynamic>.from(json['emotions']);
      for (final entry in emotionMap.entries) {
        emotions[entry.key] = (entry.value ?? 0.0).toDouble();
      }
    }
    
    // Ensure all supported emotions are present
    for (final emotion in supportedEmotions) {
      emotions.putIfAbsent(emotion, () => 0.0);
    }
    
    return EmotionMatrix(
      emotions: emotions,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      normalize: false, // Assume JSON data is already normalized
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is EmotionMatrix &&
        other.timestamp == timestamp &&
        other.confidence == confidence &&
        _mapsEqual(other._emotions, _emotions);
  }

  bool _mapsEqual(Map<String, double> map1, Map<String, double> map2) {
    if (map1.length != map2.length) return false;
    
    for (final entry in map1.entries) {
      if (!map2.containsKey(entry.key) || 
          (map2[entry.key]! - entry.value).abs() > 0.01) {
        return false;
      }
    }
    
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      timestamp,
      confidence,
      _emotions.length,
      dominantEmotion,
    );
  }

  @override
  String toString() {
    final top3 = getTopEmotions(3);
    final emotionStrings = top3.map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}%');
    return 'EmotionMatrix(dominant: $dominantEmotion, top3: [${emotionStrings.join(', ')}])';
  }
}

