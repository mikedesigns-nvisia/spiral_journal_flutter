import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the complete AI analysis of a journal entry
class AIAnalysis {
  final String id;
  final String entryId;
  final String userId;
  final EmotionalAnalysis emotionalAnalysis;
  final CognitivePatterns cognitivePatterns;
  final GrowthIndicators growthIndicators;
  final CoreEvolution coreEvolution;
  final PersonalizedInsights personalizedInsights;
  final DateTime analyzedAt;
  final double confidence;

  AIAnalysis({
    required this.id,
    required this.entryId,
    required this.userId,
    required this.emotionalAnalysis,
    required this.cognitivePatterns,
    required this.growthIndicators,
    required this.coreEvolution,
    required this.personalizedInsights,
    required this.analyzedAt,
    required this.confidence,
  });

  factory AIAnalysis.fromJson(Map<String, dynamic> json) {
    return AIAnalysis(
      id: json['id'] ?? '',
      entryId: json['entry_id'] ?? '',
      userId: json['user_id'] ?? '',
      emotionalAnalysis: EmotionalAnalysis.fromJson(json['emotional_analysis'] ?? {}),
      cognitivePatterns: CognitivePatterns.fromJson(json['cognitive_patterns'] ?? {}),
      growthIndicators: GrowthIndicators.fromJson(json['growth_indicators'] ?? {}),
      coreEvolution: CoreEvolution.fromJson(json['core_evolution'] ?? {}),
      personalizedInsights: PersonalizedInsights.fromJson(json['personalized_insights'] ?? {}),
      analyzedAt: json['analyzed_at'] != null 
          ? (json['analyzed_at'] as Timestamp).toDate()
          : DateTime.now(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_id': entryId,
      'user_id': userId,
      'emotional_analysis': emotionalAnalysis.toJson(),
      'cognitive_patterns': cognitivePatterns.toJson(),
      'growth_indicators': growthIndicators.toJson(),
      'core_evolution': coreEvolution.toJson(),
      'personalized_insights': personalizedInsights.toJson(),
      'analyzed_at': Timestamp.fromDate(analyzedAt),
      'confidence': confidence,
    };
  }
}

/// Emotional intelligence analysis from Claude
class EmotionalAnalysis {
  final List<String> primaryEmotions;
  final double emotionalIntensity;
  final String emotionalProgression;
  final String emotionalComplexity;
  final List<String> copingMechanisms;
  final List<String> emotionalStrengths;
  final String gentleObservations;

  EmotionalAnalysis({
    required this.primaryEmotions,
    required this.emotionalIntensity,
    required this.emotionalProgression,
    required this.emotionalComplexity,
    required this.copingMechanisms,
    required this.emotionalStrengths,
    required this.gentleObservations,
  });

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      primaryEmotions: List<String>.from(json['primary_emotions'] ?? []),
      emotionalIntensity: (json['emotional_intensity'] ?? 0.0).toDouble(),
      emotionalProgression: json['emotional_progression'] ?? '',
      emotionalComplexity: json['emotional_complexity'] ?? '',
      copingMechanisms: List<String>.from(json['coping_mechanisms'] ?? []),
      emotionalStrengths: List<String>.from(json['emotional_strengths'] ?? []),
      gentleObservations: json['gentle_observations'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_emotions': primaryEmotions,
      'emotional_intensity': emotionalIntensity,
      'emotional_progression': emotionalProgression,
      'emotional_complexity': emotionalComplexity,
      'coping_mechanisms': copingMechanisms,
      'emotional_strengths': emotionalStrengths,
      'gentle_observations': gentleObservations,
    };
  }
}

/// Cognitive pattern recognition analysis
class CognitivePatterns {
  final List<String> thinkingStyles;
  final List<String> cognitiveStrengths;
  final List<String> growthMindsetIndicators;
  final List<String> selfAwarenessSigns;
  final String problemSolvingApproach;
  final String reframingAbilities;
  final String cognitiveFlexibility;

  CognitivePatterns({
    required this.thinkingStyles,
    required this.cognitiveStrengths,
    required this.growthMindsetIndicators,
    required this.selfAwarenessSigns,
    required this.problemSolvingApproach,
    required this.reframingAbilities,
    required this.cognitiveFlexibility,
  });

  factory CognitivePatterns.fromJson(Map<String, dynamic> json) {
    return CognitivePatterns(
      thinkingStyles: List<String>.from(json['thinking_styles'] ?? []),
      cognitiveStrengths: List<String>.from(json['cognitive_strengths'] ?? []),
      growthMindsetIndicators: List<String>.from(json['growth_mindset_indicators'] ?? []),
      selfAwarenessSigns: List<String>.from(json['self_awareness_signs'] ?? []),
      problemSolvingApproach: json['problem_solving_approach'] ?? '',
      reframingAbilities: json['reframing_abilities'] ?? '',
      cognitiveFlexibility: json['cognitive_flexibility'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thinking_styles': thinkingStyles,
      'cognitive_strengths': cognitiveStrengths,
      'growth_mindset_indicators': growthMindsetIndicators,
      'self_awareness_signs': selfAwarenessSigns,
      'problem_solving_approach': problemSolvingApproach,
      'reframing_abilities': reframingAbilities,
      'cognitive_flexibility': cognitiveFlexibility,
    };
  }
}

/// Growth and development indicators
class GrowthIndicators {
  final List<String> evidenceOfGrowth;
  final List<String> areasOfDevelopment;
  final double resilienceScore;
  final double selfCompassionLevel;
  final String learningOrientation;

  GrowthIndicators({
    required this.evidenceOfGrowth,
    required this.areasOfDevelopment,
    required this.resilienceScore,
    required this.selfCompassionLevel,
    required this.learningOrientation,
  });

  factory GrowthIndicators.fromJson(Map<String, dynamic> json) {
    return GrowthIndicators(
      evidenceOfGrowth: List<String>.from(json['evidence_of_growth'] ?? []),
      areasOfDevelopment: List<String>.from(json['areas_of_development'] ?? []),
      resilienceScore: (json['resilience_score'] ?? 0.0).toDouble(),
      selfCompassionLevel: (json['self_compassion_level'] ?? 0.0).toDouble(),
      learningOrientation: json['learning_orientation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evidence_of_growth': evidenceOfGrowth,
      'areas_of_development': areasOfDevelopment,
      'resilience_score': resilienceScore,
      'self_compassion_level': selfCompassionLevel,
      'learning_orientation': learningOrientation,
    };
  }
}

/// Core personality evolution tracking
class CoreEvolution {
  final Map<String, CoreAdjustment> adjustments;

  CoreEvolution({required this.adjustments});

  factory CoreEvolution.fromJson(Map<String, dynamic> json) {
    final Map<String, CoreAdjustment> adjustments = {};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        adjustments[key] = CoreAdjustment.fromJson(value);
      }
    });
    return CoreEvolution(adjustments: adjustments);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    adjustments.forEach((key, value) {
      result[key] = value.toJson();
    });
    return result;
  }
}

/// Individual core adjustment
class CoreAdjustment {
  final int adjustment;
  final String reasoning;

  CoreAdjustment({
    required this.adjustment,
    required this.reasoning,
  });

  factory CoreAdjustment.fromJson(Map<String, dynamic> json) {
    return CoreAdjustment(
      adjustment: json['adjustment'] ?? 0,
      reasoning: json['reasoning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adjustment': adjustment,
      'reasoning': reasoning,
    };
  }
}

/// Personalized insights and encouragement
class PersonalizedInsights {
  final String patternRecognition;
  final String strengthCelebration;
  final String growthAcknowledgment;
  final String gentleSuggestion;
  final String connectionToJourney;
  final String encouragement;

  PersonalizedInsights({
    required this.patternRecognition,
    required this.strengthCelebration,
    required this.growthAcknowledgment,
    required this.gentleSuggestion,
    required this.connectionToJourney,
    required this.encouragement,
  });

  factory PersonalizedInsights.fromJson(Map<String, dynamic> json) {
    return PersonalizedInsights(
      patternRecognition: json['pattern_recognition'] ?? '',
      strengthCelebration: json['strength_celebration'] ?? '',
      growthAcknowledgment: json['growth_acknowledgment'] ?? '',
      gentleSuggestion: json['gentle_suggestion'] ?? '',
      connectionToJourney: json['connection_to_journey'] ?? '',
      encouragement: json['encouragement'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern_recognition': patternRecognition,
      'strength_celebration': strengthCelebration,
      'growth_acknowledgment': growthAcknowledgment,
      'gentle_suggestion': gentleSuggestion,
      'connection_to_journey': connectionToJourney,
      'encouragement': encouragement,
    };
  }
}
