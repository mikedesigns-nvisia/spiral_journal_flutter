import 'emotion_matrix.dart';

/// Enhanced EmotionalAnalysis class with comprehensive emotion matrix support
/// 
/// This class provides detailed emotional analysis with a complete emotion matrix
/// containing percentages for all emotions, plus traditional compatibility methods.
class EmotionalAnalysis {
  final EmotionMatrix emotionMatrix;
  final List<String> growthIndicators;
  final Map<String, double> coreAdjustments;
  final DateTime analyzedAt;

  EmotionalAnalysis({
    required this.emotionMatrix,
    required this.growthIndicators,
    required this.coreAdjustments,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  /// Create from primary emotions (backward compatibility)
  factory EmotionalAnalysis.fromPrimaryEmotions({
    required List<String> primaryEmotions,
    required double emotionalIntensity,
    required List<String> growthIndicators,
    required Map<String, double> coreAdjustments,
    DateTime? analyzedAt,
  }) {
    final matrix = EmotionMatrix.fromPrimaryEmotions(
      primaryEmotions: primaryEmotions,
      confidence: emotionalIntensity,
      timestamp: analyzedAt,
    );
    
    return EmotionalAnalysis(
      emotionMatrix: matrix,
      growthIndicators: growthIndicators,
      coreAdjustments: coreAdjustments,
      analyzedAt: analyzedAt,
    );
  }

  /// Get primary emotions for backward compatibility
  List<String> get primaryEmotions => emotionMatrix.primaryEmotions;

  /// Get emotional intensity for backward compatibility
  double get emotionalIntensity => emotionMatrix.emotionalIntensity;

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    EmotionMatrix matrix;
    
    if (json.containsKey('emotion_matrix')) {
      // New format with emotion matrix
      matrix = EmotionMatrix.fromJson(json['emotion_matrix']);
    } else {
      // Legacy format - convert from primary emotions
      final primaryEmotions = List<String>.from(json['primary_emotions'] ?? []);
      final emotionalIntensity = (json['emotional_intensity'] ?? 0.0).toDouble();
      matrix = EmotionMatrix.fromPrimaryEmotions(
        primaryEmotions: primaryEmotions,
        confidence: emotionalIntensity,
      );
    }
    
    return EmotionalAnalysis(
      emotionMatrix: matrix,
      growthIndicators: List<String>.from(json['growth_indicators'] ?? []),
      coreAdjustments: Map<String, double>.from(json['core_adjustments'] ?? {}),
      analyzedAt: json['analyzedAt'] != null 
          ? DateTime.parse(json['analyzedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion_matrix': emotionMatrix.toJson(),
      'growth_indicators': growthIndicators,
      'core_adjustments': coreAdjustments,
      'analyzedAt': analyzedAt.toIso8601String(),
      // Include legacy fields for backward compatibility
      'primary_emotions': primaryEmotions,
      'emotional_intensity': emotionalIntensity,
    };
  }
}