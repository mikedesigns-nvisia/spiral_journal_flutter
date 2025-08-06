/// Stub class for EmotionalAnalysis to maintain compatibility
/// This class is kept as a stub since the actual AI analysis has been removed
class EmotionalAnalysis {
  final List<String> primaryEmotions;
  final double emotionalIntensity;
  final List<String> growthIndicators;
  final Map<String, double> coreAdjustments;
  final DateTime analyzedAt;

  EmotionalAnalysis({
    required this.primaryEmotions,
    required this.emotionalIntensity,
    required this.growthIndicators,
    required this.coreAdjustments,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      primaryEmotions: List<String>.from(json['primary_emotions'] ?? []),
      emotionalIntensity: (json['emotional_intensity'] ?? 0.0).toDouble(),
      growthIndicators: List<String>.from(json['growth_indicators'] ?? []),
      coreAdjustments: Map<String, double>.from(json['core_adjustments'] ?? {}),
      analyzedAt: json['analyzedAt'] != null 
          ? DateTime.parse(json['analyzedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_emotions': primaryEmotions,
      'emotional_intensity': emotionalIntensity,
      'growth_indicators': growthIndicators,
      'core_adjustments': coreAdjustments,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
}