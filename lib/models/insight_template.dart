import 'dart:ui';

/// Categories for insight templates
enum InsightCategory {
  growth('growth', '🌱', Color(0xFF4CAF50)),
  reflection('reflection', '🤔', Color(0xFF2196F3)),
  action('action', '⚡', Color(0xFFFF9800)),
  celebration('celebration', '🎉', Color(0xFFE91E63));

  const InsightCategory(this.id, this.emoji, this.color);
  
  final String id;
  final String emoji;
  final Color color;
}

/// Animation types for insight display
enum AnimationType {
  fadeIn('fade_in', 500),
  slideUp('slide_up', 600),
  bounce('bounce', 800),
  pulse('pulse', 400),
  scaleIn('scale_in', 450),
  flipIn('flip_in', 700),
  heartbeat('heartbeat', 1000),
  shimmer('shimmer', 900);

  const AnimationType(this.id, this.durationMs);
  
  final String id;
  final int durationMs;
}

/// Conditions for template usage
enum TemplateCondition {
  // Value-based conditions
  valueIncreased('value_increased'),
  valueDecreased('value_decreased'),
  valueStable('value_stable'),
  valueHigh('value_high'),
  valueLow('value_low'),
  valueMedium('value_medium'),
  
  // Trend-based conditions
  trendUpward('trend_upward'),
  trendDownward('trend_downward'),
  trendFlat('trend_flat'),
  
  // Time-based conditions
  firstTime('first_time'),
  milestone('milestone'),
  streak('streak'),
  newRecord('new_record'),
  
  // Emotional conditions
  moodPositive('mood_positive'),
  moodNegative('mood_negative'),
  moodMixed('mood_mixed'),
  moodNeutral('mood_neutral'),
  
  // Frequency conditions
  dailyReflection('daily_reflection'),
  weeklyInsight('weekly_insight'),
  monthlyReview('monthly_review'),
  
  // Special conditions
  breakthrough('breakthrough'),
  setback('setback'),
  recovery('recovery'),
  consistency('consistency');

  const TemplateCondition(this.id);
  
  final String id;
}

/// Priority levels for template selection
enum TemplatePriority {
  low(1),
  medium(2),
  high(3),
  critical(4);

  const TemplatePriority(this.value);
  
  final int value;
}

/// Context variables that can be used in templates
enum ContextVariable {
  // Core metrics
  coreName('coreName'),
  coreValue('coreValue'),
  corePercentage('corePercentage'),
  coreChange('coreChange'),
  coreChangeDirection('coreChangeDirection'),
  
  // Time variables
  timeframe('timeframe'),
  date('date'),
  dayOfWeek('dayOfWeek'),
  streakCount('streakCount'),
  
  // Emotional variables
  dominantEmotion('dominantEmotion'),
  emotionIntensity('emotionIntensity'),
  moodCount('moodCount'),
  
  // Pattern variables
  patternName('patternName'),
  patternFrequency('patternFrequency'),
  
  // Achievement variables
  milestoneReached('milestoneReached'),
  recordValue('recordValue'),
  improvementAmount('improvementAmount'),
  
  // Contextual variables
  entryCount('entryCount'),
  wordCount('wordCount'),
  themeCount('themeCount'),
  
  // Comparative variables
  previousValue('previousValue'),
  averageValue('averageValue'),
  bestValue('bestValue'),
  
  // Motivational variables
  encouragementPhrase('encouragementPhrase'),
  actionSuggestion('actionSuggestion'),
  celebrationPhrase('celebrationPhrase');

  const ContextVariable(this.placeholder);
  
  final String placeholder;
  
  String get formatted => '{$placeholder}';
}

/// Template for generating dynamic insights
class InsightTemplate {
  final String id;
  final String title;
  final String content;
  final InsightCategory category;
  final List<TemplateCondition> conditions;
  final List<ContextVariable> requiredVariables;
  final TemplatePriority priority;
  final AnimationType animationType;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final bool isActive;

  const InsightTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.conditions,
    required this.requiredVariables,
    this.priority = TemplatePriority.medium,
    this.animationType = AnimationType.fadeIn,
    this.metadata = const {},
    this.tags = const [],
    this.isActive = true,
  });

  /// Check if template conditions are met
  bool matchesConditions(TemplateContext context) {
    if (conditions.isEmpty) return true;
    
    return conditions.any((condition) => _evaluateCondition(condition, context));
  }

  /// Evaluate a specific condition against context
  bool _evaluateCondition(TemplateCondition condition, TemplateContext context) {
    switch (condition) {
      case TemplateCondition.valueIncreased:
        return context.getNumeric('coreChange', 0) > 0;
      case TemplateCondition.valueDecreased:
        return context.getNumeric('coreChange', 0) < 0;
      case TemplateCondition.valueStable:
        final change = context.getNumeric('coreChange', 0);
        return change.abs() < 0.05; // Within 5%
      case TemplateCondition.valueHigh:
        return context.getNumeric('coreValue', 0) >= 0.7;
      case TemplateCondition.valueLow:
        return context.getNumeric('coreValue', 0) <= 0.3;
      case TemplateCondition.valueMedium:
        final value = context.getNumeric('coreValue', 0);
        return value > 0.3 && value < 0.7;
      case TemplateCondition.trendUpward:
        return context.getString('coreChangeDirection', '') == 'up';
      case TemplateCondition.trendDownward:
        return context.getString('coreChangeDirection', '') == 'down';
      case TemplateCondition.streak:
        return context.getNumeric('streakCount', 0) >= 3;
      case TemplateCondition.milestone:
        return context.getBool('milestoneReached', false);
      case TemplateCondition.moodPositive:
        return context.getNumeric('emotionIntensity', 0) > 0.6;
      case TemplateCondition.moodNegative:
        return context.getNumeric('emotionIntensity', 0) < -0.3;
      case TemplateCondition.breakthrough:
        return context.getNumeric('improvementAmount', 0) > 0.2;
      case TemplateCondition.newRecord:
        return context.getBool('isNewRecord', false);
      default:
        return false;
    }
  }

  /// Generate insight text with variable substitution
  String generateInsight(TemplateContext context) {
    String result = content;
    
    // Replace all context variables
    for (final variable in ContextVariable.values) {
      final placeholder = variable.formatted;
      if (result.contains(placeholder)) {
        final value = context.getValue(variable.placeholder);
        result = result.replaceAll(placeholder, value?.toString() ?? '');
      }
    }
    
    // Clean up any remaining placeholders
    result = result.replaceAll(RegExp(r'\{[^}]*\}'), '');
    
    return result.trim();
  }

  /// Check if all required variables are available
  bool hasRequiredVariables(TemplateContext context) {
    return requiredVariables.every((variable) => 
        context.hasVariable(variable.placeholder));
  }

  /// Calculate template score for selection
  double calculateScore(TemplateContext context) {
    double score = priority.value.toDouble();
    
    // Bonus for exact condition matches
    final matchingConditions = conditions.where((c) => _evaluateCondition(c, context)).length;
    score += matchingConditions * 2.0;
    
    // Penalty for missing required variables
    final missingVariables = requiredVariables.where((v) => !context.hasVariable(v.placeholder)).length;
    score -= missingVariables * 1.0;
    
    // Bonus for having all variables
    if (hasRequiredVariables(context)) {
      score += 3.0;
    }
    
    return score;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category.id,
    'conditions': conditions.map((c) => c.id).toList(),
    'requiredVariables': requiredVariables.map((v) => v.placeholder).toList(),
    'priority': priority.value,
    'animationType': animationType.id,
    'metadata': metadata,
    'tags': tags,
    'isActive': isActive,
  };

  factory InsightTemplate.fromJson(Map<String, dynamic> json) {
    return InsightTemplate(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: InsightCategory.values.firstWhere((c) => c.id == json['category']),
      conditions: (json['conditions'] as List<dynamic>)
          .map((id) => TemplateCondition.values.firstWhere((c) => c.id == id))
          .toList(),
      requiredVariables: (json['requiredVariables'] as List<dynamic>)
          .map((placeholder) => ContextVariable.values.firstWhere((v) => v.placeholder == placeholder))
          .toList(),
      priority: TemplatePriority.values.firstWhere((p) => p.value == json['priority']),
      animationType: AnimationType.values.firstWhere((a) => a.id == json['animationType']),
      metadata: json['metadata'] ?? {},
      tags: List<String>.from(json['tags'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  @override
  String toString() => 'InsightTemplate($id: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Context for template evaluation and variable substitution
class TemplateContext {
  final Map<String, dynamic> _variables;

  TemplateContext(Map<String, dynamic> variables)
      : _variables = Map<String, dynamic>.from(variables);

  /// Get variable value by key
  dynamic getValue(String key) => _variables[key];

  /// Get string value with default
  String getString(String key, String defaultValue) =>
      _variables[key]?.toString() ?? defaultValue;

  /// Get numeric value with default
  double getNumeric(String key, double defaultValue) {
    final value = _variables[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Get boolean value with default
  bool getBool(String key, bool defaultValue) {
    final value = _variables[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  /// Check if variable exists
  bool hasVariable(String key) => _variables.containsKey(key);

  /// Set variable value
  void setValue(String key, dynamic value) => _variables[key] = value;

  /// Remove variable
  void removeVariable(String key) => _variables.remove(key);

  /// Get all variables
  Map<String, dynamic> getAllVariables() => Map<String, dynamic>.from(_variables);

  /// Create context from core analysis
  factory TemplateContext.fromCoreAnalysis({
    required String coreName,
    required double coreValue,
    required double previousValue,
    required String timeframe,
    String? dominantEmotion,
    double? emotionIntensity,
    int? streakCount,
    bool? milestoneReached,
    Map<String, dynamic>? additionalContext,
  }) {
    final change = coreValue - previousValue;
    final changePercentage = previousValue != 0 ? (change / previousValue * 100) : 0;
    final changeDirection = change > 0.05 ? 'up' : (change < -0.05 ? 'down' : 'stable');
    
    final variables = <String, dynamic>{
      'coreName': coreName,
      'coreValue': coreValue,
      'previousValue': previousValue,
      'coreChange': change,
      'corePercentage': changePercentage.round(),
      'coreChangeDirection': changeDirection,
      'timeframe': timeframe,
      'date': DateTime.now().toString().split(' ')[0],
      'dayOfWeek': _getDayOfWeek(DateTime.now().weekday),
    };

    if (dominantEmotion != null) variables['dominantEmotion'] = dominantEmotion;
    if (emotionIntensity != null) variables['emotionIntensity'] = emotionIntensity;
    if (streakCount != null) variables['streakCount'] = streakCount;
    if (milestoneReached != null) variables['milestoneReached'] = milestoneReached;
    
    if (additionalContext != null) {
      variables.addAll(additionalContext);
    }

    return TemplateContext(variables);
  }

  static String _getDayOfWeek(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  @override
  String toString() => 'TemplateContext($_variables)';
}

/// Template selection result
class TemplateSelection {
  final InsightTemplate template;
  final double score;
  final String generatedInsight;
  final TemplateContext context;

  TemplateSelection({
    required this.template,
    required this.score,
    required this.generatedInsight,
    required this.context,
  });

  @override
  String toString() => 'TemplateSelection(${template.id}: $score)';
}